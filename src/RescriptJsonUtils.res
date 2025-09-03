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

let renameConfigKey = (config: Dict.t<JSON.t>, ~from, ~to) => {
  switch config->Dict.get(from) {
  | Some(value) =>
    config->Dict.set(to, value)
    config->Dict.delete(from)
  | _ => ()
  }
}

let modernizeConfigurationFields = (config: Dict.t<JSON.t>) => {
  renameConfigKey(config, ~from="bs-dependencies", ~to="dependencies")
  renameConfigKey(config, ~from="bs-dev-dependencies", ~to="dev-dependencies")
  renameConfigKey(config, ~from="bsc-flags", ~to="compiler-flags")
}
