type versions = {rescriptVersion: string, rescriptCoreVersion: option<string>}

let promptVersions: unit => promise<versions>

let installVersions: versions => promise<unit>

let usesRewatch: versions => bool
