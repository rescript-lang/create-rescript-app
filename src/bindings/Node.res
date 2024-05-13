module Fs = {
  @module("node:fs") external existsSync: string => bool = "existsSync"

  module Promises = {
    @module("node:fs") @scope("promises")
    external readFile: (string, @as(json`"utf8"`) _) => promise<string> = "readFile"

    @module("node:fs") @scope("promises")
    external writeFile: (string, string, @as(json`"utf8"`) _) => promise<unit> = "writeFile"

    @module("node:fs") @scope("promises")
    external appendFile: (string, string) => promise<unit> = "appendFile"

    type cpOptions = {recursive?: bool}

    @module("node:fs") @scope("promises")
    external copyFile: (string, string) => promise<unit> = "copyFile"

    @module("node:fs") @scope("promises")
    external cp: (string, string, ~options: cpOptions=?) => promise<unit> = "cp"

    @module("node:fs") @scope("promises")
    external rename: (string, string) => promise<unit> = "rename"

    @module("node:fs") @scope("promises")
    external mkdir: string => promise<unit> = "mkdir"
  }
}

module Path = {
  @module("node:path")
  external basename: string => string = "basename"

  @module("node:path")
  external dirname: string => string = "dirname"

  @module("node:path") @variadic
  external join: array<string> => string = "join"

  @module("node:path") external join2: (string, string) => string = "join"

  type parseResult = {
    root: string,
    dir: string,
    base: string,
    ext: string,
    name: string,
  }

  @module("node:path") external parse: string => parseResult = "parse"
}

module Process = {
  @scope("process") external argv: array<string> = "argv"

  @scope("process") external chdir: string => unit = "chdir"
  @scope("process") external cwd: unit => string = "cwd"

  @scope("process") external exit: unit => unit = "exit"
  @scope("process") external exitWithCode: int => unit = "exit"
}

module Url = {
  type t

  @module("node:url") external fileURLToPath: t => string = "fileURLToPath"

  @new external makeUnsafe: string => t = "URL"
  @get external href: t => string = "href"

  let make = string =>
    try Some(makeUnsafe(string)) catch {
    | _exn => None
    }
}

module Os = {
  type t

  @module("node:os") external eol: string = "EOL"
}

module Promisified = {
  module ChildProcess = {
    type execResult = {stdout: string, stderr: string}

    @module("./NodePromisified.mjs")
    external exec: string => promise<execResult> = "exec"
  }
}
