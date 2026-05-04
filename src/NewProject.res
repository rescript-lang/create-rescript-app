open Node

module P = ClackPrompts

let installGitignore = async () => {
  let templateGitignorePath = "_gitignore"
  let gitignorePath = ".gitignore"

  if Fs.existsSync(templateGitignorePath) {
    if Fs.existsSync(gitignorePath) {
      let templateGitignore = await Fs.Promises.readFile(templateGitignorePath)
      await Fs.Promises.appendFile(gitignorePath, `${Os.eol}${templateGitignore}`)
      await Fs.Promises.rm(templateGitignorePath, ~options={force: true})
    } else {
      await Fs.Promises.rename(templateGitignorePath, gitignorePath)
    }
  }
}

let updatePackageJson = async (~projectName, ~versions) =>
  await JsonUtils.updateJsonFile("package.json", json =>
    switch json {
    | Object(config) => {
        config->Dict.set("name", String(projectName))

        let scripts = switch config->Dict.get("scripts") {
        | Some(Object(scripts)) => scripts
        | _ =>
          let scripts = Dict.make()
          config->Dict.set("scripts", Object(scripts))
          scripts
        }

        if RescriptVersions.usesRewatch(versions) {
          scripts->Dict.set("res:dev", String("rescript watch"))
        }
      }
    | _ => ()
    }
  )

let updateRescriptJson = async (~projectName, ~versions: RescriptVersions.versions) =>
  await JsonUtils.updateJsonFile("rescript.json", json =>
    switch json {
    | Object(config) =>
      config->Dict.set("name", String(projectName))
      switch config->Dict.get("package-specs") {
      | Some(Object(packageSpecs)) | Some(Array([Object(packageSpecs)])) =>
        packageSpecs->Dict.set("module", String("esmodule"))
        config->Dict.set("suffix", String(".res.mjs"))
      | _ => ()
      }

      if Option.isNone(versions.rescriptCoreVersion) {
        RescriptJsonUtils.removeRescriptCore(config)
      }

      // https://github.com/rescript-lang/rescript/blob/master/CHANGELOG.md#1200-beta3
      if CompareVersions.satisfies(versions.rescriptVersion, ">=12.0.0-beta.3") {
        RescriptJsonUtils.modernizeConfigurationFields(config)
      }
    | _ => ()
    }
  )

let updateViteConfig = async () => {
  if Fs.existsSync("vite.config.js") {
    let rescriptConfig = await JsonUtils.readJsonFile("rescript.json")
    let suffix = switch rescriptConfig->JsonUtils.getStringValue(~fieldName="suffix") {
    | Some(suffix) => suffix
    | None => ".res.mjs"
    }

    let viteConfig = await Fs.Promises.readFile("vite.config.js")
    await Fs.Promises.writeFile(
      "vite.config.js",
      viteConfig->ViteTemplateUtils.stampOutputSuffix(~suffix),
    )
  }
}

let newProjectMessage = "Create a new ReScript project"

let getTemplateOptions = () =>
  Templates.templates->Array.map(({name, displayName, shortDescription, _}) => {
    P.value: name,
    label: displayName,
    hint: shortDescription,
  })

let getVariantOptions = (variants: array<Templates.variant>) =>
  variants->Array.map(({name, displayName, shortDescription}) => {
    P.value: name,
    label: displayName,
    hint: shortDescription,
  })

let promptTemplateName = async () => {
  let selectedName = await P.select({
    message: "Select a template",
    options: getTemplateOptions(),
  })->P.resultOrRaise

  switch Templates.templates->Array.find(template => template.name === selectedName) {
  | Some({variants: Some(variants)}) =>
    await P.select({
      message: "Select a variant",
      options: getVariantOptions(variants),
    })->P.resultOrRaise
  | _ => selectedName
  }
}

let createProject = async (~templateName, ~projectName, ~versions) => {
  let templatePath = CraPaths.getTemplatePath(~templateName)
  let packageName = NewProjectLocation.getPackageName(projectName)
  let projectPath = NewProjectLocation.getProjectPath(projectName)
  let createInCurrentDirectory = NewProjectLocation.isCurrentDirectoryProject(projectName)

  let s = P.spinner()

  if !CI.isRunningInCI {
    s->P.Spinner.start("Creating project...")
  }

  if createInCurrentDirectory {
    await Fs.Promises.cp(templatePath, projectPath, ~options={recursive: true, force: false})
  } else {
    await Fs.Promises.cp(templatePath, projectPath, ~options={recursive: true})
  }

  Process.chdir(projectPath)

  await installGitignore()
  await updatePackageJson(~projectName=packageName, ~versions)
  await updateRescriptJson(~projectName=packageName, ~versions)
  await updateViteConfig()

  await RescriptVersions.installVersions(versions)
  let _ = await Promisified.ChildProcess.exec("git init")

  if !CI.isRunningInCI {
    s->P.Spinner.stop("Project created.")
  }

  let getStartedMessage = createInCurrentDirectory
    ? "# See the project's README.md for more information."
    : `cd ${projectName}

# See the project's README.md for more information.`

  P.note(~title="Get started", ~message=getStartedMessage)
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
    let commandLineArguments = CommandLineArguments.fromProcessArgv(Process.argv)->Result.getOrThrow
    let useDefaultVersions = Option.isSome(commandLineArguments.templateName)

    let projectName = switch commandLineArguments.projectName {
    | Some(projectName) if useDefaultVersions =>
      // Note this throws in the some case, which is why we cannot use Option.getOrThrow here.
      switch NewProjectLocation.validateProjectName(projectName) {
      | Error(message) => JsError.throwWithMessage(message)
      | Ok() => projectName
      }

    | initialValue =>
      await P.text({
        message: "What is the name of your new ReScript project?",
        placeholder: "my-rescript-app",
        ?initialValue,
        validate: projectName =>
          switch NewProjectLocation.validateProjectName(projectName) {
          | Ok() => None
          | Error(error) => Some(error)
          },
      })->P.resultOrRaise
    }

    let templateName = switch commandLineArguments.templateName {
    | Some(templateName) => templateName
    | None => await promptTemplateName()
    }

    let versions = useDefaultVersions
      ? await RescriptVersions.getDefaultVersions()
      : await RescriptVersions.promptVersions()

    await createProject(~templateName, ~projectName, ~versions)
  }
}
