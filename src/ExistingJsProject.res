open Node

module P = ClackPrompts

type projectModuleConfig = {
  moduleSystem: string,
  suffix: string,
  gentypeConfig: option<TsConfigMapping.inferredConfig>,
}

let getOrCreateJsonObject = (config: Dict.t<JSON.t>, ~fieldName) =>
  switch config->Dict.get(fieldName) {
  | Some(Object(object)) => object
  | _ =>
    let object = Dict.make()
    config->Dict.set(fieldName, Object(object))
    object
  }

let updatePackageJson = async (~versions) =>
  await JsonUtils.updateJsonFile("package.json", json =>
    switch json {
    | Object(config) =>
      let scripts = switch config->Dict.get("scripts") {
      | Some(Object(scripts)) => scripts
      | _ =>
        let scripts = Dict.make()
        config->Dict.set("scripts", Object(scripts))
        scripts
      }
      scripts->Dict.set("res:build", String("rescript"))
      scripts->Dict.set("res:clean", String("rescript clean"))

      if RescriptVersions.usesRewatch(versions) {
        scripts->Dict.set("res:dev", String("rescript watch"))
      } else {
        scripts->Dict.set("res:dev", String("rescript -w"))
      }
    | _ => ()
    }
  )

let updateRescriptJson = async (
  ~projectName,
  ~sourceDir,
  ~moduleSystem,
  ~suffix,
  ~gentypeConfig: option<TsConfigMapping.inferredConfig>,
  ~versions,
) =>
  await JsonUtils.updateJsonFile("rescript.json", json =>
    switch json {
    | Object(config) =>
      config->Dict.set("name", String(projectName))
      config->Dict.set("suffix", String(suffix))
      switch config->Dict.get("sources") {
      | Some(Object(sources)) => sources->Dict.set("dir", String(sourceDir))
      | _ => ()
      }
      switch config->Dict.get("package-specs") {
      | Some(Object(sources)) => sources->Dict.set("module", String(moduleSystem))
      | _ => ()
      }
      switch gentypeConfig {
      | Some(gentypeConfig) =>
        let gentypeConfigJson: Dict.t<JSON.t> = Dict.make()
        gentypeConfigJson->Dict.set("module", String(gentypeConfig.moduleSystem))
        gentypeConfigJson->Dict.set(
          "moduleResolution",
          String(gentypeConfig.gentypeModuleResolution),
        )
        gentypeConfigJson->Dict.set(
          "generatedFileExtension",
          String(gentypeConfig.generatedFileExtension),
        )
        config->Dict.set("gentypeconfig", Object(gentypeConfigJson))
      | None => ()
      }

      if Option.isNone(versions.RescriptVersions.rescriptCoreVersion) {
        RescriptJsonUtils.removeRescriptCore(config)
      }
    | _ => ()
    }
  )

let getModuleSystemOptions = () => [
  {
    P.value: "esmodule",
    label: "ES Modules",
    hint: "Use import syntax and .res.mjs extension",
  },
  {
    value: "commonjs",
    label: "CommonJS",
    hint: "Use require syntax and .res.js extension",
  },
]

let getPackageJson = async () => await JsonUtils.readJsonFile("package.json")

let getPackageType = (packageJson: JSON.t) =>
  switch packageJson {
  | Object(config) =>
    switch config->Dict.get("type") {
    | Some(String(packageType)) => Some(packageType->String.toLowerCase)
    | _ => None
    }
  | _ => None
  }

let packageJsonHasDependency = (packageJson: JSON.t, dependencyNames) => {
  let dependencyFields = [
    "dependencies",
    "devDependencies",
    "peerDependencies",
    "optionalDependencies",
  ]

  switch packageJson {
  | Object(config) =>
    dependencyFields->Array.some(fieldName =>
      switch config->Dict.get(fieldName) {
      | Some(Object(dependencies)) =>
        dependencyNames->Array.some(dependencyName =>
          dependencies->Dict.get(dependencyName)->Option.isSome
        )
      | _ => false
      }
    )
  | _ => false
  }
}

let hasJsxDependency = (packageJson: JSON.t) =>
  packageJson->packageJsonHasDependency([
    "react",
    "react-dom",
    "next",
    "preact",
    "solid-js",
    "@vitejs/plugin-react",
  ])

let getManualModuleConfig = async () => {
  let moduleSystem = await P.select({
    message: "What module system will you use?",
    options: getModuleSystemOptions(),
  })->P.resultOrRaise

  {
    moduleSystem,
    suffix: moduleSystem === "esmodule" ? ".res.mjs" : ".res.js",
    gentypeConfig: None,
  }
}

let getTsConfigModuleConfig = async packageJson => {
  let projectPath = Process.cwd()
  let tsConfig = TsConfigMapping.read(projectPath)

  switch tsConfig.status {
  | "found" =>
    switch TsConfigMapping.infer(
      tsConfig,
      ~packageType=getPackageType(packageJson),
      ~hasJsxDependency=hasJsxDependency(packageJson),
    ) {
    | Ok(gentypeConfig) =>
      P.Log.info(
        `Detected tsconfig.json. ReScript will use ${gentypeConfig.moduleSystem} output, ${gentypeConfig.gentypeModuleResolution} genType module resolution, and ${gentypeConfig.suffix} generated JS files.`,
      )

      gentypeConfig.warnings->Array.forEach(P.Log.warn)

      Some({
        moduleSystem: gentypeConfig.moduleSystem,
        suffix: gentypeConfig.suffix,
        gentypeConfig: Some(gentypeConfig),
      })
    | Error(message) =>
      P.Log.warn(`${message} Falling back to manual ReScript module setup.`)
      None
    }
  | "not_found" => None
  | "typescript_missing" =>
    P.Log.warn(
      "Found tsconfig.json, but could not resolve the project's TypeScript package. Falling back to manual ReScript module setup.",
    )
    None
  | _ =>
    let message = tsConfig.message->Option.getOr("Could not read the effective tsconfig.json.")
    P.Log.warn(`${message} Falling back to manual ReScript module setup.`)
    None
  }
}

let getProjectModuleConfig = async packageJson =>
  switch await getTsConfigModuleConfig(packageJson) {
  | Some(config) => config
  | None => await getManualModuleConfig()
  }

let updateTsConfig = async (~setAllowJs, ~setAllowImportingTsExtensions) =>
  if setAllowJs || setAllowImportingTsExtensions {
    await JsonUtils.updateJsonFile("tsconfig.json", json =>
      switch json {
      | Object(config) =>
        let compilerOptions = config->getOrCreateJsonObject(~fieldName="compilerOptions")

        if setAllowJs {
          compilerOptions->Dict.set("allowJs", Boolean(true))
        }

        if setAllowImportingTsExtensions {
          compilerOptions->Dict.set("allowImportingTsExtensions", Boolean(true))
        }
      | _ => ()
      }
    )
  }

let promptTsConfigUpdates = async (gentypeConfig: option<TsConfigMapping.inferredConfig>) => {
  switch gentypeConfig {
  | None => ()
  | Some(gentypeConfig) =>
    let setAllowJs = if gentypeConfig.needsAllowJs {
      P.Log.warn(
        "TypeScript allowJs is not enabled. genType imports ReScript's generated JS files, so TypeScript needs allowJs: true to type-check the setup.",
      )

      await P.confirm({
        message: "Set compilerOptions.allowJs to true in tsconfig.json?",
      })->P.resultOrRaise
    } else {
      false
    }

    let setAllowImportingTsExtensions = if gentypeConfig.needsAllowImportingTsExtensions {
      P.Log.warn(
        "genType bundler module resolution requires TypeScript allowImportingTsExtensions: true.",
      )

      await P.confirm({
        message: "Set compilerOptions.allowImportingTsExtensions to true in tsconfig.json?",
      })->P.resultOrRaise
    } else {
      false
    }

    if gentypeConfig.cannotSetAllowImportingTsExtensions {
      P.Log.warn(
        "genType bundler module resolution requires allowImportingTsExtensions: true, but TypeScript only allows that option when noEmit or emitDeclarationOnly is enabled.",
      )

      let shouldContinue = await P.confirm({
        message: "Continue with the inferred genType bundler configuration anyway?",
      })->P.resultOrRaise

      if !shouldContinue {
        JsError.throwWithMessage("genType bundler setup requires manual tsconfig changes.")
      }
    }

    try await updateTsConfig(~setAllowJs, ~setAllowImportingTsExtensions) catch {
    | JsExn(error) =>
      P.Log.warn(
        `Could not update tsconfig.json automatically: ${error->ErrorUtils.getErrorMessage}`,
      )
    }
  }
}

let addToExistingProject = async (~projectName) => {
  let versions = await RescriptVersions.promptVersions()
  let packageJson = await getPackageJson()

  let sourceDir = await P.text({
    message: "Where will you put your ReScript source files?",
    defaultValue: "src",
    placeholder: "src",
    initialValue: "src",
  })->P.resultOrRaise

  let moduleConfig = await getProjectModuleConfig(packageJson)
  await promptTsConfigUpdates(moduleConfig.gentypeConfig)

  let shouldCheckJsFilesIntoGit = await P.confirm({
    message: `Do you want to check generated ${moduleConfig.suffix} files into git?`,
  })->P.resultOrRaise

  let templatePath = CraPaths.getTemplatePath(~templateName=Templates.basicTemplateName)
  let projectPath = Process.cwd()
  let gitignorePath = Path.join2(projectPath, ".gitignore")
  let sourceDirPath = Path.join2(projectPath, sourceDir)

  let s = P.spinner()

  s->P.Spinner.start("Adding ReScript to your project...")

  await Fs.Promises.copyFile(
    Path.join2(templatePath, "rescript.json"),
    Path.join2(projectPath, "rescript.json"),
  )

  if Fs.existsSync(gitignorePath) {
    open Os
    await Fs.Promises.appendFile(gitignorePath, `${eol}/lib/${eol}.bsb.lock${eol}`)
  } else {
    await Fs.Promises.copyFile(Path.join2(templatePath, "_gitignore"), gitignorePath)
  }

  if !shouldCheckJsFilesIntoGit {
    await Fs.Promises.appendFile(gitignorePath, `**/*${moduleConfig.suffix}${Os.eol}`)
  }

  await updatePackageJson(~versions)
  await updateRescriptJson(
    ~projectName,
    ~sourceDir,
    ~moduleSystem=moduleConfig.moduleSystem,
    ~suffix=moduleConfig.suffix,
    ~gentypeConfig=moduleConfig.gentypeConfig,
    ~versions,
  )

  if !Fs.existsSync(sourceDirPath) {
    await Fs.Promises.mkdir(sourceDirPath)
  }

  await Fs.Promises.copyFile(
    Path.join([templatePath, "src", "Demo.res"]),
    Path.join([sourceDirPath, "Demo.res"]),
  )

  await RescriptVersions.installVersions(versions)

  s->P.Spinner.stop("Added ReScript to your project.")
}
