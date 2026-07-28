import { useMemo, useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { useAuth } from "@/hooks/useAuth";
import { useNotices } from "@/contexts/NoticeContext";
import { useParentChildren } from "@/hooks/useParentChildren";
import { filterAnnouncementsForViewer, ViewerClass } from "@/lib/announcementAudience";
import { Megaphone, ChevronDown, ChevronUp, Calendar, User, Search } from "lucide-react";
import { cn } from "@/lib/utils";

const PRIORITY_CONFIG: Record<string, { label: string; bg: string; text: string }> = {
  urgent:  { label: "Urgent",  bg: "bg-rose-50",   text: "text-rose-600"   },
  high:    { label: "High",    bg: "bg-orange-50",  text: "text-orange-600" },
  normal:  { label: "Normal",  bg: "bg-blue-50",    text: "text-blue-600"   },
  low:     { label: "Low",     bg: "bg-slate-100",  text: "text-slate-500"  },
};

function fmtDate(iso?: string | null) {
  if (!iso) return "";
  const d = new Date(iso);
  if (isNaN(d.getTime())) return "";
  return d.toLocaleDateString("en-GB", { day: "2-digit", month: "short", year: "numeric" });
}

function AnnouncementCard({ notice }: { notice: any }) {
  const [expanded, setExpanded] = useState(false);
  const priority = (notice.priority ?? "normal").toLowerCase();
  const cfg = PRIORITY_CONFIG[priority] ?? PRIORITY_CONFIG.normal;

  return (
    <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden">
      <button
        className="w-full text-left p-4 hover:bg-slate-50 transition-colors"
        onClick={() => setExpanded(e => !e)}
      >
        <div className="flex items-start gap-3">
          <div className="w-9 h-9 rounded-xl bg-amber-50 flex items-center justify-center flex-shrink-0 mt-0.5">
            <Megaphone className="w-4 h-4 text-amber-600" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-start justify-between gap-2">
              <p className="text-sm font-semibold text-slate-800 leading-snug">{notice.title}</p>
              <div className="flex items-center gap-1.5 flex-shrink-0">
                <span className={cn("text-[10px] font-semibold px-2 py-0.5 rounded-md", cfg.bg, cfg.text)}>
                  {cfg.label}
                </span>
                {expanded ? <ChevronUp className="w-4 h-4 text-slate-400" /> : <ChevronDown className="w-4 h-4 text-slate-400" />}
              </div>
            </div>
            <div className="flex items-center gap-3 mt-1.5 flex-wrap">
              {notice.author && (
                <span className="flex items-center gap-1 text-[11px] text-slate-400">
                  <User className="w-3 h-3" />{notice.author}
                </span>
              )}
              {(notice.publishedAt ?? notice.createdAt) && (
                <span className="flex items-center gap-1 text-[11px] text-slate-400">
                  <Calendar className="w-3 h-3" />{fmtDate(notice.publishedAt ?? notice.createdAt)}
                </span>
              )}
              {notice.category && (
                <span className="text-[10px] font-medium px-1.5 py-0.5 rounded bg-slate-100 text-slate-500">
                  {notice.category}
                </span>
              )}
            </div>
          </div>
        </div>
      </button>

      {expanded && (
        <div className="border-t border-slate-100 px-4 pb-4 pt-3">
          <p className="text-sm text-slate-600 leading-relaxed whitespace-pre-wrap">
            {notice.content ?? notice.body ?? "No content available."}
          </p>
        </div>
      )}
    </div>
  );
}

export default function ParentAnnouncements() {
  const { user } = useAuth();
  const { selected } = useParentChildren();
  const { notices, loading } = useNotices();
  const [search, setSearch] = useState("");

  const viewerClass: ViewerClass | undefined = useMemo(() => {
    if (!selected) return undefined;
    return { classId: (selected as any).classId ?? "", gradeId: (selected as any).gradeId ?? "" };
  }, [selected]);

  const filtered = useMemo(() => {
    const base = filterAnnouncementsForViewer(notices ?? [], "parent", viewerClass);
    if (!search.trim()) return base;
    const q = search.toLowerCase();
    return base.filter(n => n.title?.toLowerCase().includes(q) || n.content?.toLowerCase().includes(q));
  }, [notices, viewerClass, search]);

  const sorted = useMemo(
    () => [...filtered].sort((a, b) =>
      (b.publishedAt ?? b.createdAt ?? "").localeCompare(a.publishedAt ?? a.createdAt ?? "")
    ),
    [filtered]
  );

  if (loading) {
    return <DashboardLayout><div className="p-6 text-center text-slate-400 text-sm">Loading announcements…</div></DashboardLayout>;
  }

  return (
    <DashboardLayout>
      <div className="space-y-5">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-xl bg-amber-100 flex items-center justify-center flex-shrink-0">
            <Megaphone className="h-5 w-5 text-amber-600" />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">Announcements</h1>
            <p className="text-sm text-slate-400">School-wide and parent-targeted notices</p>
          </div>
        </div>

        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search announcements…"
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2.5 text-sm bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-indigo-300"
          />
        </div>

        {sorted.length === 0 ? (
          <div className="bg-white rounded-2xl border border-dashed border-slate-300 p-12 text-center">
            <Megaphone className="w-10 h-10 mx-auto mb-3 text-slate-300" />
            <h2 className="font-bold text-slate-700 text-base">No announcements</h2>
            <p className="text-sm text-slate-400 mt-1">
              {search ? "No results match your search." : "There are no announcements for parents at this time."}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {sorted.map(n => <AnnouncementCard key={n.id} notice={n} />)}
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
