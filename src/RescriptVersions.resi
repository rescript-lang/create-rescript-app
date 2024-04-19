type versions = {rescriptVersion: string, rescriptCoreVersion: string}

let promptVersions: unit => promise<versions>

let installVersions: versions => promise<unit>

let esmModuleSystemName: versions => string
