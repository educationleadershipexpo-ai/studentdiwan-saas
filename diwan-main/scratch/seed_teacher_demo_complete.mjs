import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

async function seedTeacherCompleteData() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    port: process.env.DB_PORT || 3306,
  });

  console.log("⚡ Seeding complete real-time demo data for teacher@studentdiwan.com...");
  const now = new Date().toISOString();
  const todayStr = new Date().toISOString().split("T")[0];

  // 1. Ensure user and staff records for teacher@studentdiwan.com exist with complete details
  const teacherEmails = ["teacher@studentdiwan.com", "teacher"];
  const teacherNames = ["Fatima Al-Rashid", "Mr. Rizwan Ahmed"];

  for (const tEmail of teacherEmails) {
    const userObj = {
      id: "USER-STF-DEMO-01",
      email: "teacher@studentdiwan.com",
      name: "Fatima Al-Rashid",
      displayName: "Fatima Al-Rashid",
      role: "staff",
      assignedGrade: "Grade 3",
      assignedSection: "B",
      classSection: "Grade 3-B",
      assignedClassId: "C-3-B",
      department: "Mathematics",
      subject: "Mathematics",
      createdAt: now,
      updatedAt: now,
    };
    await conn.query(
      `INSERT INTO users (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      ["USER-STF-DEMO-01", JSON.stringify(userObj), "admin-uid", now, now]
    );

    const staffObj = {
      id: "STF-DEMO-01",
      email: "teacher@studentdiwan.com",
      name: "Fatima Al-Rashid",
      role: "Teacher",
      department: "Mathematics",
      assignedGrade: "Grade 3",
      assignedSection: "B",
      classSection: "Grade 3-B",
      createdAt: now,
      updatedAt: now,
    };
    await conn.query(
      `INSERT INTO staff (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      ["STF-DEMO-01", JSON.stringify(staffObj), "admin-uid", now, now]
    );
  }

  // 2. Insert subject_assignments for Fatima Al-Rashid & Mr. Rizwan Ahmed & teacher@studentdiwan.com
  const subjectsToAssign = [
    { grade: "Grade 3", section: "B", subject: "Mathematics" },
    { grade: "Grade 3", section: "B", subject: "Science" },
    { grade: "Grade 3", section: "B", subject: "English" },
    { grade: "Grade 3", section: "B", subject: "Arabic" },
    { grade: "Grade 5", section: "B", subject: "Mathematics" },
    { grade: "Grade 5", section: "B", subject: "Science" },
    { grade: "Grade 5", section: "B", subject: "Computer Science" },
    { grade: "Grade 10", section: "A", subject: "Mathematics" },
    { grade: "Grade 10", section: "A", subject: "Science" },
  ];

  for (const name of ["Fatima Al-Rashid", "Mr. Rizwan Ahmed", "Teacher", "Teacher User"]) {
    for (const sa of subjectsToAssign) {
      const saId = `SA-${sa.grade.replace(/\s+/g, '')}-${sa.section}-${sa.subject.replace(/\s+/g, '')}-${name.replace(/\s+/g, '')}`;
      const saObj = {
        id: saId,
        teacherId: "STF-DEMO-01",
        teacherName: name,
        teacherEmail: "teacher@studentdiwan.com",
        grade: sa.grade,
        section: sa.section,
        subject: sa.subject,
        academicYear: "2025-2026",
        weeklyPeriods: 5,
        room: `Room ${sa.section}`,
        status: "Active",
        createdAt: now,
        updatedAt: now,
      };
      await conn.query(
        `INSERT INTO teacher_assignments (id, data, uid, createdAt, updatedAt)
         VALUES (?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
        [saId, JSON.stringify(saObj), "admin-uid", now, now]
      );
    }
  }
  console.log("  ✓ Subject assignments seeded for Teacher accounts.");

  // 3. Insert Homework items
  const hwItems = [
    { id: "HW-001", title: "Fractions & Decimals Practice", subject: "Mathematics", grade: "Grade 3", section: "B", dueDate: "2026-09-10", description: "Complete exercises 1 to 15 on page 42 of the workbook." },
    { id: "HW-002", title: "Plant Cell & Photosynthesis Worksheet", subject: "Science", grade: "Grade 3", section: "B", dueDate: "2026-09-12", description: "Draw and label parts of a plant cell." },
    { id: "HW-003", title: "Creative Writing Essay: Summer Journey", subject: "English", grade: "Grade 3", section: "B", dueDate: "2026-09-15", description: "Write a 250-word story about an unforgettable journey." },
    { id: "HW-004", title: "Algebraic Equations Problem Set", subject: "Mathematics", grade: "Grade 5", section: "B", dueDate: "2026-09-11", description: "Solve all quadratic equation practice problems." },
    { id: "HW-005", title: "Python Basics Loops & Functions", subject: "Computer Science", grade: "Grade 5", section: "B", dueDate: "2026-09-14", description: "Write a program that prints prime numbers up to 100." },
    { id: "HW-006", title: "Trigonometric Identities Worksheet", subject: "Mathematics", grade: "Grade 10", section: "A", dueDate: "2026-09-13", description: "Complete chapter 4 review questions." },
  ];

  for (const hw of hwItems) {
    const hwObj = {
      id: hw.id,
      title: hw.title,
      subject: hw.subject,
      description: hw.description,
      dueDate: hw.dueDate,
      grade: hw.grade,
      section: hw.section,
      teacher: "Fatima Al-Rashid",
      createdAt: now,
      updatedAt: now,
      uid: "USER-STF-DEMO-01",
    };
    await conn.query(
      `INSERT INTO homework (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [hw.id, JSON.stringify(hwObj), "USER-STF-DEMO-01", now, now]
    );
  }
  console.log("  ✓ Homework items seeded.");

  // 4. Insert Study Materials
  const materials = [
    { id: "MAT-001", title: "Chapter 1: Multi-digit Multiplication Notes", subject: "Mathematics", type: "PDF Notes", grade: "Grade 3", section: "B", chapter: "Chapter 1", lesson: "Lesson 1", link: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf" },
    { id: "MAT-002", title: "Interactive Math Games Slide Deck", subject: "Mathematics", type: "PPT Presentation", grade: "Grade 3", section: "B", chapter: "Chapter 1", lesson: "Lesson 2", link: "https://example.com/slides.pdf" },
    { id: "MAT-003", title: "Photosynthesis Video Lecture", subject: "Science", type: "Video Link", grade: "Grade 3", section: "B", chapter: "Chapter 2", lesson: "Lesson 1", link: "https://www.youtube.com/watch?v=D1Ymc391fSU" },
    { id: "MAT-004", title: "English Grammar Rules Summary", subject: "English", type: "PDF Notes", grade: "Grade 3", section: "B", chapter: "Chapter 1", lesson: "Lesson 1", link: "https://example.com/grammar.pdf" },
    { id: "MAT-005", title: "Grade 5 Algebra Formula Sheet", subject: "Mathematics", type: "PDF Notes", grade: "Grade 5", section: "B", chapter: "Chapter 3", lesson: "Lesson 1", link: "https://example.com/algebra.pdf" },
    { id: "MAT-006", title: "Python Syntax Quick Reference", subject: "Computer Science", type: "PDF Notes", grade: "Grade 5", section: "B", chapter: "Chapter 1", lesson: "Lesson 3", link: "https://example.com/python.pdf" },
  ];

  for (const mat of materials) {
    const matObj = {
      id: mat.id,
      title: mat.title,
      subject: mat.subject,
      type: mat.type,
      link: mat.link,
      grade: mat.grade,
      section: mat.section,
      chapter: mat.chapter,
      lesson: mat.lesson,
      teacher: "Fatima Al-Rashid",
      createdAt: now,
      updatedAt: now,
      uid: "USER-STF-DEMO-01",
    };
    await conn.query(
      `INSERT INTO studymaterial (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [mat.id, JSON.stringify(matObj), "USER-STF-DEMO-01", now, now]
    );
  }
  console.log("  ✓ Study materials seeded.");

  // 5. Insert Flashcard Sets
  const flashcardSets = [
    { id: "FC-001", title: "Math Multiplication Tables (1-12)", subject: "Mathematics", grade: "Grade 3", section: "B", cardsCount: 15, cards: [{ term: "7 × 8", definition: "56" }, { term: "9 × 6", definition: "54" }, { term: "12 × 11", definition: "132" }] },
    { id: "FC-002", title: "Science Terminology & Vocab", subject: "Science", grade: "Grade 3", section: "B", cardsCount: 12, cards: [{ term: "Photosynthesis", definition: "Process plants use to make food from sunlight" }, { term: "Chlorophyll", definition: "Green pigment in plants that absorbs light energy" }] },
    { id: "FC-003", title: "English Vocabulary Booster", subject: "English", grade: "Grade 3", section: "B", cardsCount: 20, cards: [{ term: "Abundant", definition: "Existing in large quantities; plentiful" }, { term: "Resilient", definition: "Able to withstand or recover quickly from difficult conditions" }] },
  ];

  for (const fc of flashcardSets) {
    const fcObj = {
      id: fc.id,
      title: fc.title,
      subject: fc.subject,
      grade: fc.grade,
      section: fc.section,
      cardsCount: fc.cardsCount,
      cards: fc.cards,
      teacher: "Fatima Al-Rashid",
      createdAt: now,
      updatedAt: now,
      uid: "USER-STF-DEMO-01",
    };
    await conn.query(
      `INSERT INTO flashcard_sets (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [fc.id, JSON.stringify(fcObj), "USER-STF-DEMO-01", now, now]
    );
  }
  console.log("  ✓ Flashcard sets seeded.");

  // 6. Insert Assessments & Exam Results
  const assessments = [
    { id: "ASM-001", title: "Mid-Term Mathematics Exam", subject: "Mathematics", grade: "Grade 3", section: "B", totalMarks: 100, date: "2026-09-20", type: "Exam" },
    { id: "ASM-002", title: "Science Chapter 1 Quiz", subject: "Science", grade: "Grade 3", section: "B", totalMarks: 50, date: "2026-09-18", type: "Quiz" },
    { id: "ASM-003", title: "English Essay Assessment", subject: "English", grade: "Grade 3", section: "B", totalMarks: 50, date: "2026-09-22", type: "Assignment" },
  ];

  for (const asm of assessments) {
    const asmObj = {
      id: asm.id,
      title: asm.title,
      subject: asm.subject,
      grade: asm.grade,
      section: asm.section,
      totalMarks: asm.totalMarks,
      date: asm.date,
      type: asm.type,
      teacher: "Fatima Al-Rashid",
      createdAt: now,
      updatedAt: now,
      uid: "USER-STF-DEMO-01",
    };
    await conn.query(
      `INSERT INTO assessments (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [asm.id, JSON.stringify(asmObj), "USER-STF-DEMO-01", now, now]
    );
  }
  console.log("  ✓ Assessments seeded.");

  // 7. Seed Attendance rows for today for Grade 3-B students
  const [studentsRows] = await conn.query(`SELECT id, data FROM students LIMIT 50`);
  let count = 0;
  for (const sRow of studentsRows) {
    const sData = JSON.parse(sRow.data);
    const attId = `ATT-STU-${sRow.id}-${todayStr}`;
    const status = count % 5 === 0 ? "Absent" : count % 7 === 0 ? "Late" : "Present";
    const attObj = {
      id: attId,
      entityId: sRow.id,
      entityType: "student",
      name: sData.name || "Student",
      class: "3-B",
      grade: "Grade 3",
      section: "B",
      status,
      date: todayStr,
      time: status === "Absent" ? "-" : "08:00 AM",
      createdAt: now,
      updatedAt: now,
      uid: "USER-STF-DEMO-01",
    };
    await conn.query(
      `INSERT INTO attendance (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [attId, JSON.stringify(attObj), "USER-STF-DEMO-01", now, now]
    );
    count++;
  }
  console.log(`  ✓ Seeded ${count} daily attendance rows for teacher roster.`);

  await conn.end();
  console.log("✨ Complete Teacher Real-Time Demo Data Seeding Finished Successfully!");
}

seedTeacherCompleteData().catch(console.error);
