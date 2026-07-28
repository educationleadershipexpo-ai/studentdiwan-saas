import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

async function runAssignment() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  console.log('Fetching staff, sections, classes, and subjects...');

  const [staffRows] = await conn.query('SELECT id, data FROM staff');
  const [sectionsRows] = await conn.query('SELECT id, data FROM sections');

  const teachers = [];
  staffRows.forEach((r) => {
    try {
      const d = JSON.parse(r.data);
      teachers.push({
        id: r.id,
        name: d.name || d.fullName || 'Teacher',
        email: d.email || '',
        department: d.department || 'Academic',
        subject: d.subject || d.department || 'General',
        role: d.role || 'Teacher',
        data: d,
      });
    } catch {}
  });

  console.log(`Found ${teachers.length} teachers.`);

  const subjectList = [
    { name: 'Mathematics', dept: 'Mathematics' },
    { name: 'Arabic Language', dept: 'Arabic' },
    { name: 'English Language', dept: 'English' },
    { name: 'Science', dept: 'Science' },
    { name: 'Islamic Studies', dept: 'Islamic Studies' },
    { name: 'Social Studies', dept: 'Social Studies' },
    { name: 'Computer Science', dept: 'IT' },
    { name: 'Art & Design', dept: 'Art' },
    { name: 'Physical Education', dept: 'Sports' },
  ];

  const teachersByDept = {};
  subjectList.forEach((s) => { teachersByDept[s.dept] = []; });
  teachersByDept['General'] = [];

  teachers.forEach((t) => {
    let matched = false;
    for (const s of subjectList) {
      if (
        (t.department && t.department.toLowerCase().includes(s.dept.toLowerCase())) ||
        (t.subject && t.subject.toLowerCase().includes(s.name.toLowerCase()))
      ) {
        teachersByDept[s.dept].push(t);
        matched = true;
        break;
      }
    }
    if (!matched) {
      teachersByDept['General'].push(t);
    }
  });

  console.log('Teacher pool distribution by subject:');
  Object.keys(teachersByDept).forEach((k) => {
    console.log(`  - ${k}: ${teachersByDept[k].length} teachers`);
  });

  // Assign class teachers to ALL sections
  let updatedSections = 0;
  let teacherIdx = 0;

  for (const sRow of sectionsRows) {
    let sData = {};
    try { sData = JSON.parse(sRow.data); } catch {}

    const assignedTeacher = teachers[teacherIdx % teachers.length];
    teacherIdx++;

    sData.teacherId = assignedTeacher.id;
    sData.teacherName = assignedTeacher.name;
    sData.classTeacher = assignedTeacher.name;
    sData.teacherEmail = assignedTeacher.email;

    await conn.query('UPDATE sections SET data = ?, updatedAt = ? WHERE id = ?', [
      JSON.stringify(sData),
      new Date().toISOString(),
      sRow.id,
    ]);
    updatedSections++;
  }

  console.log(`✅ Assigned Class Teachers to all ${updatedSections} sections.`);

  // Build subject teacher assignments for ALL grades (1-12) & sections (A, B, C, D) & subjects
  const grades = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
  const sectionsArr = ['A', 'B', 'C', 'D'];
  const now = new Date().toISOString();

  let totalAssignmentsCreated = 0;
  const teacherAssignmentsToInsert = [];

  const deptPointers = {};
  Object.keys(teachersByDept).forEach((k) => { deptPointers[k] = 0; });

  grades.forEach((grade) => {
    sectionsArr.forEach((section) => {
      const sectionId = `SEC-${grade}-${section}`;

      subjectList.forEach((sub) => {
        const pool = teachersByDept[sub.dept].length > 0 ? teachersByDept[sub.dept] : teachers;
        const ptr = deptPointers[sub.dept] || 0;
        const assignedT = pool[ptr % pool.length];
        deptPointers[sub.dept] = ptr + 1;

        const assignmentId = `TA-${grade}-${section}-${sub.name.replace(/\s+/g, '')}`;
        const assignmentObj = {
          id: assignmentId,
          teacherId: assignedT.id,
          teacherName: assignedT.name,
          teacherEmail: assignedT.email,
          subject: sub.name,
          subjectId: `SUB-${sub.name.replace(/\s+/g, '')}`,
          grade: String(grade),
          section,
          classId: `C-${grade}`,
          className: `Grade ${grade}`,
          sectionId,
          academicYear: '2024-2025',
          weeklyPeriods: 4,
          room: `Room ${grade}0${section.charCodeAt(0) - 64}`,
          status: 'Active',
          uid: 'admin-uid',
          createdAt: now,
          updatedAt: now,
        };

        teacherAssignmentsToInsert.push({
          id: assignmentId,
          data: JSON.stringify(assignmentObj),
          uid: 'admin-uid',
          createdAt: now,
          updatedAt: now,
        });
        totalAssignmentsCreated++;
      });
    });
  });

  // Batch insert/upsert teacher_assignments into MySQL
  for (const item of teacherAssignmentsToInsert) {
    await conn.query(
      `INSERT INTO teacher_assignments (id, data, uid, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [item.id, item.data, item.uid, item.createdAt, item.updatedAt]
    );
  }

  console.log(`✅ Successfully created/upserted ${totalAssignmentsCreated} subject-teacher assignments across all grades & subjects.`);

  // Assign Grade Coordinators for Grades 1 to 12
  for (let g = 1; g <= 12; g++) {
    const gcTeacher = teachers[(g * 3) % teachers.length];
    const gcObj = {
      id: `GC-2025-G${g}`,
      staffId: gcTeacher.id,
      staffName: gcTeacher.name,
      staffEmail: gcTeacher.email,
      grade: String(g),
      academicYear: '2024-2025',
      assignedDate: now,
      status: 'Active',
      uid: 'admin-uid',
      createdAt: now,
      updatedAt: now,
    };
    await conn.query(
      `INSERT INTO grade_coordinators (id, data, uid, createdAt, updatedAt)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [gcObj.id, JSON.stringify(gcObj), gcObj.uid, gcObj.createdAt, gcObj.updatedAt]
    );
  }

  console.log('✅ Successfully assigned Grade Coordinators for Grades 1 through 12.');

  await conn.end();
}

runAssignment().catch(console.error);
