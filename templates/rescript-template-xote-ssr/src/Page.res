@xote.component
let make = () => {
  <main class="min-h-screen bg-slate-50 text-slate-900 flex items-center justify-center p-6">
    <div
      class="max-w-2xl w-full bg-white rounded-2xl shadow-sm border border-slate-200 p-8 space-y-8"
    >
      <header class="space-y-2">
        <p class="text-xs uppercase tracking-widest text-slate-500">
          {"xote · ssr template"}
        </p>
        <h1 class="text-3xl font-semibold"> {"Welcome to xote"} </h1>
        <p class="text-slate-600">
          {"A clean slate for building reactive UIs in ReScript, rendered on the server and hydrated on the client."}
        </p>
      </header>
      <section class="space-y-2">
        <h2 class="text-sm font-medium text-slate-700"> {"Tech stack"} </h2>
        <ul class="text-sm text-slate-600 space-y-1 list-disc pl-5">
          <li> {"ReScript v12 — typed language compiling to clean JavaScript"} </li>
          <li> {"xote — fine-grained reactivity with SSR + hydration"} </li>
          <li> {"Vite 7 — dev server (middleware mode) and bundler"} </li>
          <li> {"Tailwind CSS v4 — utility-first, CSS-first config"} </li>
        </ul>
      </section>
      <section class="space-y-2">
        <h2 class="text-sm font-medium text-slate-700"> {"Reactive counter demo"} </h2>
        <div class="border border-slate-200 rounded-lg">
          <Counter />
        </div>
        <p class="text-xs text-slate-500">
          {"State is rendered on the server and survives hydration via SSRState."}
        </p>
      </section>
      <footer class="text-xs text-slate-500">
        {"Edit src/Page.res and src/Counter.res to start building."}
      </footer>
    </div>
  </main>
}
