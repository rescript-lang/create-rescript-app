open Node

type manager = Npm | Pnpm | YarnClassic | YarnBerry | Bun
type managerInfo = {name: string, command: string, lockfile: string}
type options = {packagePath: string, manager: manager, logs: string}
type context = {
  manager: manager,
  info: managerInfo,
  workspace: string,
  logs: string,
  log: ref<string>,
  launcher: string,
  env: Dict.t<string>,
}
type prompt = (string, string)
type commandMode = Piped | Terminal(array<prompt>)

let managerInfo = manager =>
  switch manager {
  | Npm => {name: "npm", command: "npm", lockfile: "package-lock.json"}
  | Pnpm => {name: "pnpm", command: "pnpm", lockfile: "pnpm-lock.yaml"}
  | YarnClassic => {name: "yarn-classic", command: "yarn", lockfile: "yarn.lock"}
  | YarnBerry => {name: "yarn-berry", command: "yarn", lockfile: "yarn.lock"}
  | Bun => {name: "bun", command: "bun", lockfile: "bun.lock"}
  }

let parseManager = name =>
  switch name {
  | "npm" => Ok(Npm)
  | "pnpm" => Ok(Pnpm)
  | "yarn-classic" => Ok(YarnClassic)
  | "yarn-berry" => Ok(YarnBerry)
  | "bun" => Ok(Bun)
  | _ => Error(`Unknown package manager: ${name}`)
  }

let quote = value => `'${value->String.replaceAll("'", "'\\''")}'`
let shellJoin = command => command->Array.map(quote)->Array.join(" ")
let readJson = path => Fs.readFileSync(path)->JSON.parseOrThrow
let writeJson = (path, json) => Fs.writeFileSync(path, `${JSON.stringify(json, ~space=2)}\n`)

let makeContext = (options: options, workspace) => {
  let logs = Path.resolve(options.logs)
  Fs.mkdirSync(logs, {recursive: true})
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
  {
    manager: options.manager,
    info: managerInfo(options.manager),
    workspace,
    logs,
    log: ref(Path.join2(logs, "setup.log")),
    launcher: Path.join2(workspace, "launcher"),
    env,
  }
}

let killGroup = (child, signal) =>
  child
  ->ChildProcess.pid
  ->Option.forEach(pid => {
    try Process.kill(-pid, signal) catch {
    | JsExn(error) if error->errorCode === Some("ESRCH") => ()
    }
  })

let runCommand = async (context, command, cwd, ~expected, ~mode) => {
  let commandText = shellJoin(command)
  Fs.appendFileSync(context.log.contents, `\n$ ${commandText}\n(cwd: ${cwd})\n`)
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
  let child = ChildProcess.spawn(
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
  let timedOut = ref(false)
  let inputError = ref(None)
  let forceKill = ref(None)
  let timeout = Timer.setTimeout(() => {
    timedOut := true
    killGroup(child, "SIGTERM")
    forceKill := Some(Timer.setTimeout(() => killGroup(child, "SIGKILL"), 3000))
  }, 300_000)
  let collect = chunk => {
    output := output.contents ++ chunk
    pending := pending.contents ++ chunk
    Fs.appendFileSync(context.log.contents, chunk)
    switch (prompts->Array.get(nextPrompt.contents), child->ChildProcess.stdin) {
    | (Some((question, answer)), Some(stdin)) if pending.contents->String.includes(question) =>
      stdin->ChildProcess.write(answer)
      nextPrompt := nextPrompt.contents + 1
      pending := ""
    | _ => ()
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
        inputError := Some(error)
        killGroup(child, "SIGTERM")
      }
    })
  )
  let completion = await Promise.make((resolve, _reject) => {
    child->ChildProcess.onError(error => resolve(Error(error)))
    child->ChildProcess.onClose((code, signal) => resolve(Ok((code, signal))))
  })
  timeout->Timer.clearTimeout
  forceKill.contents->Option.forEach(Timer.clearTimeout)
  child->ChildProcess.stdin->Option.forEach(ChildProcess.destroyInput)
  inputError.contents->Option.forEach(JsExn.throw)
  Assert.ok(!timedOut.contents, `Command timed out: ${commandText}`)
  switch completion {
  | Error(error) => JsExn.throw(error)
  | Ok((code, signal)) =>
    let actual = code->Nullable.toOption
    let description = switch actual {
    | Some(code) => code->Int.toString
    | None => signal->Nullable.toOption->Option.getOr("unknown signal")
    }
    Assert.strictEqual(
      actual,
      Some(expected),
      ~message=`Command exited ${description}, expected ${expected->Int.toString}: ${commandText}`,
    )
  }
  Assert.strictEqual(
    nextPrompt.contents,
    prompts->Array.length,
    ~message="CLI exited before answering all prompts",
  )
  output.contents
}

let run = (context, command, cwd) => runCommand(context, command, cwd, ~expected=0, ~mode=Piped)

let cli = async (context, cwd, ~args, ~expected, ~prompts) => {
  let separator = switch context.manager {
  | Npm => ["--"]
  | _ => []
  }
  let _ = await runCommand(
    context,
    [context.info.command, "run", "cra", ...separator, cwd, ...args],
    context.launcher,
    ~expected,
    ~mode=Terminal(prompts),
  )
}

let setup = async (context, ~packagePath, ~launcherPath) => {
  let _ = await run(context, ["node", "--version"], context.workspace)
  let _ = await run(context, [context.info.command, "--version"], context.workspace)
  let cliDirectory = Path.join2(context.workspace, "cli")
  let _ = await run(
    context,
    ["npm", "install", "--prefix", cliDirectory, Path.resolve(packagePath)],
    context.workspace,
  )
  context.env->Dict.set(
    "CRA_E2E_CLI",
    Path.join2(cliDirectory, "node_modules/create-rescript-app/out/create-rescript-app.cjs"),
  )
  Fs.mkdirSync(context.launcher, {recursive: true})
  writeJson(
    Path.join2(context.launcher, "package.json"),
    JSON.parseOrThrow(
      `{
    "name": "cra-e2e-launcher",
    "private": true,
    "scripts": {"cra": ${JSON.stringify(JSON.String(shellJoin(["node", launcherPath])))}}
  }`,
    ),
  )
  switch context.manager {
  | YarnBerry =>
    Fs.writeFileSync(Path.join2(context.launcher, ".yarnrc.yml"), "nodeLinker: node-modules\n")
  | _ => ()
  }
  let _ = await run(context, [context.info.command, "install"], context.launcher)
}

let runCase = async (context, name, perform) => {
  context.log := Path.join2(context.logs, `${name}.log`)
  Fs.writeFileSync(context.log.contents, "")
  let directory = Path.join2(context.workspace, name)
  Fs.mkdirSync(directory, {recursive: true})
  Console.log(`RUN ${context.info.name}: ${name}`)
  await perform(directory)
  Console.log(`PASS ${context.info.name}: ${name}`)
}
