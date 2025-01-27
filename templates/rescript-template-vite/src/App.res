@module("./assets/rescript-logo.svg")
external rescript: string = "default"

@module("./assets/vite.svg")
external vite: string = "default"

@react.component
let make = () => {
  let (count, setCount) = React.useState(() => 0)

  <div className="max-w-200">
    <div className="flex justify-evenly items-center">
      <img src={vite} alt={"Vite logo"} className="h-24" />
      <img src={rescript} alt={"ReScript logo"} className="h-24" />
    </div>
    <h1 className="text-6xl m-16 font-semibold text-center"> {"Vite + ReScript"->React.string} </h1>
    <Button onClick={_ => setCount(count => count + 1)}>
      {React.string(`count is ${count->Int.toString}`)}
    </Button>
    <p className="my-6 text-center">
      {React.string("Edit ")}
      <code className="bg-stone-100 font-mono rounded"> {React.string("src/App.res")} </code>
      {React.string(" and save to test Fast Refresh.")}
    </p>
    <p className="text-center font-thin text-stone-400">
      {React.string("Learn more about ")}
      <a
        href="https://rescript-lang.org/" target="_blank" className="text-blue-500 hover:underline">
        {React.string("ReScript")}
        {React.string(".")}
      </a>
    </p>
  </div>
}
