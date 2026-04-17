const http = require("http");

const OLLAMA_HOST = process.env.OLLAMA_HOST || "host.docker.internal";
const OLLAMA_PORT = process.env.OLLAMA_PORT || "11434";
const LISTEN_PORT = process.env.LISTEN_PORT || "11435";

let requestCounter = 0;

const server = http.createServer((req, res) => {
  const id = ++requestCounter;
  const ts = new Date().toISOString();

  console.log(`\n${"=".repeat(80)}`);
  console.log(`[${ts}] REQUEST #${id} RECEIVED`);
  console.log(`  Method: ${req.method}`);
  console.log(`  URL: ${req.url}`);
  console.log(`  Headers: ${JSON.stringify(req.headers, null, 2)}`);

  // Collect request body
  const chunks = [];
  req.on("data", (chunk) => chunks.push(chunk));
  req.on("end", () => {
    const bodyRaw = Buffer.concat(chunks).toString();
    const bodyLen = bodyRaw.length;

    console.log(`  Body length: ${bodyLen} bytes`);

    // Parse and log the payload details
    try {
      const body = JSON.parse(bodyRaw);
      console.log(`  Model: ${body.model || "N/A"}`);
      console.log(`  Stream: ${body.stream}`);
      console.log(`  Options: ${JSON.stringify(body.options || {})}`);

      if (body.messages) {
        console.log(`  Messages count: ${body.messages.length}`);
        body.messages.forEach((msg, i) => {
          const contentLen =
            typeof msg.content === "string"
              ? msg.content.length
              : JSON.stringify(msg.content).length;
          console.log(
            `    [${i}] role=${msg.role}, content_length=${contentLen} chars`
          );
          if (msg.role === "system") {
            console.log(
              `    [${i}] SYSTEM PROMPT (first 500 chars):\n${String(msg.content).substring(0, 500)}`
            );
            console.log(
              `    [${i}] SYSTEM PROMPT (last 200 chars):\n...${String(msg.content).substring(Math.max(0, contentLen - 200))}`
            );
          }
        });
      }

      if (body.tools) {
        console.log(`  Tools count: ${body.tools.length}`);
        body.tools.forEach((tool, i) => {
          const name =
            tool.function?.name || tool.name || JSON.stringify(tool).slice(0, 60);
          console.log(`    [${i}] ${name}`);
        });
      }
    } catch (e) {
      console.log(`  Body (not JSON): ${bodyRaw.substring(0, 500)}`);
    }

    // Forward to Ollama
    console.log(
      `\n[${ts}] FORWARDING #${id} to ${OLLAMA_HOST}:${OLLAMA_PORT}${req.url}`
    );
    const forwardStart = Date.now();

    const proxyReq = http.request(
      {
        hostname: OLLAMA_HOST,
        port: parseInt(OLLAMA_PORT),
        path: req.url,
        method: req.method,
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(bodyRaw),
        },
        timeout: 300000, // 5 min
      },
      (proxyRes) => {
        const elapsed = Date.now() - forwardStart;
        console.log(
          `[${new Date().toISOString()}] OLLAMA RESPONSE #${id} status=${proxyRes.statusCode} (${elapsed}ms to first byte)`
        );

        // Collect full response
        const resChunks = [];
        proxyRes.on("data", (chunk) => {
          resChunks.push(chunk);
        });

        proxyRes.on("end", () => {
          const totalElapsed = Date.now() - forwardStart;
          const resBody = Buffer.concat(resChunks).toString();
          console.log(
            `[${new Date().toISOString()}] OLLAMA COMPLETE #${id} (${totalElapsed}ms total, ${resBody.length} bytes)`
          );
          console.log(
            `  Response preview: ${resBody.substring(0, 300)}`
          );
          console.log(`${"=".repeat(80)}\n`);

          res.writeHead(proxyRes.statusCode, proxyRes.headers);
          res.end(resBody);
        });
      }
    );

    proxyReq.on("error", (err) => {
      const elapsed = Date.now() - forwardStart;
      console.error(
        `[${new Date().toISOString()}] OLLAMA ERROR #${id} (${elapsed}ms): ${err.message}`
      );
      res.writeHead(502, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: err.message }));
    });

    proxyReq.on("timeout", () => {
      const elapsed = Date.now() - forwardStart;
      console.error(
        `[${new Date().toISOString()}] OLLAMA TIMEOUT #${id} (${elapsed}ms)`
      );
      proxyReq.destroy();
      res.writeHead(504, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Ollama request timed out" }));
    });

    proxyReq.write(bodyRaw);
    proxyReq.end();
  });
});

server.listen(parseInt(LISTEN_PORT), "0.0.0.0", () => {
  console.log(`\n${"*".repeat(80)}`);
  console.log(`  OLLAMA PROXY-SHIM listening on port ${LISTEN_PORT}`);
  console.log(`  Forwarding to ${OLLAMA_HOST}:${OLLAMA_PORT}`);
  console.log(`  Every request will be logged in full detail`);
  console.log(`${"*".repeat(80)}\n`);
});
