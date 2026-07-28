/**
 * seed-4modules-v2.mjs
 * Fixed version: waits for DB pool to recover, uses fallback teacher names,
 * increases delay and retries failed requests.
 */

const BASE         = "https://portal.studentdiwan.com";
const ADMIN_EMAIL  = "admin@eduerp.com";
const ADMIN_PASS   = "admin123";
const DELAY        = 500;   // ms between every request
const INIT_WAIT    = 6000;  // ms to wait after login for pool to recover

const sleep = ms => new Promise(r => setTimeout(r, ms));

// ── HTTP helper with 1 retry ─────────────────────────────────────────────────
const api = async (path, opts, token, attempt = 0) => {
  const headers = {
    "Content-Type": "application/json",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...(opts?.headers || {}),
  };
  try {
    const r = await fetch(`${BASE}/api/data/${path}`, { ...opts, headers });
    if (!r.ok) {
      const txt = await r.text().catch(() => "");
      // If pool is busy, wait and retry once
      if ((txt.includes("prepare") || txt.includes("max_user_conn")) && attempt === 0) {
        await sleep(3000);
        return api(path, opts, token, 1);
      }
      throw new Error(`${opts?.method || "GET"} /api/data/${path} → ${r.status}: ${txt.slice(0, 120)}`);
    }
    return r.status === 204 ? null : r.json().catch(() => null);
  } catch (e) {
    if (attempt === 0 && e.message.includes("fetch")) {
      await sleep(2000);
      return api(path, opts, token, 1);
    }
    throw e;
  }
};

// ── Purge all rows from a table one-by-one ────────────────────────────────────
async function purge(entity, token) {
  let rows;
  try { rows = await api(entity, undefined, token); }
  catch (e) { console.warn(`  ⚠ Cannot fetch ${entity}: ${e.message.slice(0, 80)}`); rows = []; }
  if (!Array.isArray(rows) || !rows.length) { console.log(`  (${entity}: empty — nothing to delete)`); return; }
  let del = 0;
  for (const row of rows) {
    try { await api(`${entity}/${row.id}`, { method: "DELETE" }, token); del++; }
    catch {}
    await sleep(DELAY);
  }
  console.log(`  ✓ Deleted ${del}/${rows.length} from ${entity}`);
}

// ── Sequential insert ─────────────────────────────────────────────────────────
async function insertAll(label, entity, records, token) {
  let ok = 0;
  for (const rec of records) {
    try { await api(entity, { method: "POST", body: JSON.stringify(rec) }, token); ok++; }
    catch (e) { /* skip duplicates silently */ }
    await sleep(DELAY);
  }
  console.log(`  ✓ ${label}: ${ok}/${records.length} inserted`);
}

const pick   = arr => arr[Math.floor(Math.random() * arr.length)];
const randI  = (lo, hi) => Math.floor(Math.random() * (hi - lo + 1)) + lo;
const dAgo   = n => new Date(Date.now() - n * 86400e3).toISOString();
const pad    = (n, l = 4) => String(n).padStart(l, "0");
const uid    = "admin-001";

// Fallback teachers if staff fetch returns 0
const FALLBACK_TEACHERS = [
  { id: "t-001", name: "Mr. Ahmed Al-Rashdi",    role: "Teacher" },
  { id: "t-002", name: "Ms. Fatima Al-Balushi",   role: "Teacher" },
  { id: "t-003", name: "Mr. Khalid Al-Amri",      role: "Teacher" },
  { id: "t-004", name: "Ms. Nadia Al-Kindi",      role: "Teacher" },
  { id: "t-005", name: "Mr. Omar Al-Habsi",        role: "Teacher" },
  { id: "t-006", name: "Ms. Rania Al-Farsi",       role: "Teacher" },
  { id: "t-007", name: "Mr. Yousuf Al-Ghafri",    role: "Teacher" },
  { id: "t-008", name: "Ms. Salma Al-Maqbali",    role: "Teacher" },
];

// Fallback student names if students fetch returns 0
const FALLBACK_STUDENTS = [
  { id: "s-001", name: "Ali Al-Balushi",       grade: "Grade 7",  section: "A" },
  { id: "s-002", name: "Fatima Al-Rawahi",     grade: "Grade 8",  section: "B" },
  { id: "s-003", name: "Omar Al-Kindi",        grade: "Grade 6",  section: "A" },
  { id: "s-004", name: "Mariam Al-Farsi",      grade: "Grade 9",  section: "C" },
  { id: "s-005", name: "Yousef Al-Busaidi",    grade: "Grade 10", section: "A" },
  { id: "s-006", name: "Noor Al-Habsi",        grade: "Grade 7",  section: "B" },
  { id: "s-007", name: "Khalid Al-Maqbali",    grade: "Grade 5",  section: "A" },
  { id: "s-008", name: "Hessa Al-Naabi",       grade: "Grade 8",  section: "A" },
  { id: "s-009", name: "Saif Al-Amri",         grade: "Grade 9",  section: "B" },
  { id: "s-010", name: "Reem Al-Lawati",       grade: "Grade 6",  section: "C" },
  { id: "s-011", name: "Ibrahim Al-Harthy",    grade: "Grade 10", section: "B" },
  { id: "s-012", name: "Zahra Al-Siyabi",      grade: "Grade 7",  section: "C" },
  { id: "s-013", name: "Turki Al-Mukhaini",    grade: "Grade 8",  section: "A" },
  { id: "s-014", name: "Amna Al-Abri",         grade: "Grade 5",  section: "B" },
  { id: "s-015", name: "Bilal Al-Yaarubi",     grade: "Grade 9",  section: "A" },
  { id: "s-016", name: "Aisha Al-Maskari",     grade: "Grade 6",  section: "A" },
  { id: "s-017", name: "Nabil Al-Riyami",      grade: "Grade 10", section: "C" },
  { id: "s-018", name: "Sana Al-Bulushi",      grade: "Grade 7",  section: "A" },
  { id: "s-019", name: "Faisal Al-Rashdi",     grade: "Grade 8",  section: "B" },
  { id: "s-020", name: "Lubna Al-Kharousi",    grade: "Grade 9",  section: "C" },
  ...Array.from({ length: 30 }, (_, i) => ({
    id: `s-${String(i + 21).padStart(3,"0")}`,
    name: `Student ${i + 21}`,
    grade: pick(["Grade 4","Grade 5","Grade 6","Grade 7","Grade 8","Grade 9","Grade 10"]),
    section: pick(["A","B","C"]),
  })),
];

// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log(`\n🔐 Logging in …`);
  const lr = await fetch(`${BASE}/api/session/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASS }),
  });
  const { token } = await lr.json();
  if (!token) throw new Error("Login failed");
  console.log(`  ✓ Logged in\n  ⏳ Waiting ${INIT_WAIT/1000}s for MySQL pool to settle …`);
  await sleep(INIT_WAIT);

  // Fetch base data with fallbacks
  console.log("  📦 Fetching students & staff …");
  let students = [], staff = [];
  try { students = await api("students", undefined, token); } catch (e) { console.warn("  ⚠ students fetch:", e.message.slice(0,60)); }
  try { staff    = await api("staff",    undefined, token); } catch (e) { console.warn("  ⚠ staff fetch:",    e.message.slice(0,60)); }

  const useStudents = (students && students.length > 0) ? students.slice(0, 80) : FALLBACK_STUDENTS;
  const useTeachers = (staff && staff.filter(s => /teacher/i.test(s.role||"")).length > 0)
    ? staff.filter(s => /teacher/i.test(s.role||""))
    : (staff && staff.length > 0 ? staff : FALLBACK_TEACHERS);
  console.log(`  students: ${useStudents.length} | teachers: ${useTeachers.length}\n`);

  // ══════════════════════════════════════════════════════════════════════════
  // 1. BEHAVIOR INCIDENTS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("──────────────────────────────────");
  console.log("🛡️  Behavior Incidents");
  console.log("──────────────────────────────────");
  await purge("behavior_incidents", token);

  const CASES = [
    { type:"Merit",   sev:"Low",    cat:"Academic Excellence",     desc:"Scored 100% in the unit test and received class recognition." },
    { type:"Merit",   sev:"Low",    cat:"Helping Peers",           desc:"Voluntarily tutored classmates before the exam without being asked." },
    { type:"Merit",   sev:"Low",    cat:"Class Leadership",        desc:"Led the class discussion effectively and ensured all voices were heard." },
    { type:"Merit",   sev:"Low",    cat:"Community Service",       desc:"Organised a classroom cleanup drive and encouraged peers to participate." },
    { type:"Merit",   sev:"Low",    cat:"Sports Achievement",      desc:"Represented the school at the inter-school football tournament — won MVP." },
    { type:"Merit",   sev:"Low",    cat:"Punctuality & Attendance",desc:"Maintained perfect attendance and punctuality for the entire term." },
    { type:"Merit",   sev:"Low",    cat:"Outstanding Teamwork",    desc:"Exceptional team coordination during the Science group project." },
    { type:"Merit",   sev:"Low",    cat:"Creative Contribution",   desc:"Submitted outstanding artwork for the Annual School Exhibition." },
    { type:"Demerit", sev:"Low",    cat:"Late Homework",           desc:"Homework submitted 2 days after the deadline without prior notification." },
    { type:"Demerit", sev:"Low",    cat:"Mobile Phone Violation",  desc:"Using mobile phone during class despite prior written warnings." },
    { type:"Demerit", sev:"Low",    cat:"Dress Code Violation",    desc:"Not wearing the correct school uniform on a standard school day." },
    { type:"Demerit", sev:"Low",    cat:"Classroom Noise",         desc:"Repeatedly talking out of turn during lesson — first warning issued." },
    { type:"Demerit", sev:"Medium", cat:"Disruption in Class",     desc:"Persistently disrupting learning for others; verbal warning logged." },
    { type:"Demerit", sev:"Medium", cat:"Disrespect to Teacher",   desc:"Used a disrespectful tone when asked to complete assigned work." },
    { type:"Demerit", sev:"Medium", cat:"Verbal Bullying",         desc:"Made unkind comments about a peer's appearance — reported by two witnesses." },
    { type:"Demerit", sev:"High",   cat:"Vandalism",               desc:"Intentionally damaged a classroom desk. Parents have been notified." },
    { type:"Demerit", sev:"High",   cat:"Examination Misconduct",  desc:"Found with unauthorised notes during the midterm exam. Zero mark issued." },
    { type:"Demerit", sev:"High",   cat:"Physical Altercation",    desc:"Physical confrontation with another student. Both families contacted." },
  ];

  const behaviorRecs = useStudents.slice(0, 50).map((s, i) => {
    const c = CASES[i % CASES.length];
    const t = pick(useTeachers);
    const d = randI(1, 45);
    return {
      id: `BI-FRESH-${pad(i+1)}`,
      studentId: s.id, studentName: s.name,
      grade: s.grade || "Grade 7", section: s.section || "A",
      type: c.type, category: c.cat, severity: c.sev, description: c.desc,
      date: dAgo(d).split("T")[0],
      reportedBy: t.name, teacherId: t.id,
      action: pick(["Verbal Warning","Written Warning","Merit Award","Parents Notified","Counselling","Detention","Reported to HOD","Merit Certificate"]),
      parentNotified: c.sev !== "Low" || Math.random() > 0.6,
      status: pick(["Open","Resolved","Resolved","Pending Review"]),
      uid, createdAt: dAgo(d),
    };
  });
  await insertAll("behavior_incidents", "behavior_incidents", behaviorRecs, token);

  // ══════════════════════════════════════════════════════════════════════════
  // 2. GRADUATES / ALUMNI
  // ══════════════════════════════════════════════════════════════════════════
  console.log("\n──────────────────────────────────");
  console.log("🎓  Graduates / Alumni");
  console.log("──────────────────────────────────");
  await purge("graduates", token);

  const ALUMNI = [
    "Fatima Bint Said Al-Rawahi","Omar Abdullah Al-Balushi","Rania Khalid Al-Kindi",
    "Yousef Nasser Al-Habsi","Salma Ibrahim Al-Farsi","Khalid Rashid Al-Amri",
    "Hessa Mohammed Al-Naabi","Marwan Tariq Al-Ghafri","Noor Issa Al-Busaidi",
    "Ali Salim Al-Maqbali","Maryam Hassan Al-Lawati","Qais Ahmed Al-Wahaibi",
    "Reem Abdullah Al-Hosni","Ibrahim Saud Al-Harthy","Zahra Mohammed Al-Siyabi",
    "Turki Khalid Al-Mukhaini","Amna Tariq Al-Abri","Saif Nasser Al-Amri",
    "Lubna Ahmed Al-Kharousi","Faisal Omar Al-Rashdi","Shaikha Yousef Al-Hinai",
    "Bilal Hamad Al-Yaarubi","Aisha Saif Al-Maskari","Nabil Sulaiman Al-Riyami",
    "Sana Khalid Al-Bulushi",
  ];
  const UNIVS = [
    "Sultan Qaboos University","University of Nizwa","A'Sharqiyah University",
    "Middle East College","Gulf College Muscat","UTAS Muscat","Dhofar University",null,null,
  ];
  const PROGS = ["Computer Engineering","Business Administration","Medicine & Surgery",
    "Electrical Engineering","Law","Education","Pharmacy","Information Technology","Finance",null];

  const gradRecs = ALUMNI.map((name, i) => {
    const yr = pick([2022,2023,2024,2025]);
    const univ = pick(UNIVS);
    return {
      id: `GRAD-FRESH-${pad(i+1)}`,
      name,
      year: yr.toString(),
      degree: "High School Diploma",
      gpa: (randI(27, 50)/10).toFixed(2),
      awards: pick(["Top of Class","Subject Excellence","Sports Champion","Best All-Rounder","None","None"]),
      status: pick(["Graduated","Graduated","Pending"]),
      email: `${name.split(" ")[0].toLowerCase()}.grad${i+1}@alumni.studentdiwan.om`,
      phone: `+968 9${randI(1000000,9999999)}`,
      date: `${yr}-06-${randI(20,30)}`,
      university: univ,
      program: univ ? pick(PROGS) : null,
      uid, createdAt: dAgo(randI(200,800)),
    };
  });
  await insertAll("graduates", "graduates", gradRecs, token);

  // ══════════════════════════════════════════════════════════════════════════
  // 3. ASSIGNMENTS (TeacherAssignment)
  // ══════════════════════════════════════════════════════════════════════════
  console.log("\n──────────────────────────────────");
  console.log("📋  Assignments");
  console.log("──────────────────────────────────");
  await purge("TeacherAssignment", token);

  const ASSIGN_DATA = [
    ["Mathematics",     "Chapter 5 – Fractions & Decimals Review",           "Complete exercises 5.1–5.4. Show all working.",                              "Homework",      "Grade 7","A"],
    ["English",         "Descriptive Writing: My Favourite Place",           "Write 250–300 words using sensory detail.",                                  "Essay",          "Grade 8","B"],
    ["Science",         "Lab Report: Photosynthesis Experiment",              "Write a formal lab report using PEEL structure.",                            "Lab Report",     "Grade 6","A"],
    ["Arabic",          "القراءة والفهم – الفصل الثالث",                    "أجب عن أسئلة الفهم من الصفحة ٤٥–٤٨ في كتاب النشاط.",                       "Worksheet",      "Grade 5","C"],
    ["Islamic Studies", "The Five Pillars of Islam – Research Summary",      "One-page research with references on any one pillar.",                       "Research Work",  "Grade 6","B"],
    ["Social Studies",  "Map Activity: Arabian Peninsula Countries",         "Label all GCC countries, capitals and water bodies on the blank map.",       "Worksheet",      "Grade 7","C"],
    ["Computer Science","Python Basics – Variables & Data Types",            "Complete the Codecademy lesson, screenshot your progress.",                  "Lab Activity",   "Grade 9","A"],
    ["Physics",         "Newton's Laws – Problem Set 3",                     "Solve problems 3.1–3.8 showing formula, substitution, and final answer.",    "Homework",       "Grade 10","A"],
    ["Biology",         "Cell Structure Diagram & Labelling",                "Draw and fully label a plant and animal cell from memory.",                  "Worksheet",      "Grade 10","B"],
    ["Chemistry",       "Periodic Table – Element Properties (1–20)",        "Record symbol, group, period and type for elements 1–20.",                  "Worksheet",      "Grade 10","C"],
    ["History",         "Essay: The Silk Road and Global Trade",             "Structured essay: intro + 3 body paragraphs + conclusion.",                  "Essay",          "Grade 8","A"],
    ["Mathematics",     "Geometry: Area and Perimeter Problems",             "Solve 12 questions. Show calculations and include a diagram for each.",      "Homework",       "Grade 6","A"],
    ["English",         "Novel Study: Summary of Chapters 6–10",            "Chapter-by-chapter summary identifying events and characters.",              "Reading Assignment","Grade 9","B"],
    ["Science",         "Worksheet: The Water Cycle",                        "Complete the diagram and answer 8 comprehension questions.",                 "Worksheet",      "Grade 7","A"],
    ["Arabic",          "تعبير كتابي: يوم لا أنساه",                       "اكتب تعبيراً عن ذكرى لا تُنسى في حياتك (١٥٠–٢٠٠ كلمة).",                  "Writing Assignment","Grade 6","C"],
    ["Computer Science","Spreadsheet Project – Student Grade Tracker",       "Excel: formulas for avg/max/min + chart.",                                   "Project",        "Grade 8","A"],
    ["Physics",         "Electricity Lab: Circuits and Resistance",          "Record measurements, data table, write conclusions.",                        "Lab Report",     "Grade 10","A"],
    ["Biology",         "Research: Communicable vs Non-Communicable Diseases","Present on one of each. Include causes, symptoms, prevention.",             "Research Work",  "Grade 9","C"],
    ["Chemistry",       "States of Matter – Group Poster Activity",          "A2 poster showing 3 states of matter with particle diagrams.",               "Group Activity", "Grade 8","B"],
    ["Mathematics",     "Algebra: Solving Linear Equations (20 Questions)",  "Show all steps clearly. Due before end of week.",                           "Homework",       "Grade 9","A"],
  ];

  const assignRecs = ASSIGN_DATA.map(([subj, title, instr, type, grade, section], i) => {
    const t = pick(useTeachers);
    const dueOffset = randI(-10, 20);
    const total = randI(22, 38);
    const subs  = dueOffset < -3 ? total : randI(0, total - 3);
    const status = dueOffset > 8 ? "Upcoming" : dueOffset < -5 ? pick(["Closed","Returned"]) : pick(["Active","Active","Active","Draft"]);
    return {
      id: `TA-FRESH-${pad(i+1)}`,
      title, subject: subj, type, grade, section,
      teacher: t.name, teacherId: t.id,
      dueDate: dAgo(-dueOffset).split("T")[0],
      totalMarks: pick([10,20,25,30,50,100]),
      submitted: subs, total,
      status,
      instructions: instr,
      allowLate: Math.random() > 0.5,
      notifyParents: Math.random() > 0.4,
      createdAt: dAgo(randI(3, 30)),
      uid,
    };
  });
  await insertAll("TeacherAssignment", "TeacherAssignment", assignRecs, token);

  // ══════════════════════════════════════════════════════════════════════════
  // 4. ASSESSMENTS
  // ══════════════════════════════════════════════════════════════════════════
  console.log("\n──────────────────────────────────");
  console.log("📊  Assessments");
  console.log("──────────────────────────────────");
  await purge("assessments", token);

  const q = (type, text, marks, extra={}) => ({
    id: `Q${Math.random().toString(36).slice(2,7)}`, type, text, marks, ...extra
  });
  const mcq = (text, marks) => q("MCQ", text, marks, {
    options: [{id:"a",text:"Option A (correct)"},{id:"b",text:"Option B"},{id:"c",text:"Option C"},{id:"d",text:"Option D"}],
    correctAnswer: "a",
  });
  const tf = (text, marks, ans="True") => q("True/False", text, marks, { correctAnswer: ans });
  const sa = (text, marks) => q("Short Answer", text, marks);
  const la = (text, marks) => q("Long Answer", text, marks);
  const fb = (text, marks) => q("Fill in the Blank", text, marks);
  const es = (text, marks) => q("Essay", text, marks);
  const db = (text, marks) => q("Diagram Based", text, marks);

  const ASSESSMENTS = [
    {
      id: "ASS-FRESH-0001", title: "Mid-Term Mathematics Test – Grade 7A",
      subject:"Mathematics", grade:"Grade 7", section:"A", type:"Test", chapter:"Chapter 3",
      duration:60, totalMarks:50, passingMarks:25, status:"Active", daysBack:2,
      description:"Covers fractions, decimals, ratios and proportion from Chapters 1–3.",
      questions:[mcq("What is 3/4 + 1/2?",5), mcq("Simplify the ratio 18:24.",5), sa("Solve: 4x + 7 = 23. Find x.",5), sa("Convert 0.75 to a fraction in simplest form.",5), la("A train travels 360 km in 4 h. Find speed and time for 540 km.",15), tf("The product of two negatives is always negative.","False",5), fb("The HCF of 12 and 18 is ___.",10)],
    },
    {
      id: "ASS-FRESH-0002", title: "Science Quiz – Ecosystems (Grade 6B)",
      subject:"Science", grade:"Grade 6", section:"B", type:"Quiz", chapter:"Chapter 4",
      duration:30, totalMarks:20, passingMarks:10, status:"Completed", daysBack:14,
      description:"Food chains, food webs and energy transfer.",
      questions:[mcq("Which organism is a primary consumer?",4), mcq("What do decomposers do?",4), tf("Plants are producers in a food chain.",4), sa("Name two examples of omnivores.",4), sa("Define the term 'biotic factor'.",4)],
    },
    {
      id: "ASS-FRESH-0003", title: "English Language – Formal Letter Writing",
      subject:"English Language", grade:"Grade 8", section:"A", type:"Assignment", chapter:"Chapter 2",
      duration:45, totalMarks:30, passingMarks:15, status:"Active", daysBack:1,
      description:"Students write a formal letter using structure taught in class.",
      questions:[es("Write a formal letter to the principal requesting a new science lab.",20), sa("Identify and explain 3 structural features of a formal letter.",10)],
    },
    {
      id: "ASS-FRESH-0004", title: "Physics Lab Assessment – Ohm's Law",
      subject:"Physics", grade:"Grade 10", section:"A", type:"Lab Assessment", chapter:"Chapter 6",
      duration:50, totalMarks:40, passingMarks:20, status:"Upcoming", daysBack:-6,
      description:"Practical assessment measuring V, I and R using Ohm's Law.",
      questions:[sa("State Ohm's Law and write its formula.",5), la("Describe the experiment to verify Ohm's Law with a labelled circuit diagram.",15), mcq("If V = 12V and R = 4Ω, what is the current?",5), fb("The SI unit of resistance is ___.",5), sa("What happens to resistance when temperature increases?",10)],
    },
    {
      id: "ASS-FRESH-0005", title: "Arabic Language – Comprehension Test (Grade 5C)",
      subject:"Arabic", grade:"Grade 5", section:"C", type:"Test", chapter:"Chapter 3",
      duration:40, totalMarks:30, passingMarks:15, status:"Active", daysBack:3,
      description:"Reading comprehension and grammar from the third chapter.",
      questions:[sa("اقرأ النص وأجب: ما الموضوع الرئيسي للقصة؟",6), sa("أعطِ ثلاث صفات لشخصية البطل.",6), fb("أكمل الجملة: ذهب الطفل إلى ___ في الصباح.",4), mcq("ما مضاد كلمة 'سعيد'؟",4), es("اكتب فقرة قصيرة (٥ جمل) عن يومك في المدرسة.",10)],
    },
    {
      id: "ASS-FRESH-0006", title: "Computer Science – Python Programming Test",
      subject:"Computer Science", grade:"Grade 9", section:"B", type:"Test", chapter:"Chapter 5",
      duration:45, totalMarks:40, passingMarks:20, status:"Draft", daysBack:10,
      description:"Variables, data types, loops and functions in Python.",
      questions:[mcq("Which keyword defines a function in Python?",4), tf("Python uses indentation to define code blocks.",4), sa("Write a Python statement to print 'Hello World'.",6), sa("What is the output of: print(type(3.14))?",6), la("Write a program to print all even numbers from 1 to 50.",20)],
    },
    {
      id: "ASS-FRESH-0007", title: "Islamic Studies – Five Pillars Worksheet",
      subject:"Islamic Studies", grade:"Grade 6", section:"A", type:"Worksheet", chapter:"Chapter 1",
      duration:30, totalMarks:25, passingMarks:13, status:"Completed", daysBack:21,
      description:"Covers the Five Pillars of Islam and their significance.",
      questions:[fb("The first pillar of Islam is ___ (Shahadah).",5), mcq("How many times do Muslims pray daily?",5), sa("Explain the importance of Zakat in Islam.",5), sa("What is the significance of the Hajj pilgrimage?",5), es("Describe how fasting during Ramadan benefits the Muslim community.",5)],
    },
    {
      id: "ASS-FRESH-0008", title: "Biology – Cell Structure & Function Project",
      subject:"Biology", grade:"Grade 10", section:"B", type:"Project", chapter:"Chapter 2",
      duration:0, totalMarks:50, passingMarks:25, status:"Active", daysBack:4,
      description:"Group project on animal vs plant cells structure and function.",
      questions:[es("Write a detailed report comparing animal and plant cells.",25), db("Draw and label a plant cell and an animal cell clearly.",25)],
    },
  ];

  const assessmentRecs = ASSESSMENTS.map(def => {
    const t = pick(useTeachers);
    const total = randI(22, 40);
    const subs = def.status === "Completed" ? total : def.status === "Active" ? randI(5, total-4) : 0;
    return {
      ...def,
      teacher: t.name, teacherId: t.id,
      date: dAgo(def.daysBack).split("T")[0],
      submissions: subs, totalStudents: total,
      resultVisibility: pick(["immediate","manual"]),
      resultsReleased: def.status === "Completed",
      createdAt: dAgo(def.daysBack + randI(0,3)),
      uid,
    };
  });
  await insertAll("assessments", "assessments", assessmentRecs, token);

  // ══════════════════════════════════════════════════════════════════════════
  console.log("\n════════════════════════════════════════");
  console.log("✅  All 4 modules refreshed successfully!");
  console.log("  /behavior               → 50 incidents");
  console.log("  /students/alumni        → 25 alumni");
  console.log("  /assignments            → 20 assignments");
  console.log("  /academics/assessments  → 8 assessments");
  console.log("════════════════════════════════════════\n");
}

main().catch(e => { console.error("FATAL:", e.message); process.exit(1); });
