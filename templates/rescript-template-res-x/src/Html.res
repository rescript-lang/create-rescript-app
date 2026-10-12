@jsx.component
let make = (~children) => {
  let language = Handler.useLanguage()

  <html lang={language->Language.htmlLang}>
    <head>
      <meta charSet="utf-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1" />
      <link rel="icon" href="/favicon.ico" sizes="any" />
      <link rel="stylesheet" href={ResXAssets.assets.styles_css} />
      <script src="https://unpkg.com/htmx.org@2.0.8/dist/htmx.min.js" defer=true />
    </head>
    <body>
      {children}
      {if ResX.BunUtils.isDev {
        <ResX.Dev />
      } else {
        Hjsx.null
      }}
      <script type_="module" src={ResXAssets.assets.resXClient_js} async=true />
    </body>
  </html>
}
