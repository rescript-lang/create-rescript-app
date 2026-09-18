import fs from "node:fs";
import { createRequire } from "node:module";
import path from "node:path";

const baseResult = {
  status: "not_found",
  allowJs: false,
  allowImportingTsExtensions: false,
  noEmit: false,
  emitDeclarationOnly: false,
  hasMts: false,
  hasCts: false,
  hasNestedPackageType: false,
};

function formatDiagnostic(ts, diagnostic) {
  if (!diagnostic) {
    return undefined;
  }

  return ts.flattenDiagnosticMessageText(diagnostic.messageText, "\n");
}

function getEnumName(enumObject, value) {
  if (value === undefined || value === null) {
    return undefined;
  }

  if (typeof value === "string") {
    return value.toLowerCase();
  }

  const name = enumObject?.[value];
  return typeof name === "string" ? name.toLowerCase() : undefined;
}

function readPackageType(packageJsonPath) {
  try {
    const json = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
    return typeof json.type === "string" ? json.type.toLowerCase() : undefined;
  } catch (_error) {
    return undefined;
  }
}

function hasNestedPackageType(projectPath, fileNames, rootPackageType) {
  for (const fileName of fileNames) {
    let currentDirectory = path.dirname(fileName);

    while (currentDirectory.startsWith(projectPath) && currentDirectory !== projectPath) {
      const packageJsonPath = path.join(currentDirectory, "package.json");
      const packageType = readPackageType(packageJsonPath);

      if (packageType !== undefined && packageType !== rootPackageType) {
        return true;
      }

      const parentDirectory = path.dirname(currentDirectory);
      if (parentDirectory === currentDirectory) {
        break;
      }
      currentDirectory = parentDirectory;
    }
  }

  return false;
}

export function read(projectPath) {
  const tsconfigPath = path.join(projectPath, "tsconfig.json");

  if (!fs.existsSync(tsconfigPath)) {
    return baseResult;
  }

  let ts;
  try {
    const requireFromProject = createRequire(path.join(projectPath, "package.json"));
    ts = requireFromProject("typescript");
  } catch (_error) {
    return {
      ...baseResult,
      status: "typescript_missing",
      tsconfigPath,
      message: "Could not resolve the project's TypeScript package.",
    };
  }

  const configFile = ts.readConfigFile(tsconfigPath, ts.sys.readFile);
  if (configFile.error !== undefined) {
    return {
      ...baseResult,
      status: "error",
      tsconfigPath,
      message: formatDiagnostic(ts, configFile.error),
    };
  }

  const parsed = ts.parseJsonConfigFileContent(
    configFile.config,
    ts.sys,
    projectPath,
    {},
    tsconfigPath,
  );

  if (parsed.errors.length > 0) {
    return {
      ...baseResult,
      status: "error",
      tsconfigPath,
      message: parsed.errors.map(error => formatDiagnostic(ts, error)).join("\n"),
    };
  }

  const options = parsed.options;
  const fileNames = parsed.fileNames ?? [];
  const rootPackageType = readPackageType(path.join(projectPath, "package.json"));

  return {
    status: "found",
    tsconfigPath,
    module: getEnumName(ts.ModuleKind, options.module),
    moduleResolution: getEnumName(ts.ModuleResolutionKind, options.moduleResolution),
    allowJs: options.allowJs === true,
    allowImportingTsExtensions: options.allowImportingTsExtensions === true,
    noEmit: options.noEmit === true,
    emitDeclarationOnly: options.emitDeclarationOnly === true,
    jsx: getEnumName(ts.JsxEmit, options.jsx),
    hasMts: fileNames.some(fileName => fileName.endsWith(".mts")),
    hasCts: fileNames.some(fileName => fileName.endsWith(".cts")),
    hasNestedPackageType: hasNestedPackageType(projectPath, fileNames, rootPackageType),
  };
}
