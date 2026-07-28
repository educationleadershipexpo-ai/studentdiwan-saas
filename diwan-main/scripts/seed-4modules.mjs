/**
 * seed-4modules.mjs
 * Deletes ALL existing records from 4 target modules and reseeds with fresh demo data:
 *   1. /behavior          → BehaviorIncident (behavior_incidents)
 *   2. /students/alumni   → Graduate (graduates)
 *   3. /assignments       → TeacherAssignment (TeacherAssignment)
 *   4. /academics/assessments → assessments
 *
 * Usage:
 *   node scripts/seed-4modules.mjs
 */

const BASE         = process.env.BASE         || "https://portal.studentdiwan.com";
const ADMIN_EMAIL  = process.env.ADMIN_EMAIL  || "admin@eduerp.com";
const ADMIN_PASS   = process.env.ADMIN_PASS   || "admin123";
const DELAY        = 250; // ms between requests — avoids connection saturation

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
    throw new Error(`${opts?.method || "GET"} /api/data/${path} → ${r.status}: ${txt.slice(0, 160)}`);
  }
  return r.status === 204 ? null : r.json().catch(() => null);
};

// ── Purge all records from a table sequentially ─────────────────────────────
async function purge(entity, token) {
  let rows;
  try { rows = await api(entity, undefined, token); }
  catch (e) { console.warn(`  ⚠ Could not fetch ${entity}: ${e.message}`); return 0; }
  if (!Array.isArray(rows) || !rows.length) { console.log(`  (${entity}: already empty)`); return 0; }
  let deleted = 0;
  for (const row of rows) {
    try { await api(`${entity}/${row.id}`, { method: "DELETE" }, token); deleted++; }
    catch (e) { console.warn(`  ✗ DELETE ${entity}/${row.id}: ${e.message.slice(0, 80)}`); }
    await sleep(DELAY);
  }
  console.log(`  ✓ Purged ${deleted}/${rows.length} from ${entity}`);
  return deleted;
}

// ── Sequential insert with delay ─────────────────────────────────────────────
async function insert(label, entity, records, token) {
  let ok = 0;
  for (const rec of records) {
    try { await api(entity, { method: "POST", body: JSON.stringify(rec) }, token); ok++; }
    catch (e) {
      if (!e.message.includes("duplicate") && !e.message.includes("ER_DUP"))
        console.warn(`  ✗ ${e.message.slice(0, 100)}`);
    }
    await sleep(DELAY);
  }
  console.log(`  ✓ ${label}: inserted ${ok}/${records.length}`);
}

const pick  = arr => arr[Math.floor(Math.random() * arr.length)];
const randI = (lo, hi) => Math.floor(Math.random() * (hi - lo + 1)) + lo;
const dAgo  = n => new Date(Date.now() - n * 86400e3).toISOString();
const uid   = "admin-001";
const pad   = (n, l = 4) => String(n).padStart(l, "0");

// ─────────────────────────────────────────────────────────────────────────────
async function main() {
  console.log(`\n🔐 Logging in to ${BASE} …`);
  const loginRes = await fetch(`${BASE}/api/session/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASS }),
  });
  const { token } = await loginRes.json();
  if (!token) throw new Error("Login failed");
  console.log("  ✓ Logged in\n");

  // Base data
  const [students, staff] = await Promise.all([
    api("students", undefined, token).catch(() => []),
    api("staff",    undefined, token).catch(() => []),
  ]);
  const teachers = staff.filter(s => /teacher/i.test(s.role || "")).length
    ? staff.filter(s => /teacher/i.test(s.role || "")) : staff.slice(0, 15);
  console.log(`  students: ${students.length}, staff: ${staff.length} (teachers: ${teachers.length})\n`);

  // ════════════════════════════════════════════════════════════════════════════
  // 1. BEHAVIOR INCIDENTS
  // ════════════════════════════════════════════════════════════════════════════
  console.log("──────────────────────────────────────────────────────");
  console.log("🛡️  MODULE 1: Behavior Incidents");
  console.log("──────────────────────────────────────────────────────");
  await purge("behavior_incidents", token);

  const someStudents = students.slice(0, 80);
  const BEHAVIOR_CASES = [
    // Positive
    { type: "Merit",   severity: "Low",    category: "Academic Excellence",    description: "Student scored 100% in Mathematics unit test and received class recognition." },
    { type: "Merit",   severity: "Low",    category: "Helping Peers",          description: "Voluntarily tutored classmates before the exam without being asked." },
    { type: "Merit",   severity: "Low",    category: "Class Leadership",        description: "Led the class discussion effectively and ensured all voices were heard." },
    { type: "Merit",   severity: "Low",    category: "Community Service",       description: "Organised a classroom cleanup drive and encouraged peers to participate." },
    { type: "Merit",   severity: "Low",    category: "Sports Achievement",      description: "Represented school in inter-school football tournament and won MVP." },
    { type: "Merit",   severity: "Low",    category: "Punctuality",             description: "Maintained perfect attendance and punctuality for the entire term." },
    { type: "Merit",   severity: "Low",    category: "Creative Contribution",   description: "Submitted outstanding artwork for the school annual display." },
    // Demerit
    { type: "Demerit", severity: "Low",    category: "Late Submission",         description: "Homework submitted 2 days after the deadline without prior communication." },
    { type: "Demerit", severity: "Low",    category: "Mobile Phone Use",        description: "Using mobile phone during class despite prior warnings." },
    { type: "Demerit", severity: "Low",    category: "Dress Code Violation",    description: "Not wearing correct school uniform on a school day." },
    { type: "Demerit", severity: "Medium", category: "Disruption in Class",     description: "Repeatedly talking loudly during lesson, disrupting learning for others." },
    { type: "Demerit", severity: "Medium", category: "Disrespect to Teacher",   description: "Used disrespectful tone when asked to complete class work." },
    { type: "Demerit", severity: "Medium", category: "Bullying (Verbal)",       description: "Made unkind comments about a peer's appearance reported by two witnesses." },
    { type: "Demerit", severity: "High",   category: "Vandalism",               description: "Damaged a classroom desk intentionally — parents have been notified." },
    { type: "Demerit", severity: "High",   category: "Examination Misconduct",  description: "Found with unauthorised notes during the midterm exam. Zero mark issued." },
    { type: "Demerit", severity: "High",   category: "Physical Altercation",    description: "Involved in a physical confrontation with another student. Both parents called." },
    // Neutral
    { type: "Demerit", severity: "Low",    category: "Truancy",                 description: "Absent without leave on Wednesday without parent notification." },
    { type: "Merit",   severity: "Low",    category: "Excellent Teamwork",      description: "Demonstrated exceptional teamwork during the Science lab group project." },
  ];

  const behaviorRecs = someStudents.slice(0, 50).map((s, i) => {
    const c = BEHAVIOR_CASES[i % BEHAVIOR_CASES.length];
    const t = pick(teachers);
    const daysBack = randI(1, 45);
    return {
      id: `BI-FRESH-${pad(i + 1)}`,
      studentId: s.id,
      studentName: s.name,
      grade: s.grade || `Grade ${randI(4, 11)}`,
      section: s.section || pick(["A", "B", "C"]),
      type: c.type,
      category: c.category,
      severity: c.severity,
      description: c.description,
      date: dAgo(daysBack).split("T")[0],
      reportedBy: t.name,
      teacherId: t.id,
      action: pick(["Verbal Warning", "Written Warning", "Merit Award", "Parents Notified", "Counselling Session", "Detention", "Reported to HOD", "Merit Certificate"]),
      parentNotified: c.severity !== "Low" || Math.random() > 0.6,
      followUp: c.severity === "High" ? "Under review by Vice Principal" : "",
      status: pick(["Open", "Resolved", "Resolved", "Pending Review"]),
      uid, createdAt: dAgo(daysBack),
    };
  });
  await insert("behavior_incidents", "behavior_incidents", behaviorRecs, token);

  // ════════════════════════════════════════════════════════════════════════════
  // 2. GRADUATES / ALUMNI
  // ════════════════════════════════════════════════════════════════════════════
  console.log("\n──────────────────────────────────────────────────────");
  console.log("🎓  MODULE 2: Graduates / Alumni");
  console.log("──────────────────────────────────────────────────────");
  await purge("graduates", token);

  const GRAD_NAMES = [
    "Fatima Bint Said Al-Rawahi",  "Omar Abdullah Al-Balushi",   "Rania Khalid Al-Kindi",
    "Yousef Nasser Al-Habsi",       "Salma Ibrahim Al-Farsi",     "Khalid Rashid Al-Amri",
    "Hessa Mohammed Al-Naabi",      "Marwan Tariq Al-Ghafri",     "Noor Issa Al-Busaidi",
    "Ali Salim Al-Maqbali",         "Maryam Hassan Al-Lawati",    "Qais Ahmed Al-Wahaibi",
    "Reem Abdullah Al-Hosni",       "Ibrahim Saud Al-Harthy",     "Zahra Mohammed Al-Siyabi",
    "Turki Khalid Al-Mukhaini",     "Amna Tariq Al-Abri",         "Saif Nasser Al-Amri",
    "Lubna Ahmed Al-Kharousi",      "Faisal Omar Al-Rashdi",      "Shaikha Yousef Al-Hinai",
    "Bilal Hamad Al-Yaarubi",       "Aisha Saif Al-Maskari",      "Nabil Sulaiman Al-Riyami",
    "Sana Khalid Al-Bulushi",
  ];
  const UNIVERSITIES = [
    "Sultan Qaboos University",  "University of Nizwa",      "A'Sharqiyah University",
    "Middle East College",        "Gulf College Muscat",       "UTAS Muscat",
    "University of Buraimi",      "Dhofar University",         null, null,
  ];
  const PROGRAMS = [
    "Computer Engineering", "Business Administration", "Medicine & Surgery",
    "Electrical Engineering", "Law", "Education", "Pharmacy", "Architecture",
    "Information Technology", "Finance", null,
  ];

  const gradRecs = GRAD_NAMES.map((name, i) => {
    const gradYear = pick([2022, 2023, 2024, 2025]);
    const gpa = (randI(27, 50) / 10).toFixed(2);
    const univ = pick(UNIVERSITIES);
    return {
      id: `GRAD-FRESH-${pad(i + 1)}`,
      name,
      year: gradYear.toString(),
      degree: "High School Diploma",
      gpa,
      awards: pick(["Top of Class", "Subject Excellence Award", "Sports Champion", "Best All-Rounder", "None", "None", "None"]),
      status: pick(["Graduated", "Graduated", "Pending"]),
      email: `${name.split(" ")[0].toLowerCase()}.${String(i + 1).padStart(3,"0")}@alumni.schooldiwan.om`,
      phone: `+968 9${randI(1000000, 9999999)}`,
      date: `${gradYear}-06-${randI(20, 30)}`,
      university: univ,
      program: univ ? pick(PROGRAMS) : null,
      currentPosition: univ ? null : pick(["Working at Bank Muscat", "Teaching Assistant", "Self-Employed", "Internship at Ministry", null]),
      uid, createdAt: dAgo(randI(200, 800)),
    };
  });
  await insert("graduates", "graduates", gradRecs, token);

  // ════════════════════════════════════════════════════════════════════════════
  // 3. ASSIGNMENTS (TeacherAssignment)
  // ════════════════════════════════════════════════════════════════════════════
  console.log("\n──────────────────────────────────────────────────────");
  console.log("📋  MODULE 3: Assignments (TeacherAssignment)");
  console.log("──────────────────────────────────────────────────────");
  await purge("TeacherAssignment", token);

  const GRADES   = ["Grade 4", "Grade 5", "Grade 6", "Grade 7", "Grade 8", "Grade 9", "Grade 10", "Grade 11"];
  const SECTIONS = ["A", "B", "C"];
  const SUBJECTS = ["Mathematics", "English", "Science", "Arabic", "Islamic Studies", "Social Studies", "Computer Science", "Physics", "Biology", "Chemistry", "History"];
  const TYPES    = ["Homework", "Project", "Essay", "Lab Report", "Presentation", "Quiz", "Worksheet", "Research Work", "Lab Activity", "Reading Assignment"];
  const STATUSES = ["Active", "Active", "Active", "Closed", "Draft", "Returned"];

  const ASSIGNMENT_TITLES = [
    ["Mathematics",       "Chapter 5 – Fractions & Decimals Review",           "Complete exercises 5.1 to 5.4 and show all working."],
    ["English",           "Descriptive Writing: My Favourite Place",           "Write 250–300 words describing your favourite place using sensory detail."],
    ["Science",           "Lab Report: Photosynthesis Experiment",              "Write a formal lab report following the PEEL structure."],
    ["Arabic",            "القراءة والفهم – الفصل الثالث",                    "أجب عن أسئلة الفهم من الصفحة ٤٥ إلى ٤٨ في كتاب النشاط."],
    ["Islamic Studies",   "Research: The Five Pillars of Islam",               "Write a one-page research summary on one of the five pillars with references."],
    ["Social Studies",    "Map Activity: Countries of the Arabian Peninsula",  "Label all GCC countries, capitals and major bodies of water on the blank map."],
    ["Computer Science",  "Python Basics – Variables & Data Types",            "Complete the Codecademy lesson and submit a screenshot of your progress."],
    ["Physics",           "Newton's Laws – Problem Set 3",                     "Solve problems 3.1 to 3.8 showing formula, substitution and final answer."],
    ["Biology",           "Cell Structure Diagram & Labelling",                "Draw and label both a plant and animal cell clearly from memory."],
    ["Chemistry",         "Periodic Table – Element Properties Worksheet",     "Fill in the worksheet for elements 1–20: symbol, group, period, and type."],
    ["History",           "Essay: The Silk Road and Trade",                    "Write a structured essay (intro, 3 body paragraphs, conclusion) on the Silk Road."],
    ["Mathematics",       "Geometry: Area and Perimeter Problems",             "Solve all 12 questions. Show calculations and include a diagram for each."],
    ["English",           "Novel Study: Summary of Chapters 6–10",             "Write a chapter-by-chapter summary identifying the main events and characters."],
    ["Science",           "Worksheet: The Water Cycle",                        "Complete the diagram and answer the 8 comprehension questions."],
    ["Arabic",            "تعبير كتابي: يوم لا أنساه",                       "اكتب تعبيراً عن ذكرى لا تُنسى في حياتك (١٥٠–٢٠٠ كلمة)."],
    ["Computer Science",  "Spreadsheet Project – Student Grade Tracker",       "Create an Excel spreadsheet with formulas for average, max, min and chart."],
    ["Physics",           "Electricity Lab: Circuits and Resistance",          "Record measurements, complete data table and write conclusions."],
    ["Biology",           "Research: Types of Human Diseases",                 "Present on one communicable and one non-communicable disease."],
    ["Chemistry",         "States of Matter – Group Poster Activity",          "Create an A2 poster showing the three states of matter with particle diagrams."],
    ["Mathematics",       "Algebra: Solving Linear Equations",                 "Complete the 20-question worksheet showing all steps clearly."],
  ];

  const assignmentRecs = ASSIGNMENT_TITLES.map(([subject, title, instructions], i) => {
    const t = pick(teachers);
    const grade = pick(GRADES);
    const section = pick(SECTIONS);
    const dueInDays = randI(-10, 20);
    const totalStudents = randI(20, 38);
    const submitted = randI(0, totalStudents);
    const status = dueInDays < -3 ? pick(["Closed", "Returned"]) : dueInDays > 7 ? "Upcoming" : pick(["Active", "Active"]);
    return {
      id: `TA-FRESH-${pad(i + 1)}`,
      title,
      subject,
      type: pick(TYPES),
      grade,
      section,
      teacher: t.name,
      teacherId: t.id,
      dueDate: dAgo(-dueInDays).split("T")[0],
      totalMarks: pick([10, 20, 25, 30, 50, 100]),
      submitted,
      total: totalStudents,
      status,
      instructions,
      allowLate: Math.random() > 0.5,
      notifyParents: Math.random() > 0.4,
      createdAt: dAgo(randI(1, 30)),
      uid,
    };
  });
  await insert("TeacherAssignment", "TeacherAssignment", assignmentRecs, token);

  // ════════════════════════════════════════════════════════════════════════════
  // 4. ASSESSMENTS
  // ════════════════════════════════════════════════════════════════════════════
  console.log("\n──────────────────────────────────────────────────────");
  console.log("📊  MODULE 4: Assessments");
  console.log("──────────────────────────────────────────────────────");
  await purge("assessments", token);

  const makeQ = (type, text, marks) => ({
    id: `Q-${Math.random().toString(36).slice(2, 8)}`,
    type, text, marks,
    ...(type === "MCQ" ? {
      options: [
        { id: "a", text: "Option A – Correct Answer" },
        { id: "b", text: "Option B – Distractor" },
        { id: "c", text: "Option C – Distractor" },
        { id: "d", text: "Option D – Distractor" },
      ],
      correctAnswer: "a",
    } : {}),
    ...(type === "True/False" ? { correctAnswer: pick(["True", "False"]) } : {}),
  });

  const ASSESSMENT_DEFS = [
    {
      title: "Mid-Term Mathematics Test – Grade 7A",
      subject: "Mathematics",  grade: "Grade 7",  section: "A",  type: "Test",
      chapter: "Chapter 3",    duration: 60,      totalMarks: 50, passingMarks: 25,
      description: "Covers fractions, decimals, ratios and proportion from Chapters 1–3.",
      questions: [
        makeQ("MCQ",          "What is 3/4 + 1/2?",                              5),
        makeQ("MCQ",          "Simplify the ratio 18:24.",                        5),
        makeQ("Short Answer", "Solve: 4x + 7 = 23. Find x.",                     5),
        makeQ("Short Answer", "Convert 0.75 to a fraction in its simplest form.", 5),
        makeQ("Long Answer",  "A train travels 360 km in 4 hours. Find the speed and time for 540 km.", 15),
        makeQ("True/False",   "The product of two negative numbers is always negative.", 5),
        makeQ("Fill in the Blank", "The HCF of 12 and 18 is ___.",               10),
      ],
      status: "Active", daysBack: 3,
    },
    {
      title: "Science Quiz – Chapter 4: Ecosystems",
      subject: "Science",      grade: "Grade 6",  section: "B",  type: "Quiz",
      chapter: "Chapter 4",    duration: 30,      totalMarks: 20, passingMarks: 10,
      description: "Short quiz on food chains, food webs and energy transfer.",
      questions: [
        makeQ("MCQ",          "Which organism is a primary consumer?",            4),
        makeQ("MCQ",          "What do decomposers do in an ecosystem?",          4),
        makeQ("True/False",   "Plants are producers in a food chain.",            2),
        makeQ("Short Answer", "Name two examples of omnivores.",                  4),
        makeQ("Short Answer", "Define the term 'biotic factor'.",                 6),
      ],
      status: "Completed", daysBack: 12,
    },
    {
      title: "English Language – Writing Assessment",
      subject: "English Language", grade: "Grade 8", section: "A", type: "Assignment",
      chapter: "Chapter 2",    duration: 45,      totalMarks: 30, passingMarks: 15,
      description: "Students write a formal letter following the structure taught in class.",
      questions: [
        makeQ("Essay",        "Write a formal letter to your school principal requesting a new science lab.", 20),
        makeQ("Short Answer", "Identify the structural features of a formal letter.",                         10),
      ],
      status: "Active", daysBack: 1,
    },
    {
      title: "Physics Lab Assessment – Ohm's Law",
      subject: "Physics",      grade: "Grade 10", section: "A",  type: "Lab Assessment",
      chapter: "Chapter 6",    duration: 50,      totalMarks: 40, passingMarks: 20,
      description: "Practical assessment measuring voltage, current and resistance.",
      questions: [
        makeQ("Short Answer", "State Ohm's Law and write its formula.",           5),
        makeQ("Long Answer",  "Describe the experiment to verify Ohm's Law with a diagram.", 15),
        makeQ("MCQ",          "If V = 12V and R = 4Ω, what is the current?",     5),
        makeQ("Fill in the Blank", "The SI unit of resistance is ___.",           5),
        makeQ("Short Answer", "What happens to resistance when temperature increases in a conductor?", 10),
      ],
      status: "Upcoming", daysBack: -5,
    },
    {
      title: "Arabic Language – Comprehension Test",
      subject: "Arabic",       grade: "Grade 5",  section: "C",  type: "Test",
      chapter: "Chapter 3",    duration: 40,      totalMarks: 30, passingMarks: 15,
      description: "Reading comprehension and grammar from the third chapter.",
      questions: [
        makeQ("Short Answer", "اقرأ النص وأجب: ما الموضوع الرئيسي للقصة؟",      6),
        makeQ("Short Answer", "أعطِ ثلاث صفات لشخصية البطل في القصة.",           6),
        makeQ("Fill in the Blank", "أكمل الجملة: ذهب الطفل إلى ___ في الصباح.", 4),
        makeQ("MCQ",          "ما مضاد كلمة 'سعيد'؟",                            4),
        makeQ("Essay",        "اكتب فقرة قصيرة (٥ جمل) عن يومك في المدرسة.",  10),
      ],
      status: "Active", daysBack: 2,
    },
    {
      title: "Computer Science – Python Programming Test",
      subject: "Computer Science", grade: "Grade 9", section: "B", type: "Test",
      chapter: "Chapter 5",    duration: 45,      totalMarks: 40, passingMarks: 20,
      description: "Covers variables, data types, loops and functions in Python.",
      questions: [
        makeQ("MCQ",          "Which Python keyword is used to define a function?", 4),
        makeQ("True/False",   "Python uses indentation to define code blocks.",   4),
        makeQ("Short Answer", "Write a Python statement to print 'Hello World'.", 6),
        makeQ("Short Answer", "What is the output of: print(type(3.14))?",        6),
        makeQ("Long Answer",  "Write a Python program to find all even numbers from 1 to 50.", 20),
      ],
      status: "Draft", daysBack: 10,
    },
    {
      title: "Islamic Studies – Five Pillars Worksheet",
      subject: "Islamic Studies", grade: "Grade 6", section: "A", type: "Worksheet",
      chapter: "Chapter 1",    duration: 30,      totalMarks: 25, passingMarks: 13,
      description: "Worksheet covering the Five Pillars of Islam and their significance.",
      questions: [
        makeQ("Fill in the Blank", "The first pillar of Islam is ___ (Shahadah).", 5),
        makeQ("MCQ",          "How many times do Muslims pray daily?",            5),
        makeQ("Short Answer", "Explain the importance of Zakat in Islam.",        5),
        makeQ("Short Answer", "What is the significance of the Hajj pilgrimage?", 5),
        makeQ("Essay",        "Describe how fasting during Ramadan benefits the Muslim community.", 5),
      ],
      status: "Completed", daysBack: 20,
    },
    {
      title: "Biology – Cell Structure & Function Project",
      subject: "Biology",      grade: "Grade 10", section: "B",  type: "Project",
      chapter: "Chapter 2",    duration: 0,       totalMarks: 50, passingMarks: 25,
      description: "Group project presenting on the structure and function of animal vs plant cells.",
      questions: [
        makeQ("Essay",        "Prepare a detailed written report comparing animal and plant cells.", 25),
        makeQ("Diagram Based","Draw and label a plant cell and an animal cell clearly.",            25),
      ],
      status: "Active", daysBack: 5,
    },
  ];

  const assessmentRecs = ASSESSMENT_DEFS.map((def, i) => {
    const t = pick(teachers);
    const totalStudents = randI(22, 40);
    const subs = def.status === "Completed" ? totalStudents : def.status === "Active" ? randI(5, totalStudents - 5) : 0;
    return {
      id: `ASS-FRESH-${pad(i + 1)}`,
      title: def.title,
      subject: def.subject,
      grade: def.grade,
      section: def.section,
      type: def.type,
      chapter: def.chapter,
      duration: def.duration,
      totalMarks: def.totalMarks,
      passingMarks: def.passingMarks,
      description: def.description,
      questions: def.questions,
      date: dAgo(def.daysBack).split("T")[0],
      submissions: subs,
      totalStudents,
      status: def.status,
      teacher: t.name,
      teacherId: t.id,
      resultVisibility: pick(["immediate", "manual"]),
      resultsReleased: def.status === "Completed",
      createdAt: dAgo(randI(def.daysBack, def.daysBack + 5)),
      uid,
    };
  });
  await insert("assessments", "assessments", assessmentRecs, token);

  // ════════════════════════════════════════════════════════════════════════════
  console.log("\n═══════════════════════════════════════════════════════");
  console.log("✅  All 4 modules refreshed with realistic demo data!");
  console.log("   1. /behavior               → 50 incidents (merit + demerit)");
  console.log("   2. /students/alumni        → 25 alumni with full profiles");
  console.log("   3. /assignments            → 20 assignments across subjects");
  console.log("   4. /academics/assessments  → 8 assessments with questions");
  console.log("═══════════════════════════════════════════════════════\n");
}

main().catch(e => { console.error("FATAL:", e.message); process.exit(1); });
