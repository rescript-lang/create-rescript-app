#!/usr/bin/env node

import c from "ansi-colors";
import enquirer from "enquirer";
import path from "path";
import fs from "fs";
import { execSync } from "child_process";

const templates = {
  Basic: "https://github.com/rescript-lang/rescript-project-template.git",
  "Next.js": "https://github.com/ryyppy/rescript-nextjs-template.git",
};

async function getParams() {
  return await enquirer.prompt([
    {
      type: "input",
      name: "projectName",
      message: "What is the name of your new project?",
      initial: "my-rescript-app",
    },
    {
      type: "select",
      name: "templateName",
      message: "Select a template",
      choices: Object.keys(templates),
    },
  ]);
}

function createProjectDir(projectName, projectPath) {
  try {
    fs.mkdirSync(projectPath);
  } catch (err) {
    if (err.code === "EEXIST") {
      console.log(`The folder ${c.red(projectName)} already exist in the current directory.`);
      console.log("Please try again with another name.");
    } else {
      console.log(err);
    }
    process.exit(1);
  }
}

function houseKeeping(projectName, projectPath) {
  process.chdir(projectPath);

  console.log("Installing packages. This might take a couple of seconds...");

  execSync("npm install");
  execSync(`find . | grep "\.git/" | xargs rm -rf`);
  execSync("git init");

  console.log(`Initialized a git repository.\n`);
  console.log(`${c.green("✔ Success!")} Created ${projectName} at ${c.green(projectPath)}`);
}

async function main() {
  console.log(c.cyan(`Welcome to ${c.red("create-rescript-app")}!`));
  console.log("This tool will help you set up your new ReScript project quickly.\n");

  const { projectName, templateName } = await getParams();
  console.log();

  const projectPath = path.join(process.cwd(), projectName);
  createProjectDir(projectName, projectPath);

  console.log(
    "Creating a new ReScript project",
    `in ${c.green(projectPath)} with template ${c.cyan(templateName)}\n`
  );

  try {
    const repoUrl = templates[templateName];
    execSync(`git clone --depth 1 ${repoUrl} ${projectPath}`);

    houseKeeping(projectName, projectPath);

    console.log(c.bold("Happy hacking!"));
  } catch (error) {
    console.log(error);
  }
}

main();
