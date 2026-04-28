type rendered = {
  html: string,
  stateScript: string,
}

let render = (): rendered => {
  let html = SSR.renderToString(App.view)
  let stateScript = SSRState.generateScript()
  {html, stateScript}
}
