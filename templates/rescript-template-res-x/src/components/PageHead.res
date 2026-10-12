@jsx.component
let make = (~title: string, ~description: string, ~robots: option<string>=?) => {
  let {requestController} = Handler.useContext()
  requestController.setFullTitle(title)

  <ResX.RenderInHead requestController>
    <meta name="description" content=description />
    <meta property="og:type" content="website" />
    <meta property="og:title" content=title />
    <meta property="og:description" content=description />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content=title />
    <meta name="twitter:description" content=description />
    {switch robots {
    | Some(content) => <meta name="robots" content />
    | None => Hjsx.null
    }}
  </ResX.RenderInHead>
}
