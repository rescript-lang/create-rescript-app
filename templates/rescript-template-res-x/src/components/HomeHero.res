@jsx.component
let make = () => {
  <section className="relative overflow-hidden border-b border-border">
    <div className="absolute inset-0 grid-bg opacity-60" ariaHidden=true />
    <div className="relative mx-auto max-w-6xl px-6 py-24 md:py-32">
      <div
        className="mb-6 inline-flex items-center gap-2 rounded-md border border-border bg-card px-3 py-1 text-xs font-medium text-muted-foreground"
      >
        <span className="inline-block h-1.5 w-1.5 rounded-full bg-brand" />
        {Hjsx.string(Handler.getTranslatedString({en: "Template"}))}
      </div>
      <h1 className="max-w-4xl text-5xl font-bold text-foreground md:text-7xl">
        {Hjsx.string(Handler.getTranslatedString({en: "A simple "}))}
        <span className="text-brand">
          {Hjsx.string(Handler.getTranslatedString({en: "ResX starter"}))}
        </span>
        {Hjsx.string(Handler.getTranslatedString({en: "."}))}
      </h1>
      <p className="mt-6 max-w-2xl text-lg text-muted-foreground md:text-xl">
        {Hjsx.string(
          Handler.getTranslatedString({
            en: "A small app shell with a few pages, assets, and examples.",
          }),
        )}
      </p>
      <div className="mt-10 flex flex-wrap gap-3">
        <a
          href="/setup"
          className="inline-flex items-center justify-center rounded-md bg-brand px-5 py-2.5 text-sm font-semibold text-brand-foreground transition-colors hover:bg-brand/90"
        >
          {Hjsx.string(Handler.getTranslatedString({en: "Setup"}))}
        </a>
        <a
          href="/examples"
          className="inline-flex items-center justify-center rounded-md border border-border bg-card px-5 py-2.5 text-sm font-semibold text-foreground transition-colors hover:bg-accent"
        >
          {Hjsx.string(Handler.getTranslatedString({en: "Examples"}))}
        </a>
      </div>
      <div className="mt-12 grid gap-4 md:grid-cols-3">
        <article className="rounded-lg border border-border bg-card p-5">
          <div className="font-mono text-xs uppercase text-muted-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "Server"}))}
          </div>
          <div className="mt-2 text-lg font-semibold text-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "Routes and health checks"}))}
          </div>
        </article>
        <article className="rounded-lg border border-border bg-card p-5">
          <div className="font-mono text-xs uppercase text-muted-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "Assets"}))}
          </div>
          <div className="mt-2 text-lg font-semibold text-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "Styles and static files"}))}
          </div>
        </article>
        <article className="rounded-lg border border-border bg-card p-5">
          <div className="font-mono text-xs uppercase text-muted-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "Patterns"}))}
          </div>
          <div className="mt-2 text-lg font-semibold text-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "A few starter examples"}))}
          </div>
        </article>
      </div>
      <div className="mt-8 max-w-4xl rounded-2xl border border-border bg-card p-6 md:p-8">
        <div className="flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
          <div className="max-w-xl">
            <div className="font-mono text-xs uppercase text-muted-foreground">
              {Hjsx.string(Handler.getTranslatedString({en: "Asset sample"}))}
            </div>
            <h2 className="mt-2 text-2xl font-bold text-foreground">
              {Hjsx.string(Handler.getTranslatedString({en: "Logo and favicon examples."}))}
            </h2>
            <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
              {Hjsx.string(
                Handler.getTranslatedString({en: "These are sample assets you can replace."}),
              )}
            </p>
          </div>
          <div className="rounded-xl border border-border bg-background px-6 py-5">
            <img
              src={ResXAssets.assets.rescript_logo_svg}
              alt={Handler.getTranslatedString({en: "ReScript logo"})}
              className="h-auto w-full max-w-60"
            />
          </div>
        </div>
      </div>
    </div>
  </section>
}
