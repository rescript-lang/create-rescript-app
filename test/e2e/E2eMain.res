open Node
module P = E2eProcess

type arguments = {
  packagePath: option<string>,
  manager: option<PackageManagers.packageManager>,
  logs: option<string>,
}

let usage = "Usage: npm run test:e2e -- --package <tarball> --manager <npm|pnpm|yarn-classic|yarn-berry|bun> --logs <directory>"

let rec parseArguments = (remaining, arguments: arguments) =>
  switch remaining {
  | list{"--package", value, ...rest} =>
    parseArguments(rest, {...arguments, packagePath: Some(value)})
  | list{"--logs", value, ...rest} => parseArguments(rest, {...arguments, logs: Some(value)})
  | list{"--manager", value, ...rest} =>
    let? Ok(manager) = P.parseManager(value)
    parseArguments(rest, {...arguments, manager: Some(manager)})
  | list{} =>
    switch arguments {
    | {packagePath: Some(packagePath), manager: Some(manager), logs: Some(logs)} =>
      Ok({P.packagePath, manager, logs})
    | _ => Error(#InvalidArguments(usage))
    }
  | _ => Error(#InvalidArguments(usage))
  }

@scope(("import", "meta")) external importMetaUrl: Url.t = "url"

let runSuite = async (context, options: P.options) => {
  let launcherPath = Path.join2(importMetaUrl->Url.fileURLToPath->Path.dirname, "E2eLaunch.res.mjs")
  let? Ok() = await P.setup(context, ~packagePath=options.packagePath, ~launcherPath)
  await E2eScenarios.execute(context)
}

let runInWorkspace = async (options, workspace) => {
  let? Ok(context) = P.makeContext(options, workspace)

  let outcome = try {
    await runSuite(context, options)
  } catch {
  | JsExn(cause) => Error(#TestFailure(cause))
  }

  switch outcome {
  | Ok() => ()
  | Error(_) =>
    if Fs.existsSync(context.log.contents) {
      switch P.fileOperation(context.log.contents, () => Fs.readFileSync(context.log.contents)) {
      | Ok(log) => Console.error(log)
      | Error(error) => Console.error(P.formatError(error))
      }
    }
    Console.error(`FAIL ${context.info.name}; log: ${context.log.contents}`)
  }
  outcome
}

let main = async () => {
  let? Ok() = switch Process.platform {
  | "linux" => Ok()
  | platform => Error(#UnsupportedPlatform(platform))
  }

  let? Ok(options) = parseArguments(
    Process.argv->Array.slice(~start=2)->List.fromArray,
    {packagePath: None, manager: None, logs: None},
  )

  let prefix = Path.join2(Os.tmpdir(), "cra e2e ")
  let? Ok(workspace) = P.fileOperation(prefix, () => Fs.mkdtempSync(prefix))

  let outcome = try await runInWorkspace(options, workspace) catch {
  | JsExn(cause) => Error(#TestFailure(cause))
  }

  let cleanup = try {
    await Fs.Promises.rm(workspace, ~options={recursive: true, force: true})
    Ok()
  } catch {
  | JsExn(cause) => Error(#FileError({P.path: workspace, cause}))
  }

  switch (outcome, cleanup) {
  | (Error(primary), Error(secondary)) =>
    Console.error(`Workspace cleanup also failed:\n${P.formatError(secondary)}`)
    Error(primary)
  | (Error(_), _) => outcome
  | (Ok(), _) => cleanup
  }
}

let run = async () =>
  switch await main() {
  | Ok() => ()
  | Error(error) =>
    Console.error(P.formatError(error))
    Process.state.exitCode = 1
  }

run()
->Promise.catch(error => {
  Console.error(error)
  Process.state.exitCode = 1
  Promise.resolve()
})
->Promise.ignore
