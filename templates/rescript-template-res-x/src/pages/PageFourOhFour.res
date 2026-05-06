@jsx.component
let make = () => {
  let {requestController} = Handler.useContext()
  requestController.setStatus(404)

  <AppLayout>
    <PageHead
      title={Handler.getTranslatedString({en: "404 - ResX Template"})}
      description={Handler.getTranslatedString({
        en: "The page you are looking for does not exist.",
      })}
      robots="noindex, nofollow"
    />
    <section className="mx-auto flex min-h-[60vh] max-w-3xl items-center justify-center px-6 py-20">
      <div className="text-center">
        <div className="text-6xl font-bold text-foreground"> {Hjsx.string("404")} </div>
        <h1 className="mt-4 text-2xl font-bold text-foreground">
          {Hjsx.string(Handler.getTranslatedString({en: "Page not found"}))}
        </h1>
        <p className="mt-3 text-muted-foreground">
          {Hjsx.string(
            Handler.getTranslatedString({
              en: "The route you requested is not part of this starter.",
            }),
          )}
        </p>
        <div className="mt-8">
          <a
            href="/"
            className="inline-flex items-center justify-center rounded-md bg-brand px-4 py-2 text-sm font-semibold text-brand-foreground transition-colors hover:bg-brand/90"
          >
            {Hjsx.string(Handler.getTranslatedString({en: "Go home"}))}
          </a>
        </div>
      </div>
    </section>
  </AppLayout>
}
