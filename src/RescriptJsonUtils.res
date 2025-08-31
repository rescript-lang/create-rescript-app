let removeRescriptCore = (config: Dict.t<JSON.t>) => {
  // Remove @rescript/core from bs-dependencies if the version is not set.
  switch config->Dict.get("bs-dependencies") {
  | Some(Array(dependencies)) => {
      let newDependencies = dependencies->Array.filter(dependency =>
        switch dependency {
        | String("@rescript/core") => false
        | _ => true
        }
      )
      config->Dict.set("bs-dependencies", Array(newDependencies))
    }
  | _ => ()
  }

  // Remove "-open RescriptCore" from bsc-flags if the version is not set.
  switch config->Dict.get("bsc-flags") {
  | Some(Array(flags)) => {
      let newFlags = flags->Array.filter(flag =>
        switch flag {
        | String("-open RescriptCore") => false
        | _ => true
        }
      )
      config->Dict.set("bsc-flags", Array(newFlags))
    }
  | _ => ()
  }
}

let modernizeConfigurationFields = (config: Dict.t<JSON.t>) => {
  // Rename "bs-dependencies" to "dependencies"
  switch config->Dict.get("bs-dependencies") {
  | Some(dependencies) =>
    config->Dict.set("dependencies", dependencies)
    config->Dict.delete("bs-dependencies")
  | _ => ()
  }

  // Rename "bs-dev-dependencies" to "devDependencies"
  switch config->Dict.get("bs-dev-dependencies") {
  | Some(devDependencies) =>
    config->Dict.set("dev-dependencies", devDependencies)
    config->Dict.delete("bs-dev-dependencies")
  | _ => ()
  }

  // Rename "bsc-flags" to "compiler-flags"
  switch config->Dict.get("bsc-flags") {
  | Some(compilerFlags) =>
    config->Dict.set("compiler-flags", compilerFlags)
    config->Dict.delete("bsc-flags")
  | _ => ()
  }
}
