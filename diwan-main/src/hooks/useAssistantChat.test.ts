import { describe, it, expect, beforeEach, vi } from "vitest";
import { renderHook, act, waitFor } from "@testing-library/react";

// ── Mock every external boundary useAssistantChat.ts touches ────────────────
vi.mock("@/hooks/useAuth", () => ({ useAuth: vi.fn() }));
vi.mock("@/hooks/useTeacherClass", () => ({ useTeacherClass: vi.fn() }));
vi.mock("@/hooks/useParentChildren", () => ({ useParentChildren: vi.fn() }));
vi.mock("@/contexts/LeaveContext", () => ({ useLeave: vi.fn() }));
vi.mock("@/contexts/NoticeContext", () => ({ useNotices: vi.fn() }));
vi.mock("@/services/geminiService", () => ({
  executeAiCommand: vi.fn(),
  routeAiQuery: vi.fn(() => Promise.resolve("LLM")),
  identifyRequiredTables: vi.fn(() => Promise.resolve([])),
  searchUserGuides: vi.fn(() => "mock-guides-context"),
}));
vi.mock("@/lib/aiCopilot", () => ({
  isDailyBriefIntent: vi.fn(() => false),
  fetchDailyBrief: vi.fn(),
  formatDailyBriefContext: vi.fn(() => "daily-brief-context"),
  isLowAttendanceIntent: vi.fn(() => false),
  parseAttendanceThreshold: vi.fn(() => 90),
  fetchLowAttendanceClasses: vi.fn(),
  formatLowAttendanceContext: vi.fn(() => "attendance-context"),
  isLowPerformersIntent: vi.fn(() => false),
  parsePerformanceThreshold: vi.fn(() => 50),
  fetchLowPerformers: vi.fn(),
  formatLowPerformersContext: vi.fn(() => "low-performers-context"),
  isLateStaffIntent: vi.fn(() => false),
  fetchLateStaffToday: vi.fn(),
  formatLateStaffContext: vi.fn(() => "late-staff-context"),
  isChildPerformanceIntent: vi.fn(() => false),
  fetchChildPerformance: vi.fn(),
  formatChildPerformanceContext: vi.fn(() => "child-perf-context"),
}));
vi.mock("@/lib/aiActions", () => ({
  isPublishReportCardsActionIntent: vi.fn(() => false),
  buildPublishReportCardsProposal: vi.fn(),
  isCreateAssignmentActionIntent: vi.fn(() => false),
  buildCreateAssignmentProposal: vi.fn(),
  isLeaveActionIntent: vi.fn(() => false),
  buildLeaveActionProposal: vi.fn(),
  isSendAnnouncementActionIntent: vi.fn(() => false),
  buildSendAnnouncementProposal: vi.fn(),
}));
vi.mock("@/lib/auditLog", () => ({ logAudit: vi.fn().mockResolvedValue(undefined) }));

import { useAuth } from "@/hooks/useAuth";
import { useTeacherClass } from "@/hooks/useTeacherClass";
import { useParentChildren } from "@/hooks/useParentChildren";
import { useLeave } from "@/contexts/LeaveContext";
import { useNotices } from "@/contexts/NoticeContext";
import {
  executeAiCommand,
  routeAiQuery,
  identifyRequiredTables,
  searchUserGuides,
} from "@/services/geminiService";
import {
  isDailyBriefIntent, fetchDailyBrief,
  isLowAttendanceIntent,
  isLowPerformersIntent, fetchLowPerformers,
  isLateStaffIntent,
  isChildPerformanceIntent, fetchChildPerformance,
} from "@/lib/aiCopilot";
import {
  isPublishReportCardsActionIntent, buildPublishReportCardsProposal,
  isCreateAssignmentActionIntent, buildCreateAssignmentProposal,
  isLeaveActionIntent, buildLeaveActionProposal,
  isSendAnnouncementActionIntent, buildSendAnnouncementProposal,
} from "@/lib/aiActions";
import { logAudit } from "@/lib/auditLog";
import { useAssistantChat } from "./useAssistantChat";

const mockedUseAuth = vi.mocked(useAuth);
const mockedUseTeacherClass = vi.mocked(useTeacherClass);
const mockedUseParentChildren = vi.mocked(useParentChildren);
const mockedUseLeave = vi.mocked(useLeave);
const mockedUseNotices = vi.mocked(useNotices);
const mockedExecuteAiCommand = vi.mocked(executeAiCommand);
const mockedRouteAiQuery = vi.mocked(routeAiQuery);
const mockedIdentifyRequiredTables = vi.mocked(identifyRequiredTables);
const mockedSearchUserGuides = vi.mocked(searchUserGuides);

function setAuth(role: string, overrides: Partial<{ uid: string; displayName: string; email: string }> = {}) {
  mockedUseAuth.mockReturnValue({
    user: { uid: "u1", displayName: "Jane Doe", email: "jane@school.test", ...overrides },
    role,
  } as any);
}

beforeEach(() => {
  vi.clearAllMocks();

  setAuth("admin");
  mockedUseTeacherClass.mockReturnValue({
    assignment: { grade: "Grade 5", section: "B", classId: "c1", className: "Grade 5 Section B", room: "205", subject: "Math", teacherName: "Mr. X" },
  } as any);
  mockedUseParentChildren.mockReturnValue({ selected: null } as any);
  mockedUseLeave.mockReturnValue({ leaves: [], approveLeaveStep: vi.fn(), rejectLeave: vi.fn() } as any);
  mockedUseNotices.mockReturnValue({ addNotice: vi.fn() } as any);

  mockedExecuteAiCommand.mockResolvedValue("A plain Gemini answer.");
  mockedRouteAiQuery.mockResolvedValue("LLM");
  mockedIdentifyRequiredTables.mockResolvedValue([]);
  mockedSearchUserGuides.mockReturnValue("mock-guides-context");

  // aiCopilot intent detectors default to false
  vi.mocked(isDailyBriefIntent).mockReturnValue(false);
  vi.mocked(isLowAttendanceIntent).mockReturnValue(false);
  vi.mocked(isLowPerformersIntent).mockReturnValue(false);
  vi.mocked(isLateStaffIntent).mockReturnValue(false);
  vi.mocked(isChildPerformanceIntent).mockReturnValue(false);
  vi.mocked(isPublishReportCardsActionIntent).mockReturnValue(false);
  vi.mocked(isCreateAssignmentActionIntent).mockReturnValue(false);
  vi.mocked(isLeaveActionIntent).mockReturnValue(false);
  vi.mocked(isSendAnnouncementActionIntent).mockReturnValue(false);
});

describe("useAssistantChat", () => {
  it("seeds the message list with the persona-specific welcome message on mount for admin", () => {
    setAuth("admin");
    const { result } = renderHook(() => useAssistantChat());
    expect(result.current.messages).toHaveLength(1);
    expect(result.current.messages[0]).toMatchObject({ id: "welcome", role: "assistant" });
    expect(result.current.messages[0].content).toMatch(/Operations Copilot/);
    expect(result.current.persona.id).toBe("admin");
    expect(result.current.isLoading).toBe(false);
  });

  it("blocks student welcome message and returns Access Denied on mount", () => {
    setAuth("student");
    const { result } = renderHook(() => useAssistantChat());
    expect(result.current.persona.id).toBe("student");
    expect(result.current.messages[0].content).toMatch(/Access Denied/);
  });

  it("sends a plain query through executeAiCommand and appends user + assistant messages with route tracer for LLM", async () => {
    mockedRouteAiQuery.mockResolvedValue("LLM");
    const { result } = renderHook(() => useAssistantChat());

    await act(async () => {
      await result.current.sendMessage("What's the weather like?");
    });

    expect(mockedExecuteAiCommand).toHaveBeenCalledWith("What's the weather like?", expect.any(String));
    expect(result.current.messages).toHaveLength(3); // welcome + user + assistant
    expect(result.current.messages[1]).toMatchObject({ role: "user", content: "What's the weather like?" });
    expect(result.current.messages[2]).toMatchObject({ role: "assistant", content: "🤖 **[General Question via LLM]**\n\nA plain Gemini answer." });
    expect(result.current.isLoading).toBe(false);

    expect(logAudit).toHaveBeenCalledWith(expect.objectContaining({
      module: "ai-assistant", action: "chat_query", status: "success", entity: "AssistantMessage",
    }));
  });

  it("ignores whitespace-only input and does not touch route classifier or command execution", async () => {
    const { result } = renderHook(() => useAssistantChat());
    await act(async () => {
      await result.current.sendMessage("   ");
    });
    expect(mockedRouteAiQuery).not.toHaveBeenCalled();
    expect(mockedExecuteAiCommand).not.toHaveBeenCalled();
    expect(result.current.messages).toHaveLength(1);
  });

  it("routes a daily-brief intent through fetchDailyBrief + formatDailyBriefContext under MCP for admin", async () => {
    setAuth("admin");
    mockedRouteAiQuery.mockResolvedValue("MCP");
    vi.mocked(isDailyBriefIntent).mockReturnValue(true);
    vi.mocked(fetchDailyBrief).mockResolvedValue({} as any);

    const { result } = renderHook(() => useAssistantChat());
    await act(async () => {
      await result.current.sendMessage("What needs my attention today?");
    });

    expect(fetchDailyBrief).toHaveBeenCalled();
    expect(mockedExecuteAiCommand).toHaveBeenCalledWith(
      expect.stringMatching(/daily brief/i),
      expect.any(String),
      "daily-brief-context",
    );
    expect(result.current.messages[2].content).toMatch(/Live ERP Data via MCP/);
    expect(logAudit).toHaveBeenCalledWith(expect.objectContaining({ action: "daily_brief_query" }));
  });

  it("blocks non-admin message sending and returns Access Denied", async () => {
    setAuth("teacher");
    const { result } = renderHook(() => useAssistantChat());
    await act(async () => {
      await result.current.sendMessage("Show my timetable");
    });

    expect(mockedRouteAiQuery).not.toHaveBeenCalled();
    expect(mockedExecuteAiCommand).not.toHaveBeenCalled();
    expect(result.current.messages[result.current.messages.length - 1].content).toMatch(/Access Denied/);
  });

  it("routes RAG queries through user guide doc search", async () => {
    setAuth("admin");
    mockedRouteAiQuery.mockResolvedValue("RAG");

    const { result } = renderHook(() => useAssistantChat());
    await act(async () => {
      await result.current.sendMessage("What is the leave policy?");
    });

    expect(mockedSearchUserGuides).toHaveBeenCalledWith("What is the leave policy?");
    expect(mockedExecuteAiCommand).toHaveBeenCalledWith(
      expect.stringMatching(/strictly on the provided school handbook/i),
      expect.any(String),
      "mock-guides-context"
    );
    expect(result.current.messages[2].content).toMatch(/School Documents & Policies via RAG/);
  });

  it("builds an action proposal (publish report cards) under MCP for admin, without executing the write", async () => {
    setAuth("admin");
    mockedRouteAiQuery.mockResolvedValue("MCP");
    vi.mocked(isPublishReportCardsActionIntent).mockReturnValue(true);
    const proposal = { kind: "publish-report-cards", description: "Publish 30 report cards for Grade 5", run: vi.fn() };
    vi.mocked(buildPublishReportCardsProposal).mockResolvedValue(proposal as any);

    const { result } = renderHook(() => useAssistantChat());
    await act(async () => {
      await result.current.sendMessage("Publish report cards for Grade 5");
    });

    const last = result.current.messages[result.current.messages.length - 1];
    expect(last.action).toMatchObject({ status: "pending", proposal });
    expect(last.content).toMatch(/Live ERP Data via MCP/);
    expect(last.content).toMatch(/Review the details below/);
    expect(proposal.run).not.toHaveBeenCalled();
  });

  it("surfaces a proposal-builder error as plain text with no pending action under MCP", async () => {
    setAuth("admin");
    mockedRouteAiQuery.mockResolvedValue("MCP");
    vi.mocked(isPublishReportCardsActionIntent).mockReturnValue(true);
    vi.mocked(buildPublishReportCardsProposal).mockResolvedValue({ error: "No unpublished report cards found." } as any);

    const { result } = renderHook(() => useAssistantChat());
    await act(async () => {
      await result.current.sendMessage("Publish report cards");
    });

    const last = result.current.messages[result.current.messages.length - 1];
    expect(last.content).toBe("No unpublished report cards found.");
    expect(last.action).toBeUndefined();
  });

  it("does not scope create-assignment for a non-teacher persona (e.g. admin)", async () => {
    setAuth("admin");
    mockedRouteAiQuery.mockResolvedValue("MCP");
    vi.mocked(isCreateAssignmentActionIntent).mockReturnValue(true);
    vi.mocked(buildCreateAssignmentProposal).mockResolvedValue({ kind: "create-assignment", description: "desc", run: vi.fn() } as any);

    const { result } = renderHook(() => useAssistantChat());
    await act(async () => {
      await result.current.sendMessage("Create an assignment for Grade 9 Section Z");
    });

    expect(buildCreateAssignmentProposal).toHaveBeenCalledWith(
      "Create an assignment for Grade 9 Section Z", "u1", undefined,
    );
  });

  it("sets an error status and friendly message when executeAiCommand throws", async () => {
    mockedExecuteAiCommand.mockRejectedValue(new Error("Gemini is down"));
    const { result } = renderHook(() => useAssistantChat());

    await act(async () => {
      await result.current.sendMessage("Tell me something");
    });

    const last = result.current.messages[result.current.messages.length - 1];
    expect(last.content).toMatch(/ran into a problem/);
    expect(logAudit).toHaveBeenCalledWith(expect.objectContaining({ status: "error" }));
  });

  it("marks the audit status as error when executeAiCommand resolves with an in-band failure string", async () => {
    mockedExecuteAiCommand.mockResolvedValue("I encountered an error while processing your request.");
    const { result } = renderHook(() => useAssistantChat());

    await act(async () => {
      await result.current.sendMessage("Tell me something");
    });

    expect(logAudit).toHaveBeenCalledWith(expect.objectContaining({ status: "error", action: "chat_query" }));
  });

  it("toggles isLoading around the async round trip", async () => {
    let resolveFn: (v: string) => void;
    mockedExecuteAiCommand.mockReturnValue(new Promise(res => { resolveFn = res; }));
    const { result } = renderHook(() => useAssistantChat());

    act(() => {
      void result.current.sendMessage("Hello");
    });

    await waitFor(() => expect(result.current.isLoading).toBe(true));

    await act(async () => {
      resolveFn!("done");
      await Promise.resolve();
    });

    await waitFor(() => expect(result.current.isLoading).toBe(false));
  });

  describe("confirmAction", () => {
    it("runs the proposal, marks the message confirmed, and logs a success audit entry", async () => {
      setAuth("admin");
      mockedRouteAiQuery.mockResolvedValue("MCP");
      vi.mocked(isPublishReportCardsActionIntent).mockReturnValue(true);
      const run = vi.fn().mockResolvedValue({ success: true, message: "Published 12 report cards." });
      vi.mocked(buildPublishReportCardsProposal).mockResolvedValue({ kind: "publish-report-cards", description: "desc", run } as any);

      const { result } = renderHook(() => useAssistantChat());
      await act(async () => {
        await result.current.sendMessage("Publish report cards");
      });
      const messageId = result.current.messages[result.current.messages.length - 1].id;

      await act(async () => {
        await result.current.confirmAction(messageId);
      });

      expect(run).toHaveBeenCalled();
      const msg = result.current.messages.find(m => m.id === messageId)!;
      expect(msg.action).toMatchObject({ status: "confirmed", resultMessage: "Published 12 report cards." });
      expect(logAudit).toHaveBeenCalledWith(expect.objectContaining({
        action: "publish_report_cards_executed", status: "success",
      }));
    });

    it("captures a thrown execution error into a safe fallback resultMessage and logs status error", async () => {
      setAuth("admin");
      mockedRouteAiQuery.mockResolvedValue("MCP");
      vi.mocked(isPublishReportCardsActionIntent).mockReturnValue(true);
      const run = vi.fn().mockRejectedValue(new Error("DB write failed"));
      vi.mocked(buildPublishReportCardsProposal).mockResolvedValue({ kind: "publish-report-cards", description: "desc", run } as any);

      const { result } = renderHook(() => useAssistantChat());
      await act(async () => {
        await result.current.sendMessage("Publish report cards");
      });
      const messageId = result.current.messages[result.current.messages.length - 1].id;

      await act(async () => {
        await result.current.confirmAction(messageId);
      });

      const msg = result.current.messages.find(m => m.id === messageId)!;
      expect(msg.action?.status).toBe("confirmed");
      expect(msg.action?.resultMessage).toMatch(/no changes may have been fully applied/);
      expect(logAudit).toHaveBeenCalledWith(expect.objectContaining({
        action: "publish_report_cards_executed", status: "error",
      }));
    });
  });

  describe("cancelAction", () => {
    it("marks a pending action cancelled and logs a success audit entry without running the proposal", async () => {
      setAuth("admin");
      mockedRouteAiQuery.mockResolvedValue("MCP");
      vi.mocked(isPublishReportCardsActionIntent).mockReturnValue(true);
      const run = vi.fn();
      vi.mocked(buildPublishReportCardsProposal).mockResolvedValue({ kind: "publish-report-cards", description: "desc", run } as any);

      const { result } = renderHook(() => useAssistantChat());
      await act(async () => {
        await result.current.sendMessage("Publish report cards");
      });
      const messageId = result.current.messages[result.current.messages.length - 1].id;

      act(() => {
        result.current.cancelAction(messageId);
      });

      expect(run).not.toHaveBeenCalled();
      const msg = result.current.messages.find(m => m.id === messageId)!;
      expect(msg.action?.status).toBe("cancelled");
      expect(logAudit).toHaveBeenCalledWith(expect.objectContaining({
        action: "publish_report_cards_cancelled", status: "success",
      }));
    });
  });
});
