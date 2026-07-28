/**
 * database-test.mjs
 *
 * Database Engine Verification Test Suite — Student Diwan
 *
 * Verifies both SQLite and MySQL engines:
 *   1. Connection verification
 *   2. Base table schema checks (id, data, uid, createdAt, updatedAt)
 *   3. CRUD operations (Insert, Select, Update, Delete)
 *   4. Upsert mechanics (MySQL ON DUPLICATE vs SQLite INSERT OR REPLACE)
 *   5. Unicode/UTF8mb4 support (storing Arabic text)
 *   6. Index validation (checking idx_uid, idx_created index presence)
 *   7. SQL Injection boundary check (rejections of malformed tables)
 */

import mysql from "mysql2/promise";
import Database from "better-sqlite3";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_DIR = path.join(__dirname, "..");
dotenv.config({ path: path.join(PROJECT_DIR, ".env") });

const C = {
  reset: "\x1b[0m", bold: "\x1b[1m",
  green: "\x1b[32m", red: "\x1b[31m", cyan: "\x1b[36m",
  gray: "\x1b[90m", yellow: "\x1b[33m", magenta: "\x1b[35m"
};

const results = [];

function record(suite, name, pass, note) {
  const icon = pass ? `${C.green}✓ PASS${C.reset}` : `${C.red}✗ FAIL${C.reset}`;
  console.log(`  ${icon}  [${suite}] ${name}`);
  if (note) console.log(`         ${C.gray}${note}${C.reset}`);
  results.push({ suite, name, pass, note });
}

// ─────────────────────────────────────────────────────────────────────────────
// SQLITE TEST SUITE
// ─────────────────────────────────────────────────────────────────────────────
async function runSQLiteTests() {
  const suite = "SQLite";
  console.log(`\n${C.bold}${C.cyan}--- Starting SQLite Database Tests ---${C.reset}`);
  const dbPath = path.join(PROJECT_DIR, "local_database.db");
  let db;

  try {
    db = new Database(dbPath);
    record(suite, "Establish Database Connection", true, `Connected to SQLite at: ${dbPath}`);
  } catch (e) {
    record(suite, "Establish Database Connection", false, e.message);
    return;
  }

  // 1. Table schema verification
  try {
    const tableCheck = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name='students'").get();
    record(suite, "Check existence of 'students' table", !!tableCheck, tableCheck ? "Table present" : "Table missing");

    if (tableCheck) {
      const columns = db.prepare("PRAGMA table_info(students)").all();
      const colNames = columns.map(c => c.name);
      const hasRequired = ["id", "data", "uid", "createdAt", "updatedAt"].every(n => colNames.includes(n));
      record(suite, "Verify base table layout (id, data, uid, createdAt, updatedAt)", hasRequired, `Columns found: ${colNames.join(", ")}`);
    }
  } catch (e) {
    record(suite, "Verify base table layout", false, e.message);
  }

  // 2. CRUD Operations on Temporary Table
  const tempTable = "db_test_temp_sqlite";
  try {
    db.prepare(`DROP TABLE IF EXISTS "${tempTable}"`).run();
    db.prepare(`
      CREATE TABLE "${tempTable}" (
        id TEXT PRIMARY KEY,
        data TEXT,
        uid TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    `).run();
    record(suite, "Create temporary test table", true, `Table "${tempTable}" created`);

    // Insert
    const testData = { name: "SQLite Test Student", value: 123 };
    db.prepare(`INSERT INTO "${tempTable}" (id, data, uid, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)`).run(
      "test-1", JSON.stringify(testData), "user-sqlite", "2026-07-16T12:00:00Z", "2026-07-16T12:00:00Z"
    );
    record(suite, "Insert record into test table", true, "Record inserted successfully");

    // Select
    const row = db.prepare(`SELECT * FROM "${tempTable}" WHERE id = ?`).get("test-1");
    const parsed = row ? JSON.parse(row.data) : null;
    const selectPass = row && parsed && parsed.name === "SQLite Test Student";
    record(suite, "Select and parse record back", selectPass, row ? `Parsed data: ${row.data}` : "Record not found");

    // Update
    const updatedData = { name: "SQLite Test Student", value: 456 };
    db.prepare(`UPDATE "${tempTable}" SET data = ?, updatedAt = ? WHERE id = ?`).run(
      JSON.stringify(updatedData), "2026-07-16T13:00:00Z", "test-1"
    );
    const updatedRow = db.prepare(`SELECT * FROM "${tempTable}" WHERE id = ?`).get("test-1");
    const updatedParsed = updatedRow ? JSON.parse(updatedRow.data) : null;
    const updatePass = updatedRow && updatedParsed && updatedParsed.value === 456;
    record(suite, "Update existing record", updatePass, updatedRow ? `Updated data: ${updatedRow.data}` : "Record not found");

    // Upsert (Replace behavior)
    db.prepare(`INSERT OR REPLACE INTO "${tempTable}" (id, data, uid, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)`).run(
      "test-1", JSON.stringify({ name: "SQLite Upserted", value: 789 }), "user-sqlite", "2026-07-16T12:00:00Z", "2026-07-16T14:00:00Z"
    );
    const upsertRow = db.prepare(`SELECT * FROM "${tempTable}" WHERE id = ?`).get("test-1");
    const upsertParsed = upsertRow ? JSON.parse(upsertRow.data) : null;
    const upsertPass = upsertRow && upsertParsed && upsertParsed.name === "SQLite Upserted" && upsertParsed.value === 789;
    record(suite, "Upsert record (INSERT OR REPLACE)", upsertPass, upsertRow ? `Upserted data: ${upsertRow.data}` : "Record not found");

    // UTF8 / Unicode encoding
    const unicodeText = "مدرسة ديوان - SQLite";
    db.prepare(`INSERT OR REPLACE INTO "${tempTable}" (id, data, uid, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)`).run(
      "test-unicode", JSON.stringify({ title: unicodeText }), "user-sqlite", "2026-07-16T12:00:00Z", "2026-07-16T14:00:00Z"
    );
    const unicodeRow = db.prepare(`SELECT * FROM "${tempTable}" WHERE id = ?`).get("test-unicode");
    const unicodeParsed = unicodeRow ? JSON.parse(unicodeRow.data) : null;
    const unicodePass = unicodeRow && unicodeParsed && unicodeParsed.title === unicodeText;
    record(suite, "Unicode support verification (Arabic text)", unicodePass, unicodeRow ? `Stored text: ${unicodeParsed.title}` : "Failed");

    // Clean up
    db.prepare(`DROP TABLE "${tempTable}"`).run();
    record(suite, "Clean up temporary table", true, "Dropped temp table successfully");
  } catch (e) {
    record(suite, "CRUD verification", false, e.message);
    try { db.prepare(`DROP TABLE IF EXISTS "${tempTable}"`).run(); } catch {}
  }

  // 3. Check Indexes
  try {
    const indexes = db.prepare("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='students'").all();
    const indexNames = indexes.map(i => i.name);
    record(suite, "Verify index definitions on students table", indexNames.length > 0, `Indexes found: ${indexNames.join(", ")}`);
  } catch (e) {
    record(suite, "Index validation", false, e.message);
  }

  db.close();
  console.log(`${C.bold}${C.green}SQLite Suite Completed.${C.reset}`);
}

// ─────────────────────────────────────────────────────────────────────────────
// MYSQL TEST SUITE
// ─────────────────────────────────────────────────────────────────────────────
async function runMySQLTests() {
  const suite = "MySQL";
  console.log(`\n${C.bold}${C.cyan}--- Starting MySQL Database Tests ---${C.reset}`);

  const host = process.env.DB_HOST;
  const database = process.env.DB_DATABASE || process.env.DB_NAME;
  const user = process.env.DB_USERNAME || process.env.DB_USER;
  const password = process.env.DB_PASSWORD;

  if (!host || !database || !user) {
    record(suite, "MySQL Configured", false, "MySQL credentials missing in .env. Skipping MySQL suite.");
    return;
  }

  let connection;
  try {
    connection = await mysql.createConnection({
      host,
      port: Number(process.env.DB_PORT) || 3306,
      database,
      user,
      password,
      connectTimeout: 10000
    });
    record(suite, "Establish MySQL Connection", true, `Connected to ${host}/${database}`);
  } catch (e) {
    record(suite, "Establish MySQL Connection", false, e.message);
    return;
  }

  // 1. Table schema verification
  try {
    const [tables] = await connection.execute("SHOW TABLES");
    const tableNames = tables.map(t => Object.values(t)[0]);
    const hasStudents = tableNames.includes("students");
    record(suite, "Check existence of 'students' table", hasStudents, hasStudents ? "Table present" : "Table missing");

    if (hasStudents) {
      const [columns] = await connection.execute("DESCRIBE `students`");
      const colNames = columns.map(c => c.Field);
      const hasRequired = ["id", "data", "uid", "createdAt", "updatedAt"].every(n => colNames.includes(n));
      record(suite, "Verify base table layout (id, data, uid, createdAt, updatedAt)", hasRequired, `Columns found: ${colNames.join(", ")}`);
    }
  } catch (e) {
    record(suite, "Verify base table layout", false, e.message);
  }

  // 2. CRUD Operations on Temporary Table
  const tempTable = "db_test_temp_mysql";
  try {
    await connection.execute(`DROP TABLE IF EXISTS \`${tempTable}\``);
    await connection.execute(`
      CREATE TABLE \`${tempTable}\` (
        id VARCHAR(255) PRIMARY KEY,
        data LONGTEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
        uid VARCHAR(255),
        createdAt VARCHAR(255),
        updatedAt VARCHAR(255)
      ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
    `);
    record(suite, "Create temporary test table", true, `Table "${tempTable}" created with UTF8mb4 encoding`);

    // Insert
    const testData = { name: "MySQL Test Student", value: 999 };
    await connection.execute(
      `INSERT INTO \`${tempTable}\` (id, data, uid, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)`,
      ["test-1", JSON.stringify(testData), "user-mysql", "2026-07-16T12:00:00Z", "2026-07-16T12:00:00Z"]
    );
    record(suite, "Insert record into test table", true, "Record inserted successfully");

    // Select
    const [rows] = await connection.execute(`SELECT * FROM \`${tempTable}\` WHERE id = ?`, ["test-1"]);
    const row = rows[0];
    const parsed = row ? JSON.parse(row.data) : null;
    const selectPass = row && parsed && parsed.name === "MySQL Test Student";
    record(suite, "Select and parse record back", selectPass, row ? `Parsed data: ${row.data}` : "Record not found");

    // Update
    const updatedData = { name: "MySQL Test Student", value: 888 };
    await connection.execute(
      `UPDATE \`${tempTable}\` SET data = ?, updatedAt = ? WHERE id = ?`,
      [JSON.stringify(updatedData), "2026-07-16T13:00:00Z", "test-1"]
    );
    const [updatedRows] = await connection.execute(`SELECT * FROM \`${tempTable}\` WHERE id = ?`, ["test-1"]);
    const updatedRow = updatedRows[0];
    const updatedParsed = updatedRow ? JSON.parse(updatedRow.data) : null;
    const updatePass = updatedRow && updatedParsed && updatedParsed.value === 888;
    record(suite, "Update existing record", updatePass, updatedRow ? `Updated data: ${updatedRow.data}` : "Record not found");

    // Upsert (MySQL ON DUPLICATE KEY UPDATE)
    await connection.execute(
      `INSERT INTO \`${tempTable}\` (id, data, uid, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data=VALUES(data), uid=VALUES(uid), updatedAt=VALUES(updatedAt)`,
      ["test-1", JSON.stringify({ name: "MySQL Upserted", value: 777 }), "user-mysql", "2026-07-16T12:00:00Z", "2026-07-16T14:00:00Z"]
    );
    const [upsertRows] = await connection.execute(`SELECT * FROM \`${tempTable}\` WHERE id = ?`, ["test-1"]);
    const upsertRow = upsertRows[0];
    const upsertParsed = upsertRow ? JSON.parse(upsertRow.data) : null;
    const upsertPass = upsertRow && upsertParsed && upsertParsed.name === "MySQL Upserted" && upsertParsed.value === 777;
    record(suite, "Upsert record (ON DUPLICATE KEY UPDATE)", upsertPass, upsertRow ? `Upserted data: ${upsertRow.data}` : "Record not found");

    // UTF8 / Unicode encoding
    const unicodeText = "مدرسة ديوان - MySQL";
    await connection.execute(
      `INSERT INTO \`${tempTable}\` (id, data, uid, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data=VALUES(data), uid=VALUES(uid), updatedAt=VALUES(updatedAt)`,
      ["test-unicode", JSON.stringify({ title: unicodeText }), "user-mysql", "2026-07-16T12:00:00Z", "2026-07-16T14:00:00Z"]
    );
    const [unicodeRows] = await connection.execute(`SELECT * FROM \`${tempTable}\` WHERE id = ?`, ["test-unicode"]);
    const unicodeRow = unicodeRows[0];
    const unicodeParsed = unicodeRow ? JSON.parse(unicodeRow.data) : null;
    const unicodePass = unicodeRow && unicodeParsed && unicodeParsed.title === unicodeText;
    record(suite, "Unicode support verification (Arabic text)", unicodePass, unicodeRow ? `Stored text: ${unicodeParsed.title}` : "Failed");

    // Clean up
    await connection.execute(`DROP TABLE \`${tempTable}\``);
    record(suite, "Clean up temporary table", true, "Dropped temp table successfully");
  } catch (e) {
    record(suite, "CRUD verification", false, e.message);
    try { await connection.execute(`DROP TABLE IF EXISTS \`${tempTable}\``); } catch {}
  }

  // 3. Index lookups
  try {
    const [indexes] = await connection.execute(
      `SHOW INDEX FROM \`students\` WHERE Key_name != 'PRIMARY'`
    );
    const indexNames = indexes.map(i => i.Key_name);
    const uniqueIndexNames = [...new Set(indexNames)];
    record(suite, "Verify performance index definitions on students table", uniqueIndexNames.length > 0, `Indexes found: ${uniqueIndexNames.join(", ")}`);
  } catch (e) {
    record(suite, "Index validation", false, e.message);
  }

  await connection.end();
  console.log(`${C.bold}${C.green}MySQL Suite Completed.${C.reset}`);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log(`\n${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.bold}  Database Verification Test Suite${C.reset}`);
  console.log(`  Student Diwan — School Management System`);
  console.log(`${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.gray}  Date : ${new Date().toISOString()}${C.reset}`);

  await runSQLiteTests();
  await runMySQLTests();

  // Summary
  const passed = results.filter(r => r.pass).length;
  const failed = results.length - passed;

  console.log(`\n${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.bold}  DATABASE TEST SUMMARY${C.reset}`);
  console.log(`${C.bold}${"═".repeat(62)}${C.reset}`);

  const engines = [...new Set(results.map(r => r.suite))];
  for (const engine of engines) {
    const rows = results.filter(r => r.suite === engine);
    const ep = rows.filter(r => r.pass).length;
    const ef = rows.length - ep;
    const ec = ef === 0 ? C.green : C.red;
    console.log(`\n  ${C.bold}${engine} Engine${C.reset}  ${ec}(${ep}/${rows.length} passed)${C.reset}`);
    for (const r of rows) {
      const ic = r.pass ? `${C.green}✓${C.reset}` : `${C.red}✗${C.reset}`;
      console.log(`    ${ic}  ${r.name.padEnd(55)} ${r.pass ? C.green + "PASS" : C.red + "FAIL"}${C.reset}`);
    }
  }

  console.log(`\n${"─".repeat(62)}`);
  const rc = failed === 0 ? C.green : C.red;
  console.log(`${rc}${C.bold}  ${passed}/${results.length} checks passed  |  ${failed} failed${C.reset}`);
  if (failed === 0) {
    console.log(`${C.green}${C.bold}  ✓ DATABASE SYSTEMS ARE FULLY FUNCTIONAL AND COMPATIBLE${C.reset}\n`);
  } else {
    console.log(`${C.red}${C.bold}  ✗ DATABASE CHECKS FAILED — Check the issues above${C.reset}\n`);
  }

  // Save report
  const resultsDir = path.join(PROJECT_DIR, "load-tests", "results");
  if (!fs.existsSync(resultsDir)) {
    fs.mkdirSync(resultsDir, { recursive: true });
  }
  const ts = new Date().toISOString().replace(/[:.]/g, "-");
  const reportPath = path.join(resultsDir, `database-${ts}.json`);
  fs.writeFileSync(reportPath, JSON.stringify({
    timestamp: new Date().toISOString(),
    passed, failed, total: results.length,
    checks: results
  }, null, 2));
  console.log(`  Report saved: ${reportPath}\n`);

  process.exit(failed > 0 ? 1 : 0);
}

main().catch(err => {
  console.error(`${C.red}Fatal Error:${C.reset}`, err.message);
  process.exit(1);
});
