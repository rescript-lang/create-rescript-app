#!/usr/bin/env node
const path = require("path");
const fs = require("fs");
const { execSync } = require("child_process");

require("colors");

const projectName = process.argv[2];
const projectType = process.argv[3];

const currentPath = process.cwd(),
  projectPath = path.join(currentPath, projectName);

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

function main() {
  try {
    let repoUrl;
    let templateName;

    switch (projectType) {
      case "-b":
      case "--basic":
        repoUrl = basicRepo;
        templateName = "basic";
        break;
      case "-nx":
      case "--nextjs":
        repoUrl = nextJsRepo;
        templateName = "nextJS";
        break;
      case "-gql":
      case "--graphql":
        repoUrl = graphqlRepo;
        templateName = "graphQL";
        break;
      case "-sb":
      case "--storybook":
        repoUrl = sbRepo;
        templateName = "storybook";
        break;
      case "-d":
      case "--default":
      default:
        repoUrl = defaultRepo;
        templateName = "default";
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

function houseKeeping() {
  console.log("\nInstalling packages. This might take a couple of seconds.");

  execSync("npm install");
  execSync(`find . | grep "\.git/" | xargs rm -rf`);
  execSync("git init");
  console.log(`\nInitialized a git repository.\n`);

  console.log(
    `✔ Success!`.green,
    `Created ${projectName} at`,
    `${projectPath}`.green
  );
}

main();
