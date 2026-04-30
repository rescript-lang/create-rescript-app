type versions = {rescriptVersion: string, rescriptCoreVersion: option<string>}

let rescriptVersionRange: string

let getDefaultVersions: unit => promise<versions>

let promptVersions: unit => promise<versions>

let installVersions: versions => promise<unit>

let usesRewatch: versions => bool
