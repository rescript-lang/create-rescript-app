module Spinner = {
  type t

  @send
  external start: (t, string) => unit = "start"

  @send
  external stop: (t, string) => unit = "stop"
}

module Log = {
  @module("@clack/prompts") @scope("log") external message: string => unit = "message"
  @module("@clack/prompts") @scope("log") external info: string => unit = "info"
  @module("@clack/prompts") @scope("log") external error: string => unit = "error"
}

type promptResult<'a>

@module("@clack/prompts") external isCancel: promptResult<'a> => bool = "isCancel"
external unsafeGetResultValue: promptResult<'a> => 'a = "%identity"

@module("@clack/prompts") external intro: string => unit = "intro"
@module("@clack/prompts") external outro: string => unit = "outro"
@module("@clack/prompts") external cancel: string => unit = "cancel"
@module("@clack/prompts") external note: (~message: string, ~title: string) => unit = "note"

type confirmOptions = {message: string}

@module("@clack/prompts")
external confirm: confirmOptions => promise<promptResult<bool>> = "confirm"

type selectOption = {
  value: string,
  label?: string,
  hint?: string,
}

type selectOptions = {
  message: string,
  options: array<selectOption>,
  initialValue?: string,
}

@module("@clack/prompts")
external select: selectOptions => promise<promptResult<string>> = "select"

type textOptions = {
  message: string,
  placeholder?: string,
  defaultValue?: string,
  initialValue?: string,
  validate?: string => option<string>,
}

@module("@clack/prompts")
external text: textOptions => promise<promptResult<string>> = "text"

@module("@clack/prompts") external spinner: unit => Spinner.t = "spinner"

exception Canceled

let resultOrRaise = async promise => {
  let result = await promise

  if result->isCancel {
    raise(Canceled)
  } else {
    result->unsafeGetResultValue
  }
}
