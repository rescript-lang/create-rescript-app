open Node

let assertCommandLineArguments = (actual: CommandLineArguments.t, ~projectName, ~templateName) => {
  Assert.strictEqual(actual.projectName, projectName)
  Assert.strictEqual(actual.templateName, templateName)
}

let assertParseError = (~remainingArguments, ~message) =>
  switch CommandLineArguments.parse(remainingArguments) {
  | Ok(_) => Assert.fail(`Expected parse error: ${message}`)
  | Error(actualMessage) => Assert.strictEqual(actualMessage, message)
  }

Test.describe("CommandLineArguments", () => {
  Test.test("returns empty values when no arguments are provided", () => {
    switch CommandLineArguments.parse(list{}) {
    | Ok(commandLineArguments) =>
      commandLineArguments->assertCommandLineArguments(~projectName=None, ~templateName=None)
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("parses the project name from the first positional argument", () => {
    switch CommandLineArguments.parse(list{"my-app"}) {
    | Ok(commandLineArguments) =>
      commandLineArguments->assertCommandLineArguments(
        ~projectName=Some("my-app"),
        ~templateName=None,
      )
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("parses the template name from the -t flag", () => {
    switch CommandLineArguments.parse(list{"my-app", "-t", "vite"}) {
    | Ok(commandLineArguments) =>
      commandLineArguments->assertCommandLineArguments(
        ~projectName=Some("my-app"),
        ~templateName=Some(Templates.viteTemplateName),
      )
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("parses the template name from the --template flag", () => {
    switch CommandLineArguments.parse(list{"my-app", "--template", "nextjs"}) {
    | Ok(commandLineArguments) =>
      commandLineArguments->assertCommandLineArguments(
        ~projectName=Some("my-app"),
        ~templateName=Some(Templates.nextjsTemplateName),
      )
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("parses the template name from the --template=... flag", () => {
    switch CommandLineArguments.parse(list{"my-app", "--template=basic"}) {
    | Ok(commandLineArguments) =>
      commandLineArguments->assertCommandLineArguments(
        ~projectName=Some("my-app"),
        ~templateName=Some(Templates.basicTemplateName),
      )
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("ignores the node executable and script path in process argv", () => {
    switch CommandLineArguments.fromProcessArgv([
      "/usr/local/bin/node",
      "/tmp/create-rescript-app",
      "my-app",
      "-t",
      "vite",
    ]) {
    | Ok(commandLineArguments) =>
      commandLineArguments->assertCommandLineArguments(
        ~projectName=Some("my-app"),
        ~templateName=Some(Templates.viteTemplateName),
      )
    | Error(message) => Assert.fail(message)
    }
  })

  Test.test("rejects a missing template value", () => {
    assertParseError(
      ~remainingArguments=list{"my-app", "--template"},
      ~message="Missing value for --template. Supported options: --template <vite|nextjs|basic> or -t <vite|nextjs|basic>.",
    )
  })

  Test.test("rejects unknown options", () => {
    assertParseError(
      ~remainingArguments=list{"my-app", "--yes"},
      ~message="Unknown option \"--yes\". Supported options: --template <vite|nextjs|basic> or -t <vite|nextjs|basic>.",
    )
  })

  Test.test("rejects unknown templates", () => {
    assertParseError(
      ~remainingArguments=list{"my-app", "--template", "unknown"},
      ~message="Unknown template \"unknown\". Available templates: vite, nextjs, basic.",
    )
  })

  Test.test("rejects positional templates", () => {
    assertParseError(
      ~remainingArguments=list{"my-app", "vite"},
      ~message="Unexpected argument \"vite\". Supported options: --template <vite|nextjs|basic> or -t <vite|nextjs|basic>.",
    )
  })

  Test.test("rejects additional positional arguments after the template", () => {
    assertParseError(
      ~remainingArguments=list{"my-app", "-t", "vite", "extra"},
      ~message="Unexpected argument \"extra\". Supported options: --template <vite|nextjs|basic> or -t <vite|nextjs|basic>.",
    )
  })
})
