#!/usr/bin/env node
// @ts-check

import * as p from "@clack/prompts";
import path from "path";
import fs from "fs";
import os from "os";
import { fileURLToPath } from "url";
import { exec } from "child_process";
import { promisify } from "util";
import { satisfies } from "compare-versions";
import c from "picocolors";

const rescriptVersionRange = "~11 >=11.0.0-rc.6";
const rescriptCoreVersionRange = ">=0.5.0";

// Get __dirname in an ES6 module
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const templates = [
  {
    value: "rescript-template-vite",
    label: "Vite",
    hint: "Vite 5, React and Tailwind CSS",
  },
  {
    value: "rescript-template-nextjs",
    label: "Next.js",
    hint: "Next.js 14 and Tailwind CSS",
  },
  {
    value: "rescript-template-basic",
    label: "Basic",
    hint: "Command line hello world app",
  },
];

async function getPackageVersions(packageName, range) {
  const { stdout } = await promisify(exec)(`npm view ${packageName} versions --json`);
  const versions = JSON.parse(stdout);
  return versions.filter(v => satisfies(v, range)).reverse();
}

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

async function updateExistingPackageJson() {
  await updateFile("package.json", contents => {
    let config = JSON.parse(contents);
    config["scripts"] = { ...(config["scripts"] || {}), "res:dev": "rescript build -w" };
    return JSON.stringify(config, null, 2);
  });
}

async function updateRescriptJson(projectName, sourceDir) {
  await updateFile("rescript.json", contents => {
    const config = JSON.parse(contents);
    config["name"] = projectName;

    if (sourceDir) {
      config["sources"]["dir"] = sourceDir;
    }

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

function getProjectPackageJson() {
  const packageJsonPath = path.join(process.cwd(), "package.json");
  const contents = fs.readFileSync(packageJsonPath, "utf8");
  return JSON.parse(contents);
}

/**
 * @param {string} projectName
 */
async function addToExistingProject(projectName) {
  const templatePath = path.join(__dirname, "templates", "rescript-template-basic");
  const projectPath = process.cwd();
  const gitignorePath = path.join(projectPath, ".gitignore");

  const s = p.spinner();

  try {
    s.start("Loading available versions...");
    const [rescriptVersions, rescriptCoreVersions] = await Promise.all([
      getPackageVersions("rescript", rescriptVersionRange),
      getPackageVersions("@rescript/core", rescriptCoreVersionRange),
    ]);
    s.stop("Versions loaded.");

    const rescriptVersion = await p.select({
      message: "ReScript version?",
      options: rescriptVersions.map(v => ({ value: v })),
    });
    checkCancel(rescriptVersion);

    const rescriptCoreVersion = await p.select({
      message: "ReScript Core version?",
      options: rescriptCoreVersions.map(v => ({ value: v })),
    });
    checkCancel(rescriptCoreVersion);

    const sourceDir = await p.text({
      message: "Where will you put your ReScript source files?",
      defaultValue: "src",
      placeholder: "src",
      initialValue: "src",
    });
    checkCancel(sourceDir);

    s.start("Adding ReScript to your project...");

    await fs.promises.copyFile(
      path.join(templatePath, "rescript.json"),
      path.join(projectPath, "rescript.json")
    );

    if (fs.existsSync(gitignorePath)) {
      await fs.promises.appendFile(gitignorePath, os.EOL + "/lib/" + os.EOL + ".bsb.lock" + os.EOL);
    }

    await updateExistingPackageJson();
    await updateRescriptJson(projectName, sourceDir);

    const sourceDirPath = path.join(projectPath, sourceDir);

    if (!fs.existsSync(sourceDirPath)) {
      await fs.promises.mkdir(sourceDirPath);
    }

    await fs.promises.copyFile(
      path.join(templatePath, "src", "Demo.res"),
      path.join(sourceDirPath, "Demo.res")
    );

    const packages = [`rescript@${rescriptVersion}`, `@rescript/core@${rescriptCoreVersion}`];

    await promisify(exec)("npm add " + packages.join(" "));

    s.stop("Added ReScript to your project.");
    p.note(`npm run res:dev`, "Next steps");
    p.outro(`Happy hacking!`);
  } catch (error) {
    console.warn(error);
    s.stop("Installation error.");

    p.outro(`Adding ReScript to project failed.`);

    p.log.error(error);
  }
}

async function createNewProject() {
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

  const s = p.spinner();

  try {
    s.start("Loading available versions...");
    const [rescriptVersions, rescriptCoreVersions] = await Promise.all([
      getPackageVersions("rescript", rescriptVersionRange),
      getPackageVersions("@rescript/core", rescriptCoreVersionRange),
    ]);
    s.stop("Versions loaded.");

    const rescriptVersion = await p.select({
      message: "ReScript version?",
      options: rescriptVersions.map(v => ({ value: v })),
    });
    checkCancel(rescriptVersion);

    const rescriptCoreVersion = await p.select({
      message: "ReScript Core version?",
      options: rescriptCoreVersions.map(v => ({ value: v })),
    });
    checkCancel(rescriptCoreVersion);

    const templatePath = path.join(__dirname, "templates", templateName);
    const projectPath = path.join(process.cwd(), projectName);

    s.start("Creating project...");

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
      `Your ReScript project ${c.cyan(projectName)} was created successfully.
Change to the ${c.cyan(projectName)} folder and view ${c.cyan("README.md")} for more information.`,
      "Next steps"
    );
    p.outro(`Happy hacking!`);
  } catch (error) {
    s.stop(`Installation error: ${error}`);

    p.outro(`Project creation failed.`);

    p.log.error(error);
  }
}

async function main() {
  console.clear();

  p.intro(c.dim("create-rescript-app " + getVersion()));

  p.note(
    `${c.cyan("Fast, Simple, Fully Typed JavaScript from the Future")}
https://www.rescript-lang.org\n\nCreate a new ReScript 11 project with modern defaults
("Core" standard library, JSX 4 automatic mode)`,
    "Welcome to ReScript!"
  );

  const existingProjectDetected = fs.existsSync(path.join(process.cwd(), "package.json"));

  if (existingProjectDetected) {
    const projectName = getProjectPackageJson().name;

    const addToExistingProjectConfirmed = await p.confirm({
      message: `Detected a package.json file. Do you want to add ReScript to "${projectName}"?`,
    });
    checkCancel(addToExistingProjectConfirmed);

    if (addToExistingProjectConfirmed) {
      addToExistingProject(projectName);
    } else {
      createNewProject();
    }
  } else {
    createNewProject();
  }
}

main();
