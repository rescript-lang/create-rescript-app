#!/usr/bin/env node

import * as p from "@clack/prompts";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { exec } from "child_process";
import { promisify } from "util";
import c from "picocolors";

// Get __dirname in an ES6 module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const templates = [
  {
    value: "rescript-template-vite",
    label: "Vite",
    hint: "Opinionated boilerplate for Vite, Tailwind and ReScript",
  },
  {
    value: "rescript-template-nextjs",
    label: "Next.js",
    hint: "Opinionated boilerplate for Next.js, Tailwind and ReScript",
  },
  {
    value: "rescript-template-basic",
    label: "Basic",
    hint: "Command line hello world app",
  },
];

function checkCancel(value) {
  if (p.isCancel(value)) {
    p.cancel("Project creation cancelled.");
    process.exit(0);
  }
}

function validateProjectName(projectName) {
  const packageNameRegExp = /^[a-z0-9-]+$/;

  if (projectName.trim().length === 0) {
    return "Project name must not be empty.";
  }

  if (!packageNameRegExp.test(projectName)) {
    return "Project name may only contain lower case letters, numbers and hyphens.";
  }

  const projectPath = path.join(process.cwd(), projectName);
  if (fs.existsSync(projectPath)) {
    return `The folder ${projectName} already exist in the current directory.`;
  }
}

async function replaceLineInFile(filename, search, replace) {
  const contents = await fs.promises.readFile(filename, "utf8");
  const replaced = contents.replace(search, replace);
  await fs.promises.writeFile(filename, replaced, "utf8");
}

async function setProjectName(templateName, projectName) {
  await replaceLineInFile("package.json", `"name": "${templateName}"`, `"name": "${projectName}"`);
  await replaceLineInFile("bsconfig.json", `"name": "${templateName}"`, `"name": "${projectName}"`);
}

function getVersion() {
  const packageJsonPath = path.join(__dirname, "package.json");
  const contents = fs.readFileSync(packageJsonPath, "utf8");
  return JSON.parse(contents).version;
}

async function main() {
  console.clear();

  const version = getVersion();
  p.intro(`${c.bgCyan(c.black(` create-rescript-app `))} ${c.dim(version)}`);

  const projectName = await p.text({
    message: "What is the name of your new ReScript project?",
    placeholder: process.argv[2] || "my-rescript-app",
    validate: validateProjectName,
  });
  checkCancel(projectName);

  const templateName = await p.select({
    message: "Select a template",
    options: templates,
  });
  checkCancel(templateName);

  const shouldContinue = await p.confirm({
    message: `Your new ReScript project ${c.cyan(projectName)} will now be created. Continue?`,
  });
  checkCancel(shouldContinue);

  if (!shouldContinue) {
    p.outro("No project created.");
    process.exit(0);
  }

  const templatePath = path.join(__dirname, "templates", templateName);
  const projectPath = path.join(process.cwd(), projectName);

  const s = p.spinner();
  s.start("Creating project...");

  try {
    await fs.promises.cp(templatePath, projectPath, { recursive: true });
    process.chdir(projectPath);

    await setProjectName(templateName, projectName);
    await promisify(exec)("npm install");
    await promisify(exec)("git init");
    s.stop("Project created.");

    p.note(`cd ${projectName}\nnpm run res:dev`, "Next steps");
    p.outro(`Happy hacking! See ${c.cyan("README.md")} for more information.`);
  } catch (error) {
    s.stop("Installation error.");

    p.outro(`Project creation failed.`);

    p.log.error(error);
  }
}

main();
