module P = ClackPrompts

let rescript12VersionRange = ">=12.0.0-beta.1"
let rescriptVersionRange = `11.x.x || ${rescript12VersionRange}`
let rescriptCoreVersionRange = ">=1.0.0"
let rescriptRewatchVersionRange = ">=12.0.0-alpha.15"

type versions = {rescriptVersion: string, rescriptCoreVersion: option<string>}

let getCompatibleRescriptCoreVersions = (~rescriptVersion, ~rescriptCoreVersions) =>
  if CompareVersions.compareVersions(rescriptVersion, "11.1.0")->Ordering.isLess {
    rescriptCoreVersions->Array.filter(coreVersion =>
      CompareVersions.compareVersions(coreVersion, "1.3.0")->Ordering.isLess
    )
  } else {
    rescriptCoreVersions
  }

let spinnerMessage = "Loading available versions..."

let promptVersions = async () => {
  let s = P.spinner()

  s->P.Spinner.start(spinnerMessage)

  let (rescriptVersionsResult, rescriptCoreVersionsResult) = await Promise.all2((
    NpmRegistry.getPackageVersions("rescript", rescriptVersionRange),
    NpmRegistry.getPackageVersions("@rescript/core", rescriptCoreVersionRange),
  ))

  switch (rescriptVersionsResult, rescriptCoreVersionsResult) {
  | (Ok(_), Ok(_)) => s->P.Spinner.stop("Versions loaded.")
  | _ => s->P.Spinner.stop(spinnerMessage)
  }

  let rescriptVersion = switch rescriptVersionsResult {
  | Ok([version]) => version
  | Ok(rescriptVersions) =>
    let options = rescriptVersions->Array.map(v => {P.value: v})

    let initialValue =
      options->Array.find(o => o.value->String.startsWith("11."))->Option.map(o => o.value)

    let selectOptions = {ClackPrompts.message: "ReScript version?", options, ?initialValue}

    await P.select(selectOptions)->P.resultOrRaise
  | Error(error) => error->NpmRegistry.getFetchErrorMessage->JsError.throwWithMessage
  }

  let rescriptCoreVersions = switch rescriptCoreVersionsResult {
  | Ok(versions) => versions
  | Error(error) => error->NpmRegistry.getFetchErrorMessage->JsError.throwWithMessage
  }

  let rescriptCoreVersions = getCompatibleRescriptCoreVersions(
    ~rescriptVersion,
    ~rescriptCoreVersions,
  )

  let isRescript12 = CompareVersions.satisfies(rescriptVersion, rescript12VersionRange)

  let rescriptCoreVersion = switch rescriptCoreVersions {
  | _ if isRescript12 => None
  | [version] => Some(version)
  | _ =>
    let version = await P.select({
      message: "ReScript Core version?",
      options: rescriptCoreVersions->Array.map(v => {P.value: v}),
    })->P.resultOrRaise
    Some(version)
  }

  {rescriptVersion, rescriptCoreVersion}
}

let installVersions = async ({rescriptVersion, rescriptCoreVersion}) => {
  let packageManager = PackageManagers.getActivePackageManager()
  let packages = switch rescriptCoreVersion {
  | Some(rescriptCoreVersion) => [
      `rescript@${rescriptVersion}`,
      `@rescript/core@${rescriptCoreVersion}`,
    ]
  | None => [`rescript@${rescriptVersion}`]
  }

  // #58: Windows: packageManager may be something like
  // "C:\Program Files\nodejs\node_modules\npm\bin\npm-cli.js".
  //
  // Therefore, packageManager needs to be in quotes, and we need to prepend "node "
  // if packageManager points to a JS file, otherwise the invocation will hang.
  let maybeNode = packageManager->String.endsWith("js") ? "node " : ""
  let command = `${maybeNode}"${packageManager}" add ${packages->Array.join(" ")}`

  let _ = await Node.Promisified.ChildProcess.exec(command)
}

let esmModuleSystemName = ({rescriptVersion}) =>
  CompareVersions.compareVersions(rescriptVersion, "11.1.0-rc.8") > 0. ? "esmodule" : "es6"

let usesRewatch = ({rescriptVersion}) =>
  CompareVersions.satisfies(rescriptVersion, rescriptRewatchVersionRange)
