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

let updateRescriptJson = async (~projectName, ~versions) =>
  await JsonUtils.updateJsonFile("rescript.json", json =>
    switch json {
    | Object(config) =>
      config->Dict.set("name", String(projectName))
      switch config->Dict.get("package-specs") {
      | Some(Object(packageSpecs)) | Some(Array([Object(packageSpecs)])) =>
        let moduleSystemName = versions->RescriptVersions.esmModuleSystemName
        packageSpecs->Dict.set("module", String(moduleSystemName))

        let suffix = moduleSystemName->ModuleSystem.getSuffix
        config->Dict.set("suffix", String(suffix))
      | _ => ()
      }

      if Option.isNone(versions.rescriptCoreVersion) {
        RescriptJsonUtils.removeRescriptCore(config)
      }
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

let createProject = async (~templateName, ~projectName, ~versions) => {
  let templatePath = CraPaths.getTemplatePath(~templateName)
  let projectPath = Path.join2(Process.cwd(), projectName)

  let s = P.spinner()

  if !CI.isRunningInCI {
    s->P.Spinner.start("Creating project...")
  }

  await Fs.Promises.cp(templatePath, projectPath, ~options={recursive: true})
  Process.chdir(projectPath)

  await Fs.Promises.rename("_gitignore", ".gitignore")
  await updatePackageJson(~projectName)
  await updateRescriptJson(~projectName, ~versions)

  await RescriptVersions.installVersions(versions)
  let _ = await Promisified.ChildProcess.exec("git init")

  if !CI.isRunningInCI {
    s->P.Spinner.stop("Project created.")
  }

  P.note(
    ~title="Get started",
    ~message=`cd ${projectName}

# See the project's README.md for more information.`,
  )
}

let createNewProject = async () => {
  P.note(~title="New Project", ~message=newProjectMessage)

  if CI.isRunningInCI {
    // type versions = {rescriptVersion: string, rescriptCoreVersion: string}
    await createProject(
      ~templateName="rescript-template-basic",
      ~projectName="test",
      ~versions={rescriptVersion: "11.1.1", rescriptCoreVersion: Some("1.5.0")},
    )
  } else {
    let projectName = await P.text({
      message: "What is the name of your new ReScript project?",
      placeholder: "my-rescript-app",
      initialValue: ?Process.argv[2],
      validate: validateProjectName,
    })->P.resultOrRaise

    let templateName =
      await P.select({message: "Select a template", options: getTemplateOptions()})->P.resultOrRaise

    let versions = await RescriptVersions.promptVersions()

    await createProject(~templateName, ~projectName, ~versions)
  }
}
