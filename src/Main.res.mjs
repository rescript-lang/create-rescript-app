// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Js_exn from "rescript/lib/es6/js_exn.js";
import * as Nodefs from "node:fs";
import * as CraPaths from "./CraPaths.res.mjs";
import * as JsonUtils from "./JsonUtils.res.mjs";
import * as Nodepath from "node:path";
import * as NewProject from "./NewProject.res.mjs";
import * as Picocolors from "picocolors";
import * as ClackPrompts from "./bindings/ClackPrompts.res.mjs";
import * as Core__Option from "@rescript/core/src/Core__Option.res.mjs";
import * as Prompts from "@clack/prompts";
import * as ExistingProject from "./ExistingProject.res.mjs";
import * as Caml_js_exceptions from "rescript/lib/es6/caml_js_exceptions.js";

async function getVersion() {
  var json = await JsonUtils.readJsonFile(CraPaths.packageJsonPath);
  return Core__Option.getOr(JsonUtils.getStringValue(json, "version"), "");
}

async function handleError(outro, perform) {
  try {
    return await perform();
  }
  catch (raw_error){
    var error = Caml_js_exceptions.internalToOCamlException(raw_error);
    if (error.RE_EXN_ID === ClackPrompts.Canceled) {
      Prompts.cancel("Canceled.");
      return ;
    }
    if (error.RE_EXN_ID === Js_exn.$$Error) {
      var message = error._1.message;
      if (message !== undefined) {
        Prompts.log.error("Error: " + message);
      }
      Prompts.outro(outro);
      process.exit(1);
      return ;
    }
    throw error;
  }
}

async function run() {
  var version = await getVersion();
  Prompts.intro(Picocolors.default.dim("create-rescript-app " + version));
  Prompts.note(Picocolors.default.cyan("Fast, Simple, Fully Typed JavaScript from the Future") + "\nhttps://www.rescript-lang.org", "Welcome to ReScript!");
  var packageJsonPath = Nodepath.join(process.cwd(), "package.json");
  if (!Nodefs.existsSync(packageJsonPath)) {
    return await handleError("Project creation failed.", (async function () {
                  await NewProject.createNewProject();
                  Prompts.outro("Happy hacking!");
                }));
  }
  var packageJson = await JsonUtils.readJsonFile(packageJsonPath);
  var projectName = Core__Option.getOr(JsonUtils.getStringValue(packageJson, "name"), "unknown");
  var addToExistingProject = await ClackPrompts.resultOrRaise(Prompts.confirm({
            message: "Detected a package.json file. Do you want to add ReScript to \"" + projectName + "\"?"
          }));
  if (addToExistingProject) {
    return await handleError("Adding to project failed.", (async function () {
                  await ExistingProject.addToExistingProject(projectName);
                  Prompts.outro("Happy hacking!");
                }));
  } else {
    Prompts.outro("No changes were made to your project.");
    return ;
  }
}

await run();

export {
  
}
/*  Not a pure module */
