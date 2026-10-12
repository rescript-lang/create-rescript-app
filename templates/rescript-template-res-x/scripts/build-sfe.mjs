import {mkdirSync, rmSync} from "node:fs";
import {spawnSync} from "node:child_process";

const run = (command, args, extraEnv = {}) => {
  const result = spawnSync(command, args, {
    env: {
      ...process.env,
      ...extraEnv,
    },
    stdio: "inherit",
  });

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
};

run("bun", ["run", "build"]);

rmSync("build", {recursive: true, force: true});
mkdirSync("build", {recursive: true});

run(
  "bun",
  [
    "build",
    "--compile",
    "--target=bun",
    "--outfile",
    "./build/resx-template",
    "./src/App.res.mjs",
  ],
  {NODE_ENV: "production"},
);
