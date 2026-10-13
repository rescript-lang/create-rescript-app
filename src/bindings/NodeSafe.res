type fileError = {path: string, cause: JsExn.t}

module Fs = {
  let withPath = (path, perform) =>
    try Ok(perform()) catch {
    | JsExn(cause) => Error(#FileError({path, cause}))
    }

  let readFileSync = path => withPath(path, () => Node.Fs.readFileSync(path))

  let writeFileSync = (path, contents) =>
    withPath(path, () => Node.Fs.writeFileSync(path, contents))

  let appendFileSync = (path, contents) =>
    withPath(path, () => Node.Fs.appendFileSync(path, contents))

  let mkdtempSync = prefix => withPath(prefix, () => Node.Fs.mkdtempSync(prefix))
  let mkdirSync = (path, options) => withPath(path, () => Node.Fs.mkdirSync(path, options))

  module Promises = {
    let rm = async (path, ~options) =>
      try {
        await Node.Fs.Promises.rm(path, ~options)
        Ok()
      } catch {
      | JsExn(cause) => Error(#FileError({path, cause}))
      }
  }
}

module Process = {
  let kill = (pid, signal) =>
    try {
      Node.Process.kill(pid, signal)
      Ok()
    } catch {
    | JsExn(error) => Error(#SignalError(error))
    }
}

module ChildProcess = {
  let spawn = (command, args, options) =>
    try Ok(Node.ChildProcess.spawn(command, args, options)) catch {
    | JsExn(error) => Error(#SpawnError(error))
    }

  let write = (stream, text) =>
    try {
      Node.ChildProcess.write(stream, text)
      Ok()
    } catch {
    | JsExn(error) => Error(#InputError(error))
    }

  let spawnSync = (command, args, options) =>
    try {
      let result = Node.ChildProcess.spawnSync(command, args, options)
      switch result.error {
      | Some(error) => Error(#SpawnError(error))
      | None => Ok(result)
      }
    } catch {
    | JsExn(error) => Error(#SpawnError(error))
    }
}

module Url = {
  let make = string =>
    try Some(Node.Url.makeUnsafe(string)) catch {
    | JsExn(_) => None
    }
}
