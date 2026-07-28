import { useEffect, useMemo, useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { useAuth } from "@/hooks/useAuth";
import { smartDb } from "@/lib/localDb";
import { MessageSquare, Users, ChevronDown, ChevronUp } from "lucide-react";
import { cn } from "@/lib/utils";

interface Participant { uid: string; name: string; role: string; email: string; }

interface ThreadRow {
  id: string;
  type: "direct" | "group";
  name: string;
  participants: Participant[];
  createdBy: string;
  createdAt: string;
  lastMessage?: string;
  lastMessageAt?: string;
  lastSenderUid?: string;
}

interface MessageRow {
  id: string;
  threadId: string;
  senderUid: string;
  senderName: string;
  text: string;
  createdAt: string;
}

interface ThreadStateRow {
  id: string;
  threadId: string;
  uid: string;
  archived?: boolean;
  lastReadAt?: string;
}

function initials(name: string) {
  return (name || "?").trim().split(/\s+/).map(w => w[0] || "").slice(0, 2).join("").toUpperCase();
}

function fmtTime(iso?: string) {
  if (!iso) return "";
  const d = new Date(iso);
  if (isNaN(d.getTime())) return "";
  const now = new Date();
  const diff = now.getTime() - d.getTime();
  if (diff < 60_000) return "Just now";
  if (diff < 3_600_000) return `${Math.floor(diff / 60_000)}m ago`;
  if (diff < 86_400_000) return d.toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" });
  if (diff < 7 * 86_400_000) return d.toLocaleDateString("en-GB", { weekday: "short" });
  return d.toLocaleDateString("en-GB", { day: "2-digit", month: "short" });
}

const AVATAR_COLORS = [
  ["#EDE9FE", "#7C3AED"], ["#FEE2E2", "#DC2626"], ["#FEF3C7", "#D97706"],
  ["#D1FAE5", "#059669"], ["#DBEAFE", "#2563EB"], ["#FCE7F3", "#DB2777"],
];

function avatarColor(name: string) {
  const idx = Math.abs([...name].reduce((h, c) => (h << 5) - h + c.charCodeAt(0), 0)) % AVATAR_COLORS.length;
  return AVATAR_COLORS[idx];
}

function ThreadCard({ thread, messages, uid }: { thread: ThreadRow; messages: MessageRow[]; uid: string }) {
  const [expanded, setExpanded] = useState(false);

  const threadMessages = useMemo(
    () => [...messages].filter(m => m.threadId === thread.id).sort((a, b) => a.createdAt.localeCompare(b.createdAt)),
    [messages, thread.id]
  );

  const otherParticipants = thread.participants.filter(p => p.uid !== uid);
  const displayName = thread.type === "group" ? thread.name : (otherParticipants[0]?.name ?? thread.name);
  const [bg, fg] = avatarColor(displayName);

  const lastMsg = thread.lastMessage ?? threadMessages[threadMessages.length - 1]?.text ?? "";
  const lastAt = thread.lastMessageAt ?? threadMessages[threadMessages.length - 1]?.createdAt;

  return (
    <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
      <button
        className="w-full text-left p-4 flex items-start gap-3 hover:bg-slate-50 transition-colors"
        onClick={() => setExpanded(e => !e)}
      >
        <div
          className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 text-sm font-bold"
          style={{ background: bg, color: fg }}
        >
          {thread.type === "group" ? <Users className="w-4 h-4" style={{ color: fg }} /> : initials(displayName)}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-semibold text-slate-800 truncate">{displayName}</p>
            <span className="text-[10px] text-slate-400 flex-shrink-0">{fmtTime(lastAt)}</span>
          </div>
          <p className="text-xs text-slate-500 mt-0.5 truncate">{lastMsg || "No messages yet"}</p>
          {thread.type === "group" && (
            <p className="text-[10px] text-slate-400 mt-0.5">
              {thread.participants.length} participant{thread.participants.length !== 1 ? "s" : ""}
            </p>
          )}
        </div>
        <div className="flex-shrink-0 text-slate-400 mt-1">
          {expanded ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
        </div>
      </button>

      {expanded && (
        <div className="border-t border-slate-100 px-4 pb-4 pt-3 space-y-3 max-h-72 overflow-y-auto">
          {threadMessages.length === 0 ? (
            <p className="text-xs text-slate-400 text-center py-4">No messages in this thread yet.</p>
          ) : (
            threadMessages.map(msg => {
              const isMine = msg.senderUid === uid;
              const [mbg, mfg] = avatarColor(msg.senderName);
              return (
                <div key={msg.id} className={cn("flex gap-2", isMine && "flex-row-reverse")}>
                  <div
                    className="w-6 h-6 rounded-full flex items-center justify-center flex-shrink-0 text-[9px] font-bold mt-0.5"
                    style={{ background: mbg, color: mfg }}
                  >
                    {initials(msg.senderName)}
                  </div>
                  <div className={cn("max-w-[75%]", isMine && "items-end flex flex-col")}>
                    <div
                      className={cn(
                        "px-3 py-2 rounded-xl text-xs leading-relaxed",
                        isMine
                          ? "bg-indigo-600 text-white rounded-tr-sm"
                          : "bg-slate-100 text-slate-700 rounded-tl-sm"
                      )}
                    >
                      {msg.text}
                    </div>
                    <p className="text-[10px] text-slate-400 mt-1 px-1">{fmtTime(msg.createdAt)}</p>
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}
    </div>
  );
}

export default function ParentMessages() {
  const { user } = useAuth();
  const uid = (user as any)?.uid ?? (user as any)?.id ?? "";

  const [threads, setThreads] = useState<ThreadRow[]>([]);
  const [messages, setMessages] = useState<MessageRow[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!uid) { setLoading(false); return; }
    Promise.all([
      smartDb.getAll("ChatThread").catch(() => []),
      smartDb.getAll("ChatMessage").catch(() => []),
      smartDb.getAll("ChatThreadState").catch(() => []),
    ]).then(([allThreads, allMessages]) => {
      const myThreads = ((allThreads || []) as ThreadRow[]).filter(t =>
        Array.isArray(t.participants) && t.participants.some(p => p.uid === uid)
      ).sort((a, b) => (b.lastMessageAt ?? b.createdAt ?? "").localeCompare(a.lastMessageAt ?? a.createdAt ?? ""));
      setThreads(myThreads);
      setMessages((allMessages || []) as MessageRow[]);
    }).finally(() => setLoading(false));
  }, [uid]);

  if (loading) {
    return <DashboardLayout><div className="p-6 text-center text-slate-400 text-sm">Loading messages…</div></DashboardLayout>;
  }

  return (
    <DashboardLayout>
      <div className="space-y-5">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-xl bg-indigo-100 flex items-center justify-center flex-shrink-0">
            <MessageSquare className="h-5 w-5 text-indigo-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Messages</h1>
            <p className="text-sm text-slate-400">Your conversations with teachers and school staff</p>
          </div>
        </div>

        {threads.length === 0 ? (
          <div className="bg-white rounded-2xl border border-dashed border-slate-300 p-12 text-center">
            <MessageSquare className="w-10 h-10 mx-auto mb-3 text-slate-300" />
            <h2 className="font-bold text-slate-700 text-base">No messages yet</h2>
            <p className="text-sm text-slate-400 mt-1">
              When teachers or staff message you, conversations will appear here.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {threads.map(t => (
              <ThreadCard key={t.id} thread={t} messages={messages} uid={uid} />
            ))}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
