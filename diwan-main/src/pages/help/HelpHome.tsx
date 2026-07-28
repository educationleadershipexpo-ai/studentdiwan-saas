import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import {
  Rocket, BookOpen, LayoutGrid, Cpu, Code2, HelpCircle,
  AlertTriangle, Sparkles, History, ArrowRight, Download, Play,
  Users, ChevronRight
} from "lucide-react";
import { ALL_GUIDES } from "@/lib/userGuides";
import { HELP_CENTER, getPopularArticles } from "@/lib/helpCenter";
import { HelpLayout } from "@/components/help/HelpLayout";
import { GuidedTour, NeedHelpWidget, TourStep } from "@/components/help/InteractiveHelp";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/hooks/useAuth";
import { getAllowedCategoryIds, getAllowedGuideIds, getPrimaryGuideId } from "@/lib/helpCenter/roleAccess";

const TOUR_STEPS: TourStep[] = [
  {
    target: "help-welcome",
    title: "Welcome to the Help Center",
    content: "This portal is your direct guide to mastering Student Diwan. You can search, browse by category, and read detailed articles."
  },
  {
    target: "help-search",
    title: "Instant Search Feature",
    content: "Press Ctrl+K at any time to open the global search modal. You can look up any feature, code snippet, or guide instantly."
  },
  {
    target: "help-download",
    title: "Offline Manual Downloads",
    content: "Need documentation offline? You can download compiled Markdown versions of our User Manual, API reference, or Admin guides."
  },
  {
    target: "help-widget",
    title: "Interactive Support Widget",
    content: "Click the floating widget in the bottom-right corner to report issues, request assistance, or suggest product improvements."
  }
];

export default function HelpHome() {
  const navigate = useNavigate();
  const { role } = useAuth();
  const [tourActive, setTourActive] = useState(false);

  const allowedCategoryIds = getAllowedCategoryIds(role);
  const allowedGuideIds    = getAllowedGuideIds(role);
  const primaryGuideId     = getPrimaryGuideId(role);

  const visibleCategories = HELP_CENTER.filter((c) => allowedCategoryIds.includes(c.id));
  const visibleGuides     = ALL_GUIDES.filter((g) => allowedGuideIds.includes(g.id));

  // Popular articles filtered to only allowed categories
  const popular = getPopularArticles(6).filter((a) => allowedCategoryIds.includes(a.categoryId));
  const totalArticles = visibleCategories.reduce((n, c) => n + c.articles.length, 0);

  // Download logic to assemble custom manuals
  const triggerDownload = (type: string, title: string) => {
    let output = `# Student Diwan Documentation - ${title}\n\n`;
    output += `Generated on: ${new Date().toLocaleDateString()}\n`;
    output += `Version: 2.4.0\n\n`;
    output += `*This is a compiled document of the Student Diwan Help Center.*\n\n---\n\n`;

    let matchedArticles: any[] = [];
    
    if (type === "quickstart") {
      const cat = HELP_CENTER.find(c => c.id === "getting-started");
      if (cat) matchedArticles = cat.articles;
    } else if (type === "admin") {
      const cat = HELP_CENTER.find(c => c.id === "system-admin");
      const userGuides = HELP_CENTER.find(c => c.id === "user-guides");
      if (cat) matchedArticles = [...matchedArticles, ...cat.articles];
      if (userGuides) {
        const adm = userGuides.articles.filter(a => a.slug === "super-admin" || a.slug === "school-admin");
        matchedArticles = [...matchedArticles, ...adm];
      }
    } else if (type === "api") {
      const cat = HELP_CENTER.find(c => c.id === "developer-docs");
      if (cat) matchedArticles = cat.articles;
    } else if (type === "release") {
      const notes = HELP_CENTER.find(c => c.id === "release-notes");
      const logs = HELP_CENTER.find(c => c.id === "changelog");
      if (notes) matchedArticles = [...matchedArticles, ...notes.articles];
      if (logs) matchedArticles = [...matchedArticles, ...logs.articles];
    } else {
      // Complete Manual (all categories)
      HELP_CENTER.forEach(c => {
        matchedArticles = [...matchedArticles, ...c.articles];
      });
    }

    matchedArticles.forEach(a => {
      output += `## ${a.title}\n\n`;
      output += `*Summary: ${a.summary}*\n\n`;
      output += `${a.content}\n\n`;
      output += `---\n\n`;
    });

    const blob = new Blob([output], { type: "text/markdown;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", `student_diwan_${type}_guide.md`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <HelpLayout>
      <div className="space-y-12">
        
        {/* Interactive Guided Tour */}
        <GuidedTour 
          steps={TOUR_STEPS} 
          active={tourActive} 
          onClose={() => setTourActive(false)} 
        />

        {/* Hero Section */}
        <div id="help-welcome" className="relative p-8 rounded-3xl bg-gradient-to-br from-violet-600 to-indigo-700 text-white shadow-xl overflow-hidden">
          <div className="absolute top-0 right-0 -translate-y-12 translate-x-12 w-64 h-64 bg-violet-400/20 rounded-full blur-3xl pointer-events-none" />
          <div className="absolute bottom-0 left-0 translate-y-12 -translate-x-12 w-64 h-64 bg-indigo-400/20 rounded-full blur-3xl pointer-events-none" />
          
          <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
            <div className="space-y-3 max-w-xl">
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-white/10 text-violet-100 backdrop-blur-sm">
                <Sparkles className="w-3.5 h-3.5" /> Documentation Center
              </span>
              <h1 className="text-3xl font-black tracking-tight">How can we help you today?</h1>
              <p className="text-violet-100 text-sm leading-relaxed">
                Access guided user manuals, detailed system parameters, developer endpoints, and FAQs. Search instantly or click any module category below.
              </p>
            </div>
            
            <div className="flex items-center gap-2.5 shrink-0">
              <button
                onClick={() => navigate('/quick-start')}
                className="h-11 px-5 rounded-xl bg-violet-500/20 hover:bg-violet-500/30 text-white font-bold text-xs flex items-center gap-2 transition-all border border-white/20"
              >
                <Rocket className="h-3.5 w-3.5" />
                Launch Quick Start Guide
              </button>
              <button
                onClick={() => setTourActive(true)}
                className="h-11 px-5 rounded-xl bg-white hover:bg-violet-50 text-violet-600 font-bold text-xs flex items-center gap-2 transition-all hover:scale-102"
              >
                <Play className="h-3.5 w-3.5 fill-violet-600" />
                Start Interactive Tour
              </button>
            </div>
          </div>
        </div>

        {/* Popular Articles Grid */}
        <section className="space-y-4">
          <h2 className="text-xs font-black uppercase tracking-widest text-slate-400">Popular Reference Articles</h2>
          <div className="grid gap-4 sm:grid-cols-2">
            {popular.map((a) => (
              <Link key={`${a.categoryId}-${a.slug}`} to={`/help/${a.categoryId}/${a.slug}`}>
                <Card className="p-5 h-full hover:border-violet-500/50 hover:shadow-lg hover:shadow-slate-100 dark:hover:shadow-none transition-all duration-200 flex flex-col gap-2">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-black uppercase tracking-wider text-slate-400">{a.categoryTitle}</span>
                    <Badge variant="secondary" className="text-[10px] font-bold bg-violet-50 text-violet-600 dark:bg-violet-950/20 dark:text-violet-400">Popular</Badge>
                  </div>
                  <h3 className="font-bold text-slate-800 dark:text-slate-200 text-base">{a.title}</h3>
                  <p className="text-slate-500 dark:text-slate-400 text-xs leading-relaxed">{a.summary}</p>
                </Card>
              </Link>
            ))}
          </div>
        </section>

        {/* Browse by Category */}
        <section className="space-y-4">
          <h2 className="text-xs font-black uppercase tracking-widest text-slate-400">Browse Documentation Directories</h2>
          <div className="grid gap-4 sm:grid-cols-2 md:grid-cols-3">
            {visibleCategories.map((cat) => (
              <Link key={cat.id} to={`/help/${cat.id}`}>
                <Card className="p-5 h-full hover:border-violet-500/50 hover:shadow-lg hover:shadow-slate-100 dark:hover:shadow-none transition-all duration-200 flex flex-col gap-3">
                  <div className="flex items-center gap-2">
                    <div className="h-10 w-10 rounded-xl bg-violet-50 dark:bg-violet-950/20 text-violet-600 dark:text-violet-400 flex items-center justify-center">
                      {cat.icon === "Rocket" && <Rocket className="h-5 w-5" />}
                      {cat.icon === "BookOpen" && <BookOpen className="h-5 w-5" />}
                      {cat.icon === "LayoutGrid" && <LayoutGrid className="h-5 w-5" />}
                      {cat.icon === "Cpu" && <Cpu className="h-5 w-5" />}
                      {cat.icon === "Code2" && <Code2 className="h-5 w-5" />}
                      {cat.icon === "HelpCircle" && <HelpCircle className="h-5 w-5" />}
                      {cat.icon === "AlertTriangle" && <AlertTriangle className="h-5 w-5" />}
                      {cat.icon === "Sparkles" && <Sparkles className="h-5 w-5" />}
                      {cat.icon === "History" && <History className="h-5 w-5" />}
                    </div>
                    <Badge variant="outline" className="ms-auto font-bold text-xs">{cat.articles.length} docs</Badge>
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800 dark:text-slate-200 text-sm leading-snug">{cat.title}</h3>
                    <p className="text-slate-500 dark:text-slate-400 text-xs leading-relaxed mt-1.5">{cat.description}</p>
                  </div>
                  <div className="mt-auto pt-2 flex items-center gap-1 text-[10px] font-bold text-violet-600 uppercase tracking-widest">
                    <span>Explore Category</span>
                    <ArrowRight className="h-3 w-3" />
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        </section>

        {/* User Guides Section */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="text-xs font-black uppercase tracking-widest text-slate-400">Role-Based User Guides</h2>
            <Link to="/help/guides" className="flex items-center gap-1 text-[10px] font-black uppercase tracking-widest text-violet-600 dark:text-violet-400 hover:underline">
              View All <ChevronRight className="h-3 w-3" />
            </Link>
          </div>
          <div className="relative rounded-2xl overflow-hidden border border-slate-200 dark:border-slate-800 bg-gradient-to-br from-slate-900 via-violet-950 to-slate-900 p-6">
            <div className="absolute inset-0 pointer-events-none">
              <div className="absolute top-0 right-1/4 w-64 h-64 bg-violet-600/10 rounded-full blur-3xl" />
            </div>
            <div className="relative flex flex-col md:flex-row items-start md:items-center gap-6">
              <div className="space-y-2 flex-1">
                <div className="flex items-center gap-2">
                  <Users className="h-5 w-5 text-violet-400" />
                  <span className="text-xs font-black uppercase tracking-widest text-violet-400">Documentation Library</span>
                </div>
                <h3 className="text-white font-black text-xl">Step-by-step guides for every role</h3>
                <p className="text-slate-400 text-sm leading-relaxed max-w-lg">
                  Illustrated manuals with annotated screenshots for Super Admin, School Admin, Teacher, Parent, Student, Accountant, HR, Transport, Library, and Mobile App roles.
                </p>
                <div className="flex flex-wrap gap-2 pt-1">
                  {visibleGuides.slice(0, 5).map(g => (
                    <Link
                      key={g.id}
                      to={`/help/guides/${g.id}`}
                      className={`flex items-center gap-1.5 h-7 px-3 rounded-full text-[10px] font-bold transition-colors border
                        ${g.id === primaryGuideId
                          ? "bg-white/25 border-white/40 text-white"
                          : "bg-white/10 border-white/10 text-white hover:bg-white/20"}`}
                    >
                      {g.id === primaryGuideId && <span className="text-yellow-300">★</span>} {g.role}
                    </Link>
                  ))}
                  {visibleGuides.length > 5 && (
                    <Link to="/help/guides" className="flex items-center gap-1 h-7 px-3 rounded-full bg-violet-600/30 hover:bg-violet-600/50 text-violet-300 text-[10px] font-bold transition-colors border border-violet-500/30">
                      +{visibleGuides.length - 5} more
                    </Link>
                  )}
                </div>
              </div>
              <Link
                to="/help/guides"
                className="shrink-0 flex items-center gap-2 h-11 px-6 rounded-xl bg-violet-600 hover:bg-violet-500 text-white font-bold text-sm transition-colors"
              >
                <BookOpen className="h-4 w-4" /> Browse Guides
              </Link>
            </div>
          </div>
        </section>

        {/* Offline Downloads Segment */}
        <section id="help-download" className="p-6 rounded-2xl border border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-900/10 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="space-y-1">
            <h3 className="font-bold text-slate-800 dark:text-slate-200 text-sm">Download Offline Documentation Guides</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
              Export compiled markdown user manuals for local archiving, offline viewing, or printing.
            </p>
          </div>
          
          <div className="flex flex-wrap gap-2.5 shrink-0">
            <button 
              onClick={() => triggerDownload("quickstart", "Quick Start Manual")}
              className="h-9 px-3.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 font-bold text-[10px] uppercase tracking-wider flex items-center gap-1.5 hover:bg-slate-50 transition-colors"
            >
              <Download className="h-3 w-3" /> Quick Start Guide
            </button>
            <button 
              onClick={() => triggerDownload("admin", "Administrator Guide")}
              className="h-9 px-3.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 font-bold text-[10px] uppercase tracking-wider flex items-center gap-1.5 hover:bg-slate-50 transition-colors"
            >
              <Download className="h-3 w-3" /> Administrator Guide
            </button>
            <button 
              onClick={() => triggerDownload("api", "Developer API Reference")}
              className="h-9 px-3.5 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 font-bold text-[10px] uppercase tracking-wider flex items-center gap-1.5 hover:bg-slate-50 transition-colors"
            >
              <Download className="h-3 w-3" /> API Manual
            </button>
          </div>
        </section>

      </div>
      
      {/* Support widget floating bubble */}
      <NeedHelpWidget />
    </HelpLayout>
  );
}
