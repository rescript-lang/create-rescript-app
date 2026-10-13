open Node

// A real package script supplies the selected manager's identity to the CLI.
let launch = () =>
  switch (Process.argv->Array.get(2), Process.env->Dict.get("CRA_E2E_CLI")) {
  | (Some(directory), Some(cliPath)) =>
    let args = Process.argv->Array.slice(~start=3)

    let? Ok(result) = ChildProcess.spawnSync(
      Process.execPath,
      [cliPath, ...args],
      {
        cwd: directory,
        stdio: "inherit",
      },
    )

    Ok(result.status->Nullable.toOption->Option.getOr(1))
  | _ => Error(#InvalidArguments("Expected a project directory and CRA_E2E_CLI"))
  }

switch launch() {
| Ok(code) => Process.state.exitCode = code
| Error(error) =>
  Console.error(E2eProcess.formatError(error))
  Process.state.exitCode = 1
}
