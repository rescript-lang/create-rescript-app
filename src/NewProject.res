open Node

module P = ClackPrompts

let packageNameRegExp = %re("/^[a-z0-9-]+$/")

let validateProjectName = projectName =>
  if projectName->String.trim->String.length === 0 {
    Some("Project name must not be empty.")
  } else if !(packageNameRegExp->RegExp.test(projectName)) {
    Some("Project name may only contain lower case letters, numbers and hyphens.")
  } else if Fs.existsSync(Path.join2(Process.cwd(), projectName)) {
    Some(`The folder ${projectName} already exist in the current directory.`)
  } else {
    None
  }

let updatePackageJson = async (~projectName) =>
  await JsonUtils.updateJsonFile("package.json", json =>
    switch json {
    | Object(config) => config->Dict.set("name", String(projectName))
    | _ => ()
    }
  )

let updateRescriptJson = async (~projectName) =>
  await JsonUtils.updateJsonFile("rescript.json", json =>
    switch json {
    | Object(config) => config->Dict.set("name", String(projectName))
    | _ => ()
    }
  )

let newProjectMessage = `Create a new ReScript 11 project with modern defaults
("Core" standard library, JSX v4)`

let getTemplateOptions = () =>
  Templates.templates->Array.map(({name, displayName, shortDescription}) => {
    P.value: name,
    label: displayName,
    hint: shortDescription,
  })

let createNewProject = async () => {
  P.note(~title="New Project", ~message=newProjectMessage)

  let projectName = await P.text({
    message: "What is the name of your new ReScript project?",
    placeholder: "my-rescript-app",
    initialValue: ?Process.argv[2],
    validate: validateProjectName,
  })->P.resultOrRaise

  let templateName =
    await P.select({message: "Select a template", options: getTemplateOptions()})->P.resultOrRaise

  let versions = await RescriptVersions.promptVersions()

  let templatePath = CraPaths.getTemplatePath(~templateName)
  let projectPath = Path.join2(Process.cwd(), projectName)

  let s = P.spinner()

  s->P.Spinner.start("Creating project...")

  await Fs.Promises.cp(templatePath, projectPath, ~options={recursive: true})
  Process.chdir(projectPath)

  await Fs.Promises.rename("_gitignore", ".gitignore")
  await updatePackageJson(~projectName)
  await updateRescriptJson(~projectName)

  await RescriptVersions.installVersions(versions)
  let _ = await Promisified.ChildProcess.exec("git init")

  s->P.Spinner.stop("Project created.")
}
