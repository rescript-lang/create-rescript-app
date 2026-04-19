@jsx.component
let make = (~resource: TemplateContent.resource, ~detailed=false) => {
  let target = if resource.isExternal {
    "_blank"
  } else {
    "_self"
  }
  let rel = if resource.isExternal {
    "noreferrer"
  } else {
    ""
  }

  if detailed {
    <a
      href={resource.href}
      target
      rel
      className="group flex flex-col gap-2 rounded-lg border border-border bg-card p-6 transition-colors hover:border-brand md:flex-row md:items-center md:justify-between md:gap-8"
    >
      <div className="shrink-0 md:w-56">
        <div className="font-mono text-xs uppercase text-muted-foreground">
          {Hjsx.string(resource.kind->TemplateContent.resourceKindToLabel)}
        </div>
        <div className="mt-1 text-2xl font-bold transition-colors group-hover:text-brand">
          {Hjsx.string(resource.name)}
        </div>
      </div>
      <p className="flex-1 text-sm text-muted-foreground"> {Hjsx.string(resource.blurb)} </p>
      <span className="text-sm font-semibold text-brand">
        {Hjsx.string(resource.cta ++ " ->")}
      </span>
    </a>
  } else {
    <a
      href={resource.href}
      target
      rel
      className="group rounded-lg border border-border bg-card p-6 transition-colors hover:border-brand"
    >
      <div className="font-mono text-xs uppercase text-muted-foreground">
        {Hjsx.string(resource.kind->TemplateContent.resourceKindToLabel)}
      </div>
      <div className="mt-2 text-xl font-semibold transition-colors group-hover:text-brand">
        {Hjsx.string(resource.name)}
      </div>
    </a>
  }
}
