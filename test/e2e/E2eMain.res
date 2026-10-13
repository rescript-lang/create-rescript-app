open Node
module N = E2eNode
module P = E2eProcess

type arguments = {packagePath: option<string>, manager: option<P.manager>, logs: option<string>}

let usage = "Usage: npm run test:e2e -- --package <tarball> --manager <npm|pnpm|yarn-classic|yarn-berry|bun> --logs <directory>"

let rec parseArguments = (remaining, arguments: arguments) =>
  switch remaining {
  | list{"--package", value, ...rest} =>
    parseArguments(rest, {...arguments, packagePath: Some(value)})
  | list{"--logs", value, ...rest} => parseArguments(rest, {...arguments, logs: Some(value)})
  | list{"--manager", value, ...rest} =>
    switch P.parseManager(value) {
    | Ok(manager) => parseArguments(rest, {...arguments, manager: Some(manager)})
    | Error(message) => Error(message)
    }
  | list{} =>
    switch arguments {
    | {packagePath: Some(packagePath), manager: Some(manager), logs: Some(logs)} =>
      Ok({P.packagePath, manager, logs})
    | _ => Error(usage)
    }
  | _ => Error(usage)
  }

@scope(("import", "meta")) external importMetaUrl: Url.t = "url"

let main = async () => {
  N.Assert.equal(
    N.Process.platform,
    "linux",
    "The E2E terminal runner requires Linux with util-linux script",
  )
  let options = switch parseArguments(
    Process.argv->Array.slice(~start=2)->List.fromArray,
    {packagePath: None, manager: None, logs: None},
  ) {
  | Ok(options) => options
  | Error(message) => N.Assert.fail(message)
  }
  let workspace = N.Fs.mkdtemp(Path.join2(N.Os.tmpdir(), "cra e2e "))
  let context = P.makeContext(options, workspace)
  let outcome = try {
    let launcherPath = Path.join2(
      importMetaUrl->Url.fileURLToPath->Path.dirname,
      "E2eLaunch.res.mjs",
    )
    await P.setup(context, ~packagePath=options.packagePath, ~launcherPath)
    await E2eScenarios.execute(context)
    Ok()
  } catch {
  | JsExn(error) => Error(error)
  }
  await Fs.Promises.rm(workspace, ~options={recursive: true, force: true})
  switch outcome {
  | Ok() => ()
  | Error(error) =>
    if Fs.existsSync(context.log.contents) {
      Console.error(Fs.readFileSync(context.log.contents))
    }
    Console.error(`FAIL ${context.info.name}; log: ${context.log.contents}`)
    Console.error(error)
    N.Process.state.exitCode = 1
  }
}

main()
->Promise.catch(error => {
  Console.error(error)
  N.Process.state.exitCode = 1
  Promise.resolve()
})
->Promise.ignore
