@jsx.component
let make = () => {
  let count = SSRState.signal("count", 0, SSRState.Codec.int)

  let decrement = (_: Dom.event) => Signal.update(count, n => n - 1)
  let increment = (_: Dom.event) => Signal.update(count, n => n + 1)

  <div class="flex items-center gap-3 p-6">
    <button
      class="px-3 py-1 rounded bg-slate-900 text-white hover:bg-slate-700"
      onClick={decrement}>
      {View.text("-")}
    </button>
    <span class="font-mono text-xl tabular-nums">
      {View.signalText(() => Signal.get(count)->Int.toString)}
    </span>
    <button
      class="px-3 py-1 rounded bg-slate-900 text-white hover:bg-slate-700"
      onClick={increment}>
      {View.text("+")}
    </button>
  </div>
}
