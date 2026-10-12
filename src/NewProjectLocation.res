open Node

let currentDirectoryArgument = "."
let packageNameRegExp = /^[a-z0-9-]+$/
let devcontainerDirectoryName = ".devcontainer"

let allowedCurrentDirectoryEntries = [
  ".git",
  ".gitattributes",
  ".gitignore",
  "licence",
  "licence.md",
  "license",
  "license.md",
  "readme",
  "readme.md",
]

let isCurrentDirectoryProject = projectName =>
  switch projectName {
  | "." | "./" => true
  | _ => false
  }

let getPackageName = (~cwd=Process.cwd(), projectName) =>
  isCurrentDirectoryProject(projectName) ? Path.basename(cwd) : projectName

let getProjectPath = (~cwd=Process.cwd(), projectName) =>
  isCurrentDirectoryProject(projectName) ? cwd : Path.join2(cwd, projectName)

let hasDevcontainerDirectory = projectPath =>
  try {
    Path.join2(projectPath, devcontainerDirectoryName)->Fs.statSync->Fs.Stats.isDirectory
  } catch {
  | Exn.Error(_) => false
  }

let containsOnlyDevcontainerDirectory = projectPath =>
  try {
    switch Fs.readdirSync(projectPath) {
    | [entry] if entry === devcontainerDirectoryName => hasDevcontainerDirectory(projectPath)
    | _ => false
    }
  } catch {
  | Exn.Error(_) => false
  }

let isAllowedCurrentDirectoryEntry = (~cwd, entry) => {
  let normalizedEntry = entry->String.toLowerCase

  switch entry {
  | ".devcontainer" => hasDevcontainerDirectory(cwd)
  | _ =>
    allowedCurrentDirectoryEntries
    ->Array.find(allowedEntry => allowedEntry === normalizedEntry)
    ->Option.isSome
  }
}

let validateCurrentDirectory = cwd => {
  let disallowedEntries =
    Fs.readdirSync(cwd)->Array.filter(entry => !isAllowedCurrentDirectoryEntry(~cwd, entry))

  switch disallowedEntries {
  | [] => Ok()
  | _ => Error("The current directory contains files that could conflict with project creation.")
  }
}

let validateProjectName = (~cwd=Process.cwd(), projectName) => {
  let packageName = getPackageName(~cwd, projectName)

  if packageName->String.trim->String.length === 0 {
    Error("Project name must not be empty.")
  } else if !(packageNameRegExp->RegExp.test(packageName)) {
    Error("Project name may only contain lower case letters, numbers and hyphens.")
  } else if isCurrentDirectoryProject(projectName) {
    validateCurrentDirectory(cwd)
  } else if (
    Fs.existsSync(getProjectPath(~cwd, projectName)) &&
    !(getProjectPath(~cwd, projectName)->containsOnlyDevcontainerDirectory)
  ) {
    Error(`The folder ${projectName} already exist in the current directory.`)
  } else {
    Ok()
  }
}
