// Node APIs used only by the installation E2E harness.
module Fs = {
  type mkdirOptions = {recursive: bool}
  @module("node:fs") external write: (string, string) => unit = "writeFileSync"
  @module("node:fs") external append: (string, string) => unit = "appendFileSync"
  @module("node:fs") external mkdtemp: string => string = "mkdtempSync"
  @module("node:fs") external mkdir: (string, mkdirOptions) => unit = "mkdirSync"
}

module Path = {
  @module("node:path") external resolve: string => string = "resolve"
}

module Os = {
  @module("node:os") external tmpdir: unit => string = "tmpdir"
}

module Process = {
  @scope("process") external env: Dict.t<string> = "env"
  @scope("process") external platform: string = "platform"
  @scope("process") external execPath: string = "execPath"
  @scope("process") external kill: (int, string) => unit = "kill"
  type state = {mutable exitCode: int}
  @val external state: state = "process"
}

module Assert = {
  @module("node:assert/strict") external check: (bool, string) => unit = "ok"
  @module("node:assert/strict") external equal: ('a, 'a, string) => unit = "strictEqual"
  @module("node:assert/strict") external deepEqual: ('a, 'a, string) => unit = "deepStrictEqual"
  @module("node:assert/strict") external fail: string => 'a = "fail"
}

module Timer = {
  type t
  @val external start: (unit => unit, int) => t = "setTimeout"
  @val external clear: t => unit = "clearTimeout"
}

module ChildProcess = {
  type readable
  type writable
  type t
  type options = {cwd: string, env: Dict.t<string>, detached: bool, stdio: array<string>}

  @module("node:child_process") external spawn: (string, array<string>, options) => t = "spawn"
  @get external pid: t => option<int> = "pid"
  @get external stdout: t => readable = "stdout"
  @get external stderr: t => readable = "stderr"
  @get @return(nullable) external stdin: t => option<writable> = "stdin"
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
