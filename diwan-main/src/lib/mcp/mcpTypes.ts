// ── MCP (Model Context Protocol) Type Definitions ───────────────────────────

export type MCPCategory = 
  | "Dashboard" | "Students" | "Admissions" | "Attendance"
  | "Teachers" | "Staff" | "Classes" | "Sections" | "Subjects"
  | "Timetable" | "Exams" | "Gradebook" | "Fees" | "Finance"
  | "Transport" | "Hostel" | "Library" | "Inventory"
  | "Notifications" | "Events" | "Reports" | "Analytics";

export interface MCPUserContext {
  userId: string;
  role: "admin" | "teacher" | "student" | "parent" | "staff";
  scope?: {
    grade?: string;
    section?: string;
    childId?: string;
  };
}

export interface MCPToolResult {
  success: boolean;
  toolName: string;
  summary: string;
  data: any;
  apiCalled: string;
  error?: string;
}

export interface MCPTool<TParams = Record<string, any>> {
  name: string;
  description: string;
  category: MCPCategory;
  execute: (params: TParams, context: MCPUserContext) => Promise<MCPToolResult>;
}
