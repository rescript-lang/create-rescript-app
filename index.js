#!/usr/bin/env node
const path = require("path");
let fs = require("fs");
const { execSync } = require("child_process");
let colors = require("colors");

let projectName = process.argv[2];
let projectType = process.argv[3];

const currentPath = process.cwd();
const projectPath = path.join(currentPath, projectName);
const basicRepo =
  "https://github.com/rescript-lang/rescript-project-template.git";
const defaultRepo = "https://github.com/mahezsh/rescript-template-default.git";
const nextJsRepo = "https://github.com/ryyppy/rescript-nextjs-template.git";
const graphqlRepo = "https://github.com/mahezsh/rescript-template-graphql.git";
const sbRepo = "https://github.com/mahezsh/rescript-template-storybook.git";

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
    let repoUrl = basicRepo;
    let templateName = "default";

    switch (projectType) {
      case "-b" || "--basic":
        repoUrl = basicRepo;
        templateName = "basic";
        break;
      case "-d" || "--default" || undefined:
        repoUrl = defaultRepo;
        templateName = "default";
        break;
      case "-nx" || "--nextjs":
        repoUrl = nextJsRepo;
        templateName = "nextJS";
        break;
      case "-gql" || "--graphql":
        repoUrl = graphqlRepo;
        templateName = "graphQL";
        break;
      case "-sb" || "--storybook":
        repoUrl = sbRepo;
        templateName = "storybook";
        break;
    }
    console.log(
      `\nCreating a new Rescript app in`,
      `${projectPath}`.green,
      `from`,
      `${templateName}`.blue,
      `template\n`
    );
    execSync(`git clone --depth 1 ${repoUrl} ${projectPath}`);
    process.chdir(projectPath);
    houseKeeping();
    console.log(`\nHappy hacking!\n`);
  } catch (error) {
    console.log(error);
  }
}

async function houseKeeping() {
  console.log("\nInstalling packages. This might take a couple of seconds.");
  execSync("npm install");
  execSync(`find . | grep "\.git/" | xargs rm -rf`);
  execSync("git init");
  console.log(`\nInitialized a git repository.`);
  console.log(
    `\nSuccess!`.green,
    `Created ${projectName} at`,
    `${projectPath}`.green
  );
}

main();
