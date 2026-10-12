@jsx.component
let make = () => {
  <section className="border-b border-border">
    <div className="mx-auto max-w-6xl px-6 py-20">
      <div className="flex items-end justify-between gap-4">
        <div>
          <div className="text-xs font-semibold uppercase text-brand">
            {Hjsx.string(Handler.getTranslatedString({en: "Examples"}))}
          </div>
          <h2 className="mt-2 text-3xl font-bold text-foreground">
            {Hjsx.string(Handler.getTranslatedString({en: "A few examples"}))}
          </h2>
        </div>
        <a
          href="/examples"
          className="text-sm font-semibold text-brand transition-colors hover:text-foreground"
        >
          {Hjsx.string(Handler.getTranslatedString({en: "View all ->"}))}
        </a>
      </div>
      <div className="mt-10 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {TemplateContent.featuredExamples()
        ->Array.map(example => <ExampleCard example compact=true />)
        ->Hjsx.array}
      </div>
    </div>
  </section>
}
