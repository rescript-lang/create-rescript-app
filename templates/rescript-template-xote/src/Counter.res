@xote.component
let make = () => {
  let count = Signal.make(0)

  let decrement = (_: Dom.event) => Signal.update(count, n => n - 1)
  let increment = (_: Dom.event) => Signal.update(count, n => n + 1)

  <div class="flex items-center gap-3 p-6">
    <button
      class="px-3 py-1 rounded bg-slate-900 text-white hover:bg-slate-700" onClick={decrement}
    >
      {"-"}
    </button>
    <span class="font-mono text-xl tabular-nums">
      {Signal.get(count)}
    </span>
    <button
      class="px-3 py-1 rounded bg-slate-900 text-white hover:bg-slate-700" onClick={increment}
    >
      {("+")}
    </button>
  </div>
}
