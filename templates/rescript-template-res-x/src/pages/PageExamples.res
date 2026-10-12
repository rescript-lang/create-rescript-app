@jsx.component
let make = () => {
  <AppLayout>
    <PageHead
      title={Handler.getTranslatedString({en: "Examples - ResX Template"})}
      description={Handler.getTranslatedString({
        en: "A few small examples included in the starter.",
      })}
    />
    <section className="border-b border-border">
      <div className="mx-auto max-w-6xl px-6 py-16 md:py-20">
        <div className="text-xs font-semibold uppercase text-brand">
          {Hjsx.string(Handler.getTranslatedString({en: "Examples"}))}
        </div>
        <h1 className="mt-2 text-4xl font-bold text-foreground md:text-5xl">
          {Hjsx.string(Handler.getTranslatedString({en: "A few examples."}))}
        </h1>
        <p className="mt-4 max-w-2xl text-muted-foreground">
          {Hjsx.string(
            Handler.getTranslatedString({
              en: "These cards point to the main pieces in the starter.",
            }),
          )}
        </p>
      </div>
    </section>
    <section className="mx-auto max-w-6xl px-6 py-16">
      <ExamplesPanel />
    </section>
  </AppLayout>
}
