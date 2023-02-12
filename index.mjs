#!/usr/bin/env node

import c from "ansi-colors";
import enquirer from "enquirer";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { execSync } from "child_process";

// Get __dirname in an ES6 module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const templates = [
  {
    name: "rescript-template-vite",
    message: "Vite",
    hint: "Opinionated boilerplate for Vite, Tailwind and ReScript",
  },
  {
    name: "rescript-template-nextjs",
    message: "Next.js",
    hint: "Opinionated boilerplate for Next.js, Tailwind and ReScript",
  },
  {
    name: "rescript-template-basic",
    message: "Basic",
    hint: "Command line hello world app",
  },
];

async function getParams() {
  return await enquirer.prompt([
    {
      type: "input",
      name: "projectName",
      message: "What is the name of your new project?",
      initial: process.argv[2] || "my-rescript-app",
    },
    {
      type: "select",
      name: "templateName",
      message: "Select a template",
      choices: templates,
    },
  ]);
}

function installPackages() {
  console.log("Installing packages. This might take a couple of seconds...");

  execSync("npm install");
  console.log(`Packages installed.`);
}

function initGitRepo() {
  execSync("git init");
  console.log(`Initialized a git repository.`);
}

function logSuccess(projectName, projectPath) {
  console.log(`\n${c.green("✔ Success!")} Created ${projectName} at ${c.green(projectPath)}.`);

  console.log("\nNext steps:");
  console.log(`• ${c.bold("cd " + projectName)}`);
  console.log(`• ${c.bold("npm run res:dev")} to start the ReScript compiler in watch mode.`);
  console.log(`• See ${c.bold("README.md")} for more information.`);
  console.log(`\n${c.bold("Happy hacking!")}`);
}

async function main() {
  console.log(c.cyan(`Welcome to ${c.red("create-rescript-app")}!`));
  console.log("This tool will help you set up your new ReScript project quickly.\n");

  const { projectName, templateName } = await getParams();

  console.log(); // newline

  const templatePath = path.join(__dirname, "templates", templateName);
  const projectPath = path.join(process.cwd(), projectName);

  if (fs.existsSync(projectPath)) {
    console.log(`The folder ${c.red(projectName)} already exist in the current directory.`);
    console.log("Please try again with another name.");
    process.exit(1);
  }

  console.log(
    "Creating a new ReScript project",
    `in ${c.green(projectPath)} with template ${c.cyan(templateName)}.`
  );

  try {
    fs.cpSync(templatePath, projectPath, { recursive: true });
    process.chdir(projectPath);

    installPackages();
    initGitRepo();
    logSuccess(projectName, projectPath);
  } catch (error) {
    console.log(error);
  }
}

main();
