open Node

module C = PicoColors
module P = ClackPrompts

let getVersion = async () => {
  let json = await JsonUtils.readJsonFile(CraPaths.packageJsonPath)
  json->JsonUtils.getStringValue(~fieldName="version")->Option.getOr("")
}

let handleError = async (~outro, perform) =>
  try await perform() catch {
  | P.Canceled => P.cancel("Canceled.")
  | Exn.Error(error) =>
    switch error->Exn.message {
    | Some(message) => P.Log.error("Error: " ++ message)
    | None => ()
    }

    P.outro(outro)

    Process.exitWithCode(1)
  }

let run = async () => {
  let version = await getVersion()
  P.intro(C.dim(`create-rescript-app ${version}`))

  P.note(
    ~title="Welcome to ReScript!",
    ~message=`${C.cyan("Fast, Simple, Fully Typed JavaScript from the Future")}
https://www.rescript-lang.org`,
  )

  let packageJsonPath = Path.join2(Process.cwd(), "package.json")
  if Fs.existsSync(packageJsonPath) {
    let packageJson = await JsonUtils.readJsonFile(packageJsonPath)
    let projectName =
      packageJson->JsonUtils.getStringValue(~fieldName="name")->Option.getOr("unknown")

    let addToExistingProject = await P.confirm({
      message: `Detected a package.json file. Do you want to add ReScript to "${projectName}"?`,
    })->P.resultOrRaise

    if addToExistingProject {
      await handleError(~outro="Adding to project failed.", async () => {
        await ExistingProject.addToExistingProject(~projectName)
        P.outro("Happy hacking!")
      })
    } else {
      P.outro("No changes were made to your project.")
    }
  } else {
    await handleError(~outro="Project creation failed.", async () => {
      await NewProject.createNewProject()
      P.outro("Happy hacking!")
    })
  }
}

await run()
