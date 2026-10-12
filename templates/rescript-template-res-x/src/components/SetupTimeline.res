@jsx.component
let make = () => {
  let steps = TemplateContent.setupSteps()

  <section className="mx-auto max-w-6xl px-6 py-16">
    <div className="space-y-8">
      {steps
      ->Array.map(step =>
        <article className="rounded-xl border border-border bg-card p-8">
          <div className="text-xs font-semibold uppercase text-brand">
            {Hjsx.string(step.eyebrow)}
          </div>
          <h2 className="mt-2 text-2xl font-bold text-foreground"> {Hjsx.string(step.title)} </h2>
          <p className="mt-3 max-w-3xl text-sm leading-relaxed text-muted-foreground">
            {Hjsx.string(step.description)}
          </p>
          {if step.commands->Array.length === 0 {
            Hjsx.null
          } else {
            <div className="mt-5 rounded-lg bg-nav px-4 py-3 font-mono text-xs text-nav-foreground">
              {step.commands
              ->Array.map(command => <div> {Hjsx.string(command)} </div>)
              ->Hjsx.array}
            </div>
          }}
        </article>
      )
      ->Hjsx.array}
    </div>
  </section>
}
