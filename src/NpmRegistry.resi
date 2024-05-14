type fetchError =
  | FetchError({message: string})
  | HttpError({status: int})
  | ParseError

let getFetchErrorMessage: fetchError => string

let getPackageVersions: (string, string) => promise<result<array<string>, fetchError>>
