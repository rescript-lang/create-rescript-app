open Node

module C = PicoColors
module P = ClackPrompts

let getVersion = async () => {
  let json = await JsonUtils.readJsonFile(CraPaths.packageJsonPath)
  json->JsonUtils.getStringValue(~fieldName="version")->Option.getOr("")
}

let handleError = async (~outro, perform) =>
  try await perform() catch {
  | JsExn(error) =>
    P.Log.error("Error: " ++ error->ErrorUtils.getErrorMessage)

    P.outro(outro)

    Process.exitWithCode(1)
  }

let main = async () => {
  let version = await getVersion()
  P.intro(C.dim(`create-rescript-app ${version}`))

  P.note(
    ~title="Welcome to ReScript!",
    ~message=`${C.cyan("Fast, Simple, Fully Typed JavaScript from the Future")}
https://rescript-lang.org`,
  )

  let packageJsonPath = Path.join2(Process.cwd(), "package.json")
  let rescriptJsonPath = Path.join2(Process.cwd(), "rescript.json")
  let bsconfigJsonPath = Path.join2(Process.cwd(), "bsconfig.json")

  if CI.isRunningInCI {
    P.note(~title="CI Mode", ~message="Running in CI, will create a test project")
    await handleError(~outro="Project creation failed.", async () => {
      await NewProject.createNewProject()
      P.outro("CI test completed successfully.")
    })
  } else if Fs.existsSync(rescriptJsonPath) || Fs.existsSync(bsconfigJsonPath) {
    ExistingRescriptProject.showUpgradeHint()
    P.outro("No changes were made to your project.")
  } else if Fs.existsSync(packageJsonPath) {
    let packageJson = await JsonUtils.readJsonFile(packageJsonPath)
    let projectName =
      packageJson->JsonUtils.getStringValue(~fieldName="name")->Option.getOr("unknown")

    let addToExistingProject = await P.confirm({
      message: `Detected a package.json file. Do you want to add ReScript to "${projectName}"?`,
    })->P.resultOrRaise

    if addToExistingProject {
      await handleError(~outro="Adding to project failed.", async () => {
        await ExistingJsProject.addToExistingProject(~projectName)
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

// Do not use top-level await, otherwise we can't package as .cjs.
let run = async () =>
  try await main() catch {
  | P.Canceled => P.cancel("Canceled.")
  }

run()->Promise.ignore
