import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT ?? 3000);
const isProd = process.env.NODE_ENV === "production";

async function createDevHandler() {
  const { createServer } = await import("vite");
  const vite = await createServer({
    root: __dirname,
    server: { middlewareMode: true },
    appType: "custom",
  });

  return async (req, res) => {
    vite.middlewares(req, res, async () => {
      try {
        const url = req.url ?? "/";
        const templatePath = path.join(__dirname, "index.html");
        let template = fs.readFileSync(templatePath, "utf-8");
        template = await vite.transformIndexHtml(url, template);

        const { render } = await vite.ssrLoadModule("/src/Server.res.mjs");
        const { html, stateScript } = render();

        const page = template
          .replace("<!--app-html-->", html)
          .replace("<!--app-state-->", stateScript);

        res.statusCode = 200;
        res.setHeader("Content-Type", "text/html");
        res.end(page);
      } catch (err) {
        vite.ssrFixStacktrace(err);
        res.statusCode = 500;
        res.end(String(err?.stack ?? err));
      }
    });
  };
}

async function createProdHandler() {
  const clientDir = path.join(__dirname, "dist/client");
  const templatePath = path.join(clientDir, "index.html");
  const template = fs.readFileSync(templatePath, "utf-8");
  const { render } = await import(
    path.join(__dirname, "dist/server/Server.res.js")
  );

  const mime = {
    ".js": "text/javascript",
    ".mjs": "text/javascript",
    ".css": "text/css",
    ".svg": "image/svg+xml",
    ".ico": "image/x-icon",
    ".png": "image/png",
    ".jpg": "image/jpeg",
    ".woff2": "font/woff2",
  };

  const serveStatic = (filePath, res) => {
    const ext = path.extname(filePath);
    res.statusCode = 200;
    res.setHeader("Content-Type", mime[ext] ?? "application/octet-stream");
    fs.createReadStream(filePath).pipe(res);
  };

  return (req, res) => {
    const url = (req.url ?? "/").split("?")[0];
    if (url !== "/" && url !== "/index.html") {
      const candidate = path.join(clientDir, url);
      if (
        candidate.startsWith(clientDir) &&
        fs.existsSync(candidate) &&
        fs.statSync(candidate).isFile()
      ) {
        serveStatic(candidate, res);
        return;
      }
    }

    const { html, stateScript } = render();
    const page = template
      .replace("<!--app-html-->", html)
      .replace("<!--app-state-->", stateScript);
    res.statusCode = 200;
    res.setHeader("Content-Type", "text/html");
    res.end(page);
  };
}

const handler = await (isProd ? createProdHandler() : createDevHandler());

http.createServer(handler).listen(PORT, () => {
  console.log(`xote ssr template ready at http://localhost:${PORT}`);
});
