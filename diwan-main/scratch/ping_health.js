import fetch from "node-fetch";

async function main() {
  const url = "https://portal.studentdiwan.com/api/health";
  try {
    const res = await fetch(url);
    const text = await res.text();
    console.log(`Health check status: ${res.status}`);
    console.log(`Health check body: ${text}`);
  } catch (e) {
    console.error("Health check request failed:", e);
  }
}

main();
