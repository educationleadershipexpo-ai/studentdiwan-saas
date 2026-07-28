import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

const STAGES = [
  'Enquiry',
  'Form Sent',
  'Form Submitted',
  'Payment Done',
  'Exam',
  'Interview',
  'Doc Verification',
  'School Fee',
  'Section Allocation',
  'Enrolled',
];

const SOURCES = ['Website', 'Walk-in', 'Referral', 'Instagram', 'Exhibition', 'Google Ads'];

const FIRST_NAMES_MALE = [
  'Tariq', 'Bader', 'Youssef', 'Khalid', 'Salim', 'Nasser', 'Hamad', 'Sultan',
  'Faisal', 'Zayed', 'Rashid', 'Adel', 'Saif', 'Omar', 'Ahmad', 'Mahmood',
];
const FIRST_NAMES_FEMALE = [
  'Mariam', 'Fatima', 'Aisha', 'Zainab', 'Layla', 'Reem', 'Noor', 'Asma',
  'Mona', 'Hala', 'Sarah', 'Khadija', 'Rania', 'Amal', 'Safia', 'Hind',
];
const LAST_NAMES = [
  'Al-Kindi', 'Al-Habsi', 'Al-Harthy', 'Al-Balushi', 'Al-Farsi', 'Al-Hinai',
  'Al-Busaidi', 'Al-Rawahi', 'Al-Maamari', 'Al-Ghafri', 'Al-Shaqsi', 'Al-Riyami',
];

const GRADES = ['KG1', 'KG2', 'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5', 'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10', 'Grade 11', 'Grade 12'];

async function seedAdmissions() {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });

  console.log('🌱 Populating Admissions pipeline with rich demo data...');

  const now = new Date();
  const leadsToInsert = [];
  const docsToInsert = [];
  const commsToInsert = [];

  let count = 0;
  // Generate 120 leads total (12 per stage)
  for (let i = 0; i < 120; i++) {
    const isFemale = i % 2 === 1;
    const sFirstName = isFemale
      ? FIRST_NAMES_FEMALE[i % FIRST_NAMES_FEMALE.length]
      : FIRST_NAMES_MALE[i % FIRST_NAMES_MALE.length];
    const lastName = LAST_NAMES[i % LAST_NAMES.length];
    const pFirstName = FIRST_NAMES_MALE[(i + 3) % FIRST_NAMES_MALE.length];

    const studentName = `${sFirstName} ${lastName}`;
    const parentName = `${pFirstName} ${lastName}`;
    const stage = STAGES[i % STAGES.length];
    const grade = GRADES[i % GRADES.length];
    const source = SOURCES[i % SOURCES.length];

    const leadId = `ADM-2025-${String(i + 1).padStart(3, '0')}`;
    const email = `${sFirstName.toLowerCase()}.${lastName.toLowerCase().replace(/[^a-z]/g, '')}@gmail.com`;
    const phone = `+968 9${Math.floor(1000000 + Math.random() * 9000000)}`;

    const daysAgo = Math.floor(Math.random() * 30);
    const createdAtDate = new Date(now.getTime() - daysAgo * 24 * 3600 * 1000);
    const createdAt = createdAtDate.toISOString();

    const score = 50 + (i % 45);

    const leadObj = {
      id: leadId,
      studentName,
      parentName,
      email,
      phone,
      interestedClass: grade,
      status: stage,
      source,
      score,
      priority: score >= 80 ? 'High' : score >= 65 ? 'Medium' : 'Standard',
      academicYear: '2025-2026',
      gender: isFemale ? 'Female' : 'Male',
      dateOfBirth: `${2018 - (i % 8)}-05-15`,
      address: `Way ${1000 + (i * 7)}, Al Khuwair, Muscat, Oman`,
      city: 'Muscat',
      country: 'Oman',
      notes: `Parent expressed strong interest during ${source} inquiry. Looking for admission in ${grade}.`,
      aiInsight: score >= 75 ? 'High probability of enrollment. Documents and fee commitment verified.' : 'Standard lead pipeline progressing smoothly.',
      uploadedDocList: [
        { name: 'Omani_Civil_ID.pdf', type: 'Civil ID', status: 'Verified', verifiedAt: createdAt },
        { name: 'Birth_Certificate.pdf', type: 'Birth Certificate', status: 'Verified', verifiedAt: createdAt },
        { name: 'Previous_School_Report.pdf', type: 'Report Card', status: 'Verified', verifiedAt: createdAt },
      ],
      uid: 'admin-001',
      createdAt,
      updatedAt: now.toISOString(),
    };

    leadsToInsert.push({
      id: leadObj.id,
      data: JSON.stringify(leadObj),
      uid: leadObj.uid,
      createdAt,
      updatedAt: leadObj.updatedAt,
    });

    // Generate Lead Document
    const docId = `DOC-${leadId}-01`;
    const docObj = {
      id: docId,
      leadId,
      name: `Civil_ID_${studentName.replace(/\s+/g, '_')}.pdf`,
      type: 'Civil ID',
      status: 'Verified',
      uploadedAt: createdAt,
      verifiedBy: 'Admissions Officer',
      uid: 'admin-001',
      createdAt,
      updatedAt: leadObj.updatedAt,
    };

    docsToInsert.push({
      id: docObj.id,
      data: JSON.stringify(docObj),
      uid: docObj.uid,
      createdAt,
      updatedAt: docObj.updatedAt,
    });

    // Generate Lead Communication
    const commId = `COMM-${leadId}-01`;
    const commObj = {
      id: commId,
      leadId,
      type: i % 3 === 0 ? 'Call' : i % 3 === 1 ? 'WhatsApp' : 'Email',
      summary: `Discussed admission procedures for ${grade} with ${parentName}. Scheduled campus visit.`,
      by: 'Admissions Team',
      timestamp: createdAt,
      uid: 'admin-001',
      createdAt,
      updatedAt: leadObj.updatedAt,
    };

    commsToInsert.push({
      id: commObj.id,
      data: JSON.stringify(commObj),
      uid: commObj.uid,
      createdAt,
      updatedAt: commObj.updatedAt,
    });

    count++;
  }

  // Insert Leads into MySQL
  for (const item of leadsToInsert) {
    await conn.query(
      `INSERT INTO leads (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [item.id, item.data, item.uid, item.createdAt, item.updatedAt]
    );
  }

  console.log(`✅ Upserted ${leadsToInsert.length} admission leads across all 10 pipeline stages.`);

  // Insert Lead Documents
  for (const item of docsToInsert) {
    await conn.query(
      `INSERT INTO lead_documents (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [item.id, item.data, item.uid, item.createdAt, item.updatedAt]
    );
  }

  console.log(`✅ Upserted ${docsToInsert.length} lead document records.`);

  // Insert Lead Communications
  for (const item of commsToInsert) {
    await conn.query(
      `INSERT INTO lead_communications (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [item.id, item.data, item.uid, item.createdAt, item.updatedAt]
    );
  }

  console.log(`✅ Upserted ${commsToInsert.length} lead communication logs.`);

  // Insert Admissions Automation Rules
  const rules = [
    { id: 'RULE-01', trigger: 'Lead Created', action: 'Send Welcome Email & SMS', active: true, stage: 'Enquiry', uid: 'admin-001' },
    { id: 'RULE-02', trigger: 'Form Submitted', action: 'Schedule Entrance Exam', active: true, stage: 'Form Submitted', uid: 'admin-001' },
    { id: 'RULE-03', trigger: 'Doc Verification Approved', action: 'Generate School Fee Invoice', active: true, stage: 'Doc Verification', uid: 'admin-001' },
    { id: 'RULE-04', trigger: 'School Fee Paid', action: 'Auto-allocate Section & Student ID', active: true, stage: 'School Fee', uid: 'admin-001' },
  ];

  for (const rule of rules) {
    await conn.query(
      `INSERT INTO admissions_automation_rules (id, data, uid, createdAt, updatedAt)
       VALUES (?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE data = VALUES(data), updatedAt = VALUES(updatedAt)`,
      [rule.id, JSON.stringify(rule), rule.uid, now.toISOString(), now.toISOString()]
    );
  }

  console.log('✅ Upserted Admissions Automation Rules.');

  await conn.end();
}

seedAdmissions().catch(console.error);
