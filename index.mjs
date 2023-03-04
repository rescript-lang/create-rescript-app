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
    hint: "ReScript 10.1, JSX4, Vite, Tailwind CSS",
  },
  {
    value: "rescript-template-basic",
    label: "Basic",
    hint: "ReScript 10.1, command line hello world app",
  },
  {
    value: "rescript-template-nextjs",
    label: "Next.js",
    hint: "ReScript 9.1, Next.js, Tailwind CSS",
    incompatibleWithCore: true,
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

async function updateBsconfigJson(projectName, withCore) {
  await updateFile("bsconfig.json", contents => {
    const config = JSON.parse(contents);

    config["name"] = projectName;

    if (withCore) {
      config["bs-dependencies"] = [...(config["bs-dependencies"] || []), "@rescript/core"];
      config["bsc-flags"] = [...(config["bsc-flags"] || []), "-open RescriptCore"];
    }

    return JSON.stringify(config, null, 2);
  });
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

  const incompatibleWithCore = templates.find(t => t.value === templateName).incompatibleWithCore;

  const withCore =
    !incompatibleWithCore &&
    (await p.confirm({
      message: "Add the new @rescript/core standard libary?",
    }));
  checkCancel(withCore);

  const templatePath = path.join(__dirname, "templates", templateName);
  const projectPath = path.join(process.cwd(), projectName);

  const s = p.spinner();
  s.start("Creating project...");

  try {
    await fs.promises.cp(templatePath, projectPath, { recursive: true });
    process.chdir(projectPath);

    await updatePackageJson(projectName);
    await updateBsconfigJson(projectName, withCore);

    if (withCore) {
      await promisify(exec)("npm add @rescript/core");
    } else {
      await promisify(exec)("npm install");
    }

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
