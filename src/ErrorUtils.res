let getErrorMessage = exn =>
  switch exn->JsExn.message {
  | Some(message) => message
  | None => exn->String.make
  }
