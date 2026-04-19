type t = {
  name: string,
  displayName: string,
  shortDescription: string,
}

let basicTemplateName = "rescript-template-basic"
let viteTemplateName = "rescript-template-vite"
let nextjsTemplateName = "rescript-template-nextjs"
let templateNamePrefix = "rescript-template-"

let supportedTemplateNames = ["vite", "nextjs", "basic"]

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
    shortDescription: "Vite 7, React and Tailwind 4",
  },
  {
    name: nextjsTemplateName,
    displayName: "Next.js",
    shortDescription: "Next.js 15 with static export and Tailwind 3",
  },
  {
    name: basicTemplateName,
    displayName: "Basic",
    shortDescription: "Command line hello world app",
  },
]
