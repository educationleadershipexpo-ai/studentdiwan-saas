// ── Admin AI Intent Router ──────────────────────────────────────────────────
// Classifies user queries into 4 explicit intent categories:
// 1. GENERAL_AI      → OpenRouter (writing, grammar, translation, general Q&A)
// 2. LIVE_ERP_DATA  → Internal MCP Tool Dispatcher (attendance, fees, timetable, stats)
// 3. ERP_ACTION     → Internal MCP Action Stager (create announcements, publish report cards)
// 4. DOCUMENT_SEARCH → RAG Engine (school policies, handbooks, regulations, FAQs)

export type IntentCategory = "GENERAL_AI" | "LIVE_ERP_DATA" | "ERP_ACTION" | "DOCUMENT_SEARCH";

export interface IntentRouteResult {
  category: IntentCategory;
  confidence: number;
  matchedKeywords: string[];
  suggestedTool?: string;
  reasoning: string;
}

const DOCUMENT_SEARCH_KEYWORDS = [
  "policy", "policies", "rule", "rules", "handbook", "guideline", "guidelines",
  "manual", "regulation", "regulations", "faq", "faqs", "procedure", "procedures",
  "leave policy", "grading system", "admission policy", "fee policy", "exam policy",
  "employee handbook", "government rules", "code of conduct", "how do i apply", "what is the policy"
];

const ERP_ACTION_KEYWORDS = [
  "publish report card", "publish report cards", "issue report card",
  "create assignment", "add assignment", "give homework",
  "approve leave", "reject leave", "process leave",
  "send announcement", "create announcement", "publish notice", "broadcast notice",
  "draft circular", "send notification", "notify parents"
];

const LIVE_ERP_DATA_KEYWORDS = [
  "attendance", "absent", "present", "late staff", "attendance summary",
  "fee", "fees", "fee collection", "outstanding", "dues", "payment",
  "student", "students", "inactive students", "admission stats", "enrollment",
  "teacher", "teachers", "staff", "timetable", "schedule", "class", "section",
  "exam", "exams", "examination", "upcoming exams", "gradebook", "marks",
  "finance", "expense", "budget", "transport", "bus", "hostel", "room",
  "library", "inventory", "stock", "daily brief", "dashboard summary", "analytics"
];

export function routeIntent(query: string): IntentRouteResult {
  const normalized = query.toLowerCase().trim();

  // Check 1: Document / RAG Search
  const docMatches = DOCUMENT_SEARCH_KEYWORDS.filter(k => normalized.includes(k));
  if (docMatches.length > 0) {
    return {
      category: "DOCUMENT_SEARCH",
      confidence: 0.95,
      matchedKeywords: docMatches,
      reasoning: `Query matched document/RAG keywords: ${docMatches.join(", ")}`
    };
  }

  // Check 2: ERP Action Intent
  const actionMatches = ERP_ACTION_KEYWORDS.filter(k => normalized.includes(k));
  if (actionMatches.length > 0) {
    return {
      category: "ERP_ACTION",
      confidence: 0.92,
      matchedKeywords: actionMatches,
      reasoning: `Query matched ERP action keywords: ${actionMatches.join(", ")}`
    };
  }

  // Check 3: Live ERP Data Intent
  const dataMatches = LIVE_ERP_DATA_KEYWORDS.filter(k => normalized.includes(k));
  if (dataMatches.length > 0) {
    return {
      category: "LIVE_ERP_DATA",
      confidence: 0.90,
      matchedKeywords: dataMatches,
      reasoning: `Query matched live ERP data keywords: ${dataMatches.join(", ")}`
    };
  }

  // Fallback: General AI
  return {
    category: "GENERAL_AI",
    confidence: 0.85,
    matchedKeywords: [],
    reasoning: "Query does not require live ERP data or policy docs; routing to General AI."
  };
}
