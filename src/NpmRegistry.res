type response = {
  ok: bool,
  json: unit => promise<Js.Json.t>,
}

@val external fetch: string => promise<response> = "fetch"

@scope(("process", "env"))
external npm_config_registry: option<string> = "NPM_CONFIG_REGISTRY"

@inline
let defaultRegistryUrl = "https://registry.npmjs.org"

let getNpmRegistry = () =>
  npm_config_registry
  ->Option.flatMap(registry => registry->Node.Url.make)
  ->Option.mapOr(defaultRegistryUrl, url => url->Node.Url.href)

let getPackageVersions = async (packageName, range) => {
  let registry = getNpmRegistry()

  switch await fetch(`${registry}/${packageName}`) {
  | response if response.ok =>
    let versions = switch await response.json() {
    | Object(dict) =>
      switch dict->Dict.get("versions") {
      | Some(Object(dict)) =>
        dict
        ->Dict.keysToArray
        ->Array.filterMap(version =>
          version->CompareVersions.satisfies(range) ? Some(version) : None
        )
      | _ => []
      }
    | _ => []
    }

    versions->Array.reverse
    versions

  | _responseNotOk => []
  }
}
