@jsx.component
let make = () => {
  <AppLayout>
    <PageHead
      title={Handler.getTranslatedString({en: "Setup - ResX Template"})}
      description={Handler.getTranslatedString({
        en: "Short notes for getting started with the template.",
      })}
    />
    <section className="border-b border-border">
      <div className="mx-auto max-w-6xl px-6 py-16 md:py-20">
        <div className="text-xs font-semibold uppercase text-brand">
          {Hjsx.string(Handler.getTranslatedString({en: "Setup"}))}
        </div>
        <h1 className="mt-2 max-w-3xl text-4xl font-bold text-foreground md:text-5xl">
          {Hjsx.string(Handler.getTranslatedString({en: "Start small."}))}
        </h1>
        <p className="mt-4 max-w-2xl text-muted-foreground">
          {Hjsx.string(
            Handler.getTranslatedString({en: "Replace the name, copy, pages, and styles first."}),
          )}
        </p>
      </div>
    </section>
    <SetupTimeline />
    <section id="next-step" className="border-t border-border bg-card">
      <div className="mx-auto max-w-6xl px-6 py-16">
        <div className="max-w-3xl">
          <div className="text-xs font-semibold uppercase text-brand">
            {Hjsx.string(Handler.getTranslatedString({en: "Next step"}))}
          </div>
          <h2 className="mt-2 text-3xl font-bold text-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "Add the database later."}))}
          </h2>
          <p className="mt-4 text-muted-foreground">
            {Hjsx.string(
              Handler.getTranslatedString({
                en: "When the data model is real, put that work on a separate branch.",
              }),
            )}
          </p>
        </div>
      </div>
    </section>
  </AppLayout>
}
