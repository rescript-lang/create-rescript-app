open Node

let readJsonFile = async filename => {
  let contents = await Fs.Promises.readFile(filename)
  JSON.parseExn(contents)
}

let updateFile = async (filename, updateFn) => {
  let contents = await Fs.Promises.readFile(filename)
  let updated = updateFn(contents)
  await Fs.Promises.writeFile(filename, updated)
}

let updateJsonFile = (filename, updateFn) =>
  updateFile(filename, contents => {
    let json = JSON.parseExn(contents)
    updateFn(json)
    JSON.stringify(json, ~space=2)
  })

let getStringValue = (json: JSON.t, ~fieldName) =>
  switch json {
  | Object(dict) =>
    switch dict->Dict.get(fieldName) {
    | Some(String(value)) => Some(value)
    | _ => None
    }
  | _ => None
  }
