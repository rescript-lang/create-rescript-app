type t = {
  projectName: option<string>,
  templateName: option<string>,
}

let parse: list<string> => result<t, string>
let fromProcessArgv: array<string> => result<t, string>
