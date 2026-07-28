/**
 * smoke-test.mjs
 *
 * Light-weight Smoke Test Suite — Student Diwan
 *
 * Verifies the absolute minimum criteria for app operation:
 *   1. Express application server boots up
 *   2. Base HTML template resolves on `/`
 *   3. Health check API endpoint is live (`/api/health`)
 *   4. Authentication API is responsive (`/api/session/login`)
 *   5. API auth guard blocks unauthenticated data requests (`/api/data/students` -> 401)
 */

import { spawn, execSync } from "child_process";
import { existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_DIR = join(__dirname, "..");
const PORT = 5403;
const BASE_URL = `http://localhost:${PORT}`;

const C = {
  reset: "\x1b[0m", bold: "\x1b[1m",
  green: "\x1b[32m", red: "\x1b[31m", cyan: "\x1b[36m", gray: "\x1b[90m"
};

let serverProc = null;
const checks = [];

function record(name, pass, note) {
  const icon = pass ? `${C.green}✓ PASS${C.reset}` : `${C.red}✗ FAIL${C.reset}`;
  console.log(`  ${icon}  ${name}`);
  if (note) console.log(`         ${C.gray}${note}${C.reset}`);
  checks.push({ name, pass, note });
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function startServer() {
  serverProc = spawn("node", ["dist/server.js"], {
    cwd: PROJECT_DIR,
    env: { ...process.env, PORT: String(PORT), DB_HOST: "", DATABASE_URL: "", DB_STRICT: "false", NODE_ENV: "production" },
    stdio: ["ignore", "pipe", "pipe"],
  });

  const deadline = Date.now() + 15000;
  while (Date.now() < deadline) {
    try {
      const r = await fetch(`${BASE_URL}/api/health`, { signal: AbortSignal.timeout(1000) });
      if (r.status === 200 || r.status === 503) {
        return true;
      }
    } catch {}
    await sleep(250);
  }
  return false;
}

function stopServer() {
  if (!serverProc) return;
  const pid = serverProc.pid;
  serverProc.removeAllListeners();
  if (process.platform === "win32" && pid) {
    try { execSync(`taskkill /F /T /PID ${pid}`, { stdio: "pipe" }); } catch {}
  } else {
    serverProc.kill("SIGTERM");
  }
  serverProc = null;
}

async function runSmokeTests() {
  console.log(`\n${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.bold}  Application Smoke Test Suite${C.reset}`);
  console.log(`  Student Diwan — School Management System`);
  console.log(`${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.gray}  Target: Server running on port ${PORT}${C.reset}`);

  // 1. Filesystem check
  const buildExists = existsSync(join(PROJECT_DIR, "dist", "server.js"));
  record("Production build assets present in dist/", buildExists, buildExists ? "Found dist/server.js" : "Missing dist/server.js - please run npm run build");

  if (!buildExists) {
    console.log(`\n${C.red}Build assets missing. Aborting smoke test.${C.reset}`);
    process.exit(1);
  }

  // 2. Server Startup check
  console.log("\n  Starting application server...");
  const serverStarted = await startServer();
  record("Server starts and responds to HTTP requests", serverStarted, serverStarted ? "Server is healthy and listening" : "Server failed to start within timeout");

  if (!serverStarted) {
    stopServer();
    process.exit(1);
  }

  // 3. Health Check API
  try {
    const r = await fetch(`${BASE_URL}/api/health`);
    const data = await r.json();
    const hasDbMode = data && typeof data.dbMode === "string";
    record("API health endpoint responds with database mode", r.ok && hasDbMode, r.ok ? `HTTP ${r.status} (mode: ${data.dbMode})` : `Failed with status ${r.status}`);
  } catch (e) {
    record("API health endpoint responds with database mode", false, e.message);
  }

  // 4. Base HTML Resolve
  try {
    const r = await fetch(`${BASE_URL}/`);
    const html = await r.text();
    const isSPA = r.ok && html.includes("<title>") && html.includes("id=\"root\"");
    record("Server serves React Single Page Application (SPA) index", isSPA, r.ok ? `HTTP ${r.status}` : `Failed with status ${r.status}`);
  } catch (e) {
    record("Server serves React Single Page Application (SPA) index", false, e.message);
  }

  // 5. Auth API and Protection
  try {
    // Session API responsive
    const authPayload = { email: "abishsuresh01@gmail.com", password: "admin" };
    const r = await fetch(`${BASE_URL}/api/session/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(authPayload)
    });
    const authData = await r.json();
    const hasToken = r.ok && !!authData.token;
    record("Authentication endpoint is live and accepts login payload", hasToken, r.ok ? "Success (token received)" : `Failed: ${JSON.stringify(authData)}`);

    // Guard works
    const guardResponse = await fetch(`${BASE_URL}/api/data/students`);
    const isBlocked = guardResponse.status === 401;
    record("API auth guard blocks unauthenticated data queries", isBlocked, `Unauthenticated request returned status: ${guardResponse.status} (expected 401)`);

  } catch (e) {
    record("Authentication endpoints live and protected", false, e.message);
  }

  stopServer();

  // Summary
  const passed = checks.filter(c => c.pass).length;
  const failed = checks.length - passed;

  console.log(`\n${"─".repeat(62)}`);
  const rc = failed === 0 ? C.green : C.red;
  console.log(`${rc}${C.bold}  ${passed}/${checks.length} smoke checks passed  |  ${failed} failed${C.reset}`);
  if (failed === 0) {
    console.log(`${C.green}${C.bold}  ✓ SYSTEM IS SMOKE-TEST CLEAN AND READY${C.reset}\n`);
    process.exit(0);
  } else {
    console.log(`${C.red}${C.bold}  ✗ SMOKE TEST FAILED — Core services are degraded${C.reset}\n`);
    process.exit(1);
  }
}

runSmokeTests().catch(err => {
  stopServer();
  console.error("Fatal:", err.message);
  process.exit(1);
});
