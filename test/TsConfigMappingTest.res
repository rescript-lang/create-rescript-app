open Node

let makeConfig = (
  ~module_=?,
  ~moduleResolution=?,
  ~allowJs=false,
  ~allowImportingTsExtensions=false,
  ~noEmit=false,
  ~emitDeclarationOnly=false,
  ~jsx=?,
  ~hasMts=false,
  ~hasCts=false,
  ~hasNestedPackageType=false,
  (),
): TsConfigMapping.parsedConfig => {
  status: "found",
  ?module_,
  ?moduleResolution,
  allowJs,
  allowImportingTsExtensions,
  noEmit,
  emitDeclarationOnly,
  ?jsx,
  hasMts,
  hasCts,
  hasNestedPackageType,
}

let assertInferred = (
  result: result<TsConfigMapping.inferredConfig, string>,
  ~moduleSystem,
  ~moduleResolution,
  ~generatedFileExtension,
  ~needsAllowJs,
) =>
  switch result {
  | Ok(config) =>
    Assert.strictEqual(config.moduleSystem, moduleSystem)
    Assert.strictEqual(config.suffix, ".res.js")
    Assert.strictEqual(config.gentypeModuleResolution, moduleResolution)
    Assert.strictEqual(config.generatedFileExtension, generatedFileExtension)
    Assert.strictEqual(config.needsAllowJs, needsAllowJs)
  | Error(message) => Assert.fail(message)
  }

let assertError = (result: result<TsConfigMapping.inferredConfig, string>, expectedMessage) =>
  switch result {
  | Ok(_) => Assert.fail(`Expected mapping error: ${expectedMessage}`)
  | Error(message) => Assert.strictEqual(message, expectedMessage)
  }

Test.describe("TsConfigMapping", () => {
  Test.test("maps CommonJS projects to CommonJS genType output", () => {
    makeConfig(~module_="commonjs", ~moduleResolution="nodejs", ())
    ->TsConfigMapping.infer(~packageType=None, ~hasJsxDependency=false)
    ->assertInferred(
      ~moduleSystem="commonjs",
      ~moduleResolution="node",
      ~generatedFileExtension=".gen.ts",
      ~needsAllowJs=true,
    )
  })

  Test.test("maps bundler ESM projects to ESM genType output", () => {
    makeConfig(
      ~module_="esnext",
      ~moduleResolution="bundler",
      ~allowJs=true,
      ~allowImportingTsExtensions=true,
      ~jsx="react-jsx",
      (),
    )
    ->TsConfigMapping.infer(~packageType=None, ~hasJsxDependency=false)
    ->assertInferred(
      ~moduleSystem="esmodule",
      ~moduleResolution="bundler",
      ~generatedFileExtension=".gen.tsx",
      ~needsAllowJs=false,
    )
  })

  Test.test("maps preserve mode to bundler genType resolution", () => {
    switch makeConfig(~module_="preserve", ~noEmit=true, ())->TsConfigMapping.infer(
      ~packageType=None,
      ~hasJsxDependency=false,
    ) {
    | Ok(config) =>
      Assert.strictEqual(config.moduleSystem, "esmodule")
      Assert.strictEqual(config.gentypeModuleResolution, "bundler")
      Assert.strictEqual(config.needsAllowImportingTsExtensions, true)
      Assert.strictEqual(config.cannotSetAllowImportingTsExtensions, false)
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("maps NodeNext package modules to ESM output and node16 genType resolution", () => {
    switch makeConfig(
      ~module_="nodenext",
      ~moduleResolution="nodenext",
      ~allowJs=true,
      (),
    )->TsConfigMapping.infer(~packageType=Some("module"), ~hasJsxDependency=false) {
    | Ok(config) =>
      Assert.strictEqual(config.moduleSystem, "esmodule")
      Assert.strictEqual(config.gentypeModuleResolution, "node16")
      Assert.strictEqual(config.warnings->Array.length, 1)
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("rejects Node dual-format projects that conflict with package type", () => {
    makeConfig(~module_="node16", ~moduleResolution="node16", ~hasMts=true, ())
    ->TsConfigMapping.infer(~packageType=None, ~hasJsxDependency=false)
    ->assertError(
      "This TypeScript project appears to use mixed Node module formats, which cannot be represented by one ReScript project-level module setting.",
    )
  })

  Test.test("rejects ESM module configs without an effective module resolution", () => {
    makeConfig(~module_="esnext", ())
    ->TsConfigMapping.infer(~packageType=None, ~hasJsxDependency=false)
    ->assertError(
      "No compilerOptions.moduleResolution setting was found for TypeScript module \"esnext\".",
    )
  })

  Test.test("uses tsx generated files when package dependencies indicate JSX", () => {
    makeConfig(~module_="commonjs", ~moduleResolution="node", ~allowJs=true, ())
    ->TsConfigMapping.infer(~packageType=None, ~hasJsxDependency=true)
    ->assertInferred(
      ~moduleSystem="commonjs",
      ~moduleResolution="node",
      ~generatedFileExtension=".gen.tsx",
      ~needsAllowJs=false,
    )
  })
})
