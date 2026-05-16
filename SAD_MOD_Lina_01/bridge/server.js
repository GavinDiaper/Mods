const express = require("express");

const app = express();
app.use(express.json({ limit: "1mb" }));

const PORT = Number(process.env.PORT || 8787);
const AZURE_ENDPOINT = String(process.env.AZURE_OPENAI_ENDPOINT || "").replace(/\/$/, "");
const AZURE_DEPLOYMENT = String(process.env.AZURE_OPENAI_DEPLOYMENT || "gpt-5-mini");
const AZURE_API_VERSION = String(process.env.AZURE_OPENAI_API_VERSION || "2025-01-01-preview");
const AZURE_KEY = String(process.env.AZURE_OPENAI_KEY || "");
const BRIDGE_TOKEN = String(process.env.BRIDGE_TOKEN || "");

function authOk(req) {
  if (!BRIDGE_TOKEN) return true;
  return req.header("x-lina-bridge-token") === BRIDGE_TOKEN;
}

app.get("/health", (_req, res) => {
  res.json({ ok: true, provider: "azure-openai", deployment: AZURE_DEPLOYMENT });
});

app.post("/v1/lina/chat", async (req, res) => {
  if (!authOk(req)) {
    return res.status(401).json({ error: "unauthorized" });
  }

  if (!AZURE_ENDPOINT || !AZURE_KEY) {
    return res.status(500).json({ error: "bridge_not_configured" });
  }

  const body = req.body || {};
  const deployment = typeof body.deployment === "string" && body.deployment ? body.deployment : AZURE_DEPLOYMENT;
  const apiVersion = typeof body.api_version === "string" && body.api_version ? body.api_version : AZURE_API_VERSION;

  const payload = {
    messages: Array.isArray(body.messages) ? body.messages : [],
    tools: Array.isArray(body.tools) ? body.tools : [],
    tool_choice: body.tool_choice || "required",
    max_completion_tokens: Number(body.max_completion_tokens || 500),
  };

  const url = `${AZURE_ENDPOINT}/openai/deployments/${encodeURIComponent(deployment)}/chat/completions?api-version=${encodeURIComponent(apiVersion)}`;

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": AZURE_KEY,
      },
      body: JSON.stringify(payload),
    });

    const text = await response.text();
    res.status(response.status);
    res.type("application/json");
    return res.send(text);
  } catch (error) {
    return res.status(502).json({ error: "bridge_upstream_failed", detail: String(error && error.message || error) });
  }
});

app.listen(PORT, "127.0.0.1", () => {
  console.log(`[ModLina-Bridge] listening on http://127.0.0.1:${PORT}`);
});
