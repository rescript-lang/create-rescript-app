type props = {
  msg: string,
  href: string,
}

let default = (props: props) =>
  <div>
    {React.string(props.msg)}
    <a href=props.href target="_blank"> {React.string("`src/Examples.res`")} </a>
  </div>

let getStaticProps = _ctx => {
  let props = {
    msg: "This page was rendered with getStaticProps. You can find the source code here: ",
    href: "https://github.com/rescript-lang/create-rescript-app/blob/master/templates/rescript-template-nextjs/src/Examples.res",
  }
  Promise.resolve({"props": props})
}
