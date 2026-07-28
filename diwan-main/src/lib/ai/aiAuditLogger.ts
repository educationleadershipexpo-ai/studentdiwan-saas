// ── Admin AI Audit Logger (Phase 8) ─────────────────────────────────────────
// Logs User ID, Admin ID, Prompt, Tool used, API called, Response time,
// Errors, and Timestamp for all Admin AI Assistant interactions.

import { logAudit } from "@/lib/auditLog";

export interface AIAuditEntry {
  userId: string;
  adminId: string;
  prompt: string;
  intentCategory: string;
  toolUsed?: string;
  apiCalled?: string;
  responseTimeMs: number;
  error?: string;
  timestamp: string;
}

const AUDIT_STORAGE_KEY = "diwan_admin_ai_audit_logs";

export function logAIAudit(entry: Omit<AIAuditEntry, "timestamp">): void {
  const fullEntry: AIAuditEntry = {
    ...entry,
    timestamp: new Date().toISOString(),
  };

  // 1. Console structured output
  console.log(`[AI AUDIT LOG] [${fullEntry.intentCategory}] Admin: ${fullEntry.adminId} | Tool: ${fullEntry.toolUsed || "None"} | API: ${fullEntry.apiCalled || "OpenRouter"} | Time: ${fullEntry.responseTimeMs}ms`);

  // 2. Local Storage Persistence
  try {
    const existingRaw = localStorage.getItem(AUDIT_STORAGE_KEY);
    const logs: AIAuditEntry[] = existingRaw ? JSON.parse(existingRaw) : [];
    logs.unshift(fullEntry);
    // Keep last 100 entries locally
    localStorage.setItem(AUDIT_STORAGE_KEY, JSON.stringify(logs.slice(0, 100)));
  } catch {
    // Ignore storage quota limits
  }

  // 3. Central ERP Audit Trail Dispatch
  logAudit(
    "AI_ASSISTANT_QUERY",
    "ai-copilot",
    `[${fullEntry.intentCategory}] Prompt: "${fullEntry.prompt.substring(0, 50)}..." | Tool: ${fullEntry.toolUsed || "None"} (${fullEntry.responseTimeMs}ms)`,
    fullEntry.adminId
  );
}

export function getAIAuditLogs(): AIAuditEntry[] {
  try {
    const raw = localStorage.getItem(AUDIT_STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}
