open Node

module Vite = {
  type transformResult = {code: string}

  type plugin = {
    name: string,
    enforce: string,
    resolveId: string => Nullable.t<string>,
    load: string => Nullable.t<string>,
  }

  type reactOptions = {
    @as("include")
    include_: array<string>,
  }

  @module("@vitejs/plugin-react")
  external react: reactOptions => array<plugin> = "default"

  type serverOptions = {hmr: bool, middlewareMode: bool}

  type config = {
    root: string,
    configFile: bool,
    logLevel: string,
    server: serverOptions,
    plugins: array<plugin>,
  }

  type server

  @module("vite") external createServer: config => promise<server> = "createServer"

  @send
  external transformRequest: (server, string) => promise<Nullable.t<transformResult>> =
    "transformRequest"

  @send external close: server => promise<unit> = "close"
}

let viteTemplatePath = "templates/rescript-template-vite"

let generatedRescriptComponent = `import * as React from "react";
import * as JsxRuntime from "react/jsx-runtime";

function App(props) {
  let match = React.useState(() => 0);
  return JsxRuntime.jsx("button", {
    children: match[0]
  });
}

let make = App;

export { make }
`

let stubReactPlugin = {
  Vite.name: "stub-react",
  enforce: "pre",
  resolveId: id =>
    switch id {
    | "react" => Nullable.Value("virtual:react")
    | "react/jsx-runtime" => Nullable.Value("virtual:react-jsx-runtime")
    | _ => Nullable.Undefined
    },
  load: id =>
    switch id {
    | "virtual:react" => Nullable.Value(`export const useState = init => [init(), () => {}];`)
    | "virtual:react-jsx-runtime" =>
      Nullable.Value(`export const jsx = () => null; export const jsxs = () => null;`)
    | _ => Nullable.Undefined
    },
}

let assertIncludes = (actual, substring, message) =>
  if !(actual->String.includes(substring)) {
    Assert.fail(message)
  }

let assertDoesNotInclude = (actual, substring, message) =>
  if actual->String.includes(substring) {
    Assert.fail(message)
  }

let assertJsonObject = (json: JSON.t, message) =>
  switch json {
  | Object(object) => object
  | _ =>
    Assert.fail(message)
    Dict.make()
  }

let assertJsonMissing = (json: option<JSON.t>, message) =>
  switch json {
  | None => ()
  | Some(_) => Assert.fail(message)
  }

let assertJsonNumber = (json: option<JSON.t>, expected, message) =>
  switch json {
  | Some(Number(actual)) => Assert.strictEqual(actual, expected)
  | _ => Assert.fail(message)
  }

let assertJsonString = (json: option<JSON.t>, expected, message) =>
  switch json {
  | Some(String(actual)) => Assert.strictEqual(actual, expected)
  | _ => Assert.fail(message)
  }

let assertCoreRemoved = config => {
  RescriptJsonUtils.removeRescriptCore(config)

  let serialized = JSON.stringify(Object(config))

  serialized->assertDoesNotInclude("@rescript/core", "Expected @rescript/core to be removed.")
  serialized->assertDoesNotInclude(
    "-open RescriptCore",
    "Expected the RescriptCore open flag to be removed.",
  )
  serialized->assertIncludes("@rescript/react", "Expected unrelated dependencies to be preserved.")
}

Test.describe("Vite template Fast Refresh", () => {
  Test.testAsync("turns generated ReScript output into a React Refresh boundary", async () => {
    let tempDir = Path.join2(Process.cwd(), ".tmp-vite-fast-refresh-test")
    let tempModulePath = Path.join2(tempDir, "App.res.mjs")

    await Fs.Promises.rm(tempDir, ~options={recursive: true, force: true})
    await Fs.Promises.mkdir(tempDir, ~options={recursive: true})
    await Fs.Promises.writeFile(tempModulePath, generatedRescriptComponent)

    let plugins = [stubReactPlugin, ...Vite.react({include_: ["**/*.res.mjs"]})]
    let server = await Vite.createServer({
      root: Process.cwd(),
      configFile: false,
      logLevel: "silent",
      server: {
        hmr: true,
        middlewareMode: true,
      },
      plugins,
    })

    let transformed = switch await server->Vite.transformRequest(
      "/.tmp-vite-fast-refresh-test/App.res.mjs",
    ) {
    | Nullable.Value({code}) => code
    | Nullable.Null | Nullable.Undefined => ""
    }

    await server->Vite.close
    await Fs.Promises.rm(tempDir, ~options={recursive: true, force: true})

    assertIncludes(
      transformed,
      "$RefreshReg$(",
      "Expected Vite's React plugin to register the generated component for React Refresh.",
    )
    assertIncludes(
      transformed,
      "registerExportsForReactRefresh",
      "Expected Vite's React plugin to validate the module as a React Refresh boundary.",
    )
    assertIncludes(
      transformed,
      "import.meta.hot.accept",
      "Expected the transformed ReScript module to accept Fast Refresh updates.",
    )
  })

  Test.test("keeps template ReScript config compatible with selectable versions", () => {
    Assert.strictEqual(
      "11.1.4"->CompareVersions.satisfies(RescriptVersions.rescriptVersionRange),
      true,
    )
    Assert.strictEqual(
      "12.0.0"->CompareVersions.satisfies(RescriptVersions.rescriptVersionRange),
      true,
    )

    let config =
      Fs.readFileSync(`${viteTemplatePath}/rescript.json`)
      ->JSON.parseOrThrow
      ->assertJsonObject("Expected the Vite template rescript.json to be a JSON object.")

    config
    ->Dict.get("suffix")
    ->assertJsonString(
      ".res.mjs",
      "Expected ReScript output to keep the .res.mjs extension used by the Vite config.",
    )

    let jsx =
      config
      ->Dict.get("jsx")
      ->Option.getOrThrow
      ->assertJsonObject("Expected the Vite template to configure JSX.")

    jsx->Dict.get("version")->assertJsonNumber(4.0, "Expected JSX v4.")
    jsx
    ->Dict.get("preserve")
    ->assertJsonMissing("Expected the Vite template not to require JSX preserve mode.")

    switch config->Dict.get("bs-dependencies") {
    | Some(Array(_)) => ()
    | _ => Assert.fail("Expected Vite template to use ReScript 11-compatible dependency fields.")
    }
    config
    ->Dict.get("dependencies")
    ->assertJsonMissing("Expected Vite template to avoid ReScript 12-only dependency fields.")
  })

  Test.test("removes @rescript/core from legacy ReScript config fields", () => {
    let config =
      `{"bs-dependencies":["@rescript/core","@rescript/react"],"bsc-flags":["-open RescriptCore"]}`
      ->JSON.parseOrThrow
      ->assertJsonObject("Expected test config to be a JSON object.")

    assertCoreRemoved(config)
  })

  Test.test("removes @rescript/core from modern ReScript config fields", () => {
    let config =
      `{"dependencies":["@rescript/core","@rescript/react"],"compiler-flags":["-open RescriptCore"]}`
      ->JSON.parseOrThrow
      ->assertJsonObject("Expected test config to be a JSON object.")

    assertCoreRemoved(config)
  })

  Test.test("keeps modernized ReScript 12 config from referencing @rescript/core", () => {
    let config =
      `{"bs-dependencies":["@rescript/core","@rescript/react"],"bsc-flags":["-open RescriptCore"]}`
      ->JSON.parseOrThrow
      ->assertJsonObject("Expected test config to be a JSON object.")

    RescriptJsonUtils.removeRescriptCore(config)
    RescriptJsonUtils.modernizeConfigurationFields(config)

    let serialized = JSON.stringify(Object(config))

    serialized->assertDoesNotInclude("@rescript/core", "Expected @rescript/core to be removed.")
    serialized->assertDoesNotInclude(
      "-open RescriptCore",
      "Expected the RescriptCore open flag to be removed.",
    )
    serialized->assertIncludes(
      "\"dependencies\":[\"@rescript/react\"]",
      "Expected remaining dependencies to be moved into modern ReScript config fields.",
    )
    config
    ->Dict.get("bs-dependencies")
    ->assertJsonMissing("Expected legacy dependency fields to be removed after modernization.")
  })

  Test.test("waits for generated ReScript output before sending HMR updates", () => {
    let config = Fs.readFileSync(`${viteTemplatePath}/vite.config.js`)
    let rescriptConfig =
      Fs.readFileSync(`${viteTemplatePath}/rescript.json`)
      ->JSON.parseOrThrow
      ->assertJsonObject("Expected the Vite template rescript.json to be a JSON object.")
    let suffix = switch rescriptConfig->Dict.get("suffix") {
    | Some(String(suffix)) => suffix
    | _ =>
      Assert.fail("Expected the Vite template rescript.json to configure a suffix.")
      ".res.mjs"
    }

    assertIncludes(
      config,
      `const rescriptOutputSuffix = ${JSON.stringify(String(suffix))};`,
      "Expected the Vite config suffix constant to match the ReScript output suffix.",
    )
    assertIncludes(
      config,
      "include: [`**/*${rescriptOutputSuffix}`]",
      "Expected @vitejs/plugin-react to transform generated ReScript output files.",
    )
    assertIncludes(
      config,
      "\"**/*.res\"",
      "Expected Vite to ignore ReScript source files and wait for generated JS.",
    )
    assertIncludes(
      config,
      "\"**/*.resi\"",
      "Expected Vite to ignore ReScript interface files and wait for generated JS.",
    )
    assertDoesNotInclude(
      config,
      "loader: \"jsx\"",
      "Expected Fast Refresh not to depend on JSX preserve-mode parsing.",
    )
  })

  Test.test("stamps the generated Vite config with the selected ReScript suffix", () => {
    let stamped = ViteTemplateUtils.stampOutputSuffix(
      ~suffix=".res.js",
      "const rescriptOutputSuffix = \".res.mjs\";\nreact({\n  include: [`**/*${rescriptOutputSuffix}`],\n});\n",
    )

    stamped->assertIncludes(
      `const rescriptOutputSuffix = ".res.js";`,
      "Expected project generation to copy the selected ReScript suffix into Vite config.",
    )
    stamped->assertDoesNotInclude(
      `const rescriptOutputSuffix = ".res.mjs";`,
      "Expected project generation not to leave the template suffix behind.",
    )
  })
})
