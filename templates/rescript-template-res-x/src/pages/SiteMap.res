type page = {path: string, changefreq: string, priority: string}

let pages: array<page> = [
  {path: "/", changefreq: "weekly", priority: "1.0"},
  {path: "/setup", changefreq: "monthly", priority: "0.8"},
  {path: "/examples", changefreq: "monthly", priority: "0.8"},
  {path: "/resources", changefreq: "monthly", priority: "0.7"},
]

@jsx.component
let make = () => {
  let {headers, requestController, url} = Handler.useContext()
  requestController.setDocHeader(Some(`<?xml version="1.0" encoding="UTF-8"?>`))

  headers->Headers.set("Content-Type", "application/xml; charset=UTF-8")
  headers->Headers.set(
    "Cache-Control",
    ResX.Utils.CacheControl.make(~cacheability=Public, ~expiration=[MaxAge(Hours(12.))]),
  )

  let origin = url->URL.origin

  <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    {pages
    ->Array.map(page =>
      <url>
        <loc> {Hjsx.string(origin ++ encodeURI(page.path))} </loc>
        <changefreq> {page.changefreq->Hjsx.string} </changefreq>
        <priority> {page.priority->Hjsx.string} </priority>
      </url>
    )
    ->Hjsx.array}
  </urlset>
}
