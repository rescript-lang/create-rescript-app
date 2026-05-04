module Fs = {
  @module("node:fs") external existsSync: string => bool = "existsSync"

  @module("node:fs") external readdirSync: string => array<string> = "readdirSync"

  @module("node:fs")
  external readFileSync: (string, @as(json`"utf8"`) _) => string = "readFileSync"

  module Promises = {
    @module("node:fs") @scope("promises")
    external readFile: (string, @as(json`"utf8"`) _) => promise<string> = "readFile"

    @module("node:fs") @scope("promises")
    external writeFile: (string, string, @as(json`"utf8"`) _) => promise<unit> = "writeFile"

    @module("node:fs") @scope("promises")
    external appendFile: (string, string) => promise<unit> = "appendFile"

    type cpOptions = {recursive?: bool, force?: bool}

    @module("node:fs") @scope("promises")
    external copyFile: (string, string) => promise<unit> = "copyFile"

    @module("node:fs") @scope("promises")
    external cp: (string, string, ~options: cpOptions=?) => promise<unit> = "cp"

    @module("node:fs") @scope("promises")
    external rename: (string, string) => promise<unit> = "rename"

    type mkdirOptions = {recursive?: bool}

    @module("node:fs") @scope("promises")
    external mkdir: (string, ~options: mkdirOptions=?) => promise<unit> = "mkdir"

    @module("node:fs") @scope("promises")
    external unlink: string => promise<unit> = "unlink"

    type rmOptions = {recursive?: bool, force?: bool}

    @module("node:fs") @scope("promises")
    external rm: (string, ~options: rmOptions=?) => promise<unit> = "rm"
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

module Assert = {
  @module("node:assert/strict")
  external strictEqual: ('a, 'a) => unit = "strictEqual"

  @module("node:assert/strict")
  external fail: string => unit = "fail"
}

module Test = {
  @module("node:test")
  external describe: (string, unit => unit) => unit = "describe"

  @module("node:test")
  external test: (string, unit => unit) => unit = "test"

  @module("node:test")
  external testAsync: (string, unit => promise<unit>) => unit = "test"
}

module Url = {
  type t

  @module("node:url") external fileURLToPath: t => string = "fileURLToPath"

  @new external makeUnsafe: string => t = "URL"
  @get external href: t => string = "href"

  let make = string =>
    try Some(makeUnsafe(string)) catch {
    | Exn.Error(_exn) => None
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
