/**
 * sanity-test.mjs
 *
 * Sanity Test Suite — Student Diwan
 *
 * Specifically verifies regions touched by recent updates:
 *   1. Database Isolation (custom SQLITE DB file overriding)
 *   2. Authentication Security Fixes (rejections of incorrect passwords)
 *   3. Graceful SIGTERM Shutdown behavior
 */

import { spawn, execSync } from "child_process";
import { existsSync, unlinkSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const PROJECT_DIR = join(__dirname, "..");
const PORT = 5404;
const BASE_URL = `http://localhost:${PORT}`;

const C = {
  reset: "\x1b[0m", bold: "\x1b[1m",
  green: "\x1b[32m", red: "\x1b[31m", cyan: "\x1b[36m", gray: "\x1b[90m"
};

const checks = [];
let serverProc = null;

function record(name, pass, note) {
  const icon = pass ? `${C.green}✓ PASS${C.reset}` : `${C.red}✗ FAIL${C.reset}`;
  console.log(`  ${icon}  ${name}`);
  if (note) console.log(`         ${C.gray}${note}${C.reset}`);
  checks.push({ name, pass, note });
}

function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function startServer(envOverrides = {}) {
  serverProc = spawn("node", ["dist/server.js"], {
    cwd: PROJECT_DIR,
    env: {
      ...process.env,
      PORT: String(PORT),
      DB_HOST: "",
      DATABASE_URL: "",
      DB_STRICT: "false",
      NODE_ENV: "production",
      ...envOverrides
    },
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

async function runSanityTests() {
  console.log(`\n${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.bold}  Application Sanity & Regression Suite${C.reset}`);
  console.log(`  Student Diwan — School Management System`);
  console.log(`${C.bold}${"═".repeat(62)}${C.reset}`);

  // Test 1: Database Path Override
  const customDbPath = join(PROJECT_DIR, "load-tests", "sanity_temp_db.db");
  try {
    if (existsSync(customDbPath)) unlinkSync(customDbPath);
  } catch {}

  console.log("\n  [1/3] Testing database isolation & custom path routing...");
  const customStarted = await startServer({ DATABASE_PATH: customDbPath });
  const dbCreated = existsSync(customDbPath);
  
  record("Server respects custom DATABASE_PATH and instantiates database file",
    customStarted && dbCreated,
    dbCreated ? `Database file created at: ${customDbPath}` : "Database file was not created"
  );
  stopServer();

  try {
    if (existsSync(customDbPath)) unlinkSync(customDbPath);
  } catch {}

  // Test 2: Authentication Security & Wrong Password Lockout
  console.log("\n  [2/3] Testing authentication validations & security fixes...");
  await startServer();

  try {
    // Test 2a: Wrong password rejection
    const wrongCredsResponse = await fetch(`${BASE_URL}/api/session/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "admin@eduerp.com", password: "definitely_wrong_password" })
    });
    record("Incorrect password for local mock users is rejected (401)",
      wrongCredsResponse.status === 401,
      `HTTP status returned: ${wrongCredsResponse.status} (expected 401)`
    );

    // Test 2b: Empty password rejection
    const emptyPasswordResponse = await fetch(`${BASE_URL}/api/session/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "admin@eduerp.com", password: "" })
    });
    record("Empty password input is blocked (400 or 401 or 429 if rate limited)",
      emptyPasswordResponse.status === 401 || emptyPasswordResponse.status === 400 || emptyPasswordResponse.status === 429,
      `HTTP status returned: ${emptyPasswordResponse.status}`
    );
  } catch (e) {
    record("Authentication security checks", false, e.message);
  }

  // Test 3: Graceful Shutdown
  console.log("\n  [3/3] Testing server graceful shutdown mechanics...");
  const t0 = Date.now();
  stopServer();
  await sleep(2000);

  let portFree = false;
  try {
    await fetch(`${BASE_URL}/api/health`, { signal: AbortSignal.timeout(500) });
  } catch {
    portFree = true;
  }
  const shutdownMs = Date.now() - t0;

  record("Server exits cleanly on SIGTERM freeing port 5404",
    portFree,
    portFree ? `Stopped cleanly in ~${shutdownMs}ms` : "Server failed to exit / port still occupied"
  );

  // Summary
  const passed = checks.filter(c => c.pass).length;
  const failed = checks.length - passed;

  console.log(`\n${"─".repeat(62)}`);
  const rc = failed === 0 ? C.green : C.red;
  console.log(`${rc}${C.bold}  ${passed}/${checks.length} sanity checks passed  |  ${failed} failed${C.reset}`);
  if (failed === 0) {
    console.log(`${C.green}${C.bold}  ✓ SYSTEM SANITY CHECKS COMPLETE — NO REGRESSIONS DEVIATIONS DETECTED${C.reset}\n`);
    process.exit(0);
  } else {
    console.log(`${C.red}${C.bold}  ✗ SANITY CHECKS FAILED — Regression detected in core fixes${C.reset}\n`);
    process.exit(1);
  }
}

runSanityTests().catch(err => {
  stopServer();
  console.error("Fatal:", err.message);
  process.exit(1);
});
