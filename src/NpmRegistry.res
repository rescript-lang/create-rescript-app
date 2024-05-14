type response = {
  ok: bool,
  status: int,
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

type fetchError =
  | FetchError({message: string})
  | HttpError({status: int})
  | ParseError

let getFetchErrorMessage = fetchError => {
  let message = switch fetchError {
  | FetchError({message}) => `Fetch error. Message: ${message}`
  | HttpError({status}) => `Http error. Status: ${status->Int.toString}`
  | ParseError => "Parse error."
  }

  `Fetching versions from registry failed: ${message}`
}

let getPackageVersions = async (packageName, range) => {
  let registryUrl = getNpmRegistry()

  switch await fetch(`${registryUrl}/${packageName}`) {
  | response if response.ok =>
    switch await response.json() {
    | Object(dict) =>
      switch dict->Dict.get("versions") {
      | Some(Object(dict)) =>
        let versions =
          dict
          ->Dict.keysToArray
          ->Array.filterMap(version =>
            version->CompareVersions.satisfies(range) ? Some(version) : None
          )
        versions->Array.reverse
        versions->Ok

      | _ => Error(ParseError)
      }
    | _ => Error(ParseError)
    }

  | responseNotOk => Error(HttpError({status: responseNotOk.status}))
  | exception Exn.Error(exn) => Error(FetchError({message: exn->ErrorUtils.getErrorMessage}))
  }
}
