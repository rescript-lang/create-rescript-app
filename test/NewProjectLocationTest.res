open Node

let testRoot = Path.join2(Process.cwd(), ".tmp-new-project-location-test")
let currentDirectoryConflictMessage = "The current directory contains files that could conflict with project creation."

let cleanupTestRoot = async () =>
  await Fs.Promises.rm(testRoot, ~options={recursive: true, force: true})

let resetTestRoot = async projectDirectoryName => {
  await cleanupTestRoot()
  let projectPath = Path.join2(testRoot, projectDirectoryName)
  await Fs.Promises.mkdir(projectPath, ~options={recursive: true})
  projectPath
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

Test.describe("NewProjectLocation", () => {
  Test.test("uses the current directory basename as the package name", () => {
    NewProjectLocation.getPackageName(~cwd="/tmp/my-app", ".")->Assert.strictEqual("my-app")
  })

  Test.test("uses the current directory as the project path", () => {
    NewProjectLocation.getProjectPath(~cwd="/tmp/my-app", ".")->Assert.strictEqual("/tmp/my-app")
  })

  Test.testAsync("allows creating in a repository with README and license files", async () => {
    let projectPath = await resetTestRoot("my-app")
    await Fs.Promises.mkdir(Path.join2(projectPath, ".git"))
    await Fs.Promises.writeFile(Path.join2(projectPath, "README.md"), "")
    await Fs.Promises.writeFile(Path.join2(projectPath, "LICENSE"), "")

    NewProjectLocation.validateProjectName(~cwd=projectPath, ".")->assertValidationOk
    await cleanupTestRoot()
  })

  Test.testAsync("rejects creating in a current directory with project files", async () => {
    let projectPath = await resetTestRoot("my-app")
    await Fs.Promises.writeFile(Path.join2(projectPath, "src"), "")

    NewProjectLocation.validateProjectName(~cwd=projectPath, ".")->assertValidationError(
      currentDirectoryConflictMessage,
    )
    await cleanupTestRoot()
  })

  Test.testAsync("rejects creating a nested project that already exists", async () => {
    let _ = await resetTestRoot("existing-app")

    NewProjectLocation.validateProjectName(~cwd=testRoot, "existing-app")->assertValidationError(
      "The folder existing-app already exist in the current directory.",
    )
    await cleanupTestRoot()
  })
})
