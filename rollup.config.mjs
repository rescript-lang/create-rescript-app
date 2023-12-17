import { nodeResolve } from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";
import terser from "@rollup/plugin-terser";

export default {
  input: `src/Main.res.mjs`,
  output: {
    file: `out/create-rescript-app.mjs`,
    format: "es",
    name: "create-rescript-app",
  },
  plugins: [terser(), nodeResolve({ preferBuiltins: true }), commonjs()],
};
