import { defineConfig } from "vite";
import resXVitePlugin from "rescript-x/res-x-vite-plugin.mjs";

export default defineConfig(({ command }) => {
  const staticAssetRouteMode = command === "build" ? "embedded" : "filesystem";

  return {
    plugins: [
      resXVitePlugin({
        serverUri: "http://0.0.0.0:5557",
        staticAssetRoutes: {
          mode: staticAssetRouteMode,
          headers: {
            "/assets/**": {
              "Cache-Control": "public, max-age=31536000, immutable",
            },
            "/favicon.ico": {
              "Cache-Control": "public, max-age=86400",
            },
          },
        },
      }),
    ],
    server: {
      host: "0.0.0.0",
      port: 9201,
      strictPort: true,
    },
  };
});
