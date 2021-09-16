#!/usr/bin/env node
const path = require("path");
let fs = require("fs");
const { execSync } = require("child_process");
let colors = require("colors");

let projectName = process.argv[2];
const currentPath = process.cwd();
const projectPath = path.join(currentPath, projectName);
const git_repo =
  "https://github.com/rescript-lang/rescript-project-template.git";

try {
  fs.mkdirSync(projectPath);
} catch (err) {
  if (err.code === "EEXIST") {
    console.log(
      `The folder`,
      `${projectName}`.red,
      `already exist in the current directory, please give it another name.`
    );
  } else {
    console.log(error);
  }
  process.exit(1);
}

async function main() {
  try {
    console.log(`Creating a new Rescript app in`, `${projectPath}\n`.green);
    execSync(`git clone --depth 1 ${git_repo} ${projectPath}`);
    process.chdir(projectPath);
    console.log("\nInstalling packages. This might take a couple of seconds.");
    execSync("npm install");
    execSync(`find . | grep "\.git/" | xargs rm -rf`);
    execSync("git init");
    console.log(`\nInitialized a git repository.`);
    console.log(
      `\nSuccess!`.green,
      `Created ${projectName} at `,
      `${projectPath}`.green
    );
    console.log(`\nHappy hacking!\n`);
  } catch (error) {
    console.log(error);
  }
}
main();
