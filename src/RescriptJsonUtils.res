let removeArrayValue = (config: Dict.t<JSON.t>, ~fieldName, ~valueToRemove) => {
  switch config->Dict.get(fieldName) {
  | Some(Array(dependencies)) => {
      let newDependencies = dependencies->Array.filter(dependency =>
        switch dependency {
        | String(value) if value === valueToRemove => false
        | _ => true
        }
      )
      config->Dict.set(fieldName, Array(newDependencies))
    }
  | _ => ()
  }
}

let removeRescriptCore = (config: Dict.t<JSON.t>) => {
  // Remove @rescript/core and its open flag if the selected ReScript version includes Core.
  removeArrayValue(config, ~fieldName="bs-dependencies", ~valueToRemove="@rescript/core")
  removeArrayValue(config, ~fieldName="dependencies", ~valueToRemove="@rescript/core")
  removeArrayValue(config, ~fieldName="bsc-flags", ~valueToRemove="-open RescriptCore")
  removeArrayValue(config, ~fieldName="compiler-flags", ~valueToRemove="-open RescriptCore")
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
