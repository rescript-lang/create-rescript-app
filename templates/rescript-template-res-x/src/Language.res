type t = | @as("en-us") English

type dict = {
  en: string,
}

let locale = language =>
  switch language {
  | English => "en-US"
  }

let htmlLang = language =>
  switch language {
  | English => "en"
  }
