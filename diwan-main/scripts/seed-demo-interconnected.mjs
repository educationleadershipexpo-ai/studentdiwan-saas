import mysql from "mysql2/promise";
import dotenv from "dotenv";
dotenv.config();

// Standard Omani locations, companies, and universities for Alumni
const OMANI_UNIVERSITIES = [
  "Sultan Qaboos University (SQU)",
  "German University of Technology in Oman (GUTech)",
  "University of Nizwa",
  "Dhofar University",
  "Sohar University",
  "National University of Science and Technology",
  "Majan University College"
];

const OMANI_COMPANIES = [
  "Petroleum Development Oman (PDO)",
  "Oman Telecommunications Company (Omantel)",
  "OQ",
  "Bank Muscat",
  "Oman Air",
  "National Bank of Oman (NBO)",
  "Asyad Group",
  "Nama Group",
  "Ministry of Education",
  "Google",
  "Microsoft UAE",
  "Saudi Aramco"
];

const OCCUPATIONS_AND_TITLES = [
  { occupation: "Petroleum Engineer", company: "PDO" },
  { occupation: "Software Engineer", company: "Google" },
  { occupation: "Financial Analyst", company: "Bank Muscat" },
  { occupation: "Marketing Manager", company: "Omantel" },
  { occupation: "HR Specialist", company: "OQ" },
  { occupation: "Operations Officer", company: "Asyad Group" },
  { occupation: "Mechanical Engineer", company: "PDO" },
  { occupation: "Database Administrator", company: "Ministry of Education" },
  { occupation: "Senior Software Engineer", company: "Microsoft UAE" },
  { occupation: "Civil Engineer", company: "Asyad Group" },
  { occupation: "Consultant", company: "PwC Middle East" },
  { occupation: "Business Analyst", company: "NBO" },
  { occupation: "Pilot", company: "Oman Air" }
];

const ALUMNI_ACHIEVEMENTS = [
  "Graduated with First Class Honors. Received Chancellor's Award.",
  "Published research paper on solar energy in Oman in a leading journal.",
  "Developed a waste management tracking app utilized by local municipalities.",
  "Led the national youth team in the Regional Robotics Championship.",
  "Elected as President of the Student Advisory Council.",
  "Received PDO Scholarship for postgraduate studies in the UK.",
  "Won the Oman Youth Innovation Award in 2023.",
  "Volunteer leader for the Oman Environment Society."
];

// Specialized rooms to seed
const SPECIALIZED_ROOMS = [
  { roomNo: "301", roomName: "Robotics & AI Lab", type: "Computer Lab", capacity: 25, floor: "Third Floor", notes: "Equipped with 15 Lego Mindstorms kits, 3D Printer, and VR headsets. Assigned to Robotics Club." },
  { roomNo: "302", roomName: "Chemistry Lab", type: "Science Lab", capacity: 30, floor: "Third Floor", notes: "Equipped with fume hoods, safety eyewash, and chemical storage. Assigned to Grade 11/12 Chemistry." },
  { roomNo: "303", roomName: "Physics Lab", type: "Science Lab", capacity: 30, floor: "Third Floor", notes: "Equipped with optics benches, mechanics kits, and digital oscilloscopes. Assigned to Grade 11/12 Physics." },
  { roomNo: "304", roomName: "Biology Lab", type: "Science Lab", capacity: 30, floor: "Third Floor", notes: "Equipped with microscopes, anatomical models, and incubators. Assigned to Grade 11/12 Biology." },
  { roomNo: "105", roomName: "Music Room", type: "Music Room", capacity: 20, floor: "First Floor", notes: "Equipped with electronic keyboards, violins, ouds, and percussion. Soundproofed." },
  { roomNo: "106", roomName: "Art Studio", type: "Art Room", capacity: 25, floor: "First Floor", notes: "Equipped with easels, pottery wheel, and drafting tables. Plenty of natural light." },
  { roomNo: "005", roomName: "Main Auditorium", type: "Auditorium", capacity: 350, floor: "Ground Floor", notes: "Equipped with stage lighting, professional audio console, and projector screen. Used for assemblies and exhibitions." },
  { roomNo: "006", roomName: "Boardroom", type: "Meeting Room", capacity: 18, floor: "Ground Floor", notes: "Equipped with video conferencing setup and digital whiteboard. Assigned to leadership team." },
];

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

// Helper to calculate statistics
function normalRandom(mean, stdDev) {
  const u1 = Math.random();
  const u2 = Math.random();
  const randStdNormal = Math.sqrt(-2.0 * Math.log(u1)) * Math.sin(2.0 * Math.PI * u2);
  return mean + stdDev * randStdNormal;
}

function getRandomScore(maxMarks, meanPct = 0.78, stdDevPct = 0.12) {
  const pct = Math.max(0.35, Math.min(1.0, normalRandom(meanPct, stdDevPct)));
  return Math.round(pct * maxMarks);
}

async function main() {
  console.log("═══════════════════════════════════════════════════");
  console.log("  Student Diwan — Integrated Demo Data Seeder      ");
  console.log("═══════════════════════════════════════════════════");

  let connection;
  for (let attempt = 1; attempt <= 10; attempt++) {
    try {
      connection = await mysql.createConnection({
        host: process.env.DB_HOST || "217.21.85.14",
        port: Number(process.env.DB_PORT) || 3306,
        database: process.env.DB_DATABASE || "nobl6990_Demo1-SD",
        user: process.env.DB_USERNAME || "nobl6990_Demo-SD",
        password: process.env.DB_PASSWORD || "Zqx~(o1ItPp{fx+-",
      });
      break;
    } catch (e) {
      console.warn(`Connection attempt ${attempt} failed: ${e.message}. Waiting 4s...`);
      await sleep(4000);
    }
  }

  if (!connection) {
    throw new Error("Could not connect to MySQL after 10 attempts");
  }

  console.log("✅ MySQL Connected successfully.");

  // UIDs to target for scoping
  const TARGET_UIDS = ["educationleadershipexpo@gmail.com", "admin-uid"];
  const now = new Date().toISOString();

  // 1. Fetch existing core lists from DB
  console.log("📖 Fetching active directory resources...");
  const [studentRows] = await connection.execute("SELECT id, data FROM students");
  const [staffRows] = await connection.execute("SELECT id, data FROM staff");
  const [subjectRows] = await connection.execute("SELECT id, data FROM subjects");

  const students = studentRows.map(r => ({ id: r.id, ...JSON.parse(r.data) }));
  const staff = staffRows.map(r => ({ id: r.id, ...JSON.parse(r.data) }));
  const subjects = subjectRows.map(r => ({ id: r.id, ...JSON.parse(r.data) }));

  console.log(`- Found ${students.length} students`);
  console.log(`- Found ${staff.length} staff records`);
  console.log(`- Found ${subjects.length} subjects`);

  if (students.length === 0 || staff.length === 0 || subjects.length === 0) {
    throw new Error("Missing core directory records! Please seed directory first.");
  }

  // Filter teachers
  const teachers = staff.filter(s => {
    const role = (s.role || s.designation || "").toLowerCase();
    return role.includes("teacher") || s.id.includes("EMP-STCH");
  });
  console.log(`- Filtered ${teachers.length} active subject/class teachers`);

  // Group students by Grade and Section
  const studentsByGradeSection = {};
  students.forEach(s => {
    const g = s.grade ? s.grade.replace(/grade\s*/i, "").trim() : "1";
    const sec = s.section ? s.section.replace(/sec(tion)?\s*/i, "").trim().toUpperCase() : "A";
    const key = `${g}|${sec}`;
    if (!studentsByGradeSection[key]) studentsByGradeSection[key] = [];
    studentsByGradeSection[key].push(s);
  });

  const activeKeys = Object.keys(studentsByGradeSection);
  console.log(`- Grouped students into ${activeKeys.length} grade+section cohorts`);

  // CLEAN TABLES
  const cleanTables = [
    "alumni",
    "graduates",
    "exitRecords",
    "assessments",
    "assessment_attempts",
    "teacher_assignments",
    "assignment_submissions",
    "exam_marks",
    "exams"
  ];

  console.log("🧹 Cleaning up old mock data...");
  for (const t of cleanTables) {
    await connection.execute(`TRUNCATE TABLE \`${t}\``);
    console.log(`  → Truncated table \`${t}\``);
  }

  // 2. SEED GRADUATES & ALUMNI
  console.log("\n🎓 Seeding Alumni Network & Graduation Registry (110 graduates)...");
  
  // Select 110 students to graduate
  const gradCohort = students.slice(0, 110);
  const graduatesToInsert = [];
  const alumniToInsert = [];

  for (let i = 0; i < gradCohort.length; i++) {
    const st = gradCohort[i];
    const gradYear = String(2020 + (i % 6)); // Years 2020-2025
    const finalGpa = Number((2.8 + Math.random() * 1.2).toFixed(2));
    const percentage = Math.round(70 + Math.random() * 29);
    const degree = i % 4 === 0 ? "General Secondary Certificate" : "Secondary School Diploma";
    const status = i % 8 === 0 ? "Transcript Issued" : "Graduated";
    const placement = i % 2 === 0 ? "Employed" : (i % 3 === 0 ? "Higher Education" : "Seeking Opportunities");

    // Update student status to Graduated
    const updatedStudent = { ...st, status: "Graduated" };
    await connection.execute("UPDATE students SET data = ?, updatedAt = ? WHERE id = ?", [
      JSON.stringify(updatedStudent),
      now,
      st.id
    ]);

    // Seed Graduate
    const gradId = `GRD-${st.id}-${gradYear}`;
    const gradData = {
      id: gradId,
      studentId: st.id,
      name: st.name || st.displayName,
      year: gradYear,
      degree,
      status,
      email: st.email || `${st.name.toLowerCase().replace(/\s/g, "")}@studentdiwan.com`,
      phone: st.phone || "+968 9" + Math.floor(10000000 + Math.random() * 9000000),
      date: `${gradYear}-06-15`,
      finalGpa,
      percentage,
      rank: (i % 15) + 1,
      placementStatus: placement
    };

    // Seed Alumnus
    const almId = `ALM-${gradYear}-${String(i + 1).padStart(3, "0")}`;
    const work = OCCUPATIONS_AND_TITLES[i % OCCUPATIONS_AND_TITLES.length];
    const university = OMANI_UNIVERSITIES[i % OMANI_UNIVERSITIES.length];
    const achievement = ALUMNI_ACHIEVEMENTS[i % ALUMNI_ACHIEVEMENTS.length];
    
    const almData = {
      id: almId,
      studentId: st.id,
      name: st.name || st.displayName,
      class: `Class of ${gradYear}`,
      occupation: placement === "Employed" ? work.occupation : (placement === "Higher Education" ? "Student" : "Graduate Associate"),
      company: placement === "Employed" ? work.company : (placement === "Higher Education" ? university : "Unemployed"),
      location: i % 3 === 0 ? "Muscat, Oman" : (i % 4 === 0 ? "Salalah, Oman" : "Sohar, Oman"),
      status: "Active Member",
      email: gradData.email,
      phone: gradData.phone,
      image: `https://api.dicebear.com/9.x/notionists-neutral/svg?seed=${st.name.toLowerCase().replace(/\s/g, "")}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf&backgroundType=gradientLinear`,
      achievements: achievement,
      employmentStatus: placement,
      university
    };

    // Insert for both uids to ensure dashboard visibility
    for (const userUid of TARGET_UIDS) {
      graduatesToInsert.push([`${gradId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...gradData, uid: userUid }), userUid, now, now]);
      alumniToInsert.push([`${almId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...almData, uid: userUid }), userUid, now, now]);
    }
  }

  // Batch insert Graduates
  if (graduatesToInsert.length > 0) {
    const chunk = 100;
    for (let i = 0; i < graduatesToInsert.length; i += chunk) {
      const slice = graduatesToInsert.slice(i, i + chunk);
      await connection.query("INSERT INTO graduates (id, data, uid, createdAt, updatedAt) VALUES ?", [slice]);
    }
  }

  // Batch insert Alumni
  if (alumniToInsert.length > 0) {
    const chunk = 100;
    for (let i = 0; i < alumniToInsert.length; i += chunk) {
      const slice = alumniToInsert.slice(i, i + chunk);
      await connection.query("INSERT INTO alumni (id, data, uid, createdAt, updatedAt) VALUES ?", [slice]);
    }
  }
  console.log(`  → Seeded ${graduatesToInsert.length} graduates and alumni records.`);

  // 3. SEED STUDENT EXIT RECORDS
  console.log("\n🚪 Seeding Exit Registry (25 exit records)...");
  const exitCohort = students.slice(110, 135);
  const exitsToInsert = [];
  const exitReasons = ["Transfer Out", "Withdrawal", "Relocating / Leaving Country", "Other"];
  const destinationSchools = ["British School Muscat", "American British Academy (ABA)", "Muscat International School", "Doha College", "American International School of Muscat (AISM)"];
  const destinationCountries = ["United Kingdom", "United Arab Emirates", "Saudi Arabia", "Canada", "Qatar"];

  for (let i = 0; i < exitCohort.length; i++) {
    const st = exitCohort[i];
    const reason = exitReasons[i % exitReasons.length];
    const destSchool = reason === "Transfer Out" ? destinationSchools[i % destinationSchools.length] : "";
    const destCountry = reason === "Relocating / Leaving Country" ? destinationCountries[i % destinationCountries.length] : "Oman";
    
    // Update student status to Left or Withdrawn
    const updatedStatus = reason === "Withdrawal" ? "Withdrawn" : "Left";
    const updatedStudent = { ...st, status: updatedStatus };
    await connection.execute("UPDATE students SET data = ?, updatedAt = ? WHERE id = ?", [
      JSON.stringify(updatedStudent),
      now,
      st.id
    ]);

    const exitId = `EXIT-${st.id}`;
    const exitData = {
      id: exitId,
      studentId: st.id,
      studentName: st.name || st.displayName,
      classId: `Grade ${st.grade || "3"} Section ${st.section || "A"}`,
      gender: st.gender || (i % 2 === 0 ? "Male" : "Female"),
      nationality: st.nationality || "Omani",
      dateOfBirth: st.dateOfBirth || st.dob || "2013-05-12",
      fatherName: st.fatherName || `Mr. ${st.name.split(" ")[0]} Al-Balushi`,
      motherName: st.motherName || "Mrs. Al-Balushi",
      admissionDate: st.admissionDate || "2020-09-01",
      exitDate: `2026-02-${String(10 + i).padStart(2, "0")}`,
      exitReason: reason,
      destinationSchool: destSchool,
      destinationCountry: destCountry,
      tcNumber: `TC/2026/${String(i + 1).padStart(4, "0")}`,
      feesClearance: "Completed",
      libraryClearance: "Completed",
      transportClearance: "Completed",
      accountsClearance: "Completed",
      uniformClearance: "Completed",
      exitRemarks: "Family relocation. Completed all transfer certificate clearances.",
      nationalIdNumber: `QID-968` + Math.floor(10000000 + Math.random() * 90000000),
      parentAcknowledgement: true,
      conduct: "Excellent",
      lastExamination: "Term 1 Exams",
      examResult: "Pass",
      promotionClass: `Grade ${Number(st.grade || 3) + 1}`,
      attendance: "94.5%",
      createdBy: "admin@studentdiwan.com"
    };

    for (const userUid of TARGET_UIDS) {
      exitsToInsert.push([`${exitId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...exitData, uid: userUid }), userUid, now, now]);
    }
  }

  if (exitsToInsert.length > 0) {
    await connection.query("INSERT INTO exitRecords (id, data, uid, createdAt, updatedAt) VALUES ?", [exitsToInsert]);
  }
  console.log(`  → Seeded ${exitsToInsert.length} exit/clearance records.`);

  // 4. SEED ASSESSMENTS, ATTEMPTS, TEACHER ASSIGNMENTS, AND SUBMISSIONS
  console.log("\n📝 Seeding Assessments, Homework & Gradebook details...");

  const assessmentsToInsert = [];
  const attemptsToInsert = [];
  const homeworksToInsert = [];
  const submissionsToInsert = [];

  const assessmentTypes = ["Unit Test", "Weekly Test", "Monthly Test", "Assignment", "Project", "Practical Exam", "Mid-Term Exam", "Final Exam"];
  const subjectList = ["Arabic", "English", "Mathematics", "Science", "Islamic Studies", "Social Studies", "Physics", "Chemistry", "Biology"];

  let assessmentCount = 0;
  let homeworkCount = 0;

  // We loop through active cohorts and seed them
  for (const cohortKey of activeKeys) {
    const [g, sec] = cohortKey.split("|");
    const cohortStudents = studentsByGradeSection[cohortKey].filter(s => s.status !== "Graduated" && s.status !== "Left" && s.status !== "Withdrawn");
    if (cohortStudents.length === 0) continue;

    // Core 4 subjects for this cohort
    const cohortSubjects = subjectList.slice(0, 4);

    for (const sub of cohortSubjects) {
      const teacher = teachers[Math.floor(Math.random() * teachers.length)]?.name || "Aisha Qureshi";
      
      // Let's create 3 assessments of different types for this subject
      const selectedTypes = [
        assessmentTypes[Math.floor(Math.random() * 3)],      // Test / Quiz
        assessmentTypes[3 + Math.floor(Math.random() * 2)],  // Assignment / Project
        assessmentTypes[5 + Math.floor(Math.random() * 3)]   // Exam
      ];

      for (let tIdx = 0; tIdx < selectedTypes.length; tIdx++) {
        const type = selectedTypes[tIdx];
        const totalMarks = type.includes("Exam") ? 100 : (type.includes("Project") || type.includes("Monthly") ? 50 : 20);
        const passingMarks = Math.round(totalMarks * 0.4);
        const assId = `ASSESS-${g}-${sec}-${sub.slice(0,3)}-${tIdx}-${Date.now().toString().slice(-4)}`;

        const assData = {
          id: assId,
          title: `${sub} ${type} — Grade ${g}${sec}`,
          chapter: `Chapter ${tIdx + 1}`,
          type,
          grade: `Grade ${g}`,
          section: sec,
          subject: sub,
          date: `2026-05-${String(10 + tIdx * 5).padStart(2, "0")}`,
          duration: type.includes("Exam") ? 120 : 45,
          totalMarks,
          passingMarks,
          description: `${type} covering syllabus topics for Term 1. Please ensure timely submission.`,
          questions: [
            { id: `Q-${assId}-1`, type: "MCQ", text: `Question 1 regarding ${sub} concepts.`, marks: Math.round(totalMarks * 0.2), options: ["Option A", "Option B", "Option C", "Option D"], correctAnswer: "Option A" },
            { id: `Q-${assId}-2`, type: "Short Answer", text: `Question 2: Write a brief analysis on ${sub} topic.`, marks: Math.round(totalMarks * 0.4) },
            { id: `Q-${assId}-3`, type: "Fill in the Blank", text: `Question 3: Fill in the blank regarding ${sub} history.`, marks: Math.round(totalMarks * 0.4) }
          ],
          submissions: cohortStudents.length,
          totalStudents: cohortStudents.length,
          status: "Completed",
          teacher,
          createdAt: `2026-04-15`,
          resultVisibility: "immediate",
          resultsReleased: true
        };

        assessmentCount++;
        // Insert for both admin uids to show on their respective dashboards
        for (const userUid of TARGET_UIDS) {
          assessmentsToInsert.push([`${assId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...assData, uid: userUid }), userUid, now, now]);
        }

        // Generate student attempts
        for (const st of cohortStudents) {
          const attemptId = `ATTEMPT-${assId}-${st.id}`;
          const score = getRandomScore(totalMarks, 0.77, 0.12);
          const attemptData = {
            id: attemptId,
            assessmentId: assId,
            studentId: st.id,
            studentName: st.name || st.displayName,
            status: "submitted",
            score,
            submittedAt: `${assData.date}T10:30:00Z`,
            isMarked: true
          };

          for (const userUid of TARGET_UIDS) {
            attemptsToInsert.push([`${attemptId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...attemptData, uid: userUid }), userUid, now, now]);
          }
        }
      }

      // Seed 2 Homework / Teacher Assignments
      for (let hwIdx = 1; hwIdx <= 2; hwIdx++) {
        const hwId = `HW-${g}-${sec}-${sub.slice(0,3)}-${hwIdx}-${Date.now().toString().slice(-4)}`;
        const totalMarks = 20;
        const hwData = {
          id: hwId,
          title: `${sub} Homework Assignment ${hwIdx}`,
          grade: `Grade ${g}`,
          section: sec,
          subject: sub,
          totalMarks,
          teacher,
          description: `Read chapter ${hwIdx + 2} and answer the exercises at the end of the chapter.`,
          dueDate: `2026-04-${String(12 + hwIdx * 7).padStart(2, "0")}`,
          status: "Completed"
        };

        homeworkCount++;
        for (const userUid of TARGET_UIDS) {
          homeworksToInsert.push([`${hwId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...hwData, uid: userUid }), userUid, now, now]);
        }

        // Student submissions
        for (const st of cohortStudents) {
          const subId = `SUBM-${hwId}-${st.id}`;
          const marks = getRandomScore(totalMarks, 0.85, 0.1);
          const subData = {
            id: subId,
            assignmentId: hwId,
            studentId: st.id,
            studentName: st.name || st.displayName,
            marks,
            status: "graded",
            submittedAt: `${hwData.dueDate}T18:00:00Z`,
            gradedAt: `${hwData.dueDate}T20:00:00Z`,
            teacherRemarks: marks >= 18 ? "Excellent submission! Very neat and correct." : (marks >= 14 ? "Good work, keep practicing." : "Need improvement in step calculation.")
          };

          for (const userUid of TARGET_UIDS) {
            submissionsToInsert.push([`${subId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...subData, uid: userUid }), userUid, now, now]);
          }
        }
      }
    }
  }

  // Batch insert assessments
  if (assessmentsToInsert.length > 0) {
    const chunk = 100;
    for (let i = 0; i < assessmentsToInsert.length; i += chunk) {
      await connection.query("INSERT INTO assessments (id, data, uid, createdAt, updatedAt) VALUES ?", [assessmentsToInsert.slice(i, i + chunk)]);
    }
  }

  // Batch insert attempts
  if (attemptsToInsert.length > 0) {
    const chunk = 500;
    for (let i = 0; i < attemptsToInsert.length; i += chunk) {
      await connection.query("INSERT INTO assessment_attempts (id, data, uid, createdAt, updatedAt) VALUES ?", [attemptsToInsert.slice(i, i + chunk)]);
    }
  }

  // Batch insert homework
  if (homeworksToInsert.length > 0) {
    const chunk = 100;
    for (let i = 0; i < homeworksToInsert.length; i += chunk) {
      await connection.query("INSERT INTO teacher_assignments (id, data, uid, createdAt, updatedAt) VALUES ?", [homeworksToInsert.slice(i, i + chunk)]);
    }
  }

  // Batch insert homework submissions
  if (submissionsToInsert.length > 0) {
    const chunk = 500;
    for (let i = 0; i < submissionsToInsert.length; i += chunk) {
      await connection.query("INSERT INTO assignment_submissions (id, data, uid, createdAt, updatedAt) VALUES ?", [submissionsToInsert.slice(i, i + chunk)]);
    }
  }

  console.log(`  → Seeded ${assessmentCount} Assessments & ${attemptsToInsert.length / TARGET_UIDS.length} Student Attempts.`);
  console.log(`  → Seeded ${homeworkCount} Homework Assignments & ${submissionsToInsert.length / TARGET_UIDS.length} Student Submissions.`);

  // 5. SEED EXAMS & EXAM MARKS
  console.log("\n🏫 Seeding Central Exams Registry (Term 1 Mid-Term & Final Exams)...");
  
  const midTermId = "EXAM-2026-T1-MIDTERM";
  const finalId = "EXAM-2026-T1-FINAL";

  const midtermGradePlans = [];
  const finalGradePlans = [];

  const midtermMarksMap = {};
  const finalMarksMap = {};

  // For every cohort, generate slots and marks
  for (const cohortKey of activeKeys) {
    const [g, sec] = cohortKey.split("|");
    const cohortStudents = studentsByGradeSection[cohortKey].filter(s => s.status !== "Graduated" && s.status !== "Left" && s.status !== "Withdrawn");
    if (cohortStudents.length === 0) continue;

    const cohortSubjects = subjectList.slice(0, 5); // 5 exam papers
    const midSlots = [];
    const finSlots = [];

    cohortSubjects.forEach((sub, sIdx) => {
      const teacherName = teachers[sIdx % teachers.length]?.name || "Majid Al-Rawahi";
      
      midSlots.push({
        subject: sub,
        date: `2026-05-${String(11 + sIdx).padStart(2, "0")}`,
        start: "08:30",
        end: "10:30",
        invigilator: teacherName,
        room: `ROOM-1${sIdx + 1}`,
        subjectTeacher: teacherName
      });

      finSlots.push({
        subject: sub,
        date: `2026-06-${String(15 + sIdx).padStart(2, "0")}`,
        start: "08:30",
        end: "11:30",
        invigilator: teacherName,
        room: `ROOM-1${sIdx + 1}`,
        subjectTeacher: teacherName
      });

      // Generate marks mapping
      midtermMarksMap[sub] = midtermMarksMap[sub] || {};
      finalMarksMap[sub] = finalMarksMap[sub] || {};

      for (const st of cohortStudents) {
        midtermMarksMap[sub][st.id] = getRandomScore(100, 0.76, 0.12);
        finalMarksMap[sub][st.id] = getRandomScore(100, 0.79, 0.11);
      }
    });

    midtermGradePlans.push({
      grade: `Grade ${g}`,
      section: "All Sections",
      sections: ["A", "B", "C", "D"],
      subjects: `${cohortSubjects.length} Subjects`,
      startDate: midSlots[0].date,
      endDate: midSlots[midSlots.length - 1].date,
      appeared: cohortStudents.length,
      total: cohortStudents.length,
      slots: midSlots,
      publishedToStudents: true
    });

    finalGradePlans.push({
      grade: `Grade ${g}`,
      section: "All Sections",
      sections: ["A", "B", "C", "D"],
      subjects: `${cohortSubjects.length} Subjects`,
      startDate: finSlots[0].date,
      endDate: finSlots[finSlots.length - 1].date,
      appeared: cohortStudents.length,
      total: cohortStudents.length,
      slots: finSlots,
      publishedToStudents: true
    });
  }

  // Create midterm exam record
  const midExamData = {
    id: midTermId,
    name: "Term 1 Mid-Term Examination",
    type: "Mid-Term Exam",
    grade: "Grade 1",
    section: "All Sections",
    sections: ["A", "B", "C", "D"],
    subjects: "5 Subjects",
    startDate: "2026-05-11",
    endDate: "2026-05-20",
    appeared: students.length,
    total: students.length,
    status: "Published",
    slots: midtermGradePlans[0].slots,
    published: true,
    gradePlans: midtermGradePlans,
    mode: "Offline",
    venue: "Main Block",
    room: "Exam Hall A",
    invigilator: "Mr. Majid Al-Rawahi",
    durationMin: 120,
    maxMarks: 100,
    passingMarks: 40,
    publishedToTeachers: true,
    publishedToStudents: true
  };

  // Create final exam record
  const finExamData = {
    id: finalId,
    name: "Term 1 Final Examination",
    type: "Final Exam",
    grade: "Grade 1",
    section: "All Sections",
    sections: ["A", "B", "C", "D"],
    subjects: "5 Subjects",
    startDate: "2026-06-15",
    endDate: "2026-06-25",
    appeared: students.length,
    total: students.length,
    status: "Published",
    slots: finalGradePlans[0].slots,
    published: true,
    gradePlans: finalGradePlans,
    mode: "Offline",
    venue: "Main Block",
    room: "Exam Hall A",
    invigilator: "Mr. Majid Al-Rawahi",
    durationMin: 180,
    maxMarks: 100,
    passingMarks: 40,
    publishedToTeachers: true,
    publishedToStudents: true
  };

  // Insert Exam records
  const examsToInsert = [];
  for (const userUid of TARGET_UIDS) {
    examsToInsert.push([`${midTermId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...midExamData, uid: userUid }), userUid, now, now]);
    examsToInsert.push([`${finalId}-${userUid.slice(0, 8)}`, JSON.stringify({ ...finExamData, uid: userUid }), userUid, now, now]);
  }
  await connection.query("INSERT INTO exams (id, data, uid, createdAt, updatedAt) VALUES ?", [examsToInsert]);

  // Insert ExamMark records (containing student subject wise mappings)
  const examMarksToInsert = [];
  for (const userUid of TARGET_UIDS) {
    examMarksToInsert.push([`${midTermId}-${userUid.slice(0, 8)}`, JSON.stringify({ id: midTermId, ...midtermMarksMap, uid: userUid }), userUid, now, now]);
    examMarksToInsert.push([`${finalId}-${userUid.slice(0, 8)}`, JSON.stringify({ id: finalId, ...finalMarksMap, uid: userUid }), userUid, now, now]);
  }
  await connection.query("INSERT INTO exam_marks (id, data, uid, createdAt, updatedAt) VALUES ?", [examMarksToInsert]);

  console.log(`  → Seeded Mid-Term & Final Exams with comprehensive student scores.`);

  // 6. SEED ROOMS
  console.log("\n🏫 Seeding Specialized Building Infrastructure Rooms...");
  for (const r of SPECIALIZED_ROOMS) {
    const roomId = `ROOM-${r.roomNo}`;
    for (const userUid of TARGET_UIDS) {
      const roomData = { ...r, id: roomId, uid: userUid };
      // Delete if duplicate roomNo exists to avoid duplicates
      await connection.execute(`DELETE FROM Room WHERE id = ?`, [`${roomId}-${userUid.slice(0, 8)}`]);
      await connection.execute(`INSERT INTO Room (id, data, uid, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?)`, [
        `${roomId}-${userUid.slice(0, 8)}`,
        JSON.stringify(roomData),
        userUid,
        now,
        now
      ]);
    }
  }
  console.log(`  → Seeded ${SPECIALIZED_ROOMS.length} Robotics Labs, Science Labs, and Studios.`);

  console.log("\n═══════════════════════════════════════════════════");
  console.log("  ✅ ALL DEMO DATA POPULATED SUCCESSFULLY           ");
  console.log("═══════════════════════════════════════════════════");

  await connection.end();
}

main().catch(error => {
  console.error("❌ Seeding failed with error:", error);
  process.exit(1);
});
