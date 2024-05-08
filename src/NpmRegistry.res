type response

@send external toJson: response => promise<Js.Json.t> = "json"
@val external fetch: string => promise<response> = "fetch"

let getPackageVersions = async (packageName, range) => {
  let result = await fetch(`https://registry.npmjs.org/${packageName}`)

  let versions = switch await result->toJson {
  | Object(dict) =>
    switch dict->Dict.get("versions") {
    | Some(Object(dict)) => dict->Dict.keysToArray
    | _ => []
    }
  | _ => []
  }

  let versions =
    versions->Array.filterMap(version =>
      version->CompareVersions.satisfies(range) ? Some(version) : None
    )

  versions->Array.reverse
  versions
}
