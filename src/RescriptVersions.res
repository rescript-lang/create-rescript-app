module P = ClackPrompts

let rescriptVersionRange = "11.x.x"
let rescriptCoreVersionRange = ">=1.0.0"

type versions = {rescriptVersion: string, rescriptCoreVersion: string}

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
    await P.select({
      message: "ReScript version?",
      options: rescriptVersions->Array.map(v => {P.value: v}),
    })->P.resultOrRaise
  | Error(error) => error->NpmRegistry.getFetchErrorMessage->Error.make->Error.raise
  }

  let rescriptCoreVersions = switch rescriptCoreVersionsResult {
  | Ok(versions) => versions
  | Error(error) => error->NpmRegistry.getFetchErrorMessage->Error.make->Error.raise
  }

  let rescriptCoreVersions = getCompatibleRescriptCoreVersions(
    ~rescriptVersion,
    ~rescriptCoreVersions,
  )

  let rescriptCoreVersion = switch rescriptCoreVersions {
  | [version] => version
  | _ =>
    await P.select({
      message: "ReScript Core version?",
      options: rescriptCoreVersions->Array.map(v => {P.value: v}),
    })->P.resultOrRaise
  }

  {rescriptVersion, rescriptCoreVersion}
}

let installVersions = async ({rescriptVersion, rescriptCoreVersion}) => {
  let packageManager = PackageManagers.getActivePackageManager()
  let packages = [`rescript@${rescriptVersion}`, `@rescript/core@${rescriptCoreVersion}`]

  let _ = await Node.Promisified.ChildProcess.execFile(packageManager, ["add", ...packages])
}

let esmModuleSystemName = ({rescriptVersion}) =>
  CompareVersions.compareVersions(rescriptVersion, "11.1.0-rc.8") > 0. ? "esmodule" : "es6"
