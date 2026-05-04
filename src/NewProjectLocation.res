open Node

let currentDirectoryArgument = "."
let packageNameRegExp = /^[a-z0-9-]+$/

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

let isCurrentDirectoryProject = projectName => projectName === currentDirectoryArgument

let getPackageName = (~cwd=Process.cwd(), projectName) =>
  isCurrentDirectoryProject(projectName) ? Path.basename(cwd) : projectName

let getProjectPath = (~cwd=Process.cwd(), projectName) =>
  isCurrentDirectoryProject(projectName) ? cwd : Path.join2(cwd, projectName)

let isAllowedCurrentDirectoryEntry = entry => {
  let normalizedEntry = entry->String.toLowerCase

  allowedCurrentDirectoryEntries
  ->Array.find(allowedEntry => allowedEntry === normalizedEntry)
  ->Option.isSome
}

let validateCurrentDirectory = cwd => {
  let disallowedEntries =
    Fs.readdirSync(cwd)->Array.filter(entry => !(entry->isAllowedCurrentDirectoryEntry))

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
  } else if Fs.existsSync(getProjectPath(~cwd, projectName)) {
    Error(`The folder ${projectName} already exist in the current directory.`)
  } else {
    Ok()
  }
}
