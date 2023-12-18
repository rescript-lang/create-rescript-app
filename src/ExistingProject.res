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
      scripts->Dict.set("res:dev", String("rescript build -w"))
    | _ => ()
    }
  )

let updateRescriptJson = async (~projectName, ~sourceDir) =>
  await JsonUtils.updateJsonFile("rescript.json", json =>
    switch json {
    | Object(config) =>
      config->Dict.set("name", String(projectName))
      switch config->Dict.get("sources") {
      | Some(Object(sources)) => sources->Dict.set("dir", String(sourceDir))
      | _ => ()
      }
    | _ => ()
    }
  )

let addToExistingProject = async (~projectName) => {
  let versions = await RescriptVersions.promptVersions()

  let sourceDir = await P.text({
    message: "Where will you put your ReScript source files?",
    defaultValue: "src",
    placeholder: "src",
    initialValue: "src",
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

  await updatePackageJson()
  await updateRescriptJson(~projectName, ~sourceDir)

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
