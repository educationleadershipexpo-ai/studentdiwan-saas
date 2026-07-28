import fs from "fs";
try {
  const pkg = JSON.parse(fs.readFileSync("node_modules/firebase/package.json", "utf8"));
  console.log("Firebase version locally:", pkg.version);
} catch (e) {
  console.error("Failed to read firebase version:", e.message);
}
