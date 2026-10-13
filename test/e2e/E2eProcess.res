open Node

type managerInfo = {name: string, command: string, lockfile: string}

type options = {
  packagePath: string,
  manager: PackageManagers.packageManager,
  logs: string,
}

type context = {
  manager: PackageManagers.packageManager,
  info: managerInfo,
  workspace: string,
  logs: string,
  log: ref<string>,
  launcher: string,
  env: Dict.t<string>,
}

type prompt = (string, string)
type commandMode = Piped | Terminal(array<prompt>)
type fileError = {path: string, cause: JsExn.t}
type exitError = {command: string, actual: option<int>, signal: option<string>, expected: int}
type promptError = {answered: int, expected: int}

type error = [
  | #InvalidArguments(string)
  | #UnsupportedPlatform(string)
  | #SpawnError(JsExn.t)
  | #InputError(JsExn.t)
  | #SignalError(JsExn.t)
  | #FileError(fileError)
  | #CommandTimedOut(string)
  | #UnexpectedExit(exitError)
  | #UnansweredPrompts(promptError)
  | #TestFailure(JsExn.t)
]

let describeCause = cause =>
  JsExn.stack(cause)->Option.orElse(JsExn.message(cause))->Option.getOr("Unknown error")

let formatError = (error: error) =>
  switch error {
  | #InvalidArguments(message) => message
  | #UnsupportedPlatform(platform) =>
    `The E2E terminal runner requires Linux with util-linux script; got ${platform}`
  | #SpawnError(cause) => `Could not start command:\n${describeCause(cause)}`
  | #InputError(cause) => `Could not answer CLI prompt:\n${describeCause(cause)}`
  | #SignalError(cause) => `Could not stop process group:\n${describeCause(cause)}`
  | #FileError({path, cause}) => `File operation failed: ${path}\n${describeCause(cause)}`
  | #CommandTimedOut(command) => `Command timed out: ${command}`
  | #UnexpectedExit({command, actual, signal, expected}) =>
    let status = switch actual {
    | Some(code) => code->Int.toString
    | None => signal->Option.getOr("unknown signal")
    }

    `Command exited ${status}, expected ${expected->Int.toString}: ${command}`
  | #UnansweredPrompts({answered, expected}) =>
    `CLI exited after answering ${answered->Int.toString} of ${expected->Int.toString} prompts`
  | #TestFailure(cause) => describeCause(cause)
  }

let fileOperation = (path, perform) =>
  try Ok(perform()) catch {
  | JsExn(cause) => Error(#FileError({path, cause}))
  }

let writeFile = (path, contents) => fileOperation(path, () => Fs.writeFileSync(path, contents))
let makeDirectory = path => fileOperation(path, () => Fs.mkdirSync(path, {recursive: true}))

let appendLog = (context, contents) =>
  fileOperation(context.log.contents, () => Fs.appendFileSync(context.log.contents, contents))

let managerInfo = (manager: PackageManagers.packageManager) =>
  switch manager {
  | Npm => {name: "npm", command: "npm", lockfile: "package-lock.json"}
  | Pnpm => {name: "pnpm", command: "pnpm", lockfile: "pnpm-lock.yaml"}
  | Yarn1 => {name: "yarn-classic", command: "yarn", lockfile: "yarn.lock"}
  | YarnBerry => {name: "yarn-berry", command: "yarn", lockfile: "yarn.lock"}
  | Bun => {name: "bun", command: "bun", lockfile: "bun.lock"}
  }

let parseManager = (name): result<PackageManagers.packageManager, [> #InvalidArguments(string)]> =>
  switch name {
  | "npm" => Ok(Npm)
  | "pnpm" => Ok(Pnpm)
  | "yarn-classic" => Ok(Yarn1)
  | "yarn-berry" => Ok(YarnBerry)
  | "bun" => Ok(Bun)
  | _ => Error(#InvalidArguments(`Unknown package manager: ${name}`))
  }

let quote = value => `'${value->String.replaceAll("'", "'\\''")}'`
let shellJoin = command => command->Array.map(quote)->Array.join(" ")
let readJson = path => Fs.readFileSync(path)->JSON.parseOrThrow
let writeJson = (path, json) => writeFile(path, `${JSON.stringify(json, ~space=2)}\n`)

let makeContext = (options: options, workspace) => {
  let logs = Path.resolve(options.logs)
  let? Ok() = makeDirectory(logs)
  let env = Process.env->Dict.copy
  [
    ("CI", "false"),
    ("TERM", "xterm"),
    ("NO_COLOR", "1"),
    ("NPM_CONFIG_AUDIT", "false"),
    ("NPM_CONFIG_FUND", "false"),
    ("YARN_ENABLE_TELEMETRY", "0"),
  ]->Array.forEach(((name, value)) => env->Dict.set(name, value))
  // Let each manager supply its own identity, rather than inherit npm run test:e2e's.
  [
    "FORCE_COLOR",
    "npm_execpath",
    "npm_config_user_agent",
    "npm_node_execpath",
    "INIT_CWD",
  ]->Array.forEach(name => env->Dict.delete(name))
  Ok({
    manager: options.manager,
    info: managerInfo(options.manager),
    workspace,
    logs,
    log: ref(Path.join2(logs, "setup.log")),
    launcher: Path.join2(workspace, "launcher"),
    env,
  })
}

let killGroup = (child, signal) =>
  switch child->ChildProcess.pid {
  | None => Ok()
  | Some(pid) =>
    switch Process.kill(-pid, signal) {
    | Error(#SignalError(cause)) if cause->errorCode === Some("ESRCH") => Ok()
    | outcome => outcome
    }
  }

let runCommand = async (context, command, cwd, ~expected, ~mode, ~timeoutMs): result<
  string,
  error,
> => {
  let commandText = shellJoin(command)
  let? Ok() = appendLog(context, `\n$ ${commandText}\n(cwd: ${cwd})\n`)

  // util-linux script supplies a real terminal; all control and assertions are ReScript.
  let (executable, args, prompts, stdinMode) = switch mode {
  | Terminal(prompts) => (
      "script",
      [
        "--quiet",
        "--return",
        "--echo=never",
        "--command",
        `stty cols 160 rows 40; exec ${commandText}`,
        "/dev/null",
      ],
      prompts,
      "pipe",
    )
  | Piped =>
    switch command->List.fromArray {
    | list{executable, ...args} => (executable, args->List.toArray, [], "ignore")
    | list{} => Assert.fail("Cannot run an empty command")
    }
  }

  let? Ok(child) = ChildProcess.spawn(
    executable,
    args,
    {
      cwd,
      env: context.env,
      detached: true,
      stdio: [stdinMode, "pipe", "pipe"],
    },
  )

  // Mutable state is confined to this command's Node event callbacks.
  let output = ref("")
  let pending = ref("")
  let nextPrompt = ref(0)
  let failure = ref(None)
  let forceKill = ref(None)

  let recordFailure = error =>
    switch failure.contents {
    | None => failure := Some(error)
    | Some(_) => ()
    }

  let stop = signal =>
    switch killGroup(child, signal) {
    | Ok() => ()
    | Error(error) => recordFailure(error)
    }

  let terminate = () => {
    stop("SIGTERM")
    switch forceKill.contents {
    | None => forceKill := Some(Timer.setTimeout(() => stop("SIGKILL"), 3000))
    | Some(_) => ()
    }
  }

  let timeout = Timer.setTimeout(() => {
    recordFailure(#CommandTimedOut(commandText))
    terminate()
  }, timeoutMs)

  let collect = chunk => {
    output := output.contents ++ chunk
    pending := pending.contents ++ chunk

    let outcome = () => {
      let? Ok() = appendLog(context, chunk)
      switch (prompts->Array.get(nextPrompt.contents), child->ChildProcess.stdin) {
      | (Some((question, answer)), Some(stdin)) if pending.contents->String.includes(question) =>
        let? Ok() = stdin->ChildProcess.write(answer)
        nextPrompt := nextPrompt.contents + 1
        pending := ""
        Ok()
      | _ => Ok()
      }
    }

    switch outcome() {
    | Ok() => ()
    | Error(error) =>
      recordFailure(error)
      terminate()
    }
  }

  [child->ChildProcess.stdout, child->ChildProcess.stderr]->Array.forEach(stream => {
    stream->ChildProcess.setEncoding
    stream->ChildProcess.onData(collect)
  })
  child
  ->ChildProcess.stdin
  ->Option.forEach(stdin =>
    stdin->ChildProcess.onInputError(error => {
      if error->errorCode !== Some("EPIPE") {
        recordFailure(#InputError(error))
        terminate()
      }
    })
  )

  let (code, signal) = await Promise.make((resolve, _reject) => {
    child->ChildProcess.onError(error => recordFailure(#SpawnError(error)))
    child->ChildProcess.onClose((code, signal) => resolve((code, signal)))
  })

  timeout->Timer.clearTimeout
  forceKill.contents->Option.forEach(Timer.clearTimeout)
  child->ChildProcess.stdin->Option.forEach(ChildProcess.destroyInput)

  // No early propagation until timers and streams have been cleaned up.
  let? Ok() = switch failure.contents {
  | Some(error) => Error(error)
  | None => Ok()
  }

  let actual = code->Nullable.toOption
  switch (actual === Some(expected), nextPrompt.contents === prompts->Array.length) {
  | (false, _) =>
    Error(
      #UnexpectedExit({command: commandText, actual, signal: signal->Nullable.toOption, expected}),
    )
  | (_, false) =>
    Error(#UnansweredPrompts({answered: nextPrompt.contents, expected: prompts->Array.length}))
  | _ => Ok(output.contents)
  }
}

let run = (context, command, cwd) =>
  runCommand(context, command, cwd, ~expected=0, ~mode=Piped, ~timeoutMs=300_000)

let cli = async (context, cwd, ~args, ~expected, ~prompts) => {
  let separator = switch context.manager {
  | Npm => ["--"]
  | _ => []
  }

  let? Ok(_) = await runCommand(
    context,
    [context.info.command, "run", "cra", ...separator, cwd, ...args],
    context.launcher,
    ~expected,
    ~mode=Terminal(prompts),
    ~timeoutMs=300_000,
  )

  Ok()
}

let setup = async (context, ~packagePath, ~launcherPath) => {
  let? Ok(_) = await run(context, ["node", "--version"], context.workspace)
  let? Ok(_) = await run(context, [context.info.command, "--version"], context.workspace)
  let cliDirectory = Path.join2(context.workspace, "cli")

  let? Ok(_) = await run(
    context,
    ["npm", "install", "--prefix", cliDirectory, Path.resolve(packagePath)],
    context.workspace,
  )

  context.env->Dict.set(
    "CRA_E2E_CLI",
    Path.join2(cliDirectory, "node_modules/create-rescript-app/out/create-rescript-app.cjs"),
  )
  let? Ok() = makeDirectory(context.launcher)

  let? Ok() = writeJson(
    Path.join2(context.launcher, "package.json"),
    JSON.parseOrThrow(
      `{
    "name": "cra-e2e-launcher",
    "private": true,
    "scripts": {"cra": ${JSON.stringify(JSON.String(shellJoin(["node", launcherPath])))}}
  }`,
    ),
  )

  let? Ok() = switch context.manager {
  | YarnBerry =>
    writeFile(Path.join2(context.launcher, ".yarnrc.yml"), "nodeLinker: node-modules\n")
  | _ => Ok()
  }

  let? Ok(_) = await run(context, [context.info.command, "install"], context.launcher)
  Ok()
}

let runCase = async (context, name, perform) => {
  context.log := Path.join2(context.logs, `${name}.log`)
  let? Ok() = writeFile(context.log.contents, "")
  let directory = Path.join2(context.workspace, name)
  let? Ok() = makeDirectory(directory)
  Console.log(`RUN ${context.info.name}: ${name}`)

  let? Ok() = try await perform(directory) catch {
  | JsExn(cause) => Error(#TestFailure(cause))
  }

  Console.log(`PASS ${context.info.name}: ${name}`)
  Ok()
}
