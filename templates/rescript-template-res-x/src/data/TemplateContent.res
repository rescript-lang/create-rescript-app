type highlight = {
  eyebrow: string,
  title: string,
  description: string,
}

type exampleCategory =
  | Foundations
  | Interactivity
  | Content
  | Ops

type exampleFilter =
  | All
  | Category(exampleCategory)

type example = {
  title: string,
  category: exampleCategory,
  summary: string,
  footnote: string,
  featured: bool,
}

type setupStep = {
  eyebrow: string,
  title: string,
  description: string,
  commands: array<string>,
}

type resourceKind =
  | Guide
  | Docs
  | NextStep

type resource = {
  name: string,
  href: string,
  kind: resourceKind,
  blurb: string,
  cta: string,
  isExternal: bool,
  featured: bool,
}

let highlights = () => {
  [
    {
      eyebrow: Handler.getTranslatedString({en: "Basics"}),
      title: Handler.getTranslatedString({en: "App shell"}),
      description: Handler.getTranslatedString({
        en: "Basic routes and health checks are included.",
      }),
    },
    {
      eyebrow: Handler.getTranslatedString({en: "Styles"}),
      title: Handler.getTranslatedString({en: "Assets and Tailwind"}),
      description: Handler.getTranslatedString({en: "Styles and static files are set up for you."}),
    },
    {
      eyebrow: Handler.getTranslatedString({en: "Build"}),
      title: Handler.getTranslatedString({en: "Executable build"}),
      description: Handler.getTranslatedString({
        en: "You can build a Bun executable if you want one.",
      }),
    },
    {
      eyebrow: Handler.getTranslatedString({en: "Examples"}),
      title: Handler.getTranslatedString({en: "Small interactions"}),
      description: Handler.getTranslatedString({en: "A few simple UI patterns are included."}),
    },
    {
      eyebrow: Handler.getTranslatedString({en: "Structure"}),
      title: Handler.getTranslatedString({en: "Clear files"}),
      description: Handler.getTranslatedString({
        en: "Pages, components, and copy are kept separate.",
      }),
    },
  ]
}

let examples = () => {
  [
    {
      title: Handler.getTranslatedString({en: "Routes and app shell"}),
      category: Foundations,
      summary: Handler.getTranslatedString({en: "This is the main server and page shell setup."}),
      footnote: Handler.getTranslatedString({en: "Start in src/Server.res."}),
      featured: true,
    },
    {
      title: Handler.getTranslatedString({en: "Page metadata and 404 page"}),
      category: Foundations,
      summary: Handler.getTranslatedString({
        en: "Simple examples for page titles and not-found handling.",
      }),
      footnote: Handler.getTranslatedString({en: "See PageHead.res and PageFourOhFour.res."}),
      featured: false,
    },
    {
      title: Handler.getTranslatedString({en: "Filter example"}),
      category: Interactivity,
      summary: Handler.getTranslatedString({
        en: "A small filtered list with server-rendered updates.",
      }),
      footnote: Handler.getTranslatedString({en: "See ExamplesPanel.res."}),
      featured: true,
    },
    {
      title: Handler.getTranslatedString({en: "Static content module"}),
      category: Content,
      summary: Handler.getTranslatedString({en: "Most of the placeholder copy lives in one file."}),
      footnote: Handler.getTranslatedString({en: "Edit TemplateContent.res first."}),
      featured: true,
    },
    {
      title: Handler.getTranslatedString({en: "Health and readiness endpoints"}),
      category: Ops,
      summary: Handler.getTranslatedString({en: "Simple live and ready endpoints are included."}),
      footnote: Handler.getTranslatedString({en: "Update these when you add real dependencies."}),
      featured: true,
    },
    {
      title: Handler.getTranslatedString({en: "Standalone executable build"}),
      category: Ops,
      summary: Handler.getTranslatedString({en: "You can build a standalone Bun executable."}),
      footnote: Handler.getTranslatedString({en: "Run bun run build:sfe."}),
      featured: true,
    },
    {
      title: Handler.getTranslatedString({en: "Robots and sitemap pages"}),
      category: Ops,
      summary: Handler.getTranslatedString({en: "Simple crawler-related pages are included."}),
      footnote: Handler.getTranslatedString({en: "Update them if your routes change."}),
      featured: false,
    },
  ]
}

let setupSteps = () => {
  [
    {
      eyebrow: Handler.getTranslatedString({en: "1. Install"}),
      title: Handler.getTranslatedString({en: "Install dependencies"}),
      description: Handler.getTranslatedString({
        en: "Start with the default setup and change it later if you need to.",
      }),
      commands: ["bun install"],
    },
    {
      eyebrow: Handler.getTranslatedString({en: "2. Run"}),
      title: Handler.getTranslatedString({en: "Run the app"}),
      description: Handler.getTranslatedString({
        en: "This starts the server, ReScript watch, and Vite together.",
      }),
      commands: ["bun run dev", "open http://localhost:9201"],
    },
    {
      eyebrow: Handler.getTranslatedString({en: "3. Rename"}),
      title: Handler.getTranslatedString({en: "Replace the placeholder content"}),
      description: Handler.getTranslatedString({
        en: "Rename the app, swap the copy, and remove the pages you do not want.",
      }),
      commands: ["src/data/TemplateContent.res", "src/pages", "src/components"],
    },
    {
      eyebrow: Handler.getTranslatedString({en: "4. Ship"}),
      title: Handler.getTranslatedString({en: "Build the executable"}),
      description: Handler.getTranslatedString({
        en: "If you want a single Bun binary, use the executable build command.",
      }),
      commands: ["bun run build:sfe", "cd build && PORT=5557 NODE_ENV=production ./resx-template"],
    },
  ]
}

let resources = () => {
  [
    {
      name: Handler.getTranslatedString({en: "Setup notes"}),
      href: "/setup",
      kind: Guide,
      blurb: Handler.getTranslatedString({en: "Short notes on where to start editing."}),
      cta: Handler.getTranslatedString({en: "Open setup"}),
      isExternal: false,
      featured: true,
    },
    {
      name: Handler.getTranslatedString({en: "Example pages"}),
      href: "/examples",
      kind: Guide,
      blurb: Handler.getTranslatedString({en: "A few small examples from the starter."}),
      cta: Handler.getTranslatedString({en: "Open examples"}),
      isExternal: false,
      featured: true,
    },
    {
      name: Handler.getTranslatedString({en: "ReScript docs"}),
      href: "https://rescript-lang.org/",
      kind: Docs,
      blurb: Handler.getTranslatedString({en: "Language docs and examples."}),
      cta: Handler.getTranslatedString({en: "Open docs"}),
      isExternal: true,
      featured: true,
    },
    {
      name: Handler.getTranslatedString({en: "Bun docs"}),
      href: "https://bun.sh/docs",
      kind: Docs,
      blurb: Handler.getTranslatedString({en: "Runtime and server docs."}),
      cta: Handler.getTranslatedString({en: "Open docs"}),
      isExternal: true,
      featured: false,
    },
    {
      name: Handler.getTranslatedString({en: "Tailwind docs"}),
      href: "https://tailwindcss.com/docs",
      kind: Docs,
      blurb: Handler.getTranslatedString({en: "Styling reference."}),
      cta: Handler.getTranslatedString({en: "Open docs"}),
      isExternal: true,
      featured: false,
    },
    {
      name: Handler.getTranslatedString({en: "Database branch later"}),
      href: "/setup#next-step",
      kind: NextStep,
      blurb: Handler.getTranslatedString({
        en: "Keep the starter simple and add DB work on a separate branch.",
      }),
      cta: Handler.getTranslatedString({en: "See note"}),
      isExternal: false,
      featured: true,
    },
  ]
}

let featuredExamples = () => examples()->Array.filter(example => example.featured)

let featuredResources = () => resources()->Array.filter(resource => resource.featured)

let exampleCategoryToQueryValue = category =>
  switch category {
  | Foundations => "Foundations"
  | Interactivity => "Interactivity"
  | Content => "Content"
  | Ops => "Ops"
  }

let exampleCategoryToLabel = category =>
  switch category {
  | Foundations => Handler.getTranslatedString({en: "Foundations"})
  | Interactivity => Handler.getTranslatedString({en: "Interactivity"})
  | Content => Handler.getTranslatedString({en: "Content"})
  | Ops => Handler.getTranslatedString({en: "Ops"})
  }

let exampleCategoryFromString = value =>
  switch value {
  | "Foundations" => Some(Foundations)
  | "Interactivity" => Some(Interactivity)
  | "Content" => Some(Content)
  | "Ops" => Some(Ops)
  | _ => None
  }

let exampleFilterToQueryValue = filter =>
  switch filter {
  | All => "all"
  | Category(category) => category->exampleCategoryToQueryValue
  }

let exampleFilterToLabel = filter =>
  switch filter {
  | All => Handler.getTranslatedString({en: "All"})
  | Category(category) => category->exampleCategoryToLabel
  }

let exampleFilterToUrl = filter => "/examples?category=" ++ exampleFilterToQueryValue(filter)

let exampleFilterEquals = (left, right) =>
  switch (left, right) {
  | (All, All) => true
  | (Category(leftCategory), Category(rightCategory)) => leftCategory === rightCategory
  | _ => false
  }

let exampleFilterFromUrl = (~url: URL.t) =>
  switch url->URL.searchParams->URLSearchParams.get("category") {
  | None | Some("all") => All
  | Some(rawCategory) =>
    switch rawCategory->exampleCategoryFromString {
    | Some(category) => Category(category)
    | None => All
    }
  }

let exampleFilters: array<exampleFilter> = [
  All,
  Category(Foundations),
  Category(Interactivity),
  Category(Content),
  Category(Ops),
]

let listExamples = (~filter) =>
  switch filter {
  | All => examples()
  | Category(category) => examples()->Array.filter(example => example.category === category)
  }

let resourceKindToLabel = kind =>
  switch kind {
  | Guide => Handler.getTranslatedString({en: "Guide"})
  | Docs => Handler.getTranslatedString({en: "Docs"})
  | NextStep => Handler.getTranslatedString({en: "Next step"})
  }
