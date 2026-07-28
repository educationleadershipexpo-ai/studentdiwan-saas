/**
 * seed-demo-modules.mjs
 * 
 * Cleans + reseeds 6 modules with fresh, realistic demo data:
 *   1. /assignments        → TeacherAssignment (teacher_assignments)
 *   2. /academics/assessments → assessments
 *   3. /students/alumni    → Alumnus (alumni)
 *   4. /graduates          → Graduate (graduates)
 *   5. /behavior           → BehaviorIncident (behavior_incidents)
 *   6. /students/exit      → exitRecords
 *
 * Usage: node scripts/seed-demo-modules.mjs
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
      // If pool is busy or connection is lost, wait and retry up to 2 times
      if ((text.includes("prepare") || text.includes("max_user_conn") || text.includes("null")) && attempt < 2) {
        console.warn(`  [Retry ${attempt + 1}] MySQL pool issue. Waiting 5s before retry...`);
        await sleep(5000);
        return apiCall(path, opts, token, attempt + 1);
      }
      throw new Error(`${opts?.method || "GET"} /api/data/${path} ${res.status}: ${text.slice(0, 150)}`);
    }
    return res.status === 204 ? null : await res.json().catch(() => null);
  } catch (err) {
    if (attempt < 2) {
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

function randomDate(startDays, endDays) {
  const now = Date.now();
  const d = new Date(now - Math.floor(Math.random() * (startDays - endDays) + endDays) * 86400000);
  return d.toISOString().slice(0, 10);
}

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

// ── Constants ────────────────────────────────────────────────────────────────

const TEACHER_NAMES = [
  "Fatima Al-Rashid", "Ahmed Khan", "Sara Mohamed", "Omar Yusuf",
  "Noor Patel", "Ibrahim Hassan", "Aisha Qureshi", "Khalid Mansoor",
  "Maryam Abdullah", "Yusuf Ali", "Layla Hameed", "Tariq Jaber",
];

const STUDENT_NAMES = [
  "Zain Ahmed", "Hana Al-Farsi", "Amir Khalil", "Laila Hassan",
  "Youssef Omar", "Sara Mansoor", "Ibrahim Patel", "Fatima Noor",
  "Khalid Yusuf", "Mariam Ali", "Rayan Qureshi", "Nadia Hameed",
  "Tariq Abdullah", "Amina Jaber", "Hassan Ibrahim", "Dina Rashid",
  "Omar Saleh", "Leena Hakim", "Faisal Kareem", "Reem Al-Sayed",
  "Adam Farouk", "Salma Othman", "Bilal Nazeer", "Yasmin Shah",
  "Zara Imran", "Hamza Rafiq", "Noura Bashar", "Sami Wadood",
  "Aya Mustafa", "Idris Jameel", "Lina Darwish", "Rana El-Din",
];

const GRADES = ["Grade 1", "Grade 2", "Grade 3", "Grade 4", "Grade 5", "Grade 6",
  "Grade 7", "Grade 8", "Grade 9", "Grade 10", "Grade 11", "Grade 12"];
const SECTIONS = ["A", "B", "C"];

const SUBJECTS = ["Mathematics", "English", "Science", "Arabic", "Islamic Studies",
  "Social Studies", "Computer Science", "Physics", "Chemistry", "Biology", "History"];

const ASSIGN_TYPES = ["Homework", "Project", "Essay", "Lab Report", "Presentation",
  "Quiz", "Worksheet", "Research Work", "Reading Assignment", "Writing Assignment"];

const ASSESS_TYPES = ["Quiz", "Worksheet", "Project", "Lab Assessment", "Test",
  "Oral Assessment", "Practical", "Assignment"];

const BEHAVIOR_CATEGORIES = ["Conduct", "Academic Integrity", "Bullying",
  "Attendance", "Dress Code", "Property Damage", "Technology Misuse",
  "Classroom Disruption", "Outstanding Achievement", "Leadership"];

const BEHAVIOR_TYPES = ["Demerit", "Merit", "Warning", "Commendation", "Infraction"];
const SEVERITIES = ["Low", "Medium", "High", "Critical"];

const COMPANIES = [
  "Google", "Microsoft", "Amazon", "Apple", "Meta", "Oracle",
  "Deloitte", "McKinsey", "KPMG", "PwC", "EY", "Accenture",
  "Qatar Airways", "Emirates", "ADNOC", "Saudi Aramco",
  "Dubai Municipality", "Ministry of Education", "Qatar Foundation",
  "Al Jazeera Media", "Carrefour Group", "Zara International",
];

const OCCUPATIONS = [
  "Software Engineer", "Data Analyst", "Product Manager", "Doctor",
  "Civil Engineer", "Architect", "Accountant", "Marketing Manager",
  "Teacher", "Business Analyst", "Research Scientist", "Lawyer",
  "Pharmacist", "Financial Analyst", "UX Designer", "HR Manager",
];

const LOCATIONS = [
  "Doha, Qatar", "Dubai, UAE", "Abu Dhabi, UAE", "Riyadh, Saudi Arabia",
  "Jeddah, Saudi Arabia", "London, UK", "Toronto, Canada", "New York, USA",
  "Bangalore, India", "Melbourne, Australia", "Paris, France", "Berlin, Germany",
];

const EXIT_REASONS = ["Transfer Out", "Graduation", "Withdrawal", "Relocating / Leaving Country", "Other"];
const CLEARANCE_STATES = ["Completed", "Pending", "Waived"];
const DEST_SCHOOLS = [
  "International School of London", "Dubai English Speaking School",
  "Al Khor International School", "Qatar Academy Sidra",
  "American School of Paris", "British School of Muscat",
  "GEMS Wellington Academy", "Kings' School Al Barsha",
];
const DEST_COUNTRIES = ["Qatar", "UAE", "Saudi Arabia", "UK", "USA", "Canada", "India", "Australia"];

// ── 1. ASSIGNMENTS (TeacherAssignment → teacher_assignments) ─────────────────

async function seedAssignments(token) {
  console.log("\n📝 Seeding Assignments…");
  await cleanTable("teacher_assignments", "Assignments", token);
  
  const assignments = [];
  for (let i = 0; i < 20; i++) {
    const grade = pick(GRADES);
    const subject = pick(SUBJECTS);
    const type = pick(ASSIGN_TYPES);
    const teacher = pick(TEACHER_NAMES);
    const dueDate = randomDate(60, -14); // past 60 days to 14 days from now
    const createdDate = randomDate(90, 30);
    const isPast = new Date(dueDate) < new Date();
    
    const titles = {
      "Homework": [`${subject} Practice Set ${i+1}`, `Chapter ${Math.ceil(Math.random()*10)} Exercises`, `${subject} Weekly Assignment`],
      "Project": [`${subject} Research Project`, `${grade} Term Project — ${subject}`, `Interactive ${subject} Model`],
      "Essay": [`Descriptive Essay on ${subject} Topics`, `${subject} Analytical Writing`, `Critical Analysis Essay`],
      "Lab Report": [`${subject} Lab Experiment ${Math.ceil(Math.random()*5)}`, `Practical Investigation Report`, `${subject} Lab Observation`],
      "Presentation": [`${subject} Topic Presentation`, `Group Presentation on ${subject}`, `${subject} Current Events`],
      "Quiz": [`${subject} Quick Quiz ${i+1}`, `Chapter Review Quiz`, `Weekly ${subject} Quiz`],
      "Worksheet": [`${subject} Practice Worksheet`, `${subject} Skill Builder`, `${subject} Review Sheet`],
      "Research Work": [`${subject} Research Paper`, `${subject} Investigation`, `${subject} Case Study`],
      "Reading Assignment": [`${subject} Chapter Reading`, `${subject} Article Review`, `Textbook Reading Ch. ${Math.ceil(Math.random()*12)}`],
      "Writing Assignment": [`${subject} Creative Writing`, `${subject} Report Writing`, `Summary Writing — ${subject}`],
    };
    
    const title = pick(titles[type] || [`${subject} ${type} ${i+1}`]);
    const totalMarks = pick([10, 20, 25, 30, 40, 50, 100]);
    const total = Math.floor(Math.random() * 25 + 15); // class size 15-40
    const submitted = isPast ? Math.floor(total * (Math.random() * 0.4 + 0.6)) : Math.floor(total * Math.random() * 0.3);
    
    assignments.push({
      id: `ASG-${Date.now()}-${i}`,
      title,
      subject,
      type,
      grade,
      section: pick(SECTIONS),
      teacher,
      dueDate,
      totalMarks,
      submitted,
      total,
      status: isPast ? (Math.random() > 0.2 ? "Closed" : "Active") : "Active",
      createdAt: createdDate,
      instructions: `Complete all questions from ${subject} ${type.toLowerCase()}. Submit before the due date. Late submissions will be penalized.`,
    });
  }

  let count = 0;
  for (const a of assignments) {
    try {
      await apiPost("teacher_assignments", a, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} assignments`);
}

// ── 2. ASSESSMENTS (assessments) ─────────────────────────────────────────────

function generateQuestions(subject, count = 5) {
  const questions = [];
  const qTypes = ["MCQ", "True/False", "Short Answer", "Long Answer", "Fill in the Blank"];
  
  const mcqBanks = {
    Mathematics: [
      { text: "What is the value of π (pi) rounded to two decimal places?", options: ["3.14", "3.41", "2.14", "3.16"], answer: "3.14" },
      { text: "Which of the following is a prime number?", options: ["7", "9", "15", "21"], answer: "7" },
      { text: "What is the square root of 144?", options: ["12", "14", "10", "16"], answer: "12" },
    ],
    Science: [
      { text: "What is the chemical symbol for water?", options: ["H2O", "CO2", "O2", "NaCl"], answer: "H2O" },
      { text: "Which planet is closest to the Sun?", options: ["Mercury", "Venus", "Earth", "Mars"], answer: "Mercury" },
      { text: "What is the powerhouse of the cell?", options: ["Mitochondria", "Nucleus", "Ribosome", "Golgi Body"], answer: "Mitochondria" },
    ],
    English: [
      { text: "Which is a synonym for 'benevolent'?", options: ["Kind", "Cruel", "Lazy", "Loud"], answer: "Kind" },
      { text: "What is the past tense of 'run'?", options: ["Ran", "Runned", "Running", "Runs"], answer: "Ran" },
    ],
    default: [
      { text: `Which of the following best describes a key concept in ${subject}?`, options: ["Option A", "Option B", "Option C", "Option D"], answer: "Option A" },
    ],
  };

  const tfBanks = {
    Mathematics: ["The sum of angles in a triangle is 180°.", "Zero is a negative number.", "Every square is a rectangle."],
    Science: ["Sound travels faster than light.", "Photosynthesis produces oxygen.", "All metals are solids at room temperature."],
    default: [`${subject} is an important area of study in modern education.`],
  };

  const shortBanks = {
    Mathematics: ["Define a polygon.", "What is the formula for the area of a circle?", "Explain the difference between mean and median."],
    Science: ["What are the three states of matter?", "Define photosynthesis in one sentence.", "Name the parts of a plant cell."],
    English: ["Define a simile with an example.", "What is alliteration?", "Name two types of pronouns."],
    default: [`Briefly explain one core concept in ${subject}.`, `List two important topics covered in ${subject}.`],
  };

  for (let i = 0; i < count; i++) {
    const qType = pick(qTypes);
    const marks = qType === "Long Answer" ? pick([5, 8, 10]) : qType === "Short Answer" ? pick([2, 3, 4]) : pick([1, 2]);
    const q = { id: `Q-${Date.now()}-${i}`, type: qType, text: "", marks, options: undefined, correctAnswer: undefined };

    if (qType === "MCQ") {
      const bank = mcqBanks[subject] || mcqBanks.default;
      const item = bank[i % bank.length];
      q.text = item.text;
      q.options = item.options.map((o, j) => ({ id: `opt-${j}`, text: o }));
      q.correctAnswer = item.answer;
    } else if (qType === "True/False") {
      const bank = tfBanks[subject] || tfBanks.default;
      q.text = bank[i % bank.length];
      q.correctAnswer = pick(["True", "False"]);
    } else if (qType === "Short Answer") {
      const bank = shortBanks[subject] || shortBanks.default;
      q.text = bank[i % bank.length];
    } else if (qType === "Long Answer") {
      q.text = `Write a detailed explanation about a topic covered in ${subject} this term. Include examples and diagrams where applicable.`;
    } else {
      q.text = `Complete the following: The most important concept in ${subject} Chapter ${Math.ceil(Math.random()*10)} is __________.`;
    }

    questions.push(q);
  }
  return questions;
}

async function seedAssessments(token) {
  console.log("\n📊 Seeding Assessments…");
  await cleanTable("assessments", "Assessments", token);

  const assessments = [];
  for (let i = 0; i < 18; i++) {
    const grade = pick(GRADES);
    const subject = pick(SUBJECTS);
    const type = pick(ASSESS_TYPES);
    const teacher = pick(TEACHER_NAMES);
    const date = randomDate(60, -7);
    const isPast = new Date(date) < new Date();
    const questions = generateQuestions(subject, Math.floor(Math.random() * 5 + 4));
    const totalMarks = questions.reduce((s, q) => s + q.marks, 0);
    const totalStudents = Math.floor(Math.random() * 25 + 15);
    const submissions = isPast ? Math.floor(totalStudents * (Math.random() * 0.3 + 0.7)) : Math.floor(totalStudents * Math.random() * 0.2);

    const titles = {
      "Quiz": [`${subject} Quick Quiz — ${grade}`, `Weekly ${subject} Assessment`, `${subject} Chapter Quiz`],
      "Test": [`${subject} Unit Test — Term 2`, `${subject} Monthly Test`, `${grade} Mid-Term ${subject}`],
      "Worksheet": [`${subject} Practice Worksheet`, `${subject} Skill Assessment`, `${subject} Review Worksheet`],
      "Project": [`${subject} Term Project Assessment`, `${subject} Group Project Evaluation`],
      "Lab Assessment": [`${subject} Lab Practical`, `${subject} Experiment Assessment`],
      "Oral Assessment": [`${subject} Oral Presentation`, `${subject} Viva Voce`],
      "Practical": [`${subject} Practical Exam`, `${subject} Hands-On Assessment`],
      "Assignment": [`${subject} Graded Assignment`, `${subject} Term Assignment`],
    };

    const statuses = isPast
      ? (Math.random() > 0.3 ? "Completed" : "Active")
      : (Math.random() > 0.3 ? "Active" : "Upcoming");

    assessments.push({
      id: `ASSESS-${Date.now()}-${i}`,
      title: pick(titles[type] || [`${subject} ${type}`]),
      chapter: `Chapter ${Math.ceil(Math.random() * 10)}`,
      type,
      grade,
      section: pick(SECTIONS),
      subject,
      date,
      duration: pick([15, 20, 30, 40, 45, 60, 90]),
      totalMarks,
      passingMarks: Math.ceil(totalMarks * 0.4),
      description: `${type} assessment for ${subject} covering recent chapters. Students must answer all questions within the allotted time.`,
      questions,
      submissions,
      totalStudents,
      status: statuses,
      teacher,
      createdAt: randomDate(90, 30),
      resultVisibility: "immediate",
      resultsReleased: isPast && Math.random() > 0.3,
    });
  }

  let count = 0;
  for (const a of assessments) {
    try {
      await apiPost("assessments", a, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} assessments`);
}

// ── 3. ALUMNI (Alumnus → alumni) ─────────────────────────────────────────────

async function seedAlumni(token) {
  console.log("\n🎓 Seeding Alumni…");
  await cleanTable("alumni", "Alumni", token);

  const alumni = [];
  for (let i = 0; i < 25; i++) {
    const name = STUDENT_NAMES[i % STUDENT_NAMES.length];
    const year = 2015 + Math.floor(Math.random() * 11); // 2015-2025
    alumni.push({
      id: `ALM-${Date.now()}-${i}`,
      name,
      class: `Class of ${year}`,
      occupation: pick(OCCUPATIONS),
      company: pick(COMPANIES),
      location: pick(LOCATIONS),
      status: pick(["Active Member", "Active Member", "Active Member", "Inactive", "Board Member"]),
      image: "",
      email: `${name.split(" ")[0].toLowerCase()}.${name.split(" ")[1]?.toLowerCase() || "user"}${year}@email.com`,
    });
  }

  let count = 0;
  for (const a of alumni) {
    try {
      await apiPost("alumni", a, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} alumni records`);
}

// ── 4. GRADUATES (Graduate → graduates) ──────────────────────────────────────

async function seedGraduates(token) {
  console.log("\n🎓 Seeding Graduates…");
  await cleanTable("graduates", "Graduates", token);

  const grads = [];
  for (let i = 0; i < 25; i++) {
    const name = STUDENT_NAMES[(i + 5) % STUDENT_NAMES.length];
    const year = String(2020 + Math.floor(Math.random() * 7)); // 2020-2026
    const month = String(Math.ceil(Math.random() * 12)).padStart(2, "0");
    grads.push({
      id: `GRD-${Date.now()}-${i}`,
      name,
      year,
      degree: pick(["High School Diploma", "Secondary Certificate", "IGCSE Certificate", "Advanced Level Certificate"]),
      status: pick(["Cleared", "Cleared", "Cleared", "Pending", "Deferred"]),
      email: `${name.split(" ")[0].toLowerCase()}.${name.split(" ")[1]?.toLowerCase() || "grad"}@studentdiwan.com`,
      phone: `+974 ${Math.floor(30000000 + Math.random() * 69999999)}`,
      date: `${year}-${month}-${String(Math.ceil(Math.random() * 28)).padStart(2, "0")}`,
    });
  }

  let count = 0;
  for (const g of grads) {
    try {
      await apiPost("graduates", g, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} graduate records`);
}

// ── 5. BEHAVIOR (BehaviorIncident → behavior_incidents) ──────────────────────

async function seedBehavior(token) {
  console.log("\n🛡️ Seeding Behavior Incidents…");
  await cleanTable("behavior_incidents", "Behavior Incidents", token);

  const incidents = [];
  const descriptionTemplates = {
    "Conduct": [
      "Student was respectful and helpful to classmates during group work",
      "Student disrupted class by talking during instruction",
      "Excellent behavior and participation in school assembly",
    ],
    "Academic Integrity": [
      "Student submitted original work with proper citations",
      "Copying was detected during examination — verbal warning issued",
      "Outstanding academic honesty demonstrated in research project",
    ],
    "Bullying": [
      "Verbal disagreement with a classmate — counselor notified",
      "Student intervened positively to help a bullied peer",
    ],
    "Attendance": [
      "Consistently punctual and prepared for class",
      "Student arrived 15 minutes late without valid excuse",
      "Perfect attendance streak for 30+ consecutive school days",
    ],
    "Dress Code": [
      "Student reminded about proper uniform standards",
      "Always maintains clean and proper school uniform",
    ],
    "Outstanding Achievement": [
      "Won first place in the Inter-School Science Fair",
      "Selected for the National Mathematics Olympiad",
      "Achieved perfect score in the quarterly assessment",
      "Led the school debate team to victory in the regional competition",
    ],
    "Leadership": [
      "Served as class monitor with excellent responsibility",
      "Organized a successful charity drive for the school community",
      "Mentored junior students in the peer tutoring program",
    ],
    "Classroom Disruption": [
      "Repeatedly talking during instruction despite warnings",
      "Using phone during class — device confiscated per school policy",
    ],
    "Technology Misuse": [
      "Inappropriate use of school computer lab resources",
      "Accessed non-educational content during lab session",
    ],
    "Property Damage": [
      "Accidentally damaged classroom equipment — parents informed",
    ],
  };

  for (let i = 0; i < 35; i++) {
    const sName = pick(STUDENT_NAMES);
    const category = pick(BEHAVIOR_CATEGORIES);
    const isMerit = category === "Outstanding Achievement" || category === "Leadership" || Math.random() > 0.6;
    const type = isMerit ? pick(["Merit", "Commendation"]) : pick(["Demerit", "Warning", "Infraction"]);
    const severity = isMerit ? pick(["Low", "Medium"]) : pick(SEVERITIES);
    const descriptions = descriptionTemplates[category] || [`Behavior incident related to ${category}`];

    incidents.push({
      id: `BEH-${Date.now()}-${i}`,
      studentName: sName,
      studentId: `STD-${1000 + i}`,
      type,
      category,
      description: pick(descriptions),
      severity,
      date: randomDate(90, 0),
      createdAt: new Date().toISOString(),
    });
  }

  let count = 0;
  for (const inc of incidents) {
    try {
      await apiPost("behavior_incidents", inc, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} behavior incidents`);
}

// ── 6. STUDENT EXIT (exitRecords) ────────────────────────────────────────────

async function seedExitRecords(token) {
  console.log("\n🚪 Seeding Student Exit Records…");
  await cleanTable("exitRecords", "Exit Records", token);

  const exitRecords = [];
  for (let i = 0; i < 12; i++) {
    const sName = STUDENT_NAMES[(i + 10) % STUDENT_NAMES.length];
    const reason = pick(EXIT_REASONS);
    const exitDate = randomDate(180, 0);
    const grade = pick(GRADES);

    exitRecords.push({
      id: `EXIT-${Date.now()}-${i}`,
      studentId: `STD-${2000 + i}`,
      studentName: sName,
      classId: `${grade} Section ${pick(SECTIONS)}`,
      gender: pick(["Male", "Female"]),
      nationality: pick(["Qatari", "Indian", "Egyptian", "Pakistani", "Jordanian", "British", "American"]),
      dateOfBirth: `${2008 + Math.floor(Math.random() * 8)}-${String(Math.ceil(Math.random()*12)).padStart(2,"0")}-${String(Math.ceil(Math.random()*28)).padStart(2,"0")}`,
      fatherName: `Mr. ${sName.split(" ")[1] || "Parent"}`,
      motherName: `Mrs. ${sName.split(" ")[1] || "Parent"}`,
      admissionDate: `${2019 + Math.floor(Math.random() * 5)}-09-01`,
      exitDate,
      exitReason: reason,
      destinationSchool: reason === "Transfer Out" ? pick(DEST_SCHOOLS) : "",
      destinationCountry: reason === "Relocating / Leaving Country" ? pick(DEST_COUNTRIES) : "",
      tcNumber: `TC-${2026}-${String(i + 1).padStart(4, "0")}`,
      feesClearance: pick(CLEARANCE_STATES),
      libraryClearance: pick(CLEARANCE_STATES),
      transportClearance: pick(CLEARANCE_STATES),
      accountsClearance: pick(CLEARANCE_STATES),
      uniformClearance: pick(CLEARANCE_STATES),
      exitRemarks: reason === "Graduation" ? "Completed all requirements successfully." :
                   reason === "Transfer Out" ? "Family relocating — transfer certificate issued." :
                   reason === "Withdrawal" ? "Parents opted for homeschooling." :
                   "Student exit processed per school policy.",
      nationalIdNumber: `QID-${Math.floor(10000000000 + Math.random() * 89999999999)}`,
      parentAcknowledgement: Math.random() > 0.2,
      conduct: pick(["Excellent", "Good", "Satisfactory"]),
      lastExamination: "Term 2 Final Exams",
      examResult: pick(["Pass", "Pass", "Pass with Distinction", "Fail"]),
      promotionClass: grade,
      attendance: `${Math.floor(80 + Math.random() * 20)}%`,
      createdAt: new Date().toISOString(),
      createdBy: "admin@studentdiwan.com",
    });
  }

  let count = 0;
  for (const rec of exitRecords) {
    try {
      await apiPost("exitRecords", rec, token);
      count++;
      await sleep(DELAY);
    } catch (e) { console.warn(`  ⚠ ${e.message}`); }
  }
  console.log(`  ✅ Inserted ${count} exit records`);
}

// ── Main ─────────────────────────────────────────────────────────────────────
async function main() {
  console.log("═══════════════════════════════════════════════════");
  console.log("  Student Diwan — Demo Data Seeder (6 Modules)");
  console.log("═══════════════════════════════════════════════════");
  console.log(`  Target: ${BASE}`);
  console.log(`  Time:   ${new Date().toISOString()}\n`);

  console.log("🔐 Logging in…");
  const lr = await fetch(`${BASE}/api/session/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASS }),
  });
  if (!lr.ok) throw new Error(`Login failed with status ${lr.status}`);
  const { token } = await lr.json();
  if (!token) throw new Error("No token returned from login");
  console.log("  ✓ Authenticated");
  console.log(`  ⏳ Waiting ${INIT_WAIT/1000}s for MySQL pool to settle…`);
  await sleep(INIT_WAIT);

  await seedAssignments(token);
  await seedAssessments(token);
  await seedAlumni(token);
  await seedGraduates(token);
  await seedBehavior(token);
  await seedExitRecords(token);

  console.log("\n═══════════════════════════════════════════════════");
  console.log("  ✅ ALL MODULES SEEDED SUCCESSFULLY");
  console.log("═══════════════════════════════════════════════════\n");
}

main().catch(err => { console.error("Fatal:", err); process.exit(1); });
