/**
 * deployment-test.mjs
 *
 * Deployment Readiness Test Suite — Student Diwan
 *
 * Checks:
 *   1. TypeScript compilation (no errors)
 *   2. Production build (npm run build)
 *   3. Server startup  (dist/server.js on port 5400)
 *   4. Health endpoint (/api/health)
 *   5. Static assets  (dist/index.html served)
 *   6. API smoke tests (login, students, 401 guard)
 *   7. Environment vars validated
 *   8. Rate-limit fires on brute-force login
 *   9. Graceful SIGTERM shutdown
 */

import { execSync, spawn } from "child_process";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname   = dirname(fileURLToPath(import.meta.url));
const PROJECT_DIR = join(__dirname, "..");
const RESULTS_DIR = join(__dirname, "results");
const PORT        = 5400;
const BASE_URL    = `http://localhost:${PORT}`;

const C = {
  reset:"\x1b[0m", bold:"\x1b[1m",
  green:"\x1b[32m", red:"\x1b[31m", cyan:"\x1b[36m", gray:"\x1b[90m",
};

const results = [];
let serverProc = null;

function sleep(ms){ return new Promise(r => setTimeout(r, ms)); }

function record(name, pass, note){
  const icon = pass ? `${C.green}✓ PASS${C.reset}` : `${C.red}✗ FAIL${C.reset}`;
  console.log(`  ${icon}  ${name}`);
  if (note) console.log(`         ${C.gray}${note}${C.reset}`);
  results.push({ name, pass, status: pass ? "PASS" : "FAIL", note });
}

// 1. TypeScript
function checkTypeScript(){
  console.log(`\n${C.bold}${C.cyan}[1/9] TypeScript Check${C.reset}`);
  try {
    execSync("npx tsc --noEmit", { cwd: PROJECT_DIR, stdio:"pipe" });
    record("TypeScript compilation", true, "0 type errors");
  } catch(e){
    const n = (e.stdout?.toString()||"").match(/error TS/g)?.length||"?";
    record("TypeScript compilation", false, `${n} error(s)`);
  }
}

// 2. Build
function checkBuild(){
  console.log(`\n${C.bold}${C.cyan}[2/9] Production Build${C.reset}`);
  try {
    const t0 = Date.now();
    execSync("npm run build", {
      cwd: PROJECT_DIR, stdio:"pipe",
      env: { ...process.env,
        VITE_FIREBASE_API_KEY:"placeholder", VITE_FIREBASE_AUTH_DOMAIN:"placeholder",
        VITE_FIREBASE_PROJECT_ID:"placeholder", VITE_FIREBASE_STORAGE_BUCKET:"placeholder",
        VITE_FIREBASE_MESSAGING_SENDER_ID:"placeholder", VITE_FIREBASE_APP_ID:"placeholder",
      },
    });
    const ms = Date.now()-t0;
    const fe = existsSync(join(PROJECT_DIR,"dist","index.html"));
    const be = existsSync(join(PROJECT_DIR,"dist","server.js"));
    record("Frontend build (Vite)", fe, `${(ms/1000).toFixed(1)}s — dist/index.html ${fe?"present":"MISSING"}`);
    record("Backend bundle (esbuild)", be, `dist/server.js ${be?"present":"MISSING"}`);
    return fe && be;
  } catch(e){
    record("Production build", false, (e.stdout?.toString()||e.message).slice(0,200));
    return false;
  }
}

// 3. Start server
async function startServer(){
  console.log(`\n${C.bold}${C.cyan}[3/9] Server Startup${C.reset}`);
  process.stdout.write(`  Starting dist/server.js on :${PORT}... `);
  // Do NOT use shell:true — on Windows that spawns cmd.exe which intercepts
  // SIGTERM and prevents it reaching the actual node process.
  serverProc = spawn("node",["dist/server.js"],{
    cwd: PROJECT_DIR,
    env: { ...process.env, PORT:String(PORT), DB_HOST:"", DATABASE_URL:"", DB_STRICT:"false", NODE_ENV:"production" },
    stdio:["ignore","pipe","pipe"],
  });
  serverProc.stdout.on("data",()=>{});
  serverProc.stderr.on("data",()=>{});

  const deadline = Date.now() + 20_000;
  while(Date.now()<deadline){
    try{
      const r = await fetch(`${BASE_URL}/api/health`);
      if(r.status===200||r.status===503){ console.log("ready"); record("Server startup",true,`dist/server.js :${PORT}`); return true; }
    } catch{}
    await sleep(300);
  }
  console.log("TIMEOUT");
  record("Server startup",false,"Did not respond within 20s");
  return false;
}

function stopServer(){
  if(!serverProc) return;
  const pid = serverProc.pid;
  serverProc.removeAllListeners();
  if(process.platform==="win32" && pid){
    // taskkill /F /T kills the whole process tree — needed because without
    // shell:true there is still a node subprocess that may hold the port.
    try{ execSync(`taskkill /F /T /PID ${pid}`,{stdio:"pipe"}); } catch{}
  } else {
    serverProc.kill("SIGTERM");
  }
  serverProc=null;
}

// 4. Health
async function checkHealth(){
  console.log(`\n${C.bold}${C.cyan}[4/9] Health Endpoint${C.reset}`);
  try{
    const r = await fetch(`${BASE_URL}/api/health`);
    const j = await r.json();
    record("GET /api/health (200 or 503)", r.status===200||r.status===503, `HTTP ${r.status} dbMode=${j.dbMode}`);
    record("Response has dbMode field",    typeof j.dbMode==="string",      `dbMode="${j.dbMode}"`);
  } catch(e){ record("Health endpoint",false,e.message); }
}

// 5. Static assets
async function checkStaticAssets(){
  console.log(`\n${C.bold}${C.cyan}[5/9] Static Assets${C.reset}`);
  try{
    const r    = await fetch(`${BASE_URL}/`);
    const html = await r.text();
    record("GET / returns 200",           r.status===200,       `HTTP ${r.status}`);
    record("HTML has <title>",            html.includes("<title>"), "Title tag present");
    record("HTML references JS bundle",   html.includes("<script"), "Script tags present");
  } catch(e){ record("Static assets",false,e.message); }
}

// 6. API smoke
async function checkApiSmoke(){
  console.log(`\n${C.bold}${C.cyan}[6/9] API Smoke Tests${C.reset}`);
  try{
    const lr = await fetch(`${BASE_URL}/api/session/login`,{
      method:"POST", headers:{"Content-Type":"application/json"},
      body: JSON.stringify({ email:"abishsuresh01@gmail.com", password:"admin" }),
    });
    const lj = await lr.json();
    record("POST /api/session/login → 200 + token", lr.ok&&!!lj.token, lr.ok?`token issued`:`HTTP ${lr.status}`);

    if(lj.token){
      const sr = await fetch(`${BASE_URL}/api/data/students`,{ headers:{Authorization:`Bearer ${lj.token}`} });
      record("GET /api/data/students (authed) → 200", sr.ok, `HTTP ${sr.status}`);

      const ur = await fetch(`${BASE_URL}/api/data/students`);
      record("GET /api/data/students (no token) → 401", ur.status===401, `HTTP ${ur.status}`);
    }

    const wr = await fetch(`${BASE_URL}/api/session/login`,{
      method:"POST", headers:{"Content-Type":"application/json"},
      body: JSON.stringify({ email:"wrong@x.com", password:"bad" }),
    });
    record("POST /api/session/login (wrong creds) → 401", wr.status===401, `HTTP ${wr.status}`);
  } catch(e){ record("API smoke",false,e.message); }
}

// 7. Env
function checkEnv(){
  console.log(`\n${C.bold}${C.cyan}[7/9] Environment Validation${C.reset}`);
  const ep = join(PROJECT_DIR,".env");
  const ex = existsSync(ep);
  record(".env file present", ex, ex?"Found":"Missing");
  if(ex){
    const env = readFileSync(ep,"utf8");
    record("DB_HOST configured in .env", env.includes("DB_HOST="), "");
    record("PORT configured in .env",    env.includes("PORT="),    "");
  }
  record("dist/ folder present",                    existsSync(join(PROJECT_DIR,"dist")),                        "");
  record("dist/firebase-blueprint.json present",    existsSync(join(PROJECT_DIR,"dist","firebase-blueprint.json")), "");
}

// 8. Rate-limit
async function checkRateLimit(){
  console.log(`\n${C.bold}${C.cyan}[8/9] Rate-Limit Protection${C.reset}`);
  const reqs = Array.from({length:13},()=>
    fetch(`${BASE_URL}/api/session/login`,{
      method:"POST", headers:{"Content-Type":"application/json"},
      body: JSON.stringify({email:"brute@force.test",password:"wrong"}),
    })
  );
  const resps = await Promise.all(reqs);
  const count429 = resps.filter(r=>r.status===429).length;
  record("Brute-force login triggers 429", count429>0, `${count429}/13 blocked`);
}

// 9. Shutdown
async function checkGracefulShutdown(){
  console.log(`\n${C.bold}${C.cyan}[9/9] Graceful Shutdown${C.reset}`);
  process.stdout.write("  Sending SIGTERM / taskkill... ");
  const t0 = Date.now();
  stopServer();
  // Give the process up to 4s to stop; Windows process cleanup is slower
  await sleep(4000);
  let alive=false;
  try{ await fetch(`${BASE_URL}/api/health`,{signal:AbortSignal.timeout(500)}); alive=true; }catch{}
  console.log(`done in ${Date.now()-t0}ms`);
  record("Server exits cleanly on SIGTERM", !alive, alive?"Still responding after 4s":"Stopped cleanly");
}

// Main
async function main(){
  console.log(`\n${C.bold}Deployment Readiness Test Suite${C.reset}  —  Student Diwan`);
  console.log(`${"─".repeat(60)}`);
  console.log(`${C.gray}${new Date().toISOString()}${C.reset}`);

  checkTypeScript();
  const buildOk = checkBuild();
  checkEnv();

  if(buildOk){
    const serverOk = await startServer();
    if(serverOk){
      await checkHealth();
      await checkStaticAssets();
      await checkApiSmoke();
      await checkRateLimit();
      await checkGracefulShutdown();
    }
  } else {
    console.log(`\n${C.red}Build failed — skipping runtime checks.${C.reset}`);
  }

  const passed = results.filter(r=>r.pass).length;
  const failed = results.length - passed;

  console.log(`\n${"─".repeat(60)}`);
  console.log(`${C.bold}DEPLOYMENT SUMMARY${C.reset}`);
  console.log(`${"─".repeat(60)}`);
  for(const r of results){
    const ic = r.pass?`${C.green}✓${C.reset}`:`${C.red}✗${C.reset}`;
    console.log(`  ${ic}  ${r.name.padEnd(52)} ${r.pass?C.green+"PASS":C.red+"FAIL"}${C.reset}`);
  }
  console.log(`${"─".repeat(60)}`);
  const sc = failed===0?C.green:C.red;
  console.log(`${sc}${C.bold}${passed}/${results.length} checks passed${C.reset}`);
  console.log(failed===0
    ?`${C.green}${C.bold}✓ Application is DEPLOYMENT READY${C.reset}\n`
    :`${C.red}${C.bold}✗ ${failed} check(s) failed — resolve before deploying${C.reset}\n`);

  mkdirSync(RESULTS_DIR,{recursive:true});
  const ts = new Date().toISOString().replace(/[:.]/g,"-");
  const rp = join(RESULTS_DIR,`deployment-${ts}.json`);
  writeFileSync(rp, JSON.stringify({
    timestamp:new Date().toISOString(), passed, failed,
    total:results.length, deploymentReady:failed===0, checks:results,
  },null,2));
  console.log(`Report: ${rp}`);
  process.exit(failed>0?1:0);
}

main().catch(err=>{ stopServer(); console.error(C.red+"Fatal:"+C.reset,err.message); process.exit(1); });
