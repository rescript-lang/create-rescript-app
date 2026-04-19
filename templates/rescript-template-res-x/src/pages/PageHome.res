@jsx.component
let make = () => {
  <AppLayout>
    <PageHead
      title={Handler.getTranslatedString({en: "ResX Template"})}
      description={Handler.getTranslatedString({
        en: "Small ResX starter with a few pages and examples.",
      })}
    />
    <HomeHero />
    <HomeIncluded />
    <HomeExamplesTeaser />
    <HomeResourcesTeaser />
  </AppLayout>
}
