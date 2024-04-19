module P = ClackPrompts

let rescriptVersionRange = "11.x.x"
let rescriptCoreVersionRange = ">=1.0.0"

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

  let rescriptVersion = switch rescriptVersions {
  | [version] => version
  | _ =>
    await P.select({
      message: "ReScript version?",
      options: rescriptVersions->Array.map(v => {P.value: v}),
    })->P.resultOrRaise
  }

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
