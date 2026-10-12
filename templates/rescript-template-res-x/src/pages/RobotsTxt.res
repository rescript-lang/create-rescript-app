@jsx.component
let make = () => {
  let {headers, requestController, url} = Handler.useContext()
  requestController.setDocHeader(None)

  headers->Headers.set("Content-Type", "text/plain; charset=utf-8")
  headers->Headers.set(
    "Cache-Control",
    ResX.Utils.CacheControl.make(~cacheability=Public, ~expiration=[MaxAge(Minutes(15.))]),
  )

  Hjsx.string(
    `User-agent: *
Allow: /

Sitemap: ${url->URL.origin}/sitemap.xml`,
  )
}
