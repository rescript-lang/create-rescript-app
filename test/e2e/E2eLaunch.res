open Node
module N = E2eNode

// A real package script supplies the selected manager's identity to the CLI.
let launch = () =>
  switch (Process.argv->Array.get(2), N.Process.env->Dict.get("CRA_E2E_CLI")) {
  | (Some(directory), Some(cliPath)) =>
    let args = Process.argv->Array.slice(~start=3)
    let result = N.ChildProcess.spawnSync(
      N.Process.execPath,
      [cliPath, ...args],
      {
        cwd: directory,
        stdio: "inherit",
      },
    )
    switch result.error {
    | Some(error) => JsExn.throw(error)
    | None => Process.exitWithCode(result.status->Nullable.toOption->Option.getOr(1))
    }
  | _ => N.Assert.fail("Expected a project directory and CRA_E2E_CLI")
  }

launch()
