import { Link } from "react-router-dom";
import { Clock, BookOpen, ChevronRight, Search, Download, Users, Star } from "lucide-react";
import { GUIDE_ICON_MAP } from "@/lib/userGuides/iconMap";
import { useState } from "react";
import { ALL_GUIDES } from "@/lib/userGuides";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/hooks/useAuth";
import { getAllowedGuideIds, getPrimaryGuideId } from "@/lib/helpCenter/roleAccess";

export default function GuideHub() {
  const { role } = useAuth();
  const [search, setSearch] = useState("");

  const allowedIds = getAllowedGuideIds(role);
  const primaryId  = getPrimaryGuideId(role);
  const visibleGuides = ALL_GUIDES.filter((g) => allowedIds.includes(g.id));

  const filtered = search.trim()
    ? visibleGuides.filter(
        (g) =>
          g.title.toLowerCase().includes(search.toLowerCase()) ||
          g.tagline.toLowerCase().includes(search.toLowerCase()) ||
          g.audience.toLowerCase().includes(search.toLowerCase())
      )
    : visibleGuides;

  const totalMinutes = visibleGuides.reduce((s, g) => s + g.estimatedMinutes, 0);
  const totalChapters = visibleGuides.reduce((s, g) => s + g.chapters.length, 0);

  return (
    <DashboardLayout>
      <div className="min-h-screen bg-slate-50 dark:bg-slate-950">

        {/* ── Hero ─────────────────────────────────────────────────── */}
        <div className="relative bg-gradient-to-br from-slate-900 via-violet-950 to-slate-900 overflow-hidden">
          {/* Background decoration */}
          <div className="absolute inset-0 pointer-events-none">
            <div className="absolute top-0 left-1/4 w-96 h-96 bg-violet-600/10 rounded-full blur-3xl" />
            <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-indigo-600/10 rounded-full blur-3xl" />
            <div className="absolute inset-0 bg-[url('/grid.svg')] opacity-5" />
          </div>

          <div className="relative max-w-5xl mx-auto px-8 py-16">
            <div className="flex flex-col items-center text-center gap-6">
              <span className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-black uppercase tracking-widest bg-violet-500/20 text-violet-300 border border-violet-500/30">
                <BookOpen className="h-3.5 w-3.5" /> Documentation Library
              </span>

              <h1 className="text-4xl md:text-5xl font-black text-white tracking-tight leading-tight">
                User Guides &<br />
                <span className="bg-gradient-to-r from-violet-400 to-indigo-400 bg-clip-text text-transparent">
                  Role Manuals
                </span>
              </h1>

              <p className="text-slate-400 text-lg max-w-xl leading-relaxed">
                Step-by-step guides for every role in Student Diwan — with annotated screenshots, real workflows, and best practices.
              </p>

              {/* Stats */}
              <div className="flex items-center gap-8 text-sm">
                <div className="text-center">
                  <div className="text-2xl font-black text-white">{visibleGuides.length}</div>
                  <div className="text-slate-500 text-xs font-semibold uppercase tracking-widest mt-0.5">Role Guides</div>
                </div>
                <div className="w-px h-10 bg-slate-700" />
                <div className="text-center">
                  <div className="text-2xl font-black text-white">{totalChapters}</div>
                  <div className="text-slate-500 text-xs font-semibold uppercase tracking-widest mt-0.5">Chapters</div>
                </div>
                <div className="w-px h-10 bg-slate-700" />
                <div className="text-center">
                  <div className="text-2xl font-black text-white">{totalMinutes}+</div>
                  <div className="text-slate-500 text-xs font-semibold uppercase tracking-widest mt-0.5">Minutes of Content</div>
                </div>
              </div>

              {/* Search */}
              <div className="relative w-full max-w-md mt-2">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 pointer-events-none" />
                <Input
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  placeholder="Search guides by role or topic..."
                  className="h-12 pl-11 pr-4 rounded-2xl bg-white/10 border-white/20 text-white placeholder:text-slate-400 focus-visible:ring-violet-500 focus-visible:border-violet-500"
                />
              </div>
            </div>
          </div>
        </div>

        {/* ── Guide Cards Grid ──────────────────────────────────────── */}
        <div className="max-w-5xl mx-auto px-8 py-12">

          {filtered.length === 0 ? (
            <div className="text-center py-20 text-slate-400">
              <Users className="h-10 w-10 mx-auto mb-3 opacity-30" />
              <p className="font-semibold">No guides match your search.</p>
            </div>
          ) : (
            <>
              <div className="flex items-center justify-between mb-8">
                <h2 className="text-xs font-black uppercase tracking-widest text-slate-400">
                  {search ? `${filtered.length} result${filtered.length !== 1 ? "s" : ""}` : "Your Role Guides"}
                </h2>
                <span className="text-xs text-slate-400">
                  Showing guides relevant to your role and access level
                </span>
              </div>

              <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                {filtered.map((guide) => (
                  <Link
                    key={guide.id}
                    to={`/help/guides/${guide.id}`}
                    className={`group relative bg-white dark:bg-slate-900 rounded-2xl border overflow-hidden hover:shadow-xl hover:shadow-slate-200/60 dark:hover:shadow-none hover:-translate-y-0.5 transition-all duration-200
                      ${guide.id === primaryId
                        ? "border-violet-400 dark:border-violet-600 ring-2 ring-violet-400/30"
                        : "border-slate-200 dark:border-slate-800"}`}
                  >
                    {/* Gradient banner */}
                    <div className={`h-28 bg-gradient-to-br ${guide.gradient} relative overflow-hidden flex items-center justify-center`}>
                      <div className="absolute inset-0 bg-black/10" />
                      <div className="absolute -bottom-6 -right-6 w-24 h-24 rounded-full bg-white/10 blur-xl" />
                      {guide.id === primaryId && (
                        <div className="absolute top-3 right-3 flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/20 backdrop-blur-sm text-white text-[10px] font-black uppercase tracking-widest z-10">
                          <Star className="h-2.5 w-2.5 fill-white" /> Your Guide
                        </div>
                      )}
                      {(() => { const Icon = GUIDE_ICON_MAP[guide.icon]; return Icon ? <Icon className="h-14 w-14 text-white relative z-10 drop-shadow-lg" /> : null; })()}
                    </div>

                    {/* Content */}
                    <div className="p-5 space-y-3">
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <span className={`inline-block text-[10px] font-black uppercase tracking-widest px-2 py-0.5 rounded-md mb-2 ${guide.badgeBg} ${guide.badgeText}`}>
                            {guide.role}
                          </span>
                          <h3 className="font-black text-slate-800 dark:text-slate-100 text-base leading-snug group-hover:text-violet-600 dark:group-hover:text-violet-400 transition-colors">
                            {guide.title}
                          </h3>
                        </div>
                      </div>

                      <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                        {guide.tagline}
                      </p>

                      <div className="flex items-center gap-3 text-[10px] font-bold text-slate-400 uppercase tracking-wider pt-1">
                        <span className="flex items-center gap-1">
                          <BookOpen className="h-3 w-3" /> {guide.chapters.length} chapters
                        </span>
                        <span className="flex items-center gap-1">
                          <Clock className="h-3 w-3" /> {guide.estimatedMinutes} min
                        </span>
                      </div>

                      <div className="pt-2 flex items-center justify-between">
                        <span className="text-[10px] text-slate-400 font-semibold">{guide.audience}</span>
                        <span className="flex items-center gap-1 text-[10px] font-black text-violet-600 dark:text-violet-400 uppercase tracking-widest group-hover:gap-2 transition-all">
                          Read Guide <ChevronRight className="h-3 w-3" />
                        </span>
                      </div>
                    </div>
                  </Link>
                ))}
              </div>
            </>
          )}

          {/* Bottom CTA — download all guides */}
          <div className="mt-16 rounded-2xl bg-gradient-to-r from-slate-900 to-violet-950 border border-slate-800 p-8 flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="space-y-1.5">
              <h3 className="font-black text-white text-lg">Need Offline Documentation?</h3>
              <p className="text-slate-400 text-sm leading-relaxed">
                Download complete PDF manuals for each role — ideal for training sessions and offline reference.
              </p>
            </div>
            <Link
              to="/help"
              className="shrink-0 flex items-center gap-2 h-11 px-6 rounded-xl bg-violet-600 hover:bg-violet-500 text-white font-bold text-sm transition-colors"
            >
              <Download className="h-4 w-4" />
              Documentation Center
            </Link>
          </div>
        </div>
      </div>
    </DashboardLayout>
  );
}
