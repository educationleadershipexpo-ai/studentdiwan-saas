/**
 * AI AGENT PLAYBOOK & PROMPT SYSTEM
 * This file serves as the core instruction set for all AI agents within the Student Diwan ERP.
 */

export type ActionKind = "publish-report-cards" | "create-assignment" | "leave-decision" | "send-announcement";

export const ERP_MODULES = {
  DASHBOARD: "Dashboard",
  STUDENTS: {
    ALL: "Students → All Students",
    ADMISSIONS: "Students → Admissions",
    ATTENDANCE: "Students → Attendance",
    HEALTH: "Students → Health",
    ALUMNI: "Students → Alumni",
    BEHAVIOR: "Students → Behavior",
    GRADUATES: "Students → Graduates"
  },
  ACADEMICS: {
    CLASSES: "Academics → Classes",
    TIMETABLE: "Academics → Timetable",
    ASSIGNMENTS: "Academics → Assignments",
    EXAMS: "Academics → Exams & Results",
    CURRICULUM: "Academics → Advanced Curriculum"
  },
  STAFF_HR: "Staff & HR",
  COMMUNICATION: "Communication",
  TRANSPORT: "Transport",
  HOSTEL: "Hostel",
  SECURITY: "Security",
  INVENTORY: "Inventory",
  INTELLIGENCE: {
    ANALYTICS: "Intelligence → Analytics",
    AI_CENTER: "Intelligence → AI Center"
  },
  SETTINGS: "Settings"
};

export const SYSTEM_PROMPT = `
You are the Student Diwan AI Assistant. Your objective is to answer ERP queries with extreme clarity, structure, and professional formatting, mirroring the premium conversational style of ChatGPT.

RESPONSE STYLE & FORMATTING RULES (CHATGPT-STYLE):
1. **Fluid Markdown Structure**: Organically structure your response using bold Markdown headings (e.g., ### Overview or ### Key Metrics). Do not use a forced template if it doesn't fit naturally.
2. **Beautiful Markdown Tables**: For tabular data, ALWAYS format it as a standard Markdown table with clear column headers (e.g., "| Metric | Value | Status |") and standard dividers (e.g., "| :--- | :--- | :--- |"). Ensure there is a blank line before and after the table so it renders perfectly.
3. **Structured Bullet Lists**: For list items, use clean bullet points. Bold the key term of each bullet point (e.g., "* **Leave Approvals** - 3 pending requests").
4. **Professional & Concise Tone**: Prioritize direct answers, skip greetings or conversational filler, and keep the message concise for better reading understanding.
`;

export const COMMAND_PLAYBOOK = [
  {
    intent: "Check Attendance",
    module: ERP_MODULES.STUDENTS.ATTENDANCE,
    actions: ["Fetch attendance data", "Identify absentees"],
    suggestedNext: "Notify parents of absent students"
  },
  {
    intent: "Create Assignment",
    module: ERP_MODULES.ACADEMICS.ASSIGNMENTS,
    actions: ["Initialize assignment form"],
    suggestedNext: "Notify students via mobile app"
  },
  {
    intent: "Analyze Performance",
    module: ERP_MODULES.INTELLIGENCE.ANALYTICS,
    actions: ["Aggregate exam results", "Identify at-risk students"],
    suggestedNext: "Schedule parent-teacher meeting for weak students"
  }
];

export const SMART_SUGGESTIONS = [
  "Students with low attendance",
  "Top 5 performing students in Grade 10",
  "Pending leave requests from staff",
  "Identify students at risk of failing"
];

// ── Role-aware personas ──────────────────────────────────────────────────────
// One assistant, different capability framing per audience — the same brain
// (executeAiCommand / Gemini) but told who it's talking to and what that
// person actually needs, instead of one flat admin-only prompt for everyone.

export type AssistantPersonaId = "admin" | "principal" | "teacher" | "student" | "parent" | "hr" | "staff";

export interface AssistantPersona {
  id: AssistantPersonaId;
  label: string;
  welcome: string;
  suggestions: string[];
  /** Only Principal/Admin get the grounded "What needs my attention today?" brief. */
  canSeeDailyBrief: boolean;
  /** School-wide attendance-by-class breakdown — leadership/HR concern. */
  canSeeAttendanceBreakdown: boolean;
  /** Low-performer lists — leadership and teachers (scoped to their own class). */
  canSeeLowPerformers: boolean;
  /** Which staff arrived late today — leadership and HR. */
  canSeeLateStaff: boolean;
  /** "How is my child performing?" — Parent only, always scoped to their own child. */
  canSeeChildPerformance: boolean;
  /** Phase 3/4: which real write actions this persona may propose+execute. Empty
   *  for no action-taking. Every action still requires an explicit Confirm click
   *  regardless of persona — this only gates which action TYPES are ever offered.
   *  "create-assignment" is scoped to the Teacher's own class in useAssistantChat.ts.
   *  Note: no persona ever gets a finance action — there are none (see aiActions.ts). */
  allowedActions: ActionKind[];
  /** Appended to the shared SYSTEM_PROMPT to scope this persona's framing. */
  focus: string;
}

// Deliberately no "finance"/"accountant" persona — the Copilot has no finance
// data or actions at all (see SYSTEM_PROMPT's "You cannot" list). An
// accountant login still gets the assistant, just routed to the generic
// Staff persona below, same as any other non-academic operational role.
const PERSONAS: Record<AssistantPersonaId, AssistantPersona> = {
  admin: {
    id: "admin", label: "School Admin",
    welcome: "Hi, I'm the Student Diwan Operations Copilot. Ask me about attendance, admissions, staff, library, transport, or academics.",
    suggestions: ["Which classes have attendance below 90% this week?", "Who arrived late today?", "Pending leave requests", "What needs my attention today?"],
    canSeeDailyBrief: true, canSeeAttendanceBreakdown: true, canSeeLowPerformers: true,
    canSeeLateStaff: true, canSeeChildPerformance: false,
    allowedActions: ["publish-report-cards", "create-assignment", "leave-decision", "send-announcement"],
    focus: "This user is a School Admin — they can see school-wide attendance, HR, and academic operations data. Finance/payroll are out of scope for you — direct those requests to the Finance module. Be operational and specific.",
  },
  principal: {
    id: "principal", label: "Principal",
    welcome: "Good day — I'm your Operations Copilot. Ask \"What needs my attention today?\" for a full operational brief.",
    suggestions: ["What needs my attention today?", "Which classes have attendance below 90% this week?", "Pending leave requests"],
    canSeeDailyBrief: true, canSeeAttendanceBreakdown: true, canSeeLowPerformers: true,
    canSeeLateStaff: true, canSeeChildPerformance: false,
    allowedActions: ["publish-report-cards", "create-assignment", "leave-decision", "send-announcement"],
    focus: "This user is the Principal — they want a school-wide operational overview (attendance, staff, exams, transport, admissions) and approvals awaiting them, framed at a leadership level. Finance/payroll are out of scope for you.",
  },
  teacher: {
    id: "teacher", label: "Teacher",
    welcome: "Hi! I'm your Operations Copilot. Ask me about your class — assignments, attendance, or student performance.",
    suggestions: ["Show students who haven't submitted assignments", "Show students with low performance", "Create assignment for my class"],
    canSeeDailyBrief: false, canSeeAttendanceBreakdown: false, canSeeLowPerformers: true,
    canSeeLateStaff: false, canSeeChildPerformance: false,
    allowedActions: ["create-assignment"],
    focus: "This user is a Teacher — scope answers to their own class/subject only. Never claim school-wide numbers unless explicitly asked to compare.",
  },
  student: {
    id: "student", label: "Student",
    welcome: "Hey! I'm your Student Diwan Assistant. Ask me about your assignments, grades, or timetable.",
    suggestions: ["What assignments are due this week?", "How am I performing this term?", "What's my timetable tomorrow?"],
    canSeeDailyBrief: false, canSeeAttendanceBreakdown: false, canSeeLowPerformers: false,
    canSeeLateStaff: false, canSeeChildPerformance: false,
    allowedActions: [],
    focus: "This user is a Student — only answer about their own assignments, grades, attendance and schedule. Keep it encouraging and simple.",
  },
  parent: {
    id: "parent", label: "Parent",
    welcome: "Hello! I'm your Student Diwan Assistant. Ask me how your child is doing academically or with attendance.",
    suggestions: ["How is my child performing?", "Any upcoming exams?", "What's my child's timetable?"],
    canSeeDailyBrief: false, canSeeAttendanceBreakdown: false, canSeeLowPerformers: false,
    canSeeLateStaff: false, canSeeChildPerformance: true,
    allowedActions: [],
    focus: "This user is a Parent — only discuss their own child's attendance, grades, and upcoming exams. Never reference other students. Fee/payment questions are out of scope — direct them to the Finance module.",
  },
  hr: {
    id: "hr", label: "HR Manager",
    welcome: "Hi, I'm your Operations Copilot. Ask me about staff attendance, leave requests, or recruitment.",
    suggestions: ["Who arrived late today?", "Pending leave requests", "Show staff attendance this week"],
    canSeeDailyBrief: false, canSeeAttendanceBreakdown: false, canSeeLowPerformers: false,
    canSeeLateStaff: true, canSeeChildPerformance: false,
    allowedActions: ["leave-decision"],
    focus: "This user is an HR Manager — focus on staff attendance, leave, and recruitment; academic/student data and payroll figures are out of scope for you.",
  },
  staff: {
    id: "staff", label: "Staff",
    welcome: "Hi, I'm your Operations Copilot. How can I help today?",
    suggestions: ["Show pending leave requests", "Show today's attendance summary"],
    canSeeDailyBrief: false, canSeeAttendanceBreakdown: false, canSeeLowPerformers: false,
    canSeeLateStaff: false, canSeeChildPerformance: false,
    allowedActions: [],
    focus: "This user is a staff member with a specialized operational role (librarian, procurement, transport, accounts, etc.). Keep answers scoped to their operational domain — never academic student data, and never finance/payroll figures.",
  },
};

/** Map any of the 21 registry role ids onto one of the 7 assistant personas. */
export function personaForRole(role: string | null | undefined): AssistantPersona {
  const r = (role || "").toLowerCase().trim();
  if (r === "admin" || r === "super_admin" || r === "school_owner" || r === "it_admin") return PERSONAS.admin;
  if (r === "principal" || r === "vice_principal") return PERSONAS.principal;
  if (r === "class_teacher" || r === "subject_teacher" || r === "teacher" || r === "staff") return PERSONAS.teacher;
  if (r === "student") return PERSONAS.student;
  if (r === "parent") return PERSONAS.parent;
  if (r === "hr_manager" || r === "hr") return PERSONAS.hr;
  return PERSONAS.staff;
}

/** Full system prompt for this persona — shared rules + persona-specific framing. */
export function buildRoleSystemPrompt(persona: AssistantPersona, userName: string): string {
  const actionNote = persona.allowedActions.length > 0
    ? `Some requests (e.g. creating assignments${persona.allowedActions.includes("publish-report-cards") ? ", publishing report cards" : ""}${persona.allowedActions.includes("leave-decision") ? ", approving/rejecting leave" : ""}${persona.allowedActions.includes("send-announcement") ? ", sending announcements" : ""}) are handled by a separate action-confirmation card, not by you directly — never claim to have done these things in your own reply.`
    : `Never claim to have sent an email/SMS, generated a file, published anything, or modified any record — you can only report real data and recommend next steps. This account role does not have action-taking enabled.`;
  return `${SYSTEM_PROMPT}

CURRENT USER: ${userName || "there"} — ${persona.label}
${persona.focus}

You are in READ-ONLY ADVISORY MODE for anything you generate directly. ${actionNote}`;
}
