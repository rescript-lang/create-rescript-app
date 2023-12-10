module P = ClackPrompts

let rescriptVersionRange = "~11 >=11.0.0-rc.6"
let rescriptCoreVersionRange = ">=0.5.0"

type versions = {rescriptVersion: string, rescriptCoreVersion: string}

let getPackageVersions = async (packageName, range) => {
  let {stdout} = await Node.Promisified.ChildProcess.exec(`npm view ${packageName} versions --json`)

  let versions = switch JSON.parseExn(stdout) {
  | Array(versions) =>
    versions->Array.filterMap(json =>
      switch json {
      | String(version) if version->CompareVersions.satisfies(range) => Some(version)
      | _ => None
      }
    )
  | _ => []
  }

  versions->Array.reverse
  versions
}

let promptVersions = async () => {
  let s = P.spinner()

  s->P.Spinner.start("Loading available versions...")

  let (rescriptVersions, rescriptCoreVersions) = await Promise.all2((
    getPackageVersions("rescript", rescriptVersionRange),
    getPackageVersions("@rescript/core", rescriptCoreVersionRange),
  ))

  s->P.Spinner.stop("Versions loaded.")

  let rescriptVersion = await P.select({
    message: "ReScript version?",
    options: rescriptVersions->Array.map(v => {P.value: v}),
  })->P.resultOrRaise

  let rescriptCoreVersion = await P.select({
    message: "ReScript Core version?",
    options: rescriptCoreVersions->Array.map(v => {P.value: v}),
  })->P.resultOrRaise

  {rescriptVersion, rescriptCoreVersion}
}

let installVersions = async ({rescriptVersion, rescriptCoreVersion}) => {
  let packageManager = PackageManagers.getActivePackageManager()
  let packages = [`rescript@${rescriptVersion}`, `@rescript/core@${rescriptCoreVersion}`]
  let command = `${packageManager} add ${packages->Array.joinWith(" ")}`

  let _ = await Node.Promisified.ChildProcess.exec(command)
}
