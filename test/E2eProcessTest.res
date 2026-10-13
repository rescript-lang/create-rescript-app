open Node
module P = E2eProcess

let withContext = async perform => {
  let workspace = Fs.mkdtempSync(Path.join2(Os.tmpdir(), "cra command test "))

  let context = switch P.makeContext(
    {packagePath: "unused.tgz", manager: Npm, logs: Path.join2(workspace, "logs")},
    workspace,
  ) {
  | Ok(context) => context
  | Error(error) => Assert.fail(P.formatError(error))
  }

  let outcome = try {
    await perform(context)
    Ok()
  } catch {
  | JsExn(cause) => Error(cause)
  }

  await Fs.Promises.rm(workspace, ~options={recursive: true, force: true})
  switch outcome {
  | Ok() => ()
  | Error(cause) => Assert.fail(P.describeCause(cause))
  }
}

Test.describe("E2E command failures", () => {
  Test.testAsync("returns asynchronous spawn failures as values", () =>
    withContext(
      async context => {
        switch await P.run(
          context,
          [Path.join2(context.workspace, "missing-command")],
          context.workspace,
        ) {
        | Error(#SpawnError(cause)) => Assert.strictEqual(cause->errorCode, Some("ENOENT"))
        | _ => Assert.fail("Expected an ENOENT spawn error")
        }
      },
    )
  )

  Test.testAsync("wraps synchronous spawn exceptions", () =>
    withContext(
      async context => {
        switch await P.run(context, [""], context.workspace) {
        | Error(#SpawnError(cause)) =>
          Assert.strictEqual(cause->errorCode, Some("ERR_INVALID_ARG_VALUE"))
        | _ => Assert.fail("Expected an invalid-command spawn error")
        }
      },
    )
  )

  Test.testAsync("wraps spawnSync error properties for the launcher", () =>
    withContext(
      async context => {
        switch NodeSafe.ChildProcess.spawnSync(
          Path.join2(context.workspace, "missing-command"),
          [],
          {cwd: context.workspace, stdio: "pipe"},
        ) {
        | Error(#SpawnError(cause)) => Assert.strictEqual(cause->errorCode, Some("ENOENT"))
        | _ => Assert.fail("Expected a launcher spawn error")
        }
      },
    )
  )

  Test.testAsync("accepts the expected nonzero exit status", () =>
    withContext(
      async context => {
        let outcome = await P.runCommand(
          context,
          [Process.execPath, "-e", "console.log('expected failure'); process.exitCode = 1"],
          context.workspace,
          ~expected=1,
          ~mode=Piped,
          ~timeoutMs=10_000,
        )

        switch outcome {
        | Ok(output) => Assert.strictEqual(output->String.trim, "expected failure")
        | Error(error) => Assert.fail(P.formatError(error))
        }
      },
    )
  )

  Test.testAsync("returns unexpected exit details", () =>
    withContext(
      async context => {
        switch await P.run(
          context,
          [Process.execPath, "-e", "process.exitCode = 7"],
          context.workspace,
        ) {
        | Error(#UnexpectedExit({actual, expected, signal})) =>
          Assert.strictEqual(actual, Some(7))
          Assert.strictEqual(expected, 0)
          Assert.strictEqual(signal, None)
        | _ => Assert.fail("Expected an unexpected-exit error")
        }
      },
    )
  )

  Test.testAsyncWithOptions(
    "stops a timed-out process and returns its failure",
    {skip: Process.platform === "win32"},
    () =>
      withContext(
        async context => {
          switch await P.runCommand(
            context,
            [Process.execPath, "-e", "setInterval(() => {}, 1000)"],
            context.workspace,
            ~expected=0,
            ~mode=Piped,
            ~timeoutMs=100,
          ) {
          | Error(#CommandTimedOut(_)) => ()
          | _ => Assert.fail("Expected a timeout error")
          }
        },
      ),
  )

  Test.testAsyncWithOptions(
    "captures callback log failures and stops the child",
    {skip: Process.platform === "win32"},
    () =>
      withContext(
        async context => {
          switch await P.runCommand(
            context,
            [
              Process.execPath,
              "-e",
              "require('node:fs').rmSync(process.argv[1], {recursive: true}); console.log('trigger log write'); setInterval(() => {}, 1000)",
              context.logs,
            ],
            context.workspace,
            ~expected=0,
            ~mode=Piped,
            ~timeoutMs=10_000,
          ) {
          | Error(#FileError({path, cause})) =>
            Assert.strictEqual(path, context.log.contents)
            Assert.strictEqual(cause->errorCode, Some("ENOENT"))
          | _ => Assert.fail("Expected the callback's file error")
          }
        },
      ),
  )

  Test.testAsync("captures assertion failures at the scenario boundary", () =>
    withContext(
      async context => {
        switch await P.runCase(
          context,
          "assertion-failure",
          async _directory => {
            Assert.strictEqual(1, 2, ~message="Intentional assertion failure")
            Ok()
          },
        ) {
        | Error(#TestFailure(cause)) =>
          Assert.ok(
            P.describeCause(cause)->String.includes("Intentional assertion failure"),
            "Lost the original assertion failure",
          )
        | _ => Assert.fail("Expected a test failure")
        }
      },
    )
  )
})
