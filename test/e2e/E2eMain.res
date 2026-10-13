open Node
module P = E2eProcess

type arguments = {packagePath: option<string>, manager: option<P.manager>, logs: option<string>}

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
    | _ => Error(usage)
    }
  | _ => Error(usage)
  }

@scope(("import", "meta")) external importMetaUrl: Url.t = "url"

let main = async () => {
  Assert.strictEqual(
    Process.platform,
    "linux",
    ~message="The E2E terminal runner requires Linux with util-linux script",
  )
  let? Ok(options) = parseArguments(
    Process.argv->Array.slice(~start=2)->List.fromArray,
    {packagePath: None, manager: None, logs: None},
  )
  let workspace = Fs.mkdtempSync(Path.join2(Os.tmpdir(), "cra e2e "))
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
  outcome->Result.mapError(error => {
    if Fs.existsSync(context.log.contents) {
      Console.error(Fs.readFileSync(context.log.contents))
    }
    let detail =
      JsExn.stack(error)->Option.orElse(JsExn.message(error))->Option.getOr("Unknown error")
    `FAIL ${context.info.name}; log: ${context.log.contents}\n${detail}`
  })
}

let run = async () =>
  switch await main() {
  | Ok() => ()
  | Error(message) =>
    Console.error(message)
    Process.state.exitCode = 1
  }

run()
->Promise.catch(error => {
  Console.error(error)
  Process.state.exitCode = 1
  Promise.resolve()
})
->Promise.ignore
