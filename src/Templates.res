type t = {
  name: string,
  displayName: string,
  shortDescription: string,
}

let basicTemplateName = "rescript-template-basic"

let templates = [
  {
    name: "rescript-template-vite",
    displayName: "Vite",
    shortDescription: "Vite 5, React and Tailwind CSS",
  },
  {
    name: "rescript-template-esbuild",
    displayName: "Esbuild",
    shortDescription: "Esbuild, React and Tailwind CSS",
  },
  {
    name: "rescript-template-nextjs",
    displayName: "Next.js",
    shortDescription: "Next.js 14 and Tailwind CSS",
  },
  {
    name: basicTemplateName,
    displayName: "Basic",
    shortDescription: "Command line hello world app",
  },
]
