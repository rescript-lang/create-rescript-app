open Node

module P = ClackPrompts

let updatePackageJson = async () =>
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
      scripts->Dict.set("res:dev", String("rescript -w"))
    | _ => ()
    }
  )

let updateRescriptJson = async (~projectName, ~sourceDir, ~moduleSystem, ~suffix) =>
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
    | _ => ()
    }
  )

let getSuffixForModuleSystem = moduleSystem =>
  switch moduleSystem {
  | "es6" => ".res.mjs"
  | _ => ".res.js"
  }

let moduleSystemOptions = [
  {
    P.value: "commonjs",
    label: "CommonJS",
    hint: "Use require syntax and .res.js extension",
  },
  {
    value: "es6",
    label: "ES6",
    hint: "Use import syntax and .res.mjs extension",
  },
]

let addToExistingProject = async (~projectName) => {
  let versions = await RescriptVersions.promptVersions()

  let sourceDir = await P.text({
    message: "Where will you put your ReScript source files?",
    defaultValue: "src",
    placeholder: "src",
    initialValue: "src",
  })->P.resultOrRaise

  let moduleSystem = await P.select({
    message: "What module system will you use?",
    options: moduleSystemOptions,
  })->P.resultOrRaise

  let suffix = moduleSystem->getSuffixForModuleSystem

  let shouldCheckJsFilesIntoGit = await P.confirm({
    message: `Do you want to check generated ${suffix} files into git?`,
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
    await Fs.Promises.appendFile(gitignorePath, `**/*${suffix}${Os.eol}`)
  }

  await updatePackageJson()
  await updateRescriptJson(~projectName, ~sourceDir, ~moduleSystem, ~suffix)

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
