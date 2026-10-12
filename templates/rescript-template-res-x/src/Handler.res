type context = {
  lang: Language.t,
}

let handler = ResX.Handlers.make(
  ~requestToContext=async _request => {
    lang: English,
  },
  ~options={
    defaultCsrfCheck: PerMethod({
      get: Some(false),
      post: Some(true),
      put: Some(true),
      patch: Some(true),
      delete: Some(true),
    }),
  },
)

let useContext = () => handler.useContext()

let useLanguage = () => {
  let {context} = useContext()
  context.lang
}

let getTranslatedString = (langDict: Language.dict) => {
  let {context} = useContext()

  switch context.lang {
  | English => langDict.en
  }
}
