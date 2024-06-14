let getSuffix = moduleSystem =>
  switch moduleSystem {
  | "esmodule" | "es6" | "es6-global" => ".res.mjs"
  | _ => ".res.js"
  }
