type t = {
  projectName: option<string>,
  templateName: option<string>,
}

let supportedOptionsHint = `Supported options: --template <${Templates.supportedTemplateNames->Array.join(
    "|",
  )}> or -t <${Templates.supportedTemplateNames->Array.join("|")}>.`

let getTemplateName = templateName =>
  switch Templates.getTemplateName(templateName) {
  | Some(templateName) => Ok(templateName)
  | None =>
    Error(
      `Unknown template "${templateName}". Available templates: ${Templates.supportedTemplateNames->Array.join(
          ", ",
        )}.`,
    )
  }

let parseError = message => Error(`${message} ${supportedOptionsHint}`)

let rec parseRemainingArguments = (remainingArguments, commandLineArguments) =>
  switch remainingArguments {
  | list{} => Ok(commandLineArguments)
  | list{"-t", templateName, ...remainingArguments}
  | list{"--template", templateName, ...remainingArguments} =>
    switch getTemplateName(templateName) {
    | Ok(templateName) =>
      parseRemainingArguments(
        remainingArguments,
        {
          ...commandLineArguments,
          templateName: Some(templateName),
        },
      )
    | Error(message) => Error(message)
    }
  | list{"-t"} | list{"--template"} => parseError("Missing value for --template.")
  | list{argument, ...remainingArguments} if argument->String.startsWith("--template=") =>
    switch argument->String.split("=") {
    | [_, templateName] =>
      switch getTemplateName(templateName) {
      | Ok(templateName) =>
        parseRemainingArguments(
          remainingArguments,
          {
            ...commandLineArguments,
            templateName: Some(templateName),
          },
        )
      | Error(message) => Error(message)
      }
    | _ => parseError("Missing value for --template.")
    }
  | list{argument, ..._remainingArguments} if argument->String.startsWith("-") =>
    parseError(`Unknown option "${argument}".`)
  | list{argument, ...remainingArguments} =>
    switch commandLineArguments.projectName {
    | None =>
      parseRemainingArguments(
        remainingArguments,
        {...commandLineArguments, projectName: Some(argument)},
      )
    | Some(_) => parseError(`Unexpected argument "${argument}".`)
    }
  }

let parse = remainingArguments =>
  parseRemainingArguments(remainingArguments, {projectName: None, templateName: None})

let fromProcessArgv = argv =>
  switch List.fromArray(argv) {
  | list{_, _, ...remainingArguments} => parse(remainingArguments)
  | _ => Ok({projectName: None, templateName: None})
  }
