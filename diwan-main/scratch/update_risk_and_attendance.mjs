import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

const MEDICAL_CONDITIONS = [
  'Asthma',
  'Type 1 Diabetes',
  'Mild Epilepsy',
  'Chronic Migraine',
  'Eczema',
  'Allergic Rhinitis',
  'G6PD Deficiency',
  'None',
  'None',
  'None',
  'None',
];

const ALLERGIES = [
  'Peanut Allergy',
  'Penicillin',
  'Dust Mites',
  'Lactose Intolerance',
  'Shellfish Allergy',
  'Egg Allergy',
  'None',
  'None',
  'None',
  'None',
];

async function updateStudents() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  console.log('🔄 Updating student records in MySQL with realistic risk scores, attendance %, fee status, and health fields...');

  const [rows] = await conn.query('SELECT id, data, uid, createdAt FROM students');
  console.log(`Found ${rows.length} total students.`);

  let atRiskCount = 0;
  let lowAttendanceCount = 0;
  let aiPriorityCount = 0;
  let medicalCount = 0;

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    let data = {};
    try {
      data = JSON.parse(row.data);
    } catch {}

    // Deterministic distribution based on index i so it's consistent:
    // 1) ~7% At-Risk (riskScore 75-95)
    // 2) ~15% AI Priority (riskScore 45-74)
    // 3) ~6% Low Attendance (<75%)
    // 4) ~12% Special Medical/Allergy Needs

    if (i % 14 === 0) {
      // High Risk
      data.riskScore = 75 + (i % 20);
      data.attendance = 55 + (i % 18); // 55% - 73% (low attendance)
      data.feeStatus = i % 2 === 0 ? 'Overdue' : 'Pending';
      data.riskFactors = ['Frequent Absences', 'Unpaid Tuition', 'Decline in Science Marks'];
      atRiskCount++;
      lowAttendanceCount++;
    } else if (i % 8 === 0) {
      // Low Attendance Only
      data.riskScore = 55 + (i % 18);
      data.attendance = 60 + (i % 14); // 60% - 74%
      data.feeStatus = i % 3 === 0 ? 'Pending' : 'Paid';
      data.riskFactors = ['Chronic Tardiness'];
      lowAttendanceCount++;
      aiPriorityCount++;
    } else if (i % 5 === 0) {
      // Moderate AI Priority
      data.riskScore = 48 + (i % 24);
      data.attendance = 78 + (i % 15);
      data.feeStatus = i % 4 === 0 ? 'Pending' : 'Paid';
      data.riskFactors = ['Needs Tutoring Support'];
      aiPriorityCount++;
    } else {
      // Low Risk / Normal
      data.riskScore = 10 + (i % 30);
      data.attendance = 85 + (i % 14); // 85% - 99%
      data.feeStatus = i % 7 === 0 ? 'Pending' : 'Paid';
    }

    // Health condition distribution
    if (i % 12 === 0) {
      data.medicalConditions = MEDICAL_CONDITIONS[i % MEDICAL_CONDITIONS.length];
      data.allergies = ALLERGIES[(i + 2) % ALLERGIES.length];
      data.bloodGroup = ['A+', 'B+', 'O+', 'AB+', 'A-', 'O-'][i % 6];
      medicalCount++;
    } else {
      if (!data.bloodGroup) {
        data.bloodGroup = ['O+', 'A+', 'B+', 'AB+'][i % 4];
      }
      if (!data.medicalConditions) data.medicalConditions = 'None';
      if (!data.allergies) data.allergies = 'None';
    }

    await conn.query('UPDATE students SET data = ?, updatedAt = ? WHERE id = ?', [
      JSON.stringify(data),
      new Date().toISOString(),
      row.id,
    ]);
  }

  console.log(`✅ Successfully updated all ${rows.length} student records:`);
  console.log(`   - At-Risk Students (riskScore >= 75): ${atRiskCount}`);
  console.log(`   - Low Attendance (<75%): ${lowAttendanceCount}`);
  console.log(`   - AI Priority Hub Flagged: ${aiPriorityCount + atRiskCount}`);
  console.log(`   - Medical Conditions / Allergies Flagged: ${medicalCount}`);

  await conn.end();
}

updateStudents().catch(console.error);
