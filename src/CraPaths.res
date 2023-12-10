open Node

@scope(("import", "meta"))
external importMetaUrl: Node.Url.t = "url"

let dirname = importMetaUrl->Node.Url.fileURLToPath->Path.dirname

let packageJsonPath = Path.join([dirname, "..", "package.json"])

let templatesPath = Path.join([dirname, "..", "templates"])

let getTemplatePath = (~templateName) => Path.join2(templatesPath, templateName)
