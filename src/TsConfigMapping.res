type parsedConfig = {
  status: string,
  message?: string,
  tsconfigPath?: string,
  @as("module")
  module_?: string,
  moduleResolution?: string,
  allowJs: bool,
  allowImportingTsExtensions: bool,
  noEmit: bool,
  emitDeclarationOnly: bool,
  jsx?: string,
  hasMts: bool,
  hasCts: bool,
  hasNestedPackageType: bool,
}

type inferredConfig = {
  moduleSystem: string,
  suffix: string,
  gentypeModuleResolution: string,
  generatedFileExtension: string,
  warnings: array<string>,
  needsAllowJs: bool,
  needsAllowImportingTsExtensions: bool,
  cannotSetAllowImportingTsExtensions: bool,
}

@module("./bindings/TsConfigParser.mjs")
external read: string => parsedConfig = "read"

let esmodule = "esmodule"
let commonjs = "commonjs"
let suffix = ".res.js"

let normalize = value => value->String.toLowerCase

let isAnyOf = (value, values) => values->Array.some(candidate => candidate === value)

let mapModule = (~module_, ~packageType) =>
  switch module_ {
  | None => Error("No compilerOptions.module setting was found in tsconfig.json.")
  | Some(moduleValue) =>
    switch moduleValue->normalize {
    | "commonjs" => Ok(commonjs)
    | "es2015" | "es6" | "es2020" | "es2022" | "esnext" => Ok(esmodule)
    | "preserve" => Ok(esmodule)
    | "node16" | "node18" | "node20" | "nodenext" =>
      switch packageType {
      | Some("module") => Ok(esmodule)
      | _ => Ok(commonjs)
      }
    | "amd" | "umd" | "system" | "none" =>
      Error(
        `TypeScript module "${moduleValue}" cannot be represented by ReScript genType's esmodule/commonjs output.`,
      )
    | _ => Error(`Unknown TypeScript module setting "${moduleValue}".`)
    }
  }

let mapModuleResolution = (~module_, ~moduleResolution) => {
  let nodeNextWarning = "TypeScript moduleResolution \"nodenext\" is approximated with genType \"node16\", because ReScript v12 only documents node/node16/bundler."

  switch moduleResolution {
  | Some(moduleResolutionValue) =>
    switch moduleResolutionValue->normalize {
    | "bundler" => Ok(("bundler", []))
    | "node16" => Ok(("node16", []))
    | "nodenext" => Ok(("node16", [nodeNextWarning]))
    | "node" | "node10" | "nodejs" => Ok(("node", []))
    | "classic" =>
      Error("TypeScript moduleResolution \"classic\" is not supported for genType setup.")
    | _ => Error(`Unknown TypeScript moduleResolution setting "${moduleResolutionValue}".`)
    }
  | None =>
    switch module_->Option.map(normalize) {
    | Some("preserve") => Ok(("bundler", []))
    | Some("node16") | Some("node18") | Some("node20") => Ok(("node16", []))
    | Some("nodenext") => Ok(("node16", [nodeNextWarning]))
    | Some("commonjs") => Ok(("node", []))
    | Some(moduleValue) if moduleValue->isAnyOf(["es2015", "es6", "es2020", "es2022", "esnext"]) =>
      Error(
        `No compilerOptions.moduleResolution setting was found for TypeScript module "${moduleValue}".`,
      )
    | Some(moduleValue) =>
      Error(
        `No supported compilerOptions.moduleResolution mapping exists for TypeScript module "${moduleValue}".`,
      )
    | None => Error("No compilerOptions.moduleResolution setting was found in tsconfig.json.")
    }
  }
}

let hasMixedNodeModuleFormat = (~moduleSystem, ~packageType, config) =>
  switch packageType {
  | Some("module") => moduleSystem === esmodule ? config.hasCts : true
  | _ => moduleSystem === commonjs ? config.hasMts : true
  } ||
  config.hasNestedPackageType

let generatedFileExtension = (~hasJsxDependency, config) =>
  switch config.jsx {
  | Some(_) => ".gen.tsx"
  | None => hasJsxDependency ? ".gen.tsx" : ".gen.ts"
  }

let infer = (config, ~packageType, ~hasJsxDependency) => {
  let normalizedModule = config.module_->Option.map(normalize)
  let normalizedPackageType = packageType->Option.map(normalize)

  switch mapModule(~module_=normalizedModule, ~packageType=normalizedPackageType) {
  | Error(message) => Error(message)
  | Ok(moduleSystem) =>
    switch normalizedModule {
    | Some(moduleValue)
      if moduleValue->isAnyOf(["node16", "node18", "node20", "nodenext"]) &&
        hasMixedNodeModuleFormat(~moduleSystem, ~packageType=normalizedPackageType, config) =>
      Error(
        "This TypeScript project appears to use mixed Node module formats, which cannot be represented by one ReScript project-level module setting.",
      )
    | _ =>
      switch mapModuleResolution(
        ~module_=normalizedModule,
        ~moduleResolution=config.moduleResolution->Option.map(normalize),
      ) {
      | Error(message) => Error(message)
      | Ok((gentypeModuleResolution, resolutionWarnings)) =>
        let preserveWarnings = switch normalizedModule {
        | Some("preserve") => [
            "TypeScript module \"preserve\" is mapped to ReScript \"esmodule\"; verify the project does not rely on statement-level CommonJS preservation for generated ReScript modules.",
          ]
        | _ => []
        }

        Ok({
          moduleSystem,
          suffix,
          gentypeModuleResolution,
          generatedFileExtension: generatedFileExtension(~hasJsxDependency, config),
          warnings: Belt.Array.concat(resolutionWarnings, preserveWarnings),
          needsAllowJs: !config.allowJs,
          needsAllowImportingTsExtensions: gentypeModuleResolution === "bundler" &&
          !config.allowImportingTsExtensions &&
          (config.noEmit || config.emitDeclarationOnly),
          cannotSetAllowImportingTsExtensions: gentypeModuleResolution === "bundler" &&
          !config.allowImportingTsExtensions &&
          !(config.noEmit || config.emitDeclarationOnly),
        })
      }
    }
  }
}
