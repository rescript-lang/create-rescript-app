@module("compare-versions")
external compareVersions: (string, string) => Ordering.t = "compareVersions"

@module("compare-versions")
external satisfies: (string, string) => bool = "satisfies"
