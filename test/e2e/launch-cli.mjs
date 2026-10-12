import { spawnSync } from "node:child_process";

// Running this script through the chosen package manager supplies its real
// npm_execpath/npm_config_user_agent, just as a user's package script would.
const [projectDirectory, ...args] = process.argv.slice(2);
const result = spawnSync(process.execPath, [process.env.CRA_E2E_CLI, ...args], {
  cwd: projectDirectory,
  stdio: "inherit",
});

if (result.error) throw result.error;
process.exit(result.status ?? 1);
