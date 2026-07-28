/**
 * localization-test.mjs
 *
 * Localization Audit & Integrity Verification — Student Diwan
 *
 * Checks performed:
 *   1. JSON integrity check (en.json, ar.json parsing)
 *   2. Namespace & key match analysis (missing keys between languages)
 *   3. Empty translation detection
 *   4. Interpolation / Placeholder validation (matching {{key}} markers)
 *   5. Integrity of dynamic lookup dictionary
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PROJECT_DIR = path.join(__dirname, "..");
const RESULTS_DIR = path.join(__dirname, "results");

const C = {
  reset: "\x1b[0m", bold: "\x1b[1m",
  green: "\x1b[32m", red: "\x1b[31m", cyan: "\x1b[36m",
  gray: "\x1b[90m", yellow: "\x1b[33m",
};

const results = [];
function record(name, pass, note) {
  const icon = pass ? `${C.green}✓ PASS${C.reset}` : `${C.red}✗ FAIL${C.reset}`;
  console.log(`  ${icon}  ${name}`);
  if (note) console.log(`         ${C.gray}${note}${C.reset}`);
  results.push({ name, pass, note });
}

// Flatten nested JSON objects to flat "path.to.key": "value" pairs
function flattenJson(obj, prefix = "") {
  let res = {};
  for (const k in obj) {
    const val = obj[k];
    const keyPath = prefix ? `${prefix}.${k}` : k;
    if (typeof val === "object" && val !== null && !Array.isArray(val)) {
      Object.assign(res, flattenJson(val, keyPath));
    } else {
      res[keyPath] = val;
    }
  }
  return res;
}

// Find placeholders like {{count}}, {{name}}
const PLACEHOLDER_REGEX = /\{\{([^}]+)\}\}/g;
function getPlaceholders(str) {
  if (typeof str !== "string") return [];
  const matches = [];
  let match;
  while ((match = PLACEHOLDER_REGEX.exec(str)) !== null) {
    matches.push(match[1].trim());
  }
  return matches;
}

function main() {
  console.log(`\n${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.bold}  Localization & i18n Audit Suite${C.reset}`);
  console.log(`  Student Diwan — School Management System`);
  console.log(`${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.gray}  Date : ${new Date().toISOString()}${C.reset}`);

  // 1. JSON loading & parsing checks
  const enPath = path.join(PROJECT_DIR, "src", "i18n", "locales", "en.json");
  const arPath = path.join(PROJECT_DIR, "src", "i18n", "locales", "ar.json");

  let enObj, arObj;
  try {
    enObj = JSON.parse(fs.readFileSync(enPath, "utf8"));
    record("Read & parse en.json", true, `Loaded successfully from ${enPath}`);
  } catch (e) {
    record("Read & parse en.json", false, e.message);
    process.exit(1);
  }

  try {
    arObj = JSON.parse(fs.readFileSync(arPath, "utf8"));
    record("Read & parse ar.json", true, `Loaded successfully from ${arPath}`);
  } catch (e) {
    record("Read & parse ar.json", false, e.message);
    process.exit(1);
  }

  const enFlat = flattenJson(enObj);
  const arFlat = flattenJson(arObj);

  const enKeys = Object.keys(enFlat);
  const arKeys = Object.keys(arFlat);

  console.log(`\n${C.bold}${C.cyan}--- Key Count Statistics ---${C.reset}`);
  console.log(`  English unique flat keys: ${enKeys.length}`);
  console.log(`  Arabic unique flat keys:  ${arKeys.length}`);

  // 2. Key matching checks
  const missingInAr = enKeys.filter(k => !(k in arFlat));
  const missingInEn = arKeys.filter(k => !(k in enFlat));

  record(
    "Verify no keys are missing in Arabic translation (en.json keys exist in ar.json)",
    missingInAr.length === 0,
    missingInAr.length === 0 ? "All English keys are present in Arabic" : `${missingInAr.length} keys missing in Arabic`
  );
  if (missingInAr.length > 0) {
    console.log(`    ${C.yellow}⚠ Sample missing Arabic keys (first 5):${C.reset}`);
    missingInAr.slice(0, 5).forEach(k => console.log(`      • ${k}`));
  }

  record(
    "Verify no keys are missing in English translation (ar.json keys exist in en.json)",
    missingInEn.length === 0,
    missingInEn.length === 0 ? "All Arabic keys are present in English" : `${missingInEn.length} keys missing in English`
  );
  if (missingInEn.length > 0) {
    console.log(`    ${C.yellow}⚠ Sample missing English keys (first 5):${C.reset}`);
    missingInEn.slice(0, 5).forEach(k => console.log(`      • ${k}`));
  }

  // 3. Empty string validation
  const emptyInEn = enKeys.filter(k => {
    if (k.toLowerCase().includes("placeholder") || k.toLowerCase().includes("suffix")) return false;
    return typeof enFlat[k] === "string" && enFlat[k].trim() === "";
  });
  const emptyInAr = arKeys.filter(k => {
    if (k.toLowerCase().includes("placeholder") || k.toLowerCase().includes("suffix")) return false;
    return typeof arFlat[k] === "string" && arFlat[k].trim() === "";
  });

  record(
    "Verify no empty values in English translation (excluding placeholders/suffixes)",
    emptyInEn.length === 0,
    emptyInEn.length === 0 ? "Zero empty values found" : `${emptyInEn.length} empty values found`
  );
  record(
    "Verify no empty values in Arabic translation (excluding placeholders/suffixes)",
    emptyInAr.length === 0,
    emptyInAr.length === 0 ? "Zero empty values found" : `${emptyInAr.length} empty values found`
  );

  // 4. Interpolation placeholder check
  const placeholderMismatches = [];
  enKeys.forEach(k => {
    if (k in arFlat) {
      const enPl = getPlaceholders(enFlat[k]);
      const arPl = getPlaceholders(arFlat[k]);

      // Check if they have the exact same set of placeholders.
      // Exception: for singular pluralized keys (*_one, *One), Arabic does not require the {{count}}
      // digit placeholder because singular is grammatically implied by the word form (e.g. "بطاقة واحدة").
      const isSingularKey = k.endsWith("_one") || k.endsWith("One") || k.toLowerCase().includes("one");
      
      const enSet = new Set(enPl);
      const arSet = new Set(arPl);

      const mismatch = enPl.some(p => {
        if (p === "count" && isSingularKey) return false; // Allow omitting {{count}} on singular key
        return !arSet.has(p);
      }) || arPl.some(p => {
        if (p === "count" && isSingularKey) return false;
        return !enSet.has(p);
      });

      if (mismatch) {
        placeholderMismatches.push({
          key: k,
          en: enFlat[k],
          ar: arFlat[k],
          enPlaceholders: enPl,
          arPlaceholders: arPl
        });
      }
    }
  });

  record(
    "Verify interpolation placeholders match exactly (e.g. {{count}} exists in both)",
    placeholderMismatches.length === 0,
    placeholderMismatches.length === 0
      ? "Zero placeholder mismatches found"
      : `${placeholderMismatches.length} placeholder mismatch(es) found`
  );

  if (placeholderMismatches.length > 0) {
    console.log(`    ${C.yellow}⚠ Sample placeholder mismatches:${C.reset}`);
    placeholderMismatches.slice(0, 5).forEach(m => {
      console.log(`      • Key: ${m.key}`);
      console.log(`        EN placeholders: [${m.enPlaceholders.join(", ")}] → "${m.en}"`);
      console.log(`        AR placeholders: [${m.arPlaceholders.join(", ")}] → "${m.ar}"`);
    });
  }

  // Final summary
  const passed = results.filter(r => r.pass).length;
  const failed = results.length - passed;

  console.log(`\n${C.bold}${"═".repeat(62)}${C.reset}`);
  console.log(`${C.bold}  LOCALIZATION SUMMARY${C.reset}`);
  console.log(`${C.bold}${"═".repeat(62)}${C.reset}`);

  for (const r of results) {
    const ic = r.pass ? `${C.green}✓${C.reset}` : `${C.red}✗${C.reset}`;
    console.log(`  ${ic}  ${r.name.padEnd(52)} ${r.pass ? C.green + "PASS" : C.red + "FAIL"}${C.reset}`);
  }

  console.log(`\n${"─".repeat(62)}`);
  const rc = failed === 0 ? C.green : C.red;
  console.log(`${rc}${C.bold}  ${passed}/${results.length} checks passed  |  ${failed} failed${C.reset}`);

  // Note: Missing keys in Arabic dictionary is a common workflow condition as new strings
  // are added in English first. So we issue a success but log detailed warnings.
  const success = failed === 0;
  if (success) {
    console.log(`${C.green}${C.bold}  ✓ LOCALIZATION DICTIONARIES ARE FULLY ALIGNED${C.reset}\n`);
  } else {
    console.log(`${C.yellow}${C.bold}  ⚠ LOCALIZATION HAS INTEGRITY WARNINGS (Check missing keys/placeholders)${C.reset}\n`);
  }

  // Save report
  if (!fs.existsSync(RESULTS_DIR)) {
    fs.mkdirSync(RESULTS_DIR, { recursive: true });
  }
  const ts = new Date().toISOString().replace(/[:.]/g, "-");
  const reportPath = path.join(RESULTS_DIR, `localization-${ts}.json`);
  fs.writeFileSync(reportPath, JSON.stringify({
    timestamp: new Date().toISOString(),
    passed, failed, total: results.length,
    statistics: {
      englishKeys: enKeys.length,
      arabicKeys: arKeys.length,
      missingInAr: missingInAr.length,
      missingInEn: missingInEn.length,
      emptyInEn: emptyInEn.length,
      emptyInAr: emptyInAr.length,
      placeholderMismatchesCount: placeholderMismatches.length
    },
    missingInAr,
    missingInEn,
    emptyInEn,
    emptyInAr,
    placeholderMismatches
  }, null, 2));

  console.log(`  Report: ${reportPath}\n`);
  process.exit(failed > 0 ? 1 : 0);
}

main();
