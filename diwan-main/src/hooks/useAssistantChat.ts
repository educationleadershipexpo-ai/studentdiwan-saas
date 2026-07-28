import { useCallback, useState } from "react";
import { useAuth } from "@/hooks/useAuth";
import { executeAiCommand } from "@/services/geminiService";
import { personaForRole, buildRoleSystemPrompt } from "@/lib/aiPlaybook";
import { logAudit } from "@/lib/auditLog";
import { routeIntent } from "@/lib/mcp/intentRouter";
import { executeMCPTool } from "@/lib/mcp/mcpToolRegistry";
import { searchRAGDocuments, formatRAGContext } from "@/lib/rag/chromaAdapter";
import { aiCache } from "@/lib/ai/aiCache";
import { logAIAudit } from "@/lib/ai/aiAuditLogger";

export interface AssistantMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
}

export function useAssistantChat() {
  const { user, role } = useAuth();
  const persona = personaForRole(role);

  // Phase 5: Strictly restrict AI Assistant to Admin Users only
  const isAdmin = role === "admin";
  const [messages, setMessages] = useState<AssistantMessage[]>(() => [
    {
      id: "welcome",
      role: "assistant",
      content: isAdmin
        ? persona.welcome
        : "Access Denied: The Student Diwan AI Assistant is strictly restricted to School Administrators."
    },
  ]);
  const [isLoading, setIsLoading] = useState(false);

  const sendMessage = useCallback(async (text: string) => {
    const trimmed = text.trim();
    if (!trimmed) return;

    setMessages(prev => [...prev, { id: `u-${Date.now()}`, role: "user", content: trimmed }]);
    setIsLoading(true);

    // Enforce Admin Permission check
    if (!isAdmin) {
      setIsLoading(false);
      setMessages(prev => [...prev, {
        id: `a-${Date.now()}`,
        role: "assistant",
        content: "Access Denied: The Student Diwan AI Assistant is strictly restricted to School Administrators."
      }]);
      return;
    }

    const startTime = Date.now();
    let status: "success" | "error" = "success";
    let responseText = "";
    let toolUsed = "OpenRouter_General";
    let apiCalled = "openrouter/free";
    const systemPrompt = buildRoleSystemPrompt(persona, user?.displayName || "Admin");

    // Phase 7: Performance Caching Check
    const cachedResponse = aiCache.get<string>(`query_${trimmed}`);
    if (cachedResponse) {
      setIsLoading(false);
      setMessages(prev => [...prev, { id: `a-${Date.now()}`, role: "assistant", content: cachedResponse }]);
      logAIAudit({
        userId: user?.uid || "admin",
        adminId: user?.email || "admin@eduerp.com",
        prompt: trimmed,
        intentCategory: "CACHED",
        toolUsed: "AICache",
        apiCalled: "aiCache.get",
        responseTimeMs: Date.now() - startTime,
      });
      return;
    }

    try {
      // Phase 4: Intent Classification via Intent Router
      const route = routeIntent(trimmed);

      if (route.category === "DOCUMENT_SEARCH") {
        // Phase 3: RAG Document Retrieval (ChromaDB / Vector Fallback)
        toolUsed = "RAG_ChromaDB";
        apiCalled = "searchRAGDocuments";

        const docs = await searchRAGDocuments(trimmed, 3);
        const docsContext = formatRAGContext(docs);

        const aiResponse = await executeAiCommand(
          `Answer the query based strictly on the provided school handbook and policy documents. Be highly accurate and reference chapters if applicable.`,
          systemPrompt,
          docsContext
        );
        responseText = `📚 **[School Documents & Policies via RAG]**\n\n${aiResponse}`;

      } else if (route.category === "LIVE_ERP_DATA" || route.category === "ERP_ACTION") {
        // Phase 2: Internal MCP Tool Layer
        const queryLower = trimmed.toLowerCase();
        let targetTool = "mcp_dashboard_getStats";
        const mcpParams: Record<string, any> = {};

        // Extract requested timeframe
        if (queryLower.includes("this week") || queryLower.includes("weekly")) {
          mcpParams.timeframe = "this_week";
        } else if (queryLower.includes("this month") || queryLower.includes("monthly")) {
          mcpParams.timeframe = "this_month";
        } else if (queryLower.includes("today") || queryLower.includes("daily")) {
          mcpParams.timeframe = "today";
        } else if (queryLower.includes("this year") || queryLower.includes("annual")) {
          mcpParams.timeframe = "this_year";
        }

        // Extract percentage threshold (e.g., "below 90%")
        const numMatch = queryLower.match(/(?:below|under|less than|<)\s*(\d{1,3})%?/);
        if (numMatch) {
          mcpParams.threshold = parseInt(numMatch[1], 10);
        }

        if (queryLower.includes("attendance") || queryLower.includes("absent") || queryLower.includes("present")) {
          targetTool = "mcp_attendance_getDailySummary";
        } else if (queryLower.includes("fee") || queryLower.includes("due") || queryLower.includes("outstanding") || queryLower.includes("payment")) {
          targetTool = "mcp_fees_getCollectionSummary";
        } else if (queryLower.includes("admission") || queryLower.includes("applicant")) {
          targetTool = "mcp_admissions_getStats";
        } else if (queryLower.includes("exam") || queryLower.includes("test")) {
          targetTool = "mcp_exams_getUpcoming";
        } else if (queryLower.includes("teacher") || queryLower.includes("faculty")) {
          targetTool = "mcp_teachers_list";
        } else if (queryLower.includes("staff") || queryLower.includes("late")) {
          targetTool = "mcp_staff_getLateToday";
        } else if (queryLower.includes("student") || queryLower.includes("inactive")) {
          targetTool = "mcp_students_list";
        } else if (queryLower.includes("class") || queryLower.includes("section")) {
          targetTool = "mcp_classes_list";
        } else if (queryLower.includes("finance") || queryLower.includes("expense") || queryLower.includes("budget")) {
          targetTool = "mcp_finance_getOverview";
        } else if (queryLower.includes("transport") || queryLower.includes("bus")) {
          targetTool = "mcp_transport_getStatus";
        } else if (queryLower.includes("hostel") || queryLower.includes("room")) {
          targetTool = "mcp_hostel_getOccupancy";
        } else if (queryLower.includes("library") || queryLower.includes("book")) {
          targetTool = "mcp_library_getSummary";
        } else if (queryLower.includes("inventory") || queryLower.includes("stock")) {
          targetTool = "mcp_inventory_getStock";
        } else if (queryLower.includes("event") || queryLower.includes("calendar")) {
          targetTool = "mcp_events_list";
        }

        toolUsed = targetTool;
        const toolRes = await executeMCPTool(targetTool, mcpParams, { userId: user?.uid || "admin", role: "admin" });
        apiCalled = toolRes.apiCalled;

        const aiResponse = await executeAiCommand(
          `Format the retrieved MCP JSON payload into a strict ERP Copilot response for the query "${trimmed}". Do not invent numbers or operational advice. Include Summary, Table, and Available Actions.`,
          systemPrompt,
          JSON.stringify(toolRes.data)
        );
        responseText = aiResponse;
      } else {
        // Phase 1: General AI via OpenRouter
        toolUsed = "OpenRouter_General";
        apiCalled = "openrouter/free";

        const aiResponse = await executeAiCommand(trimmed, systemPrompt);
        responseText = aiResponse;
      }
    } catch (err) {
      console.error("Assistant execution error:", err);
      status = "error";
      responseText = "An error occurred while processing your request. Please try again.";
    } finally {
      setIsLoading(false);
    }

    if (status === "success") {
      aiCache.set(`query_${trimmed}`, responseText);
    }

    const messageId = `a-${Date.now()}`;
    setMessages(prev => [...prev, { id: messageId, role: "assistant", content: responseText }]);

    // Phase 8: Logging and Auditing
    void logAudit({
      user_id: user?.uid || "admin",
      user_name: user?.displayName || user?.email || "Admin",
      role: role || "admin",
      module: "admin-ai-assistant",
      action: "ai_query",
      entity: "AssistantMessage",
      status,
    });

    logAIAudit({
      userId: user?.uid || "admin",
      adminId: user?.email || "admin@eduerp.com",
      prompt: trimmed,
      intentCategory: routeIntent(trimmed).category,
      toolUsed,
      apiCalled,
      responseTimeMs: Date.now() - startTime,
      error: status === "error" ? "Execution failed" : undefined,
    });
  }, [user, role, persona, isAdmin]);

  return { messages, sendMessage, isLoading, persona };
}
