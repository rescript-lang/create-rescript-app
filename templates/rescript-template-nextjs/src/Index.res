module P = {
  @react.component
  let make = (~children) => <p className="mb-2"> children </p>
}

let default = () =>
  <div>
    <h1 className="text-3xl font-semibold"> {"What is this about?"->React.string} </h1>
    <P>
      {React.string(
        "This is a simple template for a Next.js 15 project with static export using ReScript & TailwindCSS 3.",
      )}
    </P>
    <h2 className="text-2xl font-semibold mt-5"> {React.string("Quick Start")} </h2>
    {React.string("Run ")}
    <span className="font-mono"> {React.string(`npm create rescript-app@latest`)} </span>
    {React.string(" and select Next.js template.")}
  </div>
