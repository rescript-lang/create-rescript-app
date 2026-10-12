@jsx.component
let make = () => {
  <AppLayout>
    <PageHead
      title={Handler.getTranslatedString({en: "Resources - ResX Template"})}
      description={Handler.getTranslatedString({en: "Links and notes for the starter."})}
    />
    <section className="border-b border-border">
      <div className="mx-auto max-w-6xl px-6 py-16 md:py-20">
        <div className="text-xs font-semibold uppercase text-brand">
          {Hjsx.string(Handler.getTranslatedString({en: "Resources"}))}
        </div>
        <h1 className="mt-2 text-4xl font-bold text-foreground md:text-5xl">
          {Hjsx.string(Handler.getTranslatedString({en: "Links and notes."}))}
        </h1>
        <p className="mt-4 max-w-2xl text-muted-foreground">
          {Hjsx.string(
            Handler.getTranslatedString({en: "Keep the links you want and replace the rest."}),
          )}
        </p>
      </div>
    </section>
    <section className="mx-auto max-w-6xl px-6 py-16">
      <div className="space-y-4">
        {TemplateContent.resources()
        ->Array.map(resource => <ResourceCard resource detailed=true />)
        ->Hjsx.array}
      </div>
    </section>
  </AppLayout>
}
