@jsx.component
let make = () => {
  <footer className="border-t border-border bg-card">
    <div
      className="mx-auto flex max-w-6xl flex-col gap-4 px-6 py-10 text-sm text-muted-foreground md:flex-row md:items-center md:justify-between"
    >
      <div>
        <div className="font-semibold text-foreground">
          {Hjsx.string(Handler.getTranslatedString({en: "ResX Template"}))}
        </div>
        <div>
          {Hjsx.string(
            Handler.getTranslatedString({en: "Simple starter with Bun, Vite, and Tailwind."}),
          )}
        </div>
      </div>
      <div className="flex flex-wrap items-center gap-x-6 gap-y-2">
        <a href="/setup" className="transition-colors hover:text-foreground">
          {Hjsx.string(Handler.getTranslatedString({en: "Setup"}))}
        </a>
        <a href="/examples" className="transition-colors hover:text-foreground">
          {Hjsx.string(Handler.getTranslatedString({en: "Examples"}))}
        </a>
        <a href="/resources" className="transition-colors hover:text-foreground">
          {Hjsx.string(Handler.getTranslatedString({en: "Resources"}))}
        </a>
      </div>
    </div>
  </footer>
}
