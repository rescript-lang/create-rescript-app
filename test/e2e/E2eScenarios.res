open Node
open JSON
module P = E2eProcess

type moduleSystem = CommonJs | EsModule
type tsResolution = NodeNext | Bundler

let object = (entries: array<(string, JSON.t)>) => JSON.Object(entries->Dict.fromArray)
let findField = (json, name) => {
  let? Some(fields) = json->JSON.Decode.object
  fields->Dict.get(name)
}
let field = (json, name) =>
  findField(json, name)->Option.getOrThrow(~message=`Expected JSON object field: ${name}`)
let stringField = (json, name) =>
  field(json, name)
  ->JSON.Decode.string
  ->Option.getOrThrow(~message=`Expected a string in JSON field: ${name}`)
let assertContains = (actual, expected, message) =>
  Assert.ok(actual->String.includes(expected), message)

let verifyProject = async (context: P.context, directory, suffix) => {
  let packageJson = P.readJson(Path.join2(directory, "package.json"))
  let config = P.readJson(Path.join2(directory, "rescript.json"))
  Assert.strictEqual(
    stringField(config, "name"),
    stringField(packageJson, "name"),
    ~message="Project and package names differ",
  )
  Assert.strictEqual(
    stringField(config, "suffix"),
    suffix,
    ~message="Unexpected generated JS suffix",
  )
  Assert.ok(
    Fs.existsSync(Path.join2(directory, context.info.lockfile)),
    `Missing ${context.info.lockfile}: manager detection failed`,
  )
  switch context.manager {
  | Npm => ()
  | _ =>
    Assert.ok(
      !Fs.existsSync(Path.join2(directory, "package-lock.json")),
      "npm lockfile was not removed",
    )
  }
  switch context.manager {
  | YarnBerry =>
    Fs.readFileSync(Path.join2(directory, ".yarnrc.yml"))->assertContains(
      "nodeLinker: node-modules",
      "Yarn Berry node-modules linker was not configured",
    )
  | _ => ()
  }
  let version =
    P.readJson(Path.join2(directory, "node_modules/rescript/package.json"))->stringField("version")
  Assert.ok(
    version->String.startsWith("12."),
    `Expected a current ReScript 12 version, installed ${version}`,
  )
  switch field(packageJson, "dependencies") {
  | Object(dependencies) =>
    Assert.ok(
      !(dependencies->Dict.has("@rescript/core")),
      "ReScript 12 should use its bundled standard library",
    )
  | _ => Assert.fail("Expected package dependencies")
  }
  let? Ok(_) = await P.run(context, [context.info.command, "run", "res:build"], directory)
  let? Ok(output) = await P.run(context, ["node", `src/Demo${suffix}`], directory)
  Assert.strictEqual(
    output->String.trim,
    "Hello, world!",
    ~message="Unexpected generated program output",
  )
  Ok()
}

let verifyPreserved = (directory, preserved) =>
  preserved->Array.forEach(((path, contents)) => {
    let actual = Fs.readFileSync(Path.join2(directory, path))
    switch path {
    | ".gitignore" => Assert.ok(actual->String.startsWith(contents), `Overwrote ${path}`)
    | _ => Assert.strictEqual(actual, contents, ~message=`Overwrote ${path}`)
    }
  })

let newProject = async (context, directory, ~target, ~devcontainer) => {
  let currentDirectory = switch target {
  | "." | "./" => true
  | _ => false
  }
  let project = currentDirectory ? directory : Path.join2(directory, target)
  let preserved = if devcontainer {
    Fs.mkdirSync(Path.join2(project, ".devcontainer"), {recursive: true})
    let metadata = currentDirectory
      ? [("README.md", "Existing README\n"), (".gitignore", "keep-this-entry\n")]
      : []
    [(".devcontainer/devcontainer.json", "{\"name\":\"keep me\"}\n"), ...metadata]
  } else {
    []
  }
  preserved->Array.forEach(((path, contents)) =>
    Fs.writeFileSync(Path.join2(project, path), contents)
  )
  let? Ok() = await P.cli(
    context,
    directory,
    ~args=[target, "--template", "basic"],
    ~expected=0,
    ~prompts=[],
  )
  Assert.strictEqual(
    P.readJson(Path.join2(project, "package.json"))->stringField("name"),
    Path.basename(project),
    ~message="Current-directory package name was not derived from the directory",
  )
  verifyPreserved(project, preserved)
  await verifyProject(context, project, ".res.mjs")
}

let existingProject = async (
  context,
  directory,
  ~moduleSystem,
  ~typescript: option<tsResolution>,
) => {
  let moduleName = switch moduleSystem {
  | CommonJs => "commonjs"
  | EsModule => "module"
  }
  let devDependencies = switch typescript {
  | Some(_) => [("devDependencies", object([("typescript", String("5.9.3"))]))]
  | None => []
  }
  let original = object(
    [
      ("name", String(Path.basename(directory))),
      ("version", String("1.0.0")),
      ("private", Boolean(true)),
      ("type", String(moduleName)),
      ("scripts", object([("test", String("node src/original.cjs"))])),
      ("dependencies", object([("is-number", String("7.0.0"))])),
      ...devDependencies,
    ],
  )
  let? Ok() = P.writeJson(Path.join2(directory, "package.json"), original)
  Fs.mkdirSync(Path.join2(directory, "src"), {recursive: true})
  let tsPreserved = switch typescript {
  | None => []
  | Some(resolution) =>
    let (moduleName, resolutionName) = switch resolution {
    | NodeNext => ("NodeNext", "nodenext")
    | Bundler => ("ESNext", "bundler")
    }
    Fs.writeFileSync(
      Path.join2(directory, "tsconfig.json"),
      `{
  // Preserve this comment and the inherited configuration.
  "extends": "./tsconfig.base.json",
  "compilerOptions": {"skipLibCheck": true,},
  "include": ["src"],
}
`,
    )
    [
      ("src/original.ts", "export const existingValue: number = 1;\n"),
      (
        "tsconfig.base.json",
        JSON.stringify(
          object([
            (
              "compilerOptions",
              object([
                ("module", String(moduleName)),
                ("moduleResolution", String(resolutionName)),
                ("target", String("ES2022")),
                ("strict", Boolean(true)),
                ("noEmit", Boolean(true)),
              ]),
            ),
          ]),
          ~space=2,
        ),
      ),
    ]
  }
  let preserved = [
    ("README.md", "Existing project README\n"),
    (".gitignore", "existing-ignore\n"),
    ("src/original.cjs", "console.log(require(\"is-number\")(42));\n"),
    ...tsPreserved,
  ]
  preserved->Array.forEach(((path, contents)) =>
    Fs.writeFileSync(Path.join2(directory, path), contents)
  )
  let? Ok(_) = await P.run(context, [context.info.command, "install"], directory)
  let modulePrompts = switch typescript {
  | Some(resolution) =>
    let extensionPrompts = switch resolution {
    | NodeNext => []
    | Bundler => [("Set compilerOptions.allowImportingTsExtensions to true", "y")]
    }
    [("Set compilerOptions.allowJs to true", "y"), ...extensionPrompts]
  | None =>
    let answer = switch moduleSystem {
    | CommonJs => "\x1b[B\r"
    | EsModule => "\r"
    }
    [("What module system will you use?", answer)]
  }
  let? Ok() = await P.cli(
    context,
    directory,
    ~args=[],
    ~expected=0,
    ~prompts=[
      ("Do you want to add ReScript", "y"),
      ("ReScript version?", "\r"),
      ("Where will you put your ReScript source files?", "\r"),
      ...modulePrompts,
      ("Do you want to check generated", "n"),
    ],
  )
  let packageJson = P.readJson(Path.join2(directory, "package.json"))
  ["name", "version", "private", "type"]->Array.forEach(name =>
    Assert.deepStrictEqual(
      field(packageJson, name),
      field(original, name),
      `Changed existing package field ${name}`,
    )
  )
  Assert.deepStrictEqual(
    field(packageJson, "scripts")->field("test"),
    field(original, "scripts")->field("test"),
    "Overwrote existing script",
  )
  Assert.strictEqual(
    field(packageJson, "dependencies")->stringField("is-number"),
    "7.0.0",
    ~message="Changed existing dependency",
  )
  switch typescript {
  | Some(_) =>
    Assert.deepStrictEqual(
      field(packageJson, "devDependencies"),
      field(original, "devDependencies"),
      "Changed TypeScript dependency",
    )
  | None => ()
  }
  verifyPreserved(directory, preserved)
  let suffix = switch (typescript, moduleSystem) {
  | (None, EsModule) => ".res.mjs"
  | _ => ".res.js"
  }
  Fs.readFileSync(Path.join2(directory, ".gitignore"))->assertContains(
    `**/*${suffix}`,
    "Generated JS was not ignored",
  )
  switch typescript {
  | None => ()
  | Some(resolution) =>
    let (gentypeResolution, extension) = switch resolution {
    | NodeNext => ("node16", "js")
    | Bundler => ("bundler", "ts")
    }
    let config = P.readJson(Path.join2(directory, "rescript.json"))
    Assert.strictEqual(
      field(config, "gentypeconfig")->stringField("moduleResolution"),
      gentypeResolution,
      ~message="Incorrect genType mapping",
    )
    let tsconfig = Fs.readFileSync(Path.join2(directory, "tsconfig.json"))
    tsconfig->assertContains("// Preserve this comment", "Lost tsconfig comment")
    tsconfig->assertContains("\"allowJs\": true", "Did not enable allowJs")
    switch resolution {
    | NodeNext => ()
    | Bundler =>
      tsconfig->assertContains(
        "\"allowImportingTsExtensions\": true",
        "Did not enable TS extension imports",
      )
    }
    Fs.writeFileSync(Path.join2(directory, "src/Interop.res"), "@genType\nlet answer = 42\n")
    Fs.writeFileSync(
      Path.join2(directory, "src/consumer.ts"),
      `import {answer} from "./Interop.gen.${extension}";\nconst value: number = answer;\n`,
    )
  }
  let? Ok() = await verifyProject(context, directory, suffix)
  let? Ok(output) = await P.run(context, [context.info.command, "run", "test"], directory)
  Assert.ok(
    output->String.split("\n")->Array.some(line => line->String.trim === "true"),
    "Existing JavaScript program no longer runs",
  )
  switch typescript {
  | None => Ok()
  | Some(_) =>
    Assert.ok(
      Fs.existsSync(Path.join2(directory, "src/Interop.gen.ts")),
      "genType did not generate TypeScript",
    )
    let? Ok(_) = await P.run(
      context,
      ["node", "node_modules/typescript/bin/tsc", "--noEmit"],
      directory,
    )
    Ok()
  }
}

let occupiedDirectory = async (context, directory) => {
  let project = Path.join2(directory, "occupied")
  Fs.mkdirSync(project, {recursive: true})
  let sentinel = Path.join2(project, "keep.txt")
  Fs.writeFileSync(sentinel, "Do not overwrite\n")
  let? Ok() = await P.cli(
    context,
    directory,
    ~args=["occupied", "--template", "basic"],
    ~expected=1,
    ~prompts=[],
  )
  Assert.strictEqual(
    Fs.readFileSync(sentinel),
    "Do not overwrite\n",
    ~message="Overwrote occupied directory",
  )
  Assert.deepStrictEqual(
    Fs.readdirSync(project),
    ["keep.txt"],
    "Failed scaffolding left files in the occupied directory",
  )
  Ok()
}

type scenario = {name: string, perform: string => promise<result<unit, P.error>>}

let scenarios = (context: P.context) => {
  let common = [
    {
      name: "new-basic",
      perform: directory => newProject(context, directory, ~target="my-app", ~devcontainer=false),
    },
    {
      name: "existing-commonjs",
      perform: directory =>
        existingProject(context, directory, ~moduleSystem=CommonJs, ~typescript=None),
    },
  ]
  switch context.manager {
  | Npm =>
    [
      ...common,
      {
        name: "existing-esm",
        perform: directory =>
          existingProject(context, directory, ~moduleSystem=EsModule, ~typescript=None),
      },
      {
        name: "existing-ts-nodenext",
        perform: directory =>
          existingProject(context, directory, ~moduleSystem=EsModule, ~typescript=Some(NodeNext)),
      },
      {
        name: "existing-ts-bundler",
        perform: directory =>
          existingProject(context, directory, ~moduleSystem=EsModule, ~typescript=Some(Bundler)),
      },
      {
        name: "devcontainer-named",
        perform: directory => newProject(context, directory, ~target="my-app", ~devcontainer=true),
      },
      {
        name: "devcontainer-dot",
        perform: directory => newProject(context, directory, ~target=".", ~devcontainer=true),
      },
      {
        name: "devcontainer-dot-slash",
        perform: directory => newProject(context, directory, ~target="./", ~devcontainer=true),
      },
      {name: "occupied-directory", perform: directory => occupiedDirectory(context, directory)},
    ]
  | _ => common
  }
}

let rec runScenarios = async (context, remaining) =>
  switch remaining {
  | list{} => Ok()
  | list{scenario, ...rest} =>
    let? Ok() = await P.runCase(context, scenario.name, scenario.perform)
    await runScenarios(context, rest)
  }

let execute = async context => {
  let cases = scenarios(context)
  let? Ok() = await runScenarios(context, cases->List.fromArray)
  Console.log(`PASS: ${cases->Array.length->Int.toString} E2E cases for ${context.info.name}`)
  Ok()
}
