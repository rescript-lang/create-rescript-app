open Node

module P = ClackPrompts

let packageNameRegExp = /^[a-z0-9-]+$/
let resxTemplatePlaceholderName = "resx-template"

let validateProjectName = projectName =>
  if projectName->String.trim->String.length === 0 {
    Error("Project name must not be empty.")
  } else if !(packageNameRegExp->RegExp.test(projectName)) {
    Error("Project name may only contain lower case letters, numbers and hyphens.")
  } else if Fs.existsSync(Path.join2(Process.cwd(), projectName)) {
    Error(`The folder ${projectName} already exist in the current directory.`)
  } else {
    Ok()
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

let rec replaceFileContents = async (remainingFilePaths, ~replaceValue, ~withValue) =>
  switch remainingFilePaths {
  | list{} => ()
  | list{filePath, ...remainingFilePaths} =>
    let fileContents = await Fs.Promises.readFile(filePath)
    let updatedFileContents = fileContents->String.replaceAll(replaceValue, withValue)

    await Fs.Promises.writeFile(filePath, updatedFileContents)
    await replaceFileContents(remainingFilePaths, ~replaceValue, ~withValue)
  }

let synchronizeResxTemplateFiles = async (~projectName) =>
  await replaceFileContents(
    list{
      "package.json",
      "rescript.json",
      "README.md",
      "Dockerfile",
      "bun.lock",
      Path.join(["scripts", "build-sfe.mjs"]),
      Path.join(["src", "data", "TemplateContent.res"]),
    },
    ~replaceValue=resxTemplatePlaceholderName,
    ~withValue=projectName,
  )

let getPackageManagerName = (packageManager: PackageManagers.packageManager) =>
  switch packageManager {
  | Npm => "npm"
  | Yarn1 | YarnBerry => "yarn"
  | Pnpm => "pnpm"
  | Bun => "bun"
  }

let showGetStartedNote = async (~templateName, ~projectName) => {
  if templateName === Templates.resXTemplateName {
    let packageManagerInfo = await PackageManagers.getPackageManagerInfo()

    switch packageManagerInfo.packageManager {
    | Bun =>
      P.note(
        ~title="Get started",
        ~message=`cd ${projectName}

bun run dev`,
      )
    | packageManager =>
      P.note(
        ~title="Bun recommended",
        ~message=`This ResX template is Bun-centric. You created it with ${packageManager->getPackageManagerName}, but the generated project should use Bun.

cd ${projectName}
bun install
bun run dev`,
      )
    }
  } else {
    P.note(
      ~title="Get started",
      ~message=`cd ${projectName}

# See the project's README.md for more information.`,
    )
  }
}

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
  await updatePackageJson(~projectName, ~versions)
  await updateRescriptJson(~projectName, ~versions)
  await updateViteConfig()

  if templateName === Templates.resXTemplateName {
    await synchronizeResxTemplateFiles(~projectName)
  }

  await RescriptVersions.installVersions(versions)
  let _ = await Promisified.ChildProcess.exec("git init")

  if !CI.isRunningInCI {
    s->P.Spinner.stop("Project created.")
  }

  await showGetStartedNote(~templateName, ~projectName)
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
    let commandLineArguments = switch CommandLineArguments.fromProcessArgv(Process.argv) {
    | Ok(commandLineArguments) => commandLineArguments
    | Error(message) => JsError.throwWithMessage(message)
    }
    let useDefaultVersions = Option.isSome(commandLineArguments.templateName)

    let projectName = switch commandLineArguments.projectName {
    | Some(projectName) if useDefaultVersions =>
      // Note this throws in the some case, which is why we cannot use Option.getOrThrow here.
      switch validateProjectName(projectName) {
      | Error(message) => JsError.throwWithMessage(message)
      | Ok() => projectName
      }

    | initialValue =>
      await P.text({
        message: "What is the name of your new ReScript project?",
        placeholder: "my-rescript-app",
        ?initialValue,
        validate: projectName =>
          switch validateProjectName(projectName) {
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
