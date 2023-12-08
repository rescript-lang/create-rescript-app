#!/usr/bin/env node

import * as p from "@clack/prompts";
import path from "path";
import fs from "fs";
import { fileURLToPath } from "url";
import { exec } from "child_process";
import { promisify } from "util";
import { glob } from "glob";
import c from "picocolors";

// Get __dirname in an ES6 module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const templates = [
  {
    value: "rescript-template-vite",
    label: "Vite",
    hint: "React, JSX4 and Tailwind CSS",
  },
  {
    value: "rescript-template-basic",
    label: "Basic",
    hint: "Command line hello world app",
  },
  // Needs to be upgraded to current ReScript + Next.js
  // {
  //   value: "rescript-template-nextjs",
  //   label: "Next.js",
  //   hint: "Next.js, Tailwind CSS",
  // },
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

async function updateFile(filename, updateContents) {
  const contents = await fs.promises.readFile(filename, "utf8");
  const updated = updateContents(contents);
  await fs.promises.writeFile(filename, updated, "utf8");
}

async function updatePackageJson(projectName) {
  await updateFile("package.json", contents =>
    contents.replace(/"name": "rescript-template-.*"/, `"name": "${projectName}"`)
  );
}

async function updateRescriptJson(projectName, withCore) {
  await updateFile("rescript.json", contents => {
    const config = JSON.parse(contents);
    config["name"] = projectName;
    return JSON.stringify(config, null, 2);
  });
}

async function renameGitignore() {
  await fs.promises.rename("_gitignore", ".gitignore");
}

function getVersion() {
  const packageJsonPath = path.join(__dirname, "package.json");
  const contents = fs.readFileSync(packageJsonPath, "utf8");
  return JSON.parse(contents).version;
}

async function main() {
  console.clear();

  p.intro(`${c.bgCyan(c.black(` create-rescript-app `))} ${c.dim("(" + getVersion() + ")")}`);
  p.note(
    'Create a new ReScript 11 project with modern defaults\n("Core" standard library, JSX 4 automatic mode)'
  );

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

  const rescriptVersion = await p.text({
    message: "ReScript version? (keep the default if unsure)",
    initialValue: "11.0.0-rc.7",
  });
  checkCancel(rescriptVersion);

  const rescriptCoreVersion = await p.text({
    message: "ReScript Core version? (keep the default if unsure)",
    initialValue: "0.6.0",
  });
  checkCancel(rescriptCoreVersion);

  const templatePath = path.join(__dirname, "templates", templateName);
  const projectPath = path.join(process.cwd(), projectName);

  const s = p.spinner();
  s.start("Creating project...");

  try {
    await fs.promises.cp(templatePath, projectPath, { recursive: true });
    process.chdir(projectPath);

    await renameGitignore();
    await updatePackageJson(projectName);
    await updateRescriptJson(projectName);

    const packages = [`rescript@${rescriptVersion}`, `@rescript/core@${rescriptCoreVersion}`];

    await promisify(exec)("npm add " + packages.join(" "));
    await promisify(exec)("git init");
    s.stop("Project created.");

    p.note(
      `Your project ${c.cyan(projectName)} was created successfully.\nChange to the ${c.cyan(
        projectName
      )} folder and view ${c.cyan("README.md")} for more information.`,
      "Next steps"
    );
    p.outro(`Happy hacking!`);
  } catch (error) {
    s.stop(`Installation error: ${error}`);

    p.outro(`Project creation failed.`);

    p.log.error(error);
  }
}

main();
