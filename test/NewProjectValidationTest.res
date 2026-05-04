open Node

let testRoot = Path.join2(Process.cwd(), ".tmp-new-project-validation-test")
let existingProjectMessage = "The folder my-app already exist in the current directory."

let cleanupTestRoot = async () =>
  await Fs.Promises.rm(testRoot, ~options={recursive: true, force: true})

let resetTestRoot = async () => {
  await cleanupTestRoot()
  await Fs.Promises.mkdir(testRoot, ~options={recursive: true})
}

let assertValidationOk = result =>
  switch result {
  | Ok() => ()
  | Error(message) => Assert.fail(`Expected project name to be valid, got: ${message}`)
  }

let assertValidationError = (result, expectedMessage) =>
  switch result {
  | Error(message) => Assert.strictEqual(message, expectedMessage)
  | Ok() => Assert.fail(`Expected validation error: ${expectedMessage}`)
  }

let validateProjectName = projectName =>
  NewProjectValidation.validateProjectName(~cwd=testRoot, projectName)

Test.describe("NewProjectValidation", () => {
  Test.testAsync("allows an existing project directory with only .devcontainer", async () => {
    await resetTestRoot()
    await Fs.Promises.mkdir(
      Path.join([testRoot, "my-app", ".devcontainer"]),
      ~options={
        recursive: true,
      },
    )

    validateProjectName("my-app")->assertValidationOk
    await cleanupTestRoot()
  })

  Test.testAsync("rejects an existing project directory with additional files", async () => {
    await resetTestRoot()
    await Fs.Promises.mkdir(
      Path.join([testRoot, "my-app", ".devcontainer"]),
      ~options={
        recursive: true,
      },
    )
    await Fs.Promises.writeFile(Path.join([testRoot, "my-app", "package.json"]), "{}")

    validateProjectName("my-app")->assertValidationError(existingProjectMessage)
    await cleanupTestRoot()
  })

  Test.testAsync("rejects an existing project directory with a .devcontainer file", async () => {
    await resetTestRoot()
    await Fs.Promises.mkdir(Path.join2(testRoot, "my-app"), ~options={recursive: true})
    await Fs.Promises.writeFile(Path.join([testRoot, "my-app", ".devcontainer"]), "")

    validateProjectName("my-app")->assertValidationError(existingProjectMessage)
    await cleanupTestRoot()
  })
})
