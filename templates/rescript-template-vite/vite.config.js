import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

const rescriptOutputSuffix = ".res.mjs";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    tailwindcss(),
    react({
      include: [`**/*${rescriptOutputSuffix}`],
    }),
  ],
  server: {
    watch: {
      // Wait for ReScript's generated JS output before Vite sends HMR updates.
      ignored: [
        "**/*.res",
        "**/*.resi",
        "**/lib/bs/**",
        "**/lib/ocaml/**",
        "**/lib/rescript.lock",
      ],
    },
  },
});
