let readJsonFile: string => promise<JSON.t>
let updateJsonFile: (string, JSON.t => unit) => promise<unit>

let getStringValue: (JSON.t, ~fieldName: string) => option<string>
