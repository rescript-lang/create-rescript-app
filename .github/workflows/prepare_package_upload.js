const fs = require("fs");
const os = require("os");

const packageSpec = JSON.parse(fs.readFileSync("./package.json", "utf8"));
const { version } = packageSpec;

const commitHash = process.argv[2] || process.env.GITHUB_SHA;
const commitHashShort = commitHash.substring(0, 7);
const artifactFilename = `create-rescript-app-${version}-${commitHashShort}.tgz`;

fs.renameSync(`create-rescript-app-${version}.tgz`, artifactFilename);

// Pass information to subsequent GitHub actions
fs.appendFileSync(
  process.env.GITHUB_ENV,
  `artifact_filename=${artifactFilename}${os.EOL}`
);
