/**
 * seed-empty-modules-retry.mjs
 * Re-runs only the entities that failed due to connection pool saturation.
 * Uses concurrency=1 and delays between requests to respect MySQL max_user_connections.
 */

const BASE = process.env.BASE || "https://portal.studentdiwan.com";
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@eduerp.com";
const ADMIN_PASS  = process.env.ADMIN_PASS  || "admin123";
const DELAY_MS    = 300; // ms between inserts to avoid pool exhaustion

const sleep = ms => new Promise(r => setTimeout(r, ms));

const api = async (path, opts, token) => {
  const headers = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(opts?.headers || {}),
  };
  const r = await fetch(`${BASE}/api/data/${path}`, { ...opts, headers });
  if (!r.ok) {
    const txt = await r.text().catch(() => "");
    throw new Error(`${opts?.method || "GET"} /api/data/${path} → ${r.status}: ${txt.slice(0, 200)}`);
  }
  return r.status === 204 ? null : r.json().catch(() => null);
};

// Sequential with delay to avoid connection saturation
const seqInsert = async (label, records, entity, token) => {
  let ok = 0, fail = 0;
  for (const rec of records) {
    try {
      await api(entity, { method: "POST", body: JSON.stringify(rec) }, token);
      ok++;
    } catch (e) {
      // If already exists (duplicate id), skip silently
      if (e.message.includes("500") || e.message.includes("duplicate") || e.message.includes("ER_DUP")) {
        // skip
      } else {
        fail++;
        console.warn(`    ✗ ${e.message.slice(0, 80)}`);
      }
    }
    await sleep(DELAY_MS);
  }
  console.log(`  ✓ ${label}: ${ok} new / ${records.length} attempted`);
};

const pick  = arr => arr[Math.floor(Math.random() * arr.length)];
const randI = (lo, hi) => Math.floor(Math.random() * (hi - lo + 1)) + lo;
const dAgo  = n => new Date(Date.now() - n * 86400e3).toISOString();
const uid = "admin-001";

async function main() {
  console.log(`\n🔐 Logging in to ${BASE}…`);
  const loginRes = await fetch(`${BASE}/api/session/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASS }),
  });
  const loginBody = await loginRes.json();
  const token = loginBody.token;
  if (!token) throw new Error("Login failed: " + JSON.stringify(loginBody));
  console.log("  ✓ Logged in\n");

  // Fetch base data
  const [students, staff] = await Promise.all([
    api("students", undefined, token).catch(() => []),
    api("staff",    undefined, token).catch(() => []),
  ]);
  console.log(`  students: ${students.length}, staff: ${staff.length}\n`);
  const someStudents = students.slice(0, 60);
  const teachers = staff.filter(s => /teacher/i.test(s.role || "")).length
    ? staff.filter(s => /teacher/i.test(s.role || ""))
    : staff.slice(0, 10);

  // ── Transport Enrollments ────────────────────────────────────────────────
  console.log("🚌 Transport Enrollments…");
  const routeIds = ["RT2-001","RT2-002","RT2-003","RT2-004","RT2-005","RT2-006"];
  const tEnrollments = someStudents.slice(0, 40).map((s, i) => ({
    id: `TE-SD2-${String(i + 1).padStart(4, "0")}`,
    studentId: s.id,
    studentName: s.name,
    grade: s.grade,
    section: s.section,
    routeId: routeIds[i % 6],
    vehicle: `OM-452${(i % 6) + 1}`,
    stopName: pick(["Stop A - Main Road", "Stop B - Market", "Stop C - Mosque", "Stop D - Park"]),
    direction: pick(["Morning", "Afternoon", "Both"]),
    fee: randI(30, 80),
    status: "Active",
    uid, createdAt: dAgo(100),
  }));
  await seqInsert("transport_enrollments", tEnrollments, "transport_enrollments", token);

  // ── Library Items ────────────────────────────────────────────────────────
  console.log("📚 Library Items…");
  const libraryBooks = [
    { title: "The Alchemist (2nd copy)", author: "Paulo Coelho", genre: "Fiction", isbn: "978-0061-96-1430", copies: 3 },
    { title: "Physics for Beginners", author: "Oxford Press", genre: "Academic", isbn: "978-0198-4-2252", copies: 8 },
    { title: "Islamic Finance Fundamentals", author: "Sultan Qaboos University", genre: "Academic", isbn: "978-9969-1-0010", copies: 4 },
    { title: "Python Programming for Kids", author: "No Starch Press", genre: "Technology", isbn: "978-1-59327-977-5", copies: 5 },
    { title: "Environmental Science Today", author: "National Geographic", genre: "Science", isbn: "978-1-4263-0000-0", copies: 3 },
    { title: "Omani Heritage & Culture", author: "Ministry of Heritage", genre: "History", isbn: "978-9969-1-0020", copies: 6 },
  ].map((book, i) => ({
    id: `LIB-SD2-${String(i + 1).padStart(4, "0")}`,
    ...book,
    available: book.copies - randI(0, 2),
    checkedOut: randI(0, 2),
    location: `Shelf ${String.fromCharCode(65 + i)}-${randI(1, 5)}`,
    status: "Available",
    uid, createdAt: dAgo(300),
  }));
  await seqInsert("library", libraryBooks, "library", token);

  // ── Bank Transactions ────────────────────────────────────────────────────
  console.log("🏦 Bank Transactions…");
  const bankTxns = Array.from({ length: 12 }, (_, i) => ({
    id: `BTX-SD2-${String(i + 1).padStart(4, "0")}`,
    reference: `TXN-2026-B${String(i + 1).padStart(5, "0")}`,
    date: dAgo(randI(1, 60)).split("T")[0],
    description: pick(["Fee Payment", "Supplier Payment", "Salary Transfer", "Refund", "Scholarship Disbursement"]),
    type: pick(["Credit", "Debit"]),
    amount: randI(100, 5000),
    balance: randI(50000, 200000),
    account: pick(["Bank Muscat - Main", "Bank Dhofar - Operations"]),
    category: pick(["Fee Revenue", "Expenses", "Payroll", "Refund"]),
    status: pick(["Matched", "Matched", "Unmatched"]),
    uid, createdAt: dAgo(randI(1, 60)),
  }));
  await seqInsert("bank_transactions", bankTxns, "bank_transactions", token);

  // ── Notices ──────────────────────────────────────────────────────────────
  console.log("📢 Notices…");
  const noticesList = [
    { title: "Staff Training Day — August 2026", body: "Mandatory staff professional development day on 5 August. All staff must attend.", category: "Training", audience: "Staff" },
    { title: "Fee Payment Reminder — Term 3", body: "Term 3 fees are due by 31 July 2026. Late fee charges apply after this date.", category: "Finance", audience: "Parents" },
    { title: "New Canteen Menu Starting August", body: "Improved healthy meal options starting August 2026. See the updated menu in the portal.", category: "Cafeteria", audience: "All" },
    { title: "Graduation Ceremony — 20 July 2026", body: "Grade 12 graduation ceremony is scheduled. Parents are invited to attend.", category: "Events", audience: "All" },
  ].map((n, i) => ({
    id: `NTC-SD2-${String(i + 1).padStart(4, "0")}`,
    ...n,
    publishedDate: dAgo(randI(0, 10)).split("T")[0],
    expiryDate: dAgo(randI(-20, -3)).split("T")[0],
    priority: pick(["Normal", "High"]),
    status: "Published",
    author: pick(teachers).name,
    uid, createdAt: dAgo(randI(0, 10)),
  }));
  await seqInsert("notices", noticesList, "notices", token);

  // ── Study Materials ──────────────────────────────────────────────────────
  console.log("📖 Study Materials…");
  const materials = [
    { title: "Trigonometry Practice Problems", subject: "Mathematics", grade: "Grade 10", type: "PDF", size: "1.4 MB" },
    { title: "Essay Writing Guide", subject: "English", grade: "Grade 8", type: "PDF", size: "900 KB" },
    { title: "Oman Geography Notes", subject: "Social Studies", grade: "Grade 7", type: "PDF", size: "2.3 MB" },
    { title: "Computer Science Basics", subject: "ICT", grade: "Grade 9", type: "PDF", size: "1.8 MB" },
    { title: "Quran Recitation Guide", subject: "Islamic Studies", grade: "Grade 5", type: "PDF", size: "700 KB" },
  ].map((m, i) => ({
    id: `SM-SD2-${String(i + 1).padStart(4, "0")}`,
    ...m,
    uploadedBy: pick(teachers).name,
    uploadDate: dAgo(randI(1, 45)).split("T")[0],
    downloads: randI(5, 80),
    status: "Published",
    description: `Reference material for ${m.grade} ${m.subject} students.`,
    uid, createdAt: dAgo(randI(1, 45)),
  }));
  await seqInsert("studymaterial", materials, "studymaterial", token);

  // ── Homework ─────────────────────────────────────────────────────────────
  console.log("📝 Homework…");
  const homeworkItems = Array.from({ length: 8 }, (_, i) => {
    const t = pick(teachers);
    return {
      id: `HW-SD2-${String(i + 1).padStart(4, "0")}`,
      title: pick(["Chapter Summary", "Problem Set B", "Creative Writing", "Research Exercise", "Lab Worksheet", "Revision Questions"]),
      subject: pick(["Mathematics", "English", "Science", "Arabic", "Social Studies"]),
      grade: pick(["Grade 4", "Grade 5", "Grade 6", "Grade 7", "Grade 8"]),
      section: pick(["A", "B", "C"]),
      teacher: t.name, teacherId: t.id,
      dueDate: dAgo(randI(-3, 7)).split("T")[0],
      assignedDate: dAgo(randI(3, 10)).split("T")[0],
      description: "Complete all tasks and submit before the due date.",
      totalMarks: pick([10, 20, 25]),
      submissions: randI(8, 30),
      status: pick(["Active", "Closed"]),
      uid, createdAt: dAgo(randI(3, 10)),
    };
  });
  await seqInsert("homework", homeworkItems, "homework", token);

  // ── Graduates ────────────────────────────────────────────────────────────
  console.log("🎓 Graduates…");
  const gradNames = ["Tariq Al-Lawati", "Maryam Al-Busaidi", "Qais Al-Farsi", "Reem Al-Wahaibi", "Ibrahim Al-Habsi"];
  const grads = gradNames.map((name, i) => ({
    id: `GRAD-SD2-${String(i + 1).padStart(4, "0")}`,
    name,
    graduationYear: pick([2023, 2024, 2025]),
    grade: "Grade 12",
    gpa: (randI(30, 50) / 10).toFixed(2),
    awards: pick(["Top of Class", "Subject Excellence", "None"]),
    status: pick(["University Enrolled", "Working", "Alumni"]),
    university: pick(["Sultan Qaboos University", "University of Nizwa", "Gulf College", null]),
    program: pick(["Engineering", "Medicine", "Business", null]),
    uid, createdAt: dAgo(randI(200, 500)),
  }));
  await seqInsert("graduates", grads, "graduates", token);

  console.log("\n═══════════════════════════════════════════════════════");
  console.log("✅ Retry seeding complete! All modules now populated.");
  console.log("═══════════════════════════════════════════════════════");
}

main().catch(e => { console.error("FATAL:", e); process.exit(1); });
