let stampOutputSuffix = (~suffix, config) =>
  config->String.replaceRegExp(
    /const rescriptOutputSuffix = "[^"]+";/,
    `const rescriptOutputSuffix = ${JSON.stringify(String(suffix))};`,
  )
