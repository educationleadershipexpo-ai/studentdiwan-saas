import { useEffect, useMemo, useState } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { ChildSwitcher } from "@/components/parent/ChildSwitcher";
import { useParentChildren } from "@/hooks/useParentChildren";
import { smartDb } from "@/lib/localDb";
import { Calendar, BookOpen, FileText, Bell, Users2 } from "lucide-react";
import { cn } from "@/lib/utils";

interface CalEvent {
  id: string;
  date: string;
  title: string;
  type: "exam" | "assignment" | "notice" | "event";
  subtitle?: string;
  color: string;
  iconBg: string;
}

const TYPE_CONFIG = {
  exam:       { color: "text-rose-600",   iconBg: "bg-rose-50",   Icon: BookOpen,  label: "Exam"       },
  assignment: { color: "text-indigo-600", iconBg: "bg-indigo-50", Icon: FileText,  label: "Assignment" },
  notice:     { color: "text-amber-600",  iconBg: "bg-amber-50",  Icon: Bell,      label: "Notice"     },
  event:      { color: "text-emerald-600",iconBg: "bg-emerald-50",Icon: Calendar,  label: "Event"      },
};

function parseDate(v: any): string | null {
  if (!v) return null;
  const d = new Date(v);
  return isNaN(d.getTime()) ? null : d.toISOString().slice(0, 10);
}

function fmtDay(iso: string) {
  const d = new Date(iso + "T00:00:00");
  return d.toLocaleDateString("en-GB", { weekday: "short", day: "numeric", month: "short" });
}

function fmtMonth(iso: string) {
  const d = new Date(iso + "T00:00:00");
  return d.toLocaleDateString("en-GB", { month: "long", year: "numeric" });
}

function isToday(iso: string) {
  return iso === new Date().toISOString().slice(0, 10);
}

function isPast(iso: string) {
  return iso < new Date().toISOString().slice(0, 10);
}

export default function ParentCalendar() {
  const { selected, loading } = useParentChildren();
  const [events, setEvents] = useState<CalEvent[]>([]);
  const [dataLoading, setDataLoading] = useState(false);

  useEffect(() => {
    if (!selected?.id) { setEvents([]); return; }
    const sid = selected.id;
    const classId = (selected as any).classId ?? "";
    setDataLoading(true);

    Promise.all([
      smartDb.getAll("ExamSchedule").catch(() => []),
      smartDb.getAll("Assignment").catch(() => []),
      smartDb.getAll("Notice").catch(() => []),
      smartDb.getAll("CalendarEvent").catch(() => []),
    ]).then(([exams, assignments, notices, calEvents]) => {
      const out: CalEvent[] = [];

      for (const e of (exams || []) as any[]) {
        if (e.classId && classId && e.classId !== classId) continue;
        const d = parseDate(e.examDate ?? e.date);
        if (!d) continue;
        out.push({
          id: `exam-${e.id}`,
          date: d,
          title: e.subject ?? e.title ?? "Exam",
          subtitle: e.startTime ? `${e.startTime}${e.endTime ? " – " + e.endTime : ""}` : undefined,
          type: "exam",
          color: TYPE_CONFIG.exam.color,
          iconBg: TYPE_CONFIG.exam.iconBg,
        });
      }

      for (const a of (assignments || []) as any[]) {
        if (a.classId && classId && a.classId !== classId) continue;
        if (a.studentId && a.studentId !== sid) continue;
        const d = parseDate(a.dueDate ?? a.due_date);
        if (!d) continue;
        out.push({
          id: `asgn-${a.id}`,
          date: d,
          title: a.title ?? "Assignment",
          subtitle: a.subject ?? undefined,
          type: "assignment",
          color: TYPE_CONFIG.assignment.color,
          iconBg: TYPE_CONFIG.assignment.iconBg,
        });
      }

      for (const n of (notices || []) as any[]) {
        const audience: string[] = n.audience ?? n.targetAudience ?? [];
        if (Array.isArray(audience) && audience.length > 0 && !audience.some((a: string) => a === "parent" || a === "all")) continue;
        const d = parseDate(n.publishedAt ?? n.createdAt ?? n.date);
        if (!d) continue;
        out.push({
          id: `notice-${n.id}`,
          date: d,
          title: n.title ?? "Notice",
          subtitle: n.category ?? undefined,
          type: "notice",
          color: TYPE_CONFIG.notice.color,
          iconBg: TYPE_CONFIG.notice.iconBg,
        });
      }

      for (const c of (calEvents || []) as any[]) {
        const d = parseDate(c.startDate ?? c.date ?? c.start);
        if (!d) continue;
        out.push({
          id: `evt-${c.id}`,
          date: d,
          title: c.title ?? c.name ?? "Event",
          subtitle: c.location ?? undefined,
          type: "event",
          color: TYPE_CONFIG.event.color,
          iconBg: TYPE_CONFIG.event.iconBg,
        });
      }

      out.sort((a, b) => a.date.localeCompare(b.date));
      setEvents(out);
    }).finally(() => setDataLoading(false));
  }, [selected?.id]);

  const grouped = useMemo(() => {
    const map = new Map<string, CalEvent[]>();
    for (const ev of events) {
      const month = ev.date.slice(0, 7);
      if (!map.has(month)) map.set(month, []);
      map.get(month)!.push(ev);
    }
    return [...map.entries()].sort((a, b) => a[0].localeCompare(b[0]));
  }, [events]);

  const upcomingCount = useMemo(
    () => events.filter(e => !isPast(e.date) || isToday(e.date)).length,
    [events]
  );

  if (loading || dataLoading) {
    return <DashboardLayout><div className="p-6 text-center text-slate-400 text-sm">Loading calendar…</div></DashboardLayout>;
  }

  if (!selected) {
    return (
      <DashboardLayout>
        <div className="p-6">
          <div className="bg-white rounded-2xl border border-dashed border-slate-300 p-12 text-center max-w-lg mx-auto">
            <Users2 className="w-10 h-10 mx-auto mb-3 text-slate-300" />
            <h2 className="font-black text-slate-800 text-lg">No linked student found</h2>
            <p className="text-sm text-slate-500 mt-2">
              Your account isn't linked to any student record yet. Ask the school office to add your email
              as the father/mother/guardian email on your child's student profile.
            </p>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <div className="space-y-5">
        <div className="flex items-start justify-between flex-wrap gap-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl bg-emerald-100 flex items-center justify-center flex-shrink-0">
              <Calendar className="h-5 w-5 text-emerald-600" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Calendar</h1>
              <p className="text-sm text-slate-400">{selected.name} — Exams, assignments &amp; events</p>
            </div>
          </div>
          <ChildSwitcher className="w-56" />
        </div>

        {/* Legend */}
        <div className="flex items-center gap-4 flex-wrap">
          {(Object.entries(TYPE_CONFIG) as [keyof typeof TYPE_CONFIG, (typeof TYPE_CONFIG)[keyof typeof TYPE_CONFIG]][]).map(([key, cfg]) => (
            <div key={key} className="flex items-center gap-1.5">
              <div className={cn("w-2.5 h-2.5 rounded-full", cfg.iconBg.replace("bg-", "bg-").replace("-50", "-400"))} />
              <span className="text-xs text-slate-500">{cfg.label}</span>
            </div>
          ))}
          <span className="text-xs text-slate-400 ml-auto">{upcomingCount} upcoming</span>
        </div>

        {grouped.length === 0 ? (
          <div className="bg-white rounded-2xl border border-dashed border-slate-300 p-12 text-center">
            <Calendar className="w-10 h-10 mx-auto mb-3 text-slate-300" />
            <h2 className="font-bold text-slate-700 text-base">No events found</h2>
            <p className="text-sm text-slate-400 mt-1">
              Exams, assignments, and school events for {selected.name} will appear here.
            </p>
          </div>
        ) : (
          grouped.map(([month, monthEvents]) => (
            <div key={month}>
              <h2 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-3 px-1">
                {fmtMonth(month + "-01")}
              </h2>
              <div className="space-y-2.5">
                {monthEvents.map(ev => {
                  const cfg = TYPE_CONFIG[ev.type];
                  const today = isToday(ev.date);
                  const past = isPast(ev.date) && !today;
                  return (
                    <div
                      key={ev.id}
                      className={cn(
                        "bg-white rounded-2xl border p-4 flex items-start gap-3 transition-opacity",
                        today && "border-indigo-300 ring-1 ring-indigo-200",
                        past && "opacity-50",
                        !today && !past && "border-slate-200"
                      )}
                    >
                      <div className={cn("w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0", cfg.iconBg)}>
                        <cfg.Icon className={cn("w-4 h-4", cfg.color)} />
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center justify-between gap-2">
                          <p className="text-sm font-semibold text-slate-800 truncate">{ev.title}</p>
                          {today && (
                            <span className="text-[10px] font-semibold px-2 py-0.5 rounded-md bg-indigo-50 text-indigo-600 flex-shrink-0">
                              Today
                            </span>
                          )}
                        </div>
                        <div className="flex items-center gap-3 mt-0.5 flex-wrap">
                          <span className="text-xs text-slate-400">{fmtDay(ev.date)}</span>
                          {ev.subtitle && (
                            <span className="text-xs text-slate-400">· {ev.subtitle}</span>
                          )}
                          <span className={cn("text-[10px] font-semibold", cfg.color)}>{cfg.label}</span>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))
        )}
      </div>
    </DashboardLayout>
  );
}
