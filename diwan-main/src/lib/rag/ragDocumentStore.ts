// ── RAG Document Store & Index ─────────────────────────────────────────────
// Indexes comprehensive school policy documents, employee handbooks, fee rules,
// exam guidelines, user manuals, and government regulations.

export interface DocumentChunk {
  id: string;
  category: "School Policies" | "Employee Handbook" | "Admission Policy" | "Attendance Policy" | "Fee Policy" | "Exam Policy" | "User Manuals" | "Government Regulations" | "FAQs";
  title: string;
  content: string;
  tags: string[];
}

export const POLICY_DOCUMENTS: DocumentChunk[] = [
  {
    id: "doc-att-01",
    category: "Attendance Policy",
    title: "Student Attendance & Absence Regulations",
    content: "Students are required to maintain a minimum of 85% overall attendance each term to be eligible for final examinations. Absences exceeding 3 consecutive days require a valid medical certificate submitted to the school administration within 48 hours.",
    tags: ["attendance", "leave", "medical", "absent", "threshold"]
  },
  {
    id: "doc-fee-01",
    category: "Fee Policy",
    title: "Tuition & Outstanding Dues Payment Schedule",
    content: "Tuition fees are payable at the beginning of each academic term in three installments. Late payments after the 10th of the month incur a late fee penalty of OMR 15 per month. Official report cards and transcripts will be withheld for accounts with outstanding balances exceeding 60 days.",
    tags: ["fee", "tuition", "payment", "due", "penalty", "installment", "refund"]
  },
  {
    id: "doc-adm-01",
    category: "Admission Policy",
    title: "Student Admission & Transfer Procedures",
    content: "New admissions require submission of previous academic transcripts, birth certificate, civil ID copy, and health record forms. Admissions for Grade 1 through 12 require passing a placement assessment in English and Mathematics.",
    tags: ["admission", "apply", "enrollment", "transfer", "placement", "entrance"]
  },
  {
    id: "doc-exam-01",
    category: "Exam Policy",
    title: "Examinations, Grading & Report Cards",
    content: "Grades are computed based on 40% Continuous Assessment (quizzes, assignments, classwork) and 60% Final Term Examinations. Re-examinations are only permitted for documented medical emergencies approved by the Academic Council.",
    tags: ["exam", "examination", "grading", "marks", "report card", "re-test"]
  },
  {
    id: "doc-hr-01",
    category: "Employee Handbook",
    title: "Staff Work Hours & Leave Policy",
    content: "Full-time academic staff are entitled to 30 days of paid annual leave during official summer recess. Casual leave requests must be submitted at least 48 hours in advance via the ERP Staff Portal and approved by the Principal.",
    tags: ["staff", "teacher", "leave", "vacation", "work hours", "handbook", "hr"]
  },
  {
    id: "doc-faq-01",
    category: "FAQs",
    title: "Frequently Asked Questions — School Operations",
    content: "Q: How do parents apply for student leave?\nA: Parents must log in to the Parent Portal or send a request via the ERP mobile app under the Leave Requests section.\n\nQ: How are fee receipts generated?\nA: Receipts are auto-generated upon payment clearance and can be downloaded from Finance -> Receipts.",
    tags: ["faq", "question", "help", "receipt", "parent leave"]
  },
  {
    id: "doc-reg-01",
    category: "Government Regulations",
    title: "Ministry of Education Operational Compliance",
    content: "All accredited educational institutions must adhere to MoE guidelines regarding maximum student-to-teacher ratios (25:1), mandatory safety drills once per semester, and national curriculum standards for Social Studies and Arabic Language.",
    tags: ["government", "regulation", "ministry", "compliance", "ratio", "safety"]
  }
];
