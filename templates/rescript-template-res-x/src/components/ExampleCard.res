@jsx.component
let make = (~example: TemplateContent.example, ~compact=false) => {
  let paddingClassName = compact ? "p-5" : "p-6"
  let titleClassName = compact ? "text-lg" : "text-xl"

  <article className={`rounded-lg border border-border bg-background ${paddingClassName}`}>
    <div className="flex items-center justify-between gap-3">
      <div className="font-mono text-xs uppercase text-muted-foreground">
        {Hjsx.string(example.category->TemplateContent.exampleCategoryToLabel)}
      </div>
      <span
        className="rounded-md border border-border px-2 py-1 text-[10px] font-semibold text-brand"
      >
        {Hjsx.string(
          if example.featured {
            Handler.getTranslatedString({en: "Starter"})
          } else {
            Handler.getTranslatedString({en: "Reference"})
          },
        )}
      </span>
    </div>
    <h3 className={`mt-3 font-bold text-foreground ${titleClassName}`}>
      {Hjsx.string(example.title)}
    </h3>
    <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
      {Hjsx.string(example.summary)}
    </p>
    <div className="mt-4 font-mono text-xs text-muted-foreground">
      {Hjsx.string(example.footnote)}
    </div>
  </article>
}
