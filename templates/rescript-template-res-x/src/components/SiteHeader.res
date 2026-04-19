let isActivePath = (~currentPath, ~targetPath) =>
  if targetPath === "/" {
    currentPath === "/"
  } else {
    currentPath->String.startsWith(targetPath)
  }

let navLinkClass = (~currentPath, ~targetPath) =>
  if isActivePath(~currentPath, ~targetPath) {
    "text-nav-foreground"
  } else {
    "text-nav-foreground/80 transition-colors hover:text-nav-foreground"
  }

@jsx.component
let make = () => {
  let {request} = Handler.useContext()
  let currentPath =
    request
    ->Request.url
    ->URL.make
    ->URL.pathname

  <header className="border-b border-white/10 bg-nav text-nav-foreground">
    <div className="mx-auto max-w-6xl px-6 py-4">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <a href="/" className="flex items-center gap-3">
          <span
            className="inline-flex h-8 w-8 items-center justify-center rounded-md bg-brand font-mono text-xs font-bold uppercase text-brand-foreground"
          >
            {Hjsx.string("rx")}
          </span>
          <span className="font-semibold">
            {Hjsx.string(Handler.getTranslatedString({en: "ResX Template"}))}
          </span>
        </a>
        <nav className="flex flex-wrap items-center gap-4 text-sm">
          <a href="/" className={navLinkClass(~currentPath, ~targetPath="/")}>
            {Hjsx.string(Handler.getTranslatedString({en: "Home"}))}
          </a>
          <a href="/setup" className={navLinkClass(~currentPath, ~targetPath="/setup")}>
            {Hjsx.string(Handler.getTranslatedString({en: "Setup"}))}
          </a>
          <a href="/examples" className={navLinkClass(~currentPath, ~targetPath="/examples")}>
            {Hjsx.string(Handler.getTranslatedString({en: "Examples"}))}
          </a>
          <a href="/resources" className={navLinkClass(~currentPath, ~targetPath="/resources")}>
            {Hjsx.string(Handler.getTranslatedString({en: "Resources"}))}
          </a>
        </nav>
      </div>
    </div>
  </header>
}
