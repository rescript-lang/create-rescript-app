@jsx.component
let make = (~children) => {
  <div className="flex min-h-screen flex-col bg-background">
    <SiteHeader />
    <main className="flex-1"> {children} </main>
    <SiteFooter />
  </div>
}
