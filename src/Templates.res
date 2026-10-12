type variant = {
  name: string,
  displayName: string,
  shortDescription: string,
}

type t = {
  name: string,
  displayName: string,
  shortDescription: string,
  variants: option<array<variant>>,
}

let basicTemplateName = "rescript-template-basic"
let viteTemplateName = "rescript-template-vite"
let nextjsTemplateName = "rescript-template-nextjs"
let xoteTemplateName = "rescript-template-xote"
let xoteSsrTemplateName = "rescript-template-xote-ssr"
let resXTemplateName = "rescript-template-res-x"
let templateNamePrefix = "rescript-template-"

let supportedTemplateNames = ["vite", "nextjs", "xote", "xote-ssr", "res-x", "basic"]

let getTemplateName = templateName => {
  let templateName = templateName->String.toLowerCase

  supportedTemplateNames
  ->Array.find(supportedTemplateName => supportedTemplateName === templateName)
  ->Option.map(_ => `${templateNamePrefix}${templateName}`)
}

let templates = [
  {
    name: viteTemplateName,
    displayName: "Vite",
    shortDescription: "Vite 8, React and Tailwind 4",
    variants: None,
  },
  {
    name: nextjsTemplateName,
    displayName: "Next.js",
    shortDescription: "Next.js 15 with static export and Tailwind 3",
    variants: None,
  },
  {
    name: xoteTemplateName,
    displayName: "Xote",
    shortDescription: "Xote with Vite, signals and Tailwind 4",
    variants: Some([
      {
        name: xoteTemplateName,
        displayName: "Client-Side Rendering (CSR)",
        shortDescription: "Vite, signals and Tailwind 4",
      },
      {
        name: xoteSsrTemplateName,
        displayName: "Server-Side Rendering (SSR)",
        shortDescription: "Vite SSR via Node server, signals and Tailwind 4",
      },
    ]),
  },
  {
    name: resXTemplateName,
    displayName: "ResX",
    shortDescription: "Bun SSR with ResX, Vite and Tailwind 4",
    variants: None,
  },
  {
    name: basicTemplateName,
    displayName: "Basic",
    shortDescription: "Command line hello world app",
    variants: None,
  },
]
