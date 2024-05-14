let getErrorMessage = exn =>
  switch exn->Exn.message {
  | Some(message) => message
  | None => exn->String.make
  }
