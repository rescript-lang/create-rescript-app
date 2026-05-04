open Node

let packageNameRegExp = /^[a-z0-9-]+$/
let devcontainerDirectoryName = ".devcontainer"

let containsOnlyDevcontainerDirectory = projectPath =>
  try {
    switch Fs.readdirSync(projectPath) {
    | [entry] if entry === devcontainerDirectoryName =>
      Path.join2(projectPath, devcontainerDirectoryName)->Fs.statSync->Fs.Stats.isDirectory
    | _ => false
    }
  } catch {
  | Exn.Error(_) => false
  }

let validateProjectName = (~cwd=Process.cwd(), projectName) =>
  if projectName->String.trim->String.length === 0 {
    Error("Project name must not be empty.")
  } else if !(packageNameRegExp->RegExp.test(projectName)) {
    Error("Project name may only contain lower case letters, numbers and hyphens.")
  } else {
    let projectPath = Path.join2(cwd, projectName)

    if Fs.existsSync(projectPath) && !(projectPath->containsOnlyDevcontainerDirectory) {
      Error(`The folder ${projectName} already exist in the current directory.`)
    } else {
      Ok()
    }
  }
