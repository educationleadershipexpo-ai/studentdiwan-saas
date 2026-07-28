/**
 * seed-demo-more.mjs
 * 
 * Cleans + reseeds 5 key modules with fresh, realistic Omani-school context demo data:
 *   1. Calendar Events   → CalendarEvent
 *   2. Noticeboard        → Notice
 *   3. Library            → LibraryItem, LibraryCopy, library_loans
 *   4. Homework           → Homework, HomeworkSubmission
 *   5. Live Classes       → LiveClass
 *
 * Usage: node scripts/seed-demo-more.mjs
 */

const BASE         = "https://portal.studentdiwan.com";
const ADMIN_EMAIL  = "admin@eduerp.com";
const ADMIN_PASS   = "admin123";
const DELAY        = 1000;  // 1s delay to prevent overloading MySQL pool
const INIT_WAIT    = 8000;  // 8s initial wait

// ── Helpers ──────────────────────────────────────────────────────────────────
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function apiCall(path, opts, token, attempt = 0) {
  const headers = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(opts?.headers || {})
  };
  try {
    const res = await fetch(`${BASE}/api/data/${path}`, { ...opts, headers });
    if (!res.ok) {
      const text = await res.text().catch(() => "");
      if ((text.includes("prepare") || text.includes("max_user_conn") || text.includes("null")) && attempt < 3) {
        console.warn(`  [Retry ${attempt + 1}] MySQL pool issue. Waiting 5s before retry...`);
        await sleep(5000);
        return apiCall(path, opts, token, attempt + 1);
      }
      throw new Error(`${opts?.method || "GET"} /api/data/${path} ${res.status}: ${text.slice(0, 150)}`);
    }
    return res.status === 204 ? null : await res.json().catch(() => null);
  } catch (err) {
    if (attempt < 3) {
      console.warn(`  [Retry ${attempt + 1}] Fetch error: ${err.message}. Waiting 5s...`);
      await sleep(5000);
      return apiCall(path, opts, token, attempt + 1);
    }
    throw err;
  }
}

async function apiGet(table, token) {
  try {
    return await apiCall(table, undefined, token);
  } catch (err) {
    console.warn(`  ⚠ Failed to get ${table}: ${err.message}`);
    return [];
  }
}

async function apiPost(table, data, token) {
  return await apiCall(table, { method: "POST", body: JSON.stringify(data) }, token);
}

async function apiDelete(table, id, token) {
  try {
    await apiCall(`${table}/${encodeURIComponent(id)}`, { method: "DELETE" }, token);
  } catch (err) {
    console.warn(`  ⚠ Failed to delete ${table}/${id}: ${err.message}`);
  }
}

async function cleanTable(table, label, token) {
  console.log(`🗑  Cleaning ${label} (${table})…`);
  const rows = await apiGet(table, token);
  if (!rows || !rows.length) { console.log(`   → Already empty`); return; }
  let delCount = 0;
  for (const row of rows) {
    await apiDelete(table, row.id, token);
    delCount++;
    await sleep(DELAY);
  }
  console.log(`   → Deleted ${delCount} rows`);
}

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

function getDaysOffsetDate(daysOffset) {
  const d = new Date();
  d.setDate(d.getDate() + daysOffset);
  return d.toISOString().slice(0, 10);
}

// ── Seeding Calendar Events ──────────────────────────────────────────────────
async function seedCalendarEvents(token) {
  console.log("\n📅 Seeding Calendar Events…");
  await cleanTable("CalendarEvent", "Calendar Events", token);

  const events = [
    {
      id: "CAL-EVT-001",
      title: "Omani National Day Celebrations",
      description: "Annual parade, student performances, and cultural exhibition in the school courtyard.",
      date: getDaysOffsetDate(15),
      time: "08:30 AM",
      location: "School Main Courtyard",
      category: "Exhibition",
      color: "bg-emerald-500",
      status: "Published",
      targetAudience: "All",
      source: "Manual",
      createdBy: "admin-uid"
    },
    {
      id: "CAL-EVT-002",
      title: "Term 1 Final Examination Start",
      description: "Mid-year final assessments begin for Grade 5 to Grade 12.",
      date: getDaysOffsetDate(10),
      time: "08:00 AM",
      location: "School Exam Hall & Classrooms",
      category: "Exams",
      color: "bg-red-500",
      status: "Published",
      targetAudience: "Students",
      source: "Exam",
      createdBy: "admin-uid"
    },
    {
      id: "CAL-EVT-003",
      title: "Parent-Teacher Association (PTA) Meeting",
      description: "First parent-teacher conference of the academic term to review syllabus progression.",
      date: getDaysOffsetDate(5),
      time: "04:30 PM",
      location: "Auditorium",
      category: "Meetings",
      color: "bg-purple-500",
      status: "Published",
      targetAudience: "Parents",
      source: "PTM",
      createdBy: "admin-uid"
    },
    {
      id: "CAL-EVT-004",
      title: "Annual Sports Day",
      description: "Track events, relay races, and football finals across houses.",
      date: getDaysOffsetDate(25),
      time: "07:30 AM",
      location: "Sports Ground & Track",
      category: "Sports",
      color: "bg-blue-500",
      status: "Published",
      targetAudience: "All",
      source: "Manual",
      createdBy: "admin-uid"
    },
    {
      id: "CAL-EVT-005",
      title: "Prophet's Birthday Holiday (Mawlid)",
      description: "National holiday observed. School closed.",
      date: getDaysOffsetDate(12),
      time: "All Day",
      location: "Nationwide",
      category: "Holidays",
      color: "bg-amber-500",
      status: "Published",
      targetAudience: "All",
      source: "Manual",
      createdBy: "admin-uid"
    },
    {
      id: "CAL-EVT-006",
      title: "AI & Robotics Science Exhibition",
      description: "Students showcase coding, robotics, and smart home projects in the library lobby.",
      date: getDaysOffsetDate(18),
      time: "09:00 AM",
      location: "Library Lobby",
      category: "Exhibition",
      color: "bg-emerald-500",
      status: "Published",
      targetAudience: "All",
      source: "Manual",
      createdBy: "admin-uid"
    },
    {
      id: "CAL-EVT-007",
      title: "Academic Staff Curriculum Alignment Workshop",
      description: "Term 2 curriculum alignment and exam preparation workshop for all teachers.",
      date: getDaysOffsetDate(-2),
      time: "02:00 PM",
      location: "Conference Room A",
      category: "Meetings",
      color: "bg-purple-500",
      status: "Published",
      targetAudience: "Staff",
      source: "Manual",
      createdBy: "admin-uid"
    },
    {
      id: "CAL-EVT-008",
      title: "Arabic Creative Writing Competition",
      description: "Special session for middle school students to submit creative stories and poems.",
      date: getDaysOffsetDate(4),
      time: "10:30 AM",
      location: "Classroom 8-A",
      category: "Academic",
      color: "bg-indigo-500",
      status: "Published",
      targetAudience: "Students",
      source: "Manual",
      createdBy: "admin-uid"
    }
  ];

  let count = 0;
  for (const ev of events) {
    try {
      await apiPost("CalendarEvent", ev, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} calendar events`);
}

// ── Seeding Noticeboard (Notice) ─────────────────────────────────────────────
async function seedNotices(token) {
  console.log("\n📢 Seeding Noticeboard (Notice)…");
  await cleanTable("Notice", "Noticeboard", token);

  const notices = [
    {
      id: "NOTIC-001",
      title: "Announcement of Term 1 Exams Schedule",
      content: "Dear Parents and Students, the official exam schedules for Term 1 are now uploaded under Exam Operations. Assessments will commence on the scheduled date. Please ensure students prepare appropriately. Hall tickets will be issued starting next week.",
      category: "Academic",
      priority: "High",
      status: "Published",
      targetAudience: "All",
      postedBy: "Dr. Sarah Mitchell",
      date: getDaysOffsetDate(0),
      views: 142,
      uid: "admin-uid"
    },
    {
      id: "NOTIC-002",
      title: "Important Notice: School Fees Term 1 Due",
      content: "Please note that the final deadline for Term 1 tuition fees and transport services is fast approaching. Payments can be settled online through the secure Payments portal or directly at the finance office during working hours.",
      category: "Finance",
      priority: "High",
      status: "Published",
      targetAudience: "Parents",
      postedBy: "Robert Wilson",
      date: getDaysOffsetDate(-1),
      views: 95,
      uid: "admin-uid"
    },
    {
      id: "NOTIC-003",
      title: "National Day Celebration Attendance & Dress Code",
      content: "Oman National Day celebrations are scheduled at the school courtyard. Students are encouraged to dress in Omani traditional attire or national colors (green, white, red) to showcase their patriotic spirit. Celebrations end at 12:30 PM, buses will depart thereafter.",
      category: "Event",
      priority: "Medium",
      status: "Published",
      targetAudience: "All",
      postedBy: "Dr. Sarah Mitchell",
      date: getDaysOffsetDate(1),
      views: 204,
      uid: "admin-uid"
    },
    {
      id: "NOTIC-004",
      title: "Urgent: Influenza Vaccination Campaign in School Clinic",
      content: "In coordination with the Ministry of Health, our school clinic is organizing a voluntary seasonal flu vaccine drive. Consent forms have been emailed to all parents. Only students with a signed physical consent form will receive the vaccine.",
      category: "Urgent",
      priority: "High",
      status: "Published",
      targetAudience: "Parents",
      postedBy: "Nurse Maryam Al-Balushi",
      date: getDaysOffsetDate(0),
      views: 78,
      uid: "admin-uid"
    },
    {
      id: "NOTIC-005",
      title: "Updated Bus Route Schedules for Winter Season",
      content: "To accommodate route optimization and seasonal traffic adjustments, morning pickup times for Zone B and Zone D have been slightly adjusted by 10-15 minutes. Please check your specific route details under Transport -> Fleet in your portal.",
      category: "General",
      priority: "Medium",
      status: "Published",
      targetAudience: "Parents",
      postedBy: "Transport Manager",
      date: getDaysOffsetDate(-3),
      views: 110,
      uid: "admin-uid"
    },
    {
      id: "NOTIC-006",
      title: "Notice: Weekly Homework Submissions Policy",
      content: "Teachers have noticed several late homework submissions. Please note that starting this term, all weekly homework assignments must be submitted before 11:59 PM on the due date. System locks submissions automatically thereafter.",
      category: "Academic",
      priority: "Medium",
      status: "Published",
      targetAudience: "Students",
      postedBy: "Fatima Al-Rashid",
      date: getDaysOffsetDate(-5),
      views: 185,
      uid: "admin-uid"
    }
  ];

  let count = 0;
  for (const n of notices) {
    try {
      await apiPost("Notice", n, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} notices`);
}

// ── Seeding Library ──────────────────────────────────────────────────────────
async function seedLibrary(token) {
  console.log("\n📚 Seeding Library module…");
  await cleanTable("LibraryItem", "Library Catalogue Items", token);
  await cleanTable("LibraryCopy", "Library Copy Records", token);
  await cleanTable("library_loans", "Library Loans Log", token);

  const books = [
    {
      id: "LIB-BK-001",
      title: "The Alchemist",
      author: "Paulo Coelho",
      category: "Literature",
      status: "Available",
      isbn: "9780061122415",
      type: "Book",
      totalCopies: 3,
      shelfLocation: "LIT-A-1",
      publisher: "HarperOne",
      language: "English",
      edition: "25th Anniversary",
      publicationYear: "2014",
      coverUrl: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=400"
    },
    {
      id: "LIB-BK-002",
      title: "A Brief History of Time",
      author: "Stephen Hawking",
      category: "Science",
      status: "Available",
      isbn: "9780553380163",
      type: "Book",
      totalCopies: 2,
      shelfLocation: "SCI-B-2",
      publisher: "Bantam Books",
      language: "English",
      edition: "10th Anniversary",
      publicationYear: "1998",
      coverUrl: "https://images.unsplash.com/photo-1532012197267-da84d127e765?w=400"
    },
    {
      id: "LIB-BK-003",
      title: "The Muqaddimah: An Introduction to History",
      author: "Ibn Khaldun",
      category: "History",
      status: "Borrowed",
      isbn: "9780691166285",
      type: "Book",
      totalCopies: 2,
      shelfLocation: "HIS-C-1",
      publisher: "Princeton University Press",
      language: "English",
      edition: "Bollingen Series",
      publicationYear: "2015",
      coverUrl: "https://images.unsplash.com/photo-1516979187457-637abb4f9353?w=400"
    },
    {
      id: "LIB-BK-004",
      title: "Basic Algebra for Grades 9-10",
      author: "Omani Ministry of Education",
      category: "Mathematics",
      status: "Available",
      isbn: "MOE-OM-MAT-09",
      type: "Book",
      totalCopies: 5,
      shelfLocation: "MAT-D-3",
      publisher: "MoE Publishing",
      language: "Arabic",
      edition: "2024 Edition",
      publicationYear: "2024",
      coverUrl: "https://images.unsplash.com/photo-1509228468518-180dd4864904?w=400"
    },
    {
      id: "LIB-BK-005",
      title: "Python Coding for Young Creators",
      author: "K. Mansoor & N. Patel",
      category: "Technology",
      status: "Borrowed",
      isbn: "9781119543136",
      type: "Book",
      totalCopies: 3,
      shelfLocation: "TECH-A-4",
      publisher: "Wiley Kids",
      language: "English",
      edition: "2nd Edition",
      publicationYear: "2021",
      coverUrl: "https://images.unsplash.com/photo-1515879218367-8466d910aaa4?w=400"
    }
  ];

  let bCount = 0;
  for (const b of books) {
    try {
      await apiPost("LibraryItem", b, token);
      bCount++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${bCount} library catalogue books`);

  const copies = [
    { id: "LIB-BK-001-C1", bookId: "LIB-BK-001", bookTitle: "The Alchemist", accessionNo: "LIB-BK-001-C1", status: "Available" },
    { id: "LIB-BK-001-C2", bookId: "LIB-BK-001", bookTitle: "The Alchemist", accessionNo: "LIB-BK-001-C2", status: "Available" },
    { id: "LIB-BK-001-C3", bookId: "LIB-BK-001", bookTitle: "The Alchemist", accessionNo: "LIB-BK-001-C3", status: "Available" },
    
    { id: "LIB-BK-002-C1", bookId: "LIB-BK-002", bookTitle: "A Brief History of Time", accessionNo: "LIB-BK-002-C1", status: "Available" },
    { id: "LIB-BK-002-C2", bookId: "LIB-BK-002", bookTitle: "A Brief History of Time", accessionNo: "LIB-BK-002-C2", status: "Available" },
    
    { id: "LIB-BK-003-C1", bookId: "LIB-BK-003", bookTitle: "The Muqaddimah: An Introduction to History", accessionNo: "LIB-BK-003-C1", status: "Borrowed", borrowedBy: "STD-1002", borrowerName: "Hana Al-Farsi", issueDate: getDaysOffsetDate(-5), dueDate: getDaysOffsetDate(9) },
    { id: "LIB-BK-003-C2", bookId: "LIB-BK-003", bookTitle: "The Muqaddimah: An Introduction to History", accessionNo: "LIB-BK-003-C2", status: "Available" },
    
    { id: "LIB-BK-004-C1", bookId: "LIB-BK-004", bookTitle: "Basic Algebra for Grades 9-10", accessionNo: "LIB-BK-004-C1", status: "Available" },
    { id: "LIB-BK-004-C2", bookId: "LIB-BK-004", bookTitle: "Basic Algebra for Grades 9-10", accessionNo: "LIB-BK-004-C2", status: "Available" },
    { id: "LIB-BK-004-C3", bookId: "LIB-BK-004", bookTitle: "Basic Algebra for Grades 9-10", accessionNo: "LIB-BK-004-C3", status: "Available" },
    
    { id: "LIB-BK-005-C1", bookId: "LIB-BK-005", bookTitle: "Python Coding for Young Creators", accessionNo: "LIB-BK-005-C1", status: "Borrowed", borrowedBy: "STD-1005", borrowerName: "Youssef Omar", issueDate: getDaysOffsetDate(-8), dueDate: getDaysOffsetDate(6) },
    { id: "LIB-BK-005-C2", bookId: "LIB-BK-005", bookTitle: "Python Coding for Young Creators", accessionNo: "LIB-BK-005-C2", status: "Available" }
  ];

  let cCount = 0;
  for (const c of copies) {
    try {
      await apiPost("LibraryCopy", c, token);
      cCount++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${cCount} physical copy records`);

  const loans = [
    {
      id: "LOAN-001",
      bookId: "LIB-BK-003",
      bookTitle: "The Muqaddimah: An Introduction to History",
      copyId: "LIB-BK-003-C1",
      accessionNo: "LIB-BK-003-C1",
      studentId: "STD-1002",
      studentName: "Hana Al-Farsi",
      issueDate: getDaysOffsetDate(-5),
      dueDate: getDaysOffsetDate(9),
      returnedAt: null,
      overdue: false
    },
    {
      id: "LOAN-002",
      bookId: "LIB-BK-005",
      bookTitle: "Python Coding for Young Creators",
      copyId: "LIB-BK-005-C1",
      accessionNo: "LIB-BK-005-C1",
      studentId: "STD-1005",
      studentName: "Youssef Omar",
      issueDate: getDaysOffsetDate(-8),
      dueDate: getDaysOffsetDate(6),
      returnedAt: null,
      overdue: false
    },
    {
      id: "LOAN-003",
      bookId: "LIB-BK-001",
      bookTitle: "The Alchemist",
      copyId: "LIB-BK-001-C1",
      accessionNo: "LIB-BK-001-C1",
      studentId: "STD-1001",
      studentName: "Zain Ahmed",
      issueDate: getDaysOffsetDate(-20),
      dueDate: getDaysOffsetDate(-6),
      returnedAt: getDaysOffsetDate(-7),
      overdue: false
    }
  ];

  let lCount = 0;
  for (const l of loans) {
    try {
      await apiPost("library_loans", l, token);
      lCount++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${lCount} active and historical loan records`);
}

// ── Seeding Homework ─────────────────────────────────────────────────────────
async function seedHomework(token) {
  console.log("\n📝 Seeding Homework module…");
  await cleanTable("Homework", "Homework Assignments", token);
  await cleanTable("HomeworkSubmission", "Homework Submissions", token);

  const homework = [
    {
      id: "HW-001",
      title: "Algebra Problems Exercise 3.2",
      description: "Solve linear equations from questions 1 to 10 on page 78 of your textbook. Write down all steps clearly.",
      subject: "Mathematics",
      dueDate: getDaysOffsetDate(1),
      assignedBy: "Fatima Al-Rashid",
      initials: "FR",
      grade: "10",
      section: "A"
    },
    {
      id: "HW-002",
      title: "Omani Empire History Essay",
      description: "Write a 300-word essay about the trade routes established by the Omani Empire in East Africa during the 18th century.",
      subject: "History",
      dueDate: getDaysOffsetDate(3),
      assignedBy: "Tariq Jaber",
      initials: "TJ",
      grade: "10",
      section: "A"
    },
    {
      id: "HW-003",
      title: "Plant Photosynthesis Experiment Review",
      description: "Summarize the experiment we conducted in the laboratory regarding light absorption of green leaves. Answer the 5 questions listed in the handout.",
      subject: "Science",
      dueDate: getDaysOffsetDate(-2),
      assignedBy: "Sara Mohamed",
      initials: "SM",
      grade: "10",
      section: "A"
    },
    {
      id: "HW-004",
      title: "Python Basic Loop Structures Exercise",
      description: "Write a simple script using a 'for' loop to print numbers from 1 to 50, and highlight all multiples of 5.",
      subject: "Computer Science",
      dueDate: getDaysOffsetDate(2),
      assignedBy: "Omar Yusuf",
      initials: "OY",
      grade: "10",
      section: "A"
    }
  ];

  let hwCount = 0;
  for (const hw of homework) {
    try {
      await apiPost("Homework", hw, token);
      hwCount++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${hwCount} homework assignments`);

  const submissions = [
    {
      id: "HW-SUB-001",
      homeworkId: "HW-003",
      studentId: "STD-1001",
      studentName: "Zain Ahmed",
      submittedAt: new Date(Date.now() - 3 * 86400000).toISOString(),
      status: "graded",
      score: "95/100",
      feedback: "Excellent description of the light-spectrum parameters. Well written!",
      text: "The leaf chromatography shows distinct bands corresponding to chlorophyll A, chlorophyll B, and carotene pigments. Under red light, absorption was highest."
    },
    {
      id: "HW-SUB-002",
      homeworkId: "HW-003",
      studentId: "STD-1002",
      studentName: "Hana Al-Farsi",
      submittedAt: new Date(Date.now() - 2 * 86400000).toISOString(),
      status: "submitted",
      score: null,
      feedback: "",
      text: "My experimental data and lab questions are uploaded here. The controls did not exhibit bubble formation."
    }
  ];

  let subCount = 0;
  for (const s of submissions) {
    try {
      await apiPost("HomeworkSubmission", s, token);
      subCount++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${subCount} homework submission records`);
}

// ── Seeding Live Classes ─────────────────────────────────────────────────────
async function seedLiveClasses(token) {
  console.log("\n📺 Seeding Live Classes…");
  await cleanTable("LiveClass", "Live Classes", token);

  const classes = [
    {
      id: "LC-001",
      title: "Algebraic Formulas & Roots Review",
      subject: "Mathematics",
      date: getDaysOffsetDate(0),
      time: "10:30 AM",
      duration: 45,
      grade: "10",
      section: "A",
      teacherName: "Fatima Al-Rashid",
      meetingLink: "https://zoom.us/j/9876543210",
      status: "scheduled",
      description: "Interactive revision of quadratic equations and root properties ahead of the exams next week."
    },
    {
      id: "LC-002",
      title: "English Grammar: Tense Alignment & Patterns",
      subject: "English",
      date: getDaysOffsetDate(1),
      time: "09:00 AM",
      duration: 60,
      grade: "10",
      section: "A",
      teacherName: "Noor Patel",
      meetingLink: "https://zoom.us/j/9876543211",
      status: "scheduled",
      description: "Deep dive into present perfect vs past simple tense structures and passive voice construction."
    },
    {
      id: "LC-003",
      title: "Physics: Chemical Bond Strength & Kinetics",
      subject: "Science",
      date: getDaysOffsetDate(0),
      time: "12:00 PM",
      duration: 45,
      grade: "10",
      section: "A",
      teacherName: "Sara Mohamed",
      meetingLink: "https://zoom.us/j/9876543212",
      status: "live",
      description: "Live lab demonstration of exothermic reactions and catalyst effect analysis. Join now!"
    },
    {
      id: "LC-004",
      title: "Oman History: Rise of Muscat Port trade",
      subject: "History",
      date: getDaysOffsetDate(-1),
      time: "11:00 AM",
      duration: 45,
      grade: "10",
      section: "A",
      teacherName: "Tariq Jaber",
      meetingLink: "https://zoom.us/j/9876543213",
      status: "completed",
      description: "Completed lecture on maritime trade links, fort architectures, and diplomatic treaties of Oman."
    }
  ];

  let cCount = 0;
  for (const c of classes) {
    try {
      await apiPost("LiveClass", c, token);
      cCount++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${cCount} live classes`);
}

// ── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log("═══════════════════════════════════════════════════");
  console.log("  Student Diwan — Demo Data Seeder (More Modules)");
  console.log("═══════════════════════════════════════════════════");
  console.log(`  Target: ${BASE}`);
  console.log(`  Time:   ${new Date().toISOString()}\n`);

  console.log("🔐 Logging in…");
  let lr, loginData;
  for (let attempt = 1; attempt <= 5; attempt++) {
    try {
      lr = await fetch(`${BASE}/api/session/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASS }),
      });
      if (lr.ok) {
        loginData = await lr.json();
        break;
      }
      console.warn(`  [Login Attempt ${attempt}] Failed with status ${lr.status}. Waiting 5s...`);
      await sleep(5000);
    } catch (e) {
      console.warn(`  [Login Attempt ${attempt}] Error: ${e.message}. Waiting 5s...`);
      await sleep(5000);
    }
  }
  
  if (!loginData || !loginData.token) {
    throw new Error("No token returned from login after 5 attempts");
  }
  const token = loginData.token;
  console.log("  ✓ Authenticated");
  console.log(`  ⏳ Waiting ${INIT_WAIT/1000}s for MySQL pool to settle…`);
  await sleep(INIT_WAIT);

  await seedCalendarEvents(token);
  await seedNotices(token);
  await seedLibrary(token);
  await seedHomework(token);
  await seedLiveClasses(token);

  console.log("\n═══════════════════════════════════════════════════");
  console.log("  ✅ ALL MODULES SEEDED SUCCESSFULLY");
  console.log("═══════════════════════════════════════════════════");
}

main().catch(console.error);
