import fs from "fs";
import path from "path";

const rescript = JSON.parse(fs.readFileSync("./rescript.json"));
const transpileModules = ["rescript"].concat(rescript["bs-dependencies"]);

const config = {
  pageExtensions: ["jsx", "js"],
  output: "export",
  env: {
    ENV: process.env.NODE_ENV,
  },
  webpack: (config, options) => {
    const { isServer } = options;

    if (!isServer) {
      // We shim fs for things like the blog slugs component
      // where we need fs access in the server-side part
      config.resolve.fallback = {
        fs: false,
        path: false,
      };
      config.watchOptions = {
        ...config.watchOptions,
        // We ignore ReScript build artifacts to avoid unnecessarily triggering HMR on incremental compilation
        ignored: ["**/lib/bs/**", "**/lib/ocaml/**", "**/lib/rescript.lock"],
      };
    }

    // We need this additional rule to make sure that mjs files are
    // correctly detected within our src/ folder
    config.module.rules.push({
      test: /\.m?js$/,
      use: options.defaultLoaders.babel,
      exclude: /node_modules/,
      type: "javascript/auto",
      resolve: {
        fullySpecified: false,
      },
    });

    return config;
  },
};

export default {
  transpilePackages: transpileModules,
  ...config,
};
