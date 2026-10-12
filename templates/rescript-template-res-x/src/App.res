let port =
  Bun.env
  ->Bun.Env.get("PORT")
  ->Option.flatMap(p => p->Int.fromString(~radix=10))
  ->Option.getOr(5557)

let server = Server.start(~port)
let portString = server->Bun.Server.port->Int.toString

Console.log(`Listening on http://localhost:${portString}`)

if ResX.BunUtils.isDev {
  ResX.BunUtils.runDevServer(~port)
}
