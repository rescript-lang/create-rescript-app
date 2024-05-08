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

let promptVersions = async () => {
  let s = P.spinner()

  s->P.Spinner.start("Loading available versions...")

  let (rescriptVersions, rescriptCoreVersions) = await Promise.all2((
    NpmRegistry.getPackageVersions("rescript", rescriptVersionRange),
    NpmRegistry.getPackageVersions("@rescript/core", rescriptCoreVersionRange),
  ))

  s->P.Spinner.stop("Versions loaded.")

  let rescriptVersion = switch rescriptVersions {
  | [version] => version
  | _ =>
    await P.select({
      message: "ReScript version?",
      options: rescriptVersions->Array.map(v => {P.value: v}),
    })->P.resultOrRaise
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
  let command = `${packageManager} add ${packages->Array.join(" ")}`

  let _ = await Node.Promisified.ChildProcess.exec(command)
}

let esmModuleSystemName = ({rescriptVersion}) =>
  CompareVersions.compareVersions(rescriptVersion, "11.1.0-rc.8") > 0. ? "esmodule" : "es6"
