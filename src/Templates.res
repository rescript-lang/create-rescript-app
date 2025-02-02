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
    shortDescription: "Vite 6, React and Tailwind 4",
  },
  {
    name: "rescript-template-nextjs",
    displayName: "Next.js",
    shortDescription: "Next.js 15 with static export and Tailwind 3",
  },
  {
    name: basicTemplateName,
    displayName: "Basic",
    shortDescription: "Command line hello world app",
  },
]
