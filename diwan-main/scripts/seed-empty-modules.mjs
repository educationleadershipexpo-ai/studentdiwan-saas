/**
 * seed-empty-modules.mjs
 * Seeds realtime demo data into all known-empty modules.
 * Run against production:  BASE=https://portal.studentdiwan.com node scripts/seed-empty-modules.mjs
 */

const BASE = process.env.BASE || "https://portal.studentdiwan.com";
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@eduerp.com";
const ADMIN_PASS  = process.env.ADMIN_PASS  || "admin123";

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

const safe = async (label, fn) => {
  try { const r = await fn(); console.log(`  ✓ ${label}`); return r; }
  catch (e) { console.warn(`  ✗ ${label}: ${e.message}`); return null; }
};

const pool = async (items, worker, concurrency = 6) => {
  let i = 0, done = 0, failed = 0;
  const run = async () => {
    while (i < items.length) {
      const idx = i++;
      try { await worker(items[idx]); done++; }
      catch (e) { failed++; console.error("   ! " + e.message); done++; }
    }
  };
  await Promise.all(Array.from({ length: Math.min(concurrency, items.length || 1) }, run));
  return { done, failed };
};

const pick  = arr => arr[Math.floor(Math.random() * arr.length)];
const randI = (lo, hi) => Math.floor(Math.random() * (hi - lo + 1)) + lo;
const dAgo  = n => new Date(Date.now() - n * 86400e3).toISOString();
const today = () => new Date().toISOString().split("T")[0];

// ──────────────────────────────────────────────
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

  // ── Fetch base data ────────────────────────────────────────────────────────
  console.log("📦 Fetching base data…");
  const [students, staff] = await Promise.all([
    api("students", undefined, token).catch(() => []),
    api("staff",    undefined, token).catch(() => []),
  ]);
  console.log(`  students: ${students.length}, staff: ${staff.length}\n`);

  const someStudents = students.slice(0, 60);
  const teachers     = staff.filter(s => /teacher/i.test(s.role || "")).length
    ? staff.filter(s => /teacher/i.test(s.role || ""))
    : staff.slice(0, 10);
  const uid = "admin-001";

  // ══════════════════════════════════════════════════════════════════════════
  // 1. HEALTH RECORDS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🏥 Health Records…");
  const conditions = ["None", "Asthma", "Diabetes Type 1", "Nut Allergy", "Lactose Intolerant", "Epilepsy", "None", "None"];
  const bloodGroups = ["A+", "B+", "O+", "AB+", "A-", "O-", "B-"];
  const healthRecs = someStudents.slice(0, 40).map((s, i) => ({
    id: `HR-SD-${String(i + 1).padStart(4, "0")}`,
    studentId: s.id,
    studentName: s.name,
    grade: s.grade,
    section: s.section,
    bloodGroup: pick(bloodGroups),
    height: `${randI(130, 175)} cm`,
    weight: `${randI(35, 75)} kg`,
    bmi: `${(randI(170, 240) / 10).toFixed(1)}`,
    medicalCondition: pick(conditions),
    allergies: pick(["None", "Pollen", "Dust Mites", "Penicillin", "None", "None"]),
    emergencyContact: `+968 9${randI(1000000, 9999999)}`,
    lastVisit: dAgo(randI(5, 90)).split("T")[0],
    notes: pick(["Routine check-up", "Medication review", "Vaccination updated", "No concerns", "Annual health screening"]),
    status: pick(["Active", "Active", "Active", "Monitoring"]),
    uid, createdAt: dAgo(randI(10, 120)),
  }));
  const r1 = await pool(healthRecs, rec => api("health_records", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r1.done - r1.failed}/${healthRecs.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 2. HOSTEL ROOMS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🏨 Hostel Rooms…");
  const hostelRooms = Array.from({ length: 20 }, (_, i) => {
    const block = pick(["A", "B", "C"]);
    const capacity = pick([2, 3, 4]);
    const occupied = randI(0, capacity);
    return {
      id: `HST-RM-${String(i + 1).padStart(3, "0")}`,
      roomNumber: `${block}${String((i % 10) + 1).padStart(2, "0")}`,
      block,
      type: pick(["Single", "Double", "Triple", "Quad"]),
      capacity,
      occupied,
      available: capacity - occupied,
      floor: pick(["Ground", "1st", "2nd"]),
      amenities: ["AC", "WiFi", ...(Math.random() > 0.5 ? ["Attached Bath"] : [])],
      status: occupied >= capacity ? "Full" : occupied === 0 ? "Vacant" : "Available",
      uid, createdAt: dAgo(200),
    };
  });
  const r2 = await pool(hostelRooms, rec => api("hostel_rooms", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r2.done - r2.failed}/${hostelRooms.length} inserted\n`);

  // Hostel Allocations
  console.log("🏠 Hostel Allocations…");
  const hostelAllocs = someStudents.slice(0, 15).map((s, i) => ({
    id: `HST-ALL-${String(i + 1).padStart(3, "0")}`,
    studentId: s.id,
    studentName: s.name,
    grade: s.grade,
    roomId: hostelRooms[i % hostelRooms.length].id,
    roomNumber: hostelRooms[i % hostelRooms.length].roomNumber,
    block: hostelRooms[i % hostelRooms.length].block,
    startDate: dAgo(180).split("T")[0],
    endDate: "2027-06-30",
    feePerMonth: randI(150, 400),
    status: pick(["Active", "Active", "Active", "Pending"]),
    uid, createdAt: dAgo(180),
  }));
  const r2b = await pool(hostelAllocs, rec => api("hostel_allocations", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r2b.done - r2b.failed}/${hostelAllocs.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 3. CAFETERIA / MESS MENU
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🍽️ Mess Menu…");
  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
  const menus = days.flatMap((day, di) => [
    { id: `MM-${di}-B`, day, mealType: "Breakfast", items: ["Oats Porridge", "Boiled Eggs", "Bread & Butter", "Fruit Juice"], calories: 450, uid, createdAt: dAgo(1) },
    { id: `MM-${di}-L`, day, mealType: "Lunch",     items: ["Grilled Chicken", "Steamed Rice", "Mixed Salad", "Fresh Yoghurt"], calories: 680, uid, createdAt: dAgo(1) },
    { id: `MM-${di}-S`, day, mealType: "Snack",     items: ["Samosa", "Fruit Plate", "Water"], calories: 200, uid, createdAt: dAgo(1) },
    { id: `MM-${di}-D`, day, mealType: "Dinner",    items: ["Lamb Biryani", "Dal Tadka", "Chapati", "Raita"], calories: 750, uid, createdAt: dAgo(1) },
  ]);
  const r3 = await pool(menus, rec => api("mess_menu", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r3.done - r3.failed}/${menus.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 4. INVENTORY
  // ══════════════════════════════════════════════════════════════════════════
  console.log("📦 Inventory Items…");
  const inventoryItems = [
    { name: "A4 Copy Paper (500 sheets)", category: "Stationery", unit: "Ream",  quantity: 250,  minStock: 50,  unitPrice: 2.5 },
    { name: "Whiteboard Marker Set",       category: "Stationery", unit: "Box",   quantity: 80,   minStock: 20,  unitPrice: 4.0 },
    { name: "Classroom Chair",             category: "Furniture",  unit: "Units", quantity: 350,  minStock: 30,  unitPrice: 45  },
    { name: "Teacher Desk",                category: "Furniture",  unit: "Units", quantity: 40,   minStock: 5,   unitPrice: 120 },
    { name: "Science Lab Glassware Set",   category: "Lab Equipment", unit: "Set", quantity: 25,  minStock: 5,   unitPrice: 85  },
    { name: "Basketball",                  category: "Sports",     unit: "Units", quantity: 30,   minStock: 10,  unitPrice: 15  },
    { name: "First Aid Kit",               category: "Medical",    unit: "Units", quantity: 15,   minStock: 5,   unitPrice: 25  },
    { name: "Printer Cartridge HP",        category: "IT",         unit: "Units", quantity: 20,   minStock: 10,  unitPrice: 18  },
    { name: "Projector Bulb",              category: "IT",         unit: "Units", quantity: 8,    minStock: 3,   unitPrice: 65  },
    { name: "Cafeteria Tray",              category: "Cafeteria",  unit: "Units", quantity: 200,  minStock: 50,  unitPrice: 3.5 },
    { name: "Arabic Textbook Grade 5",     category: "Books",      unit: "Units", quantity: 120,  minStock: 20,  unitPrice: 8   },
    { name: "Maths Textbook Grade 7",      category: "Books",      unit: "Units", quantity: 95,   minStock: 20,  unitPrice: 9.5 },
    { name: "Cleaning Supplies Bundle",    category: "Maintenance",unit: "Set",   quantity: 60,   minStock: 15,  unitPrice: 22  },
    { name: "Extension Cable 5m",          category: "IT",         unit: "Units", quantity: 35,   minStock: 10,  unitPrice: 7   },
    { name: "Safety Goggles",              category: "Lab Equipment", unit: "Units", quantity: 50, minStock: 15, unitPrice: 5   },
  ].map((item, i) => ({
    id: `INV-SD-${String(i + 1).padStart(4, "0")}`,
    ...item,
    totalValue: item.quantity * item.unitPrice,
    status: item.quantity <= item.minStock ? "Low Stock" : "In Stock",
    location: pick(["Main Store", "Block A Store", "Science Block", "Sports Store", "Library Store"]),
    lastRestocked: dAgo(randI(5, 60)).split("T")[0],
    supplier: pick(["Al Fajr Office Supplies", "Muscat Tech Traders", "Gulf Furniture Co.", "Nizwa Sports Equipment"]),
    uid, createdAt: dAgo(randI(30, 180)),
  }));
  const r4 = await pool(inventoryItems, rec => api("inventory", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r4.done - r4.failed}/${inventoryItems.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 5. PAYROLL
  // ══════════════════════════════════════════════════════════════════════════
  console.log("💰 Payroll Records…");
  const payrollMonths = ["May 2026", "June 2026", "July 2026"];
  const payrollRecs = staff.slice(0, 25).flatMap((s, si) =>
    payrollMonths.map((month, mi) => {
      const basic   = randI(500, 1800);
      const housing = Math.round(basic * 0.25);
      const transport = randI(50, 150);
      const deductions = randI(50, 200);
      const net = basic + housing + transport - deductions;
      return {
        id: `PAY-${mi}-${String(si + 1).padStart(3, "0")}`,
        staffId: s.id, staffName: s.name,
        department: s.department || "General",
        role: s.role || "Staff",
        month,
        basic, housing, transport, deductions,
        amount: net, netSalary: net,
        status: pick(["Paid", "Paid", "Paid", "Pending"]),
        processedDate: dAgo(randI(1, 30)).split("T")[0],
        paymentMethod: pick(["Bank Transfer", "Cash", "Cheque"]),
        uid, createdAt: dAgo(randI(1, 60)),
      };
    })
  );
  const r5 = await pool(payrollRecs, rec => api("payroll", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r5.done - r5.failed}/${payrollRecs.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 6. BEHAVIOR INCIDENTS (admin-side BehaviorIncident)
  // ══════════════════════════════════════════════════════════════════════════
  console.log("⚠️ Behavior Incidents…");
  const behaviorTypes = ["Positive", "Positive", "Negative", "Neutral"];
  const behaviorCats  = ["Excellent Participation", "Helping Peers", "Late Submission", "Disruption in Class", "Outstanding Teamwork", "Disrespect to Teacher", "Academic Honesty", "Punctuality Issue"];
  const behaviorIncs = someStudents.slice(0, 30).map((s, i) => ({
    id: `BI-SD-${String(i + 1).padStart(4, "0")}`,
    studentId: s.id,
    studentName: s.name,
    grade: s.grade,
    section: s.section,
    type: pick(behaviorTypes),
    category: pick(behaviorCats),
    description: `Incident observed during class session on ${dAgo(randI(1, 30)).split("T")[0]}.`,
    date: dAgo(randI(1, 30)).split("T")[0],
    reportedBy: pick(teachers).name,
    parentNotified: Math.random() > 0.4,
    action: pick(["Counseled", "Warning Issued", "Merit Award", "Parents Called", "Reported to HOD", "No Action"]),
    status: pick(["Open", "Resolved", "Resolved", "Pending"]),
    uid, createdAt: dAgo(randI(1, 30)),
  }));
  const r6 = await pool(behaviorIncs, rec => api("behavior_incidents", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r6.done - r6.failed}/${behaviorIncs.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 7. ACHIEVEMENTS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🏆 Achievements…");
  const achievementTypes = ["Academic", "Sports", "Arts", "Leadership", "Community Service", "Technology"];
  const achievementLevels = ["School Level", "District Level", "National Level", "International Level"];
  const achievements = someStudents.slice(0, 25).map((s, i) => ({
    id: `ACH-SD-${String(i + 1).padStart(4, "0")}`,
    studentId: s.id,
    studentName: s.name,
    grade: s.grade,
    section: s.section,
    title: pick([
      "First Place - Mathematics Olympiad",
      "Best Debater Award",
      "Science Fair Gold Medal",
      "Spelling Bee Champion",
      "Football Tournament Winner",
      "Inter-School Art Competition 2nd Place",
      "Technology Innovation Award",
      "Community Service Excellence",
      "Best Actor - Annual Play",
      "Chess Tournament Champion",
    ]),
    category: pick(achievementTypes),
    level: pick(achievementLevels),
    date: dAgo(randI(5, 120)).split("T")[0],
    issuedBy: pick(["School Administration", "Ministry of Education", "Sports Council", "District Education Office"]),
    description: `Recognised for outstanding performance and dedication.`,
    status: "Verified",
    certificateUrl: null,
    uid, createdAt: dAgo(randI(5, 120)),
  }));
  const r7 = await pool(achievements, rec => api("achievements", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r7.done - r7.failed}/${achievements.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 8. SCHOLARSHIPS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🎓 Scholarships…");
  const scholarships = someStudents.slice(0, 15).map((s, i) => ({
    id: `SCH-SD-${String(i + 1).padStart(4, "0")}`,
    studentId: s.id,
    studentName: s.name,
    grade: s.grade,
    section: s.section,
    scholarshipName: pick(["Merit Excellence Award", "Need-Based Scholarship", "Sports Scholarship", "Arts & Culture Grant", "STEM Achievement Award"]),
    type: pick(["Full", "Partial", "Partial", "Merit"]),
    amount: randI(500, 2500),
    percentage: pick([25, 50, 75, 100]),
    startDate: "2026-09-01",
    endDate: "2027-06-30",
    status: pick(["Active", "Active", "Active", "Pending Review"]),
    gpa: (randI(35, 50) / 10).toFixed(1),
    reason: pick(["Academic Excellence", "Financial Need", "Sports Achievement", "Arts Contribution"]),
    approvedBy: pick(teachers).name,
    uid, createdAt: dAgo(randI(10, 60)),
  }));
  const r8 = await pool(scholarships, rec => api("Scholarship", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r8.done - r8.failed}/${scholarships.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 9. PURCHASE ORDERS (Inventory/Finance)
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🛒 Purchase Orders…");
  const purchaseOrders = Array.from({ length: 12 }, (_, i) => {
    const qty = randI(10, 100);
    const price = randI(5, 500);
    return {
      id: `PO-SD-${String(i + 1).padStart(4, "0")}`,
      poNumber: `PO-2026-${String(i + 1).padStart(4, "0")}`,
      vendor: pick(["Al Fajr Office Supplies", "Muscat Tech Traders", "Gulf Furniture Co.", "Nizwa Sports Equipment", "Bright Future Stationery"]),
      category: pick(["Stationery", "IT Equipment", "Furniture", "Lab Supplies", "Sports", "Maintenance"]),
      items: [{ description: pick(["Office Chair", "A4 Paper (Bulk)", "Whiteboard", "Projector", "Sports Kit", "Lab Equipment"]), qty, unitPrice: price, total: qty * price }],
      totalAmount: qty * price,
      status: pick(["Draft", "Pending Approval", "Approved", "Delivered", "Cancelled"]),
      requestedBy: pick(teachers).name,
      approvedBy: pick([null, pick(teachers).name]),
      requestedDate: dAgo(randI(5, 60)).split("T")[0],
      deliveryDate: dAgo(randI(-10, 5)).split("T")[0],
      uid, createdAt: dAgo(randI(5, 60)),
    };
  });
  const r9 = await pool(purchaseOrders, rec => api("purchase_orders", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r9.done - r9.failed}/${purchaseOrders.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 10. VENDORS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🏢 Vendors…");
  const vendors = [
    { id: "VND-001", name: "Al Fajr Office Supplies",  category: "Stationery",    contact: "+968 24001111", email: "info@alfajr.om",      city: "Muscat", country: "Oman", status: "Active", taxNumber: "OM-VAT-1001" },
    { id: "VND-002", name: "Muscat Tech Traders",       category: "IT Equipment",  contact: "+968 24002222", email: "sales@mtt.om",         city: "Muscat", country: "Oman", status: "Active", taxNumber: "OM-VAT-1002" },
    { id: "VND-003", name: "Gulf Furniture Co.",        category: "Furniture",     contact: "+968 24003333", email: "orders@gulffurn.om",   city: "Seeb",   country: "Oman", status: "Active", taxNumber: "OM-VAT-1003" },
    { id: "VND-004", name: "Nizwa Sports Equipment",   category: "Sports",        contact: "+968 25004444", email: "nizwasport@gmail.com", city: "Nizwa",  country: "Oman", status: "Active", taxNumber: "OM-VAT-1004" },
    { id: "VND-005", name: "Bright Future Stationery", category: "Stationery",    contact: "+968 24005555", email: "bfs@live.com",         city: "Muscat", country: "Oman", status: "Active", taxNumber: "OM-VAT-1005" },
    { id: "VND-006", name: "Oman Lab Solutions",        category: "Lab Supplies",  contact: "+968 24006666", email: "labs@ols.om",          city: "Muscat", country: "Oman", status: "Active", taxNumber: "OM-VAT-1006" },
    { id: "VND-007", name: "CleanPro Services",         category: "Maintenance",   contact: "+968 24007777", email: "cleanpro@om.net",      city: "Qurum",  country: "Oman", status: "Inactive", taxNumber: "OM-VAT-1007" },
  ].map(v => ({ ...v, uid, createdAt: dAgo(200) }));
  const r10 = await pool(vendors, rec => api("vendors", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r10.done - r10.failed}/${vendors.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 11. TRANSPORT DRIVERS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🚌 Transport Drivers…");
  const drivers = [
    { id: "DRV-001", name: "Salim Al-Amri",    phone: "+968 93001001", licenseNumber: "OM-DL-2001", licenseExpiry: "2028-01-01", experience: "8 years", routeId: "RT2-001", vehicle: "OM-4521", status: "Active" },
    { id: "DRV-002", name: "Nasser Al-Balushi", phone: "+968 93001002", licenseNumber: "OM-DL-2002", licenseExpiry: "2027-06-15", experience: "5 years", routeId: "RT2-002", vehicle: "OM-4522", status: "Active" },
    { id: "DRV-003", name: "Hamad Al-Kindi",    phone: "+968 93001003", licenseNumber: "OM-DL-2003", licenseExpiry: "2027-03-30", experience: "6 years", routeId: "RT2-003", vehicle: "OM-4523", status: "Active" },
    { id: "DRV-004", name: "Waleed Al-Harthy",  phone: "+968 93001004", licenseNumber: "OM-DL-2004", licenseExpiry: "2028-09-01", experience: "10 years", routeId: "RT2-004", vehicle: "OM-4524", status: "Active" },
    { id: "DRV-005", name: "Talal Al-Siyabi",   phone: "+968 93001005", licenseNumber: "OM-DL-2005", licenseExpiry: "2026-08-20", experience: "4 years", routeId: "RT2-005", vehicle: "OM-4525", status: "On Leave" },
    { id: "DRV-006", name: "Adel Al-Wahaibi",   phone: "+968 93001006", licenseNumber: "OM-DL-2006", licenseExpiry: "2027-12-01", experience: "7 years", routeId: "RT2-006", vehicle: "OM-4526", status: "Active" },
  ].map(d => ({ ...d, uid, createdAt: dAgo(200) }));
  const r11 = await pool(drivers, rec => api("drivers", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r11.done - r11.failed}/${drivers.length} inserted\n`);

  // Transport Enrollments (students on buses)
  console.log("🚌 Transport Enrollments…");
  const tEnrollments = someStudents.slice(0, 35).map((s, i) => {
    const routeIdx = i % 6;
    const routeIds = ["RT2-001","RT2-002","RT2-003","RT2-004","RT2-005","RT2-006"];
    return {
      id: `TE-SD-${String(i + 1).padStart(4, "0")}`,
      studentId: s.id,
      studentName: s.name,
      grade: s.grade,
      section: s.section,
      routeId: routeIds[routeIdx],
      vehicle: `OM-452${routeIdx + 1}`,
      stopName: pick(["Stop A - Main Road", "Stop B - Market", "Stop C - Mosque", "Stop D - Park"]),
      direction: pick(["Morning", "Afternoon", "Both"]),
      fee: randI(30, 80),
      status: "Active",
      uid, createdAt: dAgo(100),
    };
  });
  const r11b = await pool(tEnrollments, rec => api("transport_enrollments", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r11b.done - r11b.failed}/${tEnrollments.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 12. LIBRARY ITEMS (books)
  // ══════════════════════════════════════════════════════════════════════════
  console.log("📚 Library Items…");
  const libraryBooks = [
    { title: "The Alchemist", author: "Paulo Coelho", genre: "Fiction", isbn: "978-0061-96-1429", copies: 4 },
    { title: "A Brief History of Time", author: "Stephen Hawking", genre: "Science", isbn: "978-0553-38-0163", copies: 2 },
    { title: "To Kill a Mockingbird", author: "Harper Lee", genre: "Classic", isbn: "978-0061-93-5460", copies: 3 },
    { title: "Mathematics Grade 8 Textbook", author: "Ministry of Education", genre: "Academic", isbn: "978-9969-1-0001", copies: 15 },
    { title: "Arabic Language & Literature", author: "National Curriculum", genre: "Academic", isbn: "978-9969-1-0002", copies: 12 },
    { title: "Science Explorers Grade 6", author: "Oxford Press", genre: "Academic", isbn: "978-0198-4-2251", copies: 10 },
    { title: "Rich Dad Poor Dad", author: "Robert Kiyosaki", genre: "Self-Help", isbn: "978-1612-68-0-451", copies: 3 },
    { title: "1984", author: "George Orwell", genre: "Classic", isbn: "978-0451-52-4935", copies: 4 },
    { title: "Harry Potter & Philosopher's Stone", author: "J.K. Rowling", genre: "Fiction", isbn: "978-0439-70-8180", copies: 5 },
    { title: "Diary of a Wimpy Kid", author: "Jeff Kinney", genre: "Children", isbn: "978-0810-99-3445", copies: 6 },
    { title: "Encyclopedia Britannica Vol. 1", author: "Britannica", genre: "Reference", isbn: "978-1-59339-292-5", copies: 1 },
    { title: "The Holy Quran (English Translation)", author: "M. Pickthall", genre: "Religious", isbn: "978-1-56744-133-1", copies: 8 },
  ].map((book, i) => {
    const available = book.copies - randI(0, Math.min(book.copies, 3));
    return {
      id: `LIB-SD-${String(i + 1).padStart(4, "0")}`,
      ...book,
      available,
      checkedOut: book.copies - available,
      location: `Shelf ${String.fromCharCode(65 + (i % 6))}-${randI(1, 5)}`,
      status: available > 0 ? "Available" : "All Checked Out",
      uid, createdAt: dAgo(300),
    };
  });
  const r12 = await pool(libraryBooks, rec => api("library", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r12.done - r12.failed}/${libraryBooks.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 13. BANK TRANSACTIONS (Finance Reconciliation)
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🏦 Bank Transactions…");
  const bankTxns = Array.from({ length: 20 }, (_, i) => {
    const amount = randI(100, 5000);
    const type = pick(["Credit", "Debit"]);
    return {
      id: `BTX-SD-${String(i + 1).padStart(4, "0")}`,
      reference: `TXN-2026-${String(i + 1).padStart(5, "0")}`,
      date: dAgo(randI(1, 60)).split("T")[0],
      description: pick(["Fee Payment", "Supplier Payment", "Salary Transfer", "Refund", "Scholarship Disbursement", "Maintenance Payment"]),
      type,
      amount,
      balance: randI(50000, 200000),
      account: pick(["Bank Muscat - Main", "Bank Dhofar - Operations"]),
      category: pick(["Fee Revenue", "Expenses", "Payroll", "Refund"]),
      status: pick(["Matched", "Matched", "Unmatched", "Pending"]),
      uid, createdAt: dAgo(randI(1, 60)),
    };
  });
  const r13 = await pool(bankTxns, rec => api("bank_transactions", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r13.done - r13.failed}/${bankTxns.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 14. NOTICES (Communication)
  // ══════════════════════════════════════════════════════════════════════════
  console.log("📢 Notices…");
  const notices = [
    { title: "Annual Sports Day — 15 August", body: "All students are invited to participate in the Annual Sports Day. Events include athletics, football, and swimming.", category: "Events", audience: "All" },
    { title: "Parent-Teacher Meeting — July 30", body: "PTM scheduled for Grade 6-10 parents. Slots are available in the portal.", category: "PTM", audience: "Parents" },
    { title: "Examination Timetable Released", body: "The final exam timetable for Term 3 is now available. Please check the portal.", category: "Exams", audience: "All" },
    { title: "School Holiday — Eid Al-Adha", body: "School will remain closed from 15-19 July 2026 for Eid Al-Adha.", category: "Holiday", audience: "All" },
    { title: "Library Book Return Deadline", body: "All borrowed books must be returned by 25 July 2026 to avoid fines.", category: "Library", audience: "Students" },
    { title: "New Student Orientation", body: "Welcome new students! Orientation will be held on 1 September 2026 in the main auditorium.", category: "Orientation", audience: "Students" },
  ].map((n, i) => ({
    id: `NTC-SD-${String(i + 1).padStart(4, "0")}`,
    ...n,
    publishedDate: dAgo(randI(0, 20)).split("T")[0],
    expiryDate: dAgo(randI(-30, -5)).split("T")[0],
    priority: pick(["Normal", "Normal", "High", "Urgent"]),
    status: "Published",
    author: pick(teachers).name,
    uid, createdAt: dAgo(randI(0, 20)),
  }));
  const r14 = await pool(notices, rec => api("notices", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r14.done - r14.failed}/${notices.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 15. STUDY MATERIALS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("📖 Study Materials…");
  const materials = [
    { title: "Algebra Revision Notes", subject: "Mathematics", grade: "Grade 7", type: "PDF",   size: "1.2 MB" },
    { title: "Newton's Laws of Motion", subject: "Physics",    grade: "Grade 9", type: "PDF",   size: "2.1 MB" },
    { title: "English Grammar Guide",   subject: "English",    grade: "Grade 5", type: "PDF",   size: "800 KB" },
    { title: "Islamic Studies Term 2",  subject: "Islamic Studies", grade: "Grade 6", type: "PDF", size: "1.5 MB" },
    { title: "History of Oman",         subject: "Social Studies", grade: "Grade 8", type: "PDF", size: "3.2 MB" },
    { title: "Arabic Vocabulary List",  subject: "Arabic",     grade: "Grade 4", type: "PDF",   size: "500 KB" },
    { title: "Biology Cell Structure",  subject: "Biology",    grade: "Grade 10", type: "PDF",  size: "4.0 MB" },
    { title: "Chemistry Periodic Table Notes", subject: "Chemistry", grade: "Grade 10", type: "PDF", size: "600 KB" },
  ].map((m, i) => ({
    id: `SM-SD-${String(i + 1).padStart(4, "0")}`,
    ...m,
    uploadedBy: pick(teachers).name,
    uploadDate: dAgo(randI(1, 60)).split("T")[0],
    downloads: randI(10, 150),
    status: "Published",
    description: `Comprehensive ${m.type} material for ${m.grade} ${m.subject} students.`,
    uid, createdAt: dAgo(randI(1, 60)),
  }));
  const r15 = await pool(materials, rec => api("studymaterial", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r15.done - r15.failed}/${materials.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 16. HOMEWORK
  // ══════════════════════════════════════════════════════════════════════════
  console.log("📝 Homework…");
  const homeworkItems = Array.from({ length: 12 }, (_, i) => {
    const t = pick(teachers);
    return {
      id: `HW-SD-${String(i + 1).padStart(4, "0")}`,
      title: pick(["Chapter Review Questions", "Math Practice Set", "Essay Draft", "Reading Comprehension", "Science Lab Report", "Vocabulary Worksheet"]),
      subject: pick(["Mathematics", "English", "Science", "Arabic", "Social Studies", "Islamic Studies"]),
      grade: pick(["Grade 4", "Grade 5", "Grade 6", "Grade 7", "Grade 8", "Grade 9"]),
      section: pick(["A", "B", "C"]),
      teacher: t.name,
      teacherId: t.id,
      dueDate: dAgo(randI(-5, 5)).split("T")[0],
      assignedDate: dAgo(randI(5, 15)).split("T")[0],
      description: "Complete the assigned tasks and submit before the due date.",
      totalMarks: pick([10, 20, 25, 50]),
      submissions: randI(10, 35),
      status: pick(["Active", "Active", "Closed"]),
      uid, createdAt: dAgo(randI(5, 15)),
    };
  });
  const r16 = await pool(homeworkItems, rec => api("homework", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r16.done - r16.failed}/${homeworkItems.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 17. GRADUATES
  // ══════════════════════════════════════════════════════════════════════════
  console.log("🎓 Graduates…");
  const grads = Array.from({ length: 20 }, (_, i) => ({
    id: `GRAD-SD-${String(i + 1).padStart(4, "0")}`,
    name: pick(["Fatima Al-Rawahi", "Omar Al-Balushi", "Rania Al-Kindi", "Yousef Al-Habsi", "Salma Al-Farsi", "Khalid Al-Amri", "Hessa Al-Naabi", "Marwan Al-Ghafri", "Noor Al-Busaidi", "Ali Al-Maqbali"]),
    graduationYear: pick([2022, 2023, 2024, 2025]),
    grade: "Grade 12",
    gpa: (randI(30, 50) / 10).toFixed(2),
    awards: pick(["Top of Class", "Subject Excellence", "Sports Champion", "None", "None"]),
    status: pick(["Alumni", "University Enrolled", "Working"]),
    university: pick(["Sultan Qaboos University", "University of Nizwa", "Gulf College", "UTAS Muscat", null, null]),
    program: pick(["Engineering", "Medicine", "Business", "IT", "Education", null]),
    uid, createdAt: dAgo(randI(200, 600)),
  }));
  const r17 = await pool(grads, rec => api("graduates", { method: "POST", body: JSON.stringify(rec) }, token));
  console.log(`  → ${r17.done - r17.failed}/${grads.length} inserted\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // Summary
  // ══════════════════════════════════════════════════════════════════════════
  console.log("═".repeat(55));
  console.log("✅  Seeding complete!");
  console.log("Modules populated:");
  console.log("  • Health Records");
  console.log("  • Hostel Rooms & Allocations");
  console.log("  • Mess Menu (Cafeteria)");
  console.log("  • Inventory");
  console.log("  • Payroll");
  console.log("  • Behavior Incidents");
  console.log("  • Achievements");
  console.log("  • Scholarships");
  console.log("  • Purchase Orders");
  console.log("  • Vendors");
  console.log("  • Transport Drivers & Enrollments");
  console.log("  • Library Items");
  console.log("  • Bank Transactions");
  console.log("  • Notices");
  console.log("  • Study Materials");
  console.log("  • Homework");
  console.log("  • Graduates");
  console.log("═".repeat(55));
}

main().catch(e => { console.error("FATAL:", e); process.exit(1); });
