module C = PicoColors
module P = ClackPrompts

let showUpgradeHint = () =>
  P.note(
    ~title="Already installed",
    ~message=`ReScript is already installed in your project.

To upgrade to v11, check out the migration guide at
${C.cyan("https://rescript-lang.org/docs/manual/latest/migrate-to-v11")}`,
  )
