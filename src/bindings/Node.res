module Fs = {
  @module("node:fs") external existsSync: string => bool = "existsSync"

  @module("node:fs") external readdirSync: string => array<string> = "readdirSync"

  @module("node:fs")
  external readFileSync: (string, @as(json`"utf8"`) _) => string = "readFileSync"

  @module("node:fs") external writeFileSync: (string, string) => unit = "writeFileSync"
  @module("node:fs") external appendFileSync: (string, string) => unit = "appendFileSync"
  @module("node:fs") external mkdtempSync: string => string = "mkdtempSync"

  type mkdirOptions = {recursive: bool}
  @module("node:fs") external mkdirSync: (string, mkdirOptions) => unit = "mkdirSync"

  type stats

  @module("node:fs") external statSync: string => stats = "statSync"

  module Stats = {
    @send external isDirectory: stats => bool = "isDirectory"
  }

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

  @module("node:path") external resolve: string => string = "resolve"

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
  @scope("process") external env: Dict.t<string> = "env"
  @scope("process") external platform: string = "platform"
  @scope("process") external execPath: string = "execPath"
  @scope("process") external kill: (int, string) => unit = "kill"

  type state = {mutable exitCode: int}
  @val external state: state = "process"

  @scope("process") external chdir: string => unit = "chdir"
  @scope("process") external cwd: unit => string = "cwd"

  @scope("process") external exit: unit => unit = "exit"
  @scope("process") external exitWithCode: int => unit = "exit"
}

module Assert = {
  @module("node:assert/strict")
  external strictEqual: ('a, 'a, ~message: string=?) => unit = "strictEqual"

  @module("node:assert/strict")
  external deepStrictEqual: ('a, 'a, string) => unit = "deepStrictEqual"

  @module("node:assert/strict") external ok: (bool, string) => unit = "ok"

  @module("node:assert/strict")
  external fail: string => 'a = "fail"
}

module Test = {
  @module("node:test")
  external describe: (string, unit => unit) => unit = "describe"

  @module("node:test")
  external test: (string, unit => unit) => unit = "test"

  @module("node:test")
  external testAsync: (string, unit => promise<unit>) => unit = "test"

  type options = {skip: bool}
  @module("node:test")
  external testAsyncWithOptions: (string, options, unit => promise<unit>) => unit = "test"
}

module Url = {
  type t

  @module("node:url") external fileURLToPath: t => string = "fileURLToPath"

  @new external makeUnsafe: string => t = "URL"
  @get external href: t => string = "href"
}

module Os = {
  type t

  @module("node:os") external eol: string = "EOL"
  @module("node:os") external tmpdir: unit => string = "tmpdir"
}

module Timer = {
  type t
  @val external setTimeout: (unit => unit, int) => t = "setTimeout"
  @val external clearTimeout: t => unit = "clearTimeout"
}

module ChildProcess = {
  type readable
  type writable
  type t
  type options = {cwd: string, env: Dict.t<string>, detached: bool, stdio: array<string>}

  @module("node:child_process")
  external spawn: (string, array<string>, options) => t = "spawn"

  @get external pid: t => option<int> = "pid"
  @get external stdout: t => readable = "stdout"
  @get external stderr: t => readable = "stderr"
  @get external stdin: t => Nullable.t<writable> = "stdin"
  @send external setEncoding: (readable, @as("utf8") _) => unit = "setEncoding"
  @send external onData: (readable, @as("data") _, string => unit) => unit = "on"
  @send external onInputError: (writable, @as("error") _, JsExn.t => unit) => unit = "on"
  @send external onError: (t, @as("error") _, JsExn.t => unit) => unit = "once"
  @send
  external onClose: (t, @as("close") _, (Nullable.t<int>, Nullable.t<string>) => unit) => unit =
    "once"
  @send external write: (writable, string) => unit = "write"

  @send external destroyInput: writable => unit = "destroy"

  type syncOptions = {cwd: string, stdio: string}
  type syncResult = {status: Nullable.t<int>, error?: JsExn.t}
  @module("node:child_process")
  external spawnSync: (string, array<string>, syncOptions) => syncResult = "spawnSync"
}

@get external errorCode: JsExn.t => option<string> = "code"

module Promisified = {
  module ChildProcess = {
    type execResult = {stdout: string, stderr: string}

    @module("./NodePromisified.mjs")
    external exec: string => promise<execResult> = "exec"
  }
}
