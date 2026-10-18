const http = require("http");
const fs = require("fs");
const path = require("path");

const dir = process.env.OBJECT_STORE_DIR || "/data";
const port = Number(process.env.PORT || 9000);

fs.mkdirSync(dir, { recursive: true });

function send(res, status, body, contentType = "application/json") {
  const payload = typeof body === "string" || Buffer.isBuffer(body) ? body : JSON.stringify(body);
  res.writeHead(status, { "content-type": contentType });
  res.end(payload);
}

function objectPath(urlPath) {
  const key = decodeURIComponent(urlPath.replace(/^\/objects\/?/, "")).replace(/[^A-Za-z0-9._:-]/g, "_");
  if (!key) return null;
  return path.join(dir, key);
}

const server = http.createServer((req, res) => {
  if (req.url === "/health") {
    send(res, 200, { status: "ok" });
    return;
  }

  if (!req.url.startsWith("/objects/")) {
    send(res, 404, { error: { code: "NOT_FOUND", message: "Unknown object path.", details: {} } });
    return;
  }

  const filePath = objectPath(req.url);
  if (!filePath) {
    send(res, 400, { error: { code: "VALIDATION_ERROR", message: "Missing object key.", details: {} } });
    return;
  }

  if (req.method === "PUT") {
    const chunks = [];
    req.on("data", (chunk) => chunks.push(chunk));
    req.on("end", () => {
      fs.writeFile(filePath, Buffer.concat(chunks), (error) => {
        if (error) {
          send(res, 500, { error: { code: "INTERNAL_ERROR", message: "Failed to store object.", details: {} } });
          return;
        }
        send(res, 201, { status: "stored" });
      });
    });
    return;
  }

  if (req.method === "GET") {
    fs.readFile(filePath, (error, data) => {
      if (error) {
        send(res, 404, { error: { code: "NOT_FOUND", message: "Object was not found.", details: {} } });
        return;
      }
      send(res, 200, data, "application/octet-stream");
    });
    return;
  }

  send(res, 405, { error: { code: "VALIDATION_ERROR", message: "Method not allowed.", details: {} } });
});

server.listen(port, "0.0.0.0", () => {
  console.log(`object-store listening on ${port}`);
});
