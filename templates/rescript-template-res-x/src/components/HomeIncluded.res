@jsx.component
let make = () => {
  <section className="border-b border-border bg-card">
    <div className="mx-auto max-w-6xl px-6 py-20">
      <div className="max-w-2xl">
        <div className="text-xs font-semibold uppercase text-brand">
          {Hjsx.string(Handler.getTranslatedString({en: "Included"}))}
        </div>
        <h2 className="mt-2 text-3xl font-bold text-foreground md:text-4xl">
          {Hjsx.string(Handler.getTranslatedString({en: "A few pieces included in the starter."}))}
        </h2>
      </div>
      <div className="mt-10 grid gap-4 md:grid-cols-2">
        {TemplateContent.highlights()
        ->Array.map(highlight =>
          <article className="rounded-lg border border-border bg-background p-6">
            <div className="font-mono text-xs uppercase text-brand">
              {Hjsx.string(highlight.eyebrow)}
            </div>
            <h3 className="mt-3 text-xl font-semibold text-foreground">
              {Hjsx.string(highlight.title)}
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
              {Hjsx.string(highlight.description)}
            </p>
          </article>
        )
        ->Hjsx.array}
      </div>
    </div>
  </section>
}
