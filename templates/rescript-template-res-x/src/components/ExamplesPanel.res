let targetId = "examples-panel"

let filterExamplesHandler = Handler.handler.hxGetRef("/examples/filter")

module FilterLink = {
  @jsx.component
  let make = (~filter, ~activeFilter) => {
    let queryValue = filter->TemplateContent.exampleFilterToQueryValue
    let pageUrl = filter->TemplateContent.exampleFilterToUrl
    let isActive = TemplateContent.exampleFilterEquals(activeFilter, filter)

    <a
      href={pageUrl}
      hxGet=filterExamplesHandler
      rawHxVals={"{\"category\":\"" ++ queryValue ++ "\"}"}
      rawHxPushUrl={pageUrl}
      hxTarget={ResX.Htmx.Target.make(CssSelector("#" ++ targetId))}
      hxSwap={ResX.Htmx.Swap.make(OuterHTML)}
      className={if isActive {
        "rounded-md border border-brand bg-brand px-3 py-1 text-xs font-semibold text-brand-foreground transition-colors"
      } else {
        "rounded-md border border-border bg-card px-3 py-1 text-xs font-semibold text-muted-foreground transition-colors hover:border-brand hover:text-brand"
      }}
    >
      {Hjsx.string(filter->TemplateContent.exampleFilterToLabel)}
    </a>
  }
}

module Panel = {
  @jsx.component
  let make = (~examples: array<TemplateContent.example>, ~activeFilter) => {
    <div id=targetId>
      <div className="mb-8 flex flex-wrap items-center gap-2">
        <span className="mr-2 font-mono text-xs uppercase text-muted-foreground">
          {Hjsx.string(Handler.getTranslatedString({en: "Filter:"}))}
        </span>
        {TemplateContent.exampleFilters
        ->Array.map(filter => <FilterLink filter activeFilter />)
        ->Hjsx.array}
        <span className="ml-auto font-mono text-xs text-muted-foreground">
          {Hjsx.string(
            examples->Array.length->Int.toString ++
            " " ++ if examples->Array.length === 1 {
              Handler.getTranslatedString({en: "example"})
            } else {
              Handler.getTranslatedString({en: "examples"})
            },
          )}
        </span>
      </div>
      {if examples->Array.length === 0 {
        <div
          className="rounded-lg border border-dashed border-border p-12 text-center text-sm text-muted-foreground"
        >
          {Hjsx.string(Handler.getTranslatedString({en: "No examples in this category yet."}))}
        </div>
      } else {
        <div className="grid gap-4 md:grid-cols-2">
          {examples->Array.map(example => <ExampleCard example />)->Hjsx.array}
        </div>
      }}
    </div>
  }
}

filterExamplesHandler->Handler.handler.hxGetDefine(
  ~securityPolicy=ResX.SecurityPolicy.allow,
  ~handler=async ({request}) => {
    let url = request->Request.url->URL.make
    let activeFilter = TemplateContent.exampleFilterFromUrl(~url)
    let examples = TemplateContent.listExamples(~filter=activeFilter)
    <Panel examples activeFilter />
  },
)

@jsx.component
let make = () => {
  let {request} = Handler.useContext()
  let url = request->Request.url->URL.make
  let activeFilter = TemplateContent.exampleFilterFromUrl(~url)
  let examples = TemplateContent.listExamples(~filter=activeFilter)

  <Panel examples activeFilter />
}
