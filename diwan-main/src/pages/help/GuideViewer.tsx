import { useParams, Link, Navigate } from "react-router-dom";
import { useState, useEffect, useRef } from "react";
import {
  ArrowLeft, BookOpen, Clock, ChevronRight, ChevronDown, ChevronUp,
  CheckCircle2, AlertTriangle, Info, Lightbulb, XCircle,
  Menu, X, List, Lock
} from "lucide-react";
import { getGuide } from "@/lib/userGuides";
import { GUIDE_ICON_MAP } from "@/lib/userGuides/iconMap";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { AnnotatedScreenshot } from "@/components/help/AnnotatedScreenshot";
import type { Block, Chapter } from "@/lib/userGuides/types";
import { useAuth } from "@/hooks/useAuth";
import { canAccessGuide } from "@/lib/helpCenter/roleAccess";

export default function GuideViewer() {
  const { roleId } = useParams<{ roleId: string }>();
  const { role } = useAuth();
  const guide = roleId ? getGuide(roleId) : undefined;

  const [activeChapter, setActiveChapter] = useState(0);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [readProgress, setReadProgress] = useState(0);
  const contentRef = useRef<HTMLDivElement>(null);

  useEffect(() => { setActiveChapter(0); }, [roleId]);

  useEffect(() => {
    const el = contentRef.current;
    if (!el) return;
    const onScroll = () => {
      const { scrollTop, scrollHeight, clientHeight } = el;
      const max = scrollHeight - clientHeight;
      setReadProgress(max > 0 ? Math.round((scrollTop / max) * 100) : 0);
    };
    el.addEventListener("scroll", onScroll, { passive: true });
    return () => el.removeEventListener("scroll", onScroll);
  }, [activeChapter]);

  if (!guide) return <Navigate to="/help/guides" replace />;

  // Access gate — show a locked state instead of hard redirect so the URL is preserved
  if (!canAccessGuide(role, guide.id)) {
    return (
      <DashboardLayout>
        <div className="flex h-[calc(100vh-4rem)] items-center justify-center bg-white dark:bg-slate-950 px-8">
          <div className="max-w-sm text-center space-y-4">
            <div className="h-16 w-16 rounded-2xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center mx-auto">
              <Lock className="h-7 w-7 text-slate-400" />
            </div>
            <h2 className="text-xl font-black text-slate-800 dark:text-slate-100">Guide Not Available</h2>
            <p className="text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
              The <strong>{guide.title}</strong> is not part of your assigned role's documentation.
              If you believe this is an error, contact your system administrator.
            </p>
            <Link
              to="/help/guides"
              className="inline-flex items-center gap-2 h-10 px-5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-sm font-bold transition-colors"
            >
              <ArrowLeft className="h-4 w-4" /> Back to Your Guides
            </Link>
          </div>
        </div>
      </DashboardLayout>
    );
  }

  const chapter = guide.chapters[activeChapter];

  return (
    <DashboardLayout>
      <div className="flex h-[calc(100vh-4rem)] bg-white dark:bg-slate-950 overflow-hidden">

        {/* ── Chapter Sidebar ───────────────────────────────────────────────── */}
        <aside
          className={`
            flex-shrink-0 border-r border-slate-200 dark:border-slate-800
            flex flex-col overflow-hidden transition-all duration-200
            ${sidebarOpen ? "w-72" : "w-14"}
          `}
        >
          {/* Sidebar header */}
          <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex items-center gap-3">
            <button
              onClick={() => setSidebarOpen(!sidebarOpen)}
              className="h-8 w-8 rounded-lg flex items-center justify-center text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors flex-shrink-0"
            >
              {sidebarOpen ? <X className="h-4 w-4" /> : <List className="h-4 w-4" />}
            </button>
            {sidebarOpen && (
              <div className="min-w-0">
                <div className="text-[10px] font-black uppercase tracking-widest text-slate-400">Guide</div>
                <div className="font-black text-slate-800 dark:text-slate-100 text-sm truncate">{guide.title}</div>
              </div>
            )}
          </div>

          {/* Chapter list */}
          <div className="flex-1 overflow-y-auto py-2">
            {guide.chapters.map((ch, i) => (
              <button
                key={ch.id}
                onClick={() => { setActiveChapter(i); setReadProgress(0); }}
                className={`
                  w-full flex items-center gap-3 px-4 py-3 text-left transition-all group
                  ${i === activeChapter
                    ? "bg-violet-50 dark:bg-violet-950/30 text-violet-700 dark:text-violet-300 border-r-2 border-violet-500"
                    : "text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/50"}
                `}
              >
                <span className={`flex-shrink-0 w-7 h-7 rounded-lg flex items-center justify-center transition-colors
                  ${i === activeChapter ? "bg-violet-600 text-white" : "bg-slate-100 dark:bg-slate-800 text-slate-500 group-hover:bg-slate-200 dark:group-hover:bg-slate-700"}`}>
                  {GUIDE_ICON_MAP[ch.icon]
                    ? (() => { const Icon = GUIDE_ICON_MAP[ch.icon]; return <Icon className="h-3.5 w-3.5" />; })()
                    : <span className="text-xs font-black">{ch.number}</span>}
                </span>
                {sidebarOpen && (
                  <span className="text-sm font-bold leading-snug truncate">{ch.title}</span>
                )}
              </button>
            ))}
          </div>

          {/* Progress footer */}
          {sidebarOpen && (
            <div className="p-4 border-t border-slate-100 dark:border-slate-800 space-y-2">
              <div className="flex items-center justify-between text-[10px] font-bold text-slate-400 uppercase tracking-widest">
                <span>Progress</span>
                <span>{Math.round(((activeChapter) / guide.chapters.length) * 100)}%</span>
              </div>
              <div className="h-1.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-violet-500 to-indigo-500 transition-all duration-500"
                  style={{ width: `${Math.round(((activeChapter) / guide.chapters.length) * 100)}%` }}
                />
              </div>
              <div className="text-[10px] text-slate-400">
                Chapter {activeChapter + 1} of {guide.chapters.length}
              </div>
            </div>
          )}
        </aside>

        {/* ── Main Content ──────────────────────────────────────────────────── */}
        <main ref={contentRef} className="flex-1 overflow-y-auto">

          {/* Reading progress bar */}
          <div className="sticky top-0 z-10 h-0.5 bg-slate-100 dark:bg-slate-800">
            <div
              className="h-full bg-gradient-to-r from-violet-500 to-indigo-500 transition-all duration-100"
              style={{ width: `${readProgress}%` }}
            />
          </div>

          <div className="max-w-3xl mx-auto px-8 py-10 space-y-10">

            {/* Back + breadcrumb */}
            <div className="flex items-center gap-2 text-xs text-slate-400">
              <Link to="/help/guides" className="flex items-center gap-1 hover:text-violet-600 dark:hover:text-violet-400 font-bold transition-colors">
                <ArrowLeft className="h-3 w-3" /> All Guides
              </Link>
              <ChevronRight className="h-3 w-3" />
              <span className="text-slate-500 dark:text-slate-400 font-semibold">{guide.title}</span>
              <ChevronRight className="h-3 w-3" />
              <span className="text-slate-700 dark:text-slate-200 font-bold">{chapter.title}</span>
            </div>

            {/* Guide header (first chapter only) */}
            {activeChapter === 0 && (
              <div className={`rounded-2xl bg-gradient-to-br ${guide.gradient} p-8 text-white space-y-3 relative overflow-hidden`}>
                <div className="absolute -right-8 -top-8 w-40 h-40 rounded-full bg-white/10 blur-2xl" />
                {(() => { const Icon = GUIDE_ICON_MAP[guide.icon]; return Icon ? <Icon className="h-10 w-10 text-white" /> : null; })()}
                <span className={`inline-block text-[10px] font-black uppercase tracking-widest px-2.5 py-1 rounded-md bg-white/20`}>
                  {guide.role} Manual
                </span>
                <h1 className="text-2xl font-black leading-tight">{guide.title}</h1>
                <p className="text-white/80 text-sm leading-relaxed max-w-lg">{guide.tagline}</p>
                <div className="flex items-center gap-6 text-xs font-bold text-white/70 pt-2">
                  <span className="flex items-center gap-1.5"><BookOpen className="h-3.5 w-3.5" /> {guide.chapters.length} Chapters</span>
                  <span className="flex items-center gap-1.5"><Clock className="h-3.5 w-3.5" /> {guide.estimatedMinutes} min</span>
                  <span>v{guide.version}</span>
                </div>
              </div>
            )}

            {/* Chapter header */}
            <div className="space-y-2 pb-6 border-b border-slate-100 dark:border-slate-800">
              <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-violet-500">
                <span className="w-5 h-5 rounded-md bg-violet-100 dark:bg-violet-950/50 flex items-center justify-center font-black text-violet-600 dark:text-violet-400">
                  {chapter.number}
                </span>
                Chapter {chapter.number}
              </div>
              <h2 className="text-2xl font-black text-slate-800 dark:text-slate-100 tracking-tight">{chapter.title}</h2>
              <p className="text-slate-500 dark:text-slate-400 text-sm leading-relaxed max-w-xl">{chapter.summary}</p>
            </div>

            {/* Chapter blocks */}
            <div className="space-y-8">
              {chapter.blocks.map((block, i) => (
                <BlockRenderer key={i} block={block} />
              ))}
            </div>

            {/* Chapter navigation */}
            <div className="pt-6 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between gap-4">
              <button
                onClick={() => { setActiveChapter(Math.max(0, activeChapter - 1)); setReadProgress(0); contentRef.current?.scrollTo(0,0); }}
                disabled={activeChapter === 0}
                className="flex items-center gap-2 h-10 px-5 rounded-xl border border-slate-200 dark:border-slate-700 text-sm font-bold text-slate-600 dark:text-slate-300 hover:border-violet-400 disabled:opacity-30 disabled:pointer-events-none transition-all"
              >
                <ArrowLeft className="h-4 w-4" /> Previous
              </button>

              <span className="text-xs text-slate-400 font-semibold">
                {activeChapter + 1} / {guide.chapters.length}
              </span>

              {activeChapter < guide.chapters.length - 1 ? (
                <button
                  onClick={() => { setActiveChapter(activeChapter + 1); setReadProgress(0); contentRef.current?.scrollTo(0,0); }}
                  className="flex items-center gap-2 h-10 px-5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-sm font-bold transition-colors"
                >
                  Next Chapter <ChevronRight className="h-4 w-4" />
                </button>
              ) : (
                <Link
                  to="/help/guides"
                  className="flex items-center gap-2 h-10 px-5 rounded-xl bg-gradient-to-r from-violet-600 to-indigo-600 text-white text-sm font-bold hover:opacity-90 transition-opacity"
                >
                  <CheckCircle2 className="h-4 w-4" /> Guide Complete
                </Link>
              )}
            </div>
          </div>
        </main>
      </div>
    </DashboardLayout>
  );
}

/* ── Block Renderers ──────────────────────────────────────────────────── */

function BlockRenderer({ block }: { block: Block }) {
  switch (block.type) {
    case "text":      return <TextBlockView markdown={block.markdown} />;
    case "steps":     return <StepsBlockView block={block} />;
    case "screenshot":return <AnnotatedScreenshot src={block.src} caption={block.caption} alt={block.alt} annotations={block.annotations} />;
    case "callout":   return <CalloutBlockView block={block} />;
    case "table":     return <TableBlockView block={block} />;
    case "faq":       return <FaqBlockView block={block} />;
    default:          return null;
  }
}

function TextBlockView({ markdown }: { markdown: string }) {
  const lines = markdown.split("\n");
  return (
    <div className="prose prose-slate dark:prose-invert prose-sm max-w-none">
      {lines.map((line, i) => {
        if (line.startsWith("## ")) return <h2 key={i} className="text-lg font-black text-slate-800 dark:text-slate-100 mt-6 mb-2">{line.slice(3)}</h2>;
        if (line.startsWith("### ")) return <h3 key={i} className="text-base font-bold text-slate-700 dark:text-slate-200 mt-4 mb-1">{line.slice(4)}</h3>;
        if (line.startsWith("- ") || line.startsWith("* ")) return <li key={i} className="text-slate-600 dark:text-slate-400 text-sm ml-4">{line.slice(2)}</li>;
        if (line.startsWith("**") && line.endsWith("**")) return <p key={i} className="font-bold text-slate-800 dark:text-slate-200 text-sm">{line.slice(2, -2)}</p>;
        if (line.trim() === "") return <div key={i} className="h-2" />;
        return <p key={i} className="text-slate-600 dark:text-slate-400 text-sm leading-relaxed">{line}</p>;
      })}
    </div>
  );
}

function StepsBlockView({ block }: { block: import("@/lib/userGuides/types").StepsBlock }) {
  return (
    <div className="space-y-3">
      {block.title && (
        <h3 className="text-sm font-black uppercase tracking-widest text-slate-500 dark:text-slate-400">{block.title}</h3>
      )}
      <ol className="space-y-3">
        {block.steps.map((step, i) => (
          <li key={i} className="flex gap-4 p-4 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800">
            <span className="flex-shrink-0 w-8 h-8 rounded-full bg-violet-600 text-white flex items-center justify-center font-black text-sm">
              {i + 1}
            </span>
            <div className="space-y-1 pt-0.5">
              <div className="font-bold text-slate-800 dark:text-slate-100 text-sm">{step.title}</div>
              <div className="text-slate-500 dark:text-slate-400 text-xs leading-relaxed">{step.description}</div>
              {step.tip && (
                <div className="mt-2 flex items-start gap-2 text-xs text-amber-700 dark:text-amber-400 bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800/50 rounded-lg px-3 py-2">
                  <Lightbulb className="h-3.5 w-3.5 flex-shrink-0 mt-0.5" />
                  {step.tip}
                </div>
              )}
            </div>
          </li>
        ))}
      </ol>
    </div>
  );
}

const calloutConfig = {
  tip:     { icon: Lightbulb,     bg: "bg-amber-50 dark:bg-amber-950/20",  border: "border-amber-200 dark:border-amber-800/50",  text: "text-amber-800 dark:text-amber-300",  iconColor: "text-amber-500" },
  warning: { icon: AlertTriangle, bg: "bg-orange-50 dark:bg-orange-950/20",border: "border-orange-200 dark:border-orange-800/50",text: "text-orange-800 dark:text-orange-300",iconColor: "text-orange-500" },
  info:    { icon: Info,          bg: "bg-blue-50 dark:bg-blue-950/20",    border: "border-blue-200 dark:border-blue-800/50",    text: "text-blue-800 dark:text-blue-300",    iconColor: "text-blue-500" },
  success: { icon: CheckCircle2,  bg: "bg-emerald-50 dark:bg-emerald-950/20",border: "border-emerald-200 dark:border-emerald-800/50",text: "text-emerald-800 dark:text-emerald-300",iconColor: "text-emerald-500" },
  danger:  { icon: XCircle,       bg: "bg-red-50 dark:bg-red-950/20",      border: "border-red-200 dark:border-red-800/50",      text: "text-red-800 dark:text-red-300",      iconColor: "text-red-500" },
};

function CalloutBlockView({ block }: { block: import("@/lib/userGuides/types").CalloutBlock }) {
  const cfg = calloutConfig[block.variant];
  const Icon = cfg.icon;
  return (
    <div className={`flex gap-3 p-4 rounded-xl border ${cfg.bg} ${cfg.border}`}>
      <Icon className={`h-4 w-4 flex-shrink-0 mt-0.5 ${cfg.iconColor}`} />
      <div>
        <div className={`text-xs font-black uppercase tracking-widest mb-1 ${cfg.text}`}>{block.title}</div>
        <div className={`text-xs leading-relaxed ${cfg.text} opacity-90`}>{block.body}</div>
      </div>
    </div>
  );
}

function TableBlockView({ block }: { block: import("@/lib/userGuides/types").TableBlock }) {
  return (
    <div className="space-y-2 not-prose">
      {block.caption && <p className="text-xs font-semibold text-slate-500 dark:text-slate-400">{block.caption}</p>}
      <div className="overflow-x-auto rounded-xl border border-slate-200 dark:border-slate-700">
        <table className="w-full text-xs">
          <thead>
            <tr className="bg-slate-50 dark:bg-slate-800/80">
              {block.headers.map((h, i) => (
                <th key={i} className="px-4 py-3 text-left font-black text-slate-600 dark:text-slate-300 uppercase tracking-wider text-[10px]">{h}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
            {block.rows.map((row, i) => (
              <tr key={i} className="bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors">
                {row.map((cell, j) => (
                  <td key={j} className="px-4 py-3 text-slate-600 dark:text-slate-400">{cell}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function FaqBlockView({ block }: { block: import("@/lib/userGuides/types").FaqBlock }) {
  const [open, setOpen] = useState<number | null>(null);
  return (
    <div className="space-y-2">
      {block.questions.map((faq, i) => (
        <div key={i} className={`rounded-xl border overflow-hidden transition-all ${open === i ? "border-violet-300 dark:border-violet-700" : "border-slate-200 dark:border-slate-800"}`}>
          <button
            onClick={() => setOpen(open === i ? null : i)}
            className="w-full flex items-center justify-between gap-4 px-4 py-3.5 text-left bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
          >
            <span className="text-sm font-bold text-slate-700 dark:text-slate-200">{faq.q}</span>
            {open === i
              ? <ChevronUp className="h-4 w-4 text-violet-500 flex-shrink-0" />
              : <ChevronDown className="h-4 w-4 text-slate-400 flex-shrink-0" />
            }
          </button>
          {open === i && (
            <div className="px-4 pb-4 pt-1 bg-white dark:bg-slate-900 border-t border-slate-100 dark:border-slate-800/60 text-sm text-slate-500 dark:text-slate-400 leading-relaxed">
              {faq.a}
            </div>
          )}
        </div>
      ))}
    </div>
  );
}
