import { nodeResolve } from "@rollup/plugin-node-resolve";
import commonjs from "@rollup/plugin-commonjs";
import terser from "@rollup/plugin-terser";

export default {
  input: `src/Main.res.mjs`,
  output: {
    file: `out/create-rescript-app.cjs`,
    format: "cjs",
    banner: "#!/usr/bin/env node",
  },
  plugins: [terser(), nodeResolve({ preferBuiltins: true }), commonjs()],
};
