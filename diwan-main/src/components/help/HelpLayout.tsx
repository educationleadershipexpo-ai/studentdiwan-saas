import { ReactNode, useState, useEffect, useRef, useCallback } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import {
  Search, Printer, Share2, Sun, Moon, ChevronRight,
  Menu, X, BookOpen, Eye, ArrowLeft,
  HelpCircle, AlertTriangle, Sparkles, History, Cpu, Code2, Rocket, LayoutGrid,
  Check, Link2,
} from "lucide-react";
import { HELP_CENTER, searchArticles, FlatArticle } from "@/lib/helpCenter";
import { getAllowedCategoryIds } from "@/lib/helpCenter/roleAccess";
import { Input } from "@/components/ui/input";
import { useTheme } from "@/contexts/ThemeContext";
import { useAuth } from "@/hooks/useAuth";

interface HelpLayoutProps {
  children: ReactNode;
  title?: string;
  articleId?: string;
  categoryTitle?: string;
  categorySlug?: string;
  toc?: { id: string; text: string }[];
}

export function HelpLayout({ children, title, articleId, categoryTitle, categorySlug, toc = [] }: HelpLayoutProps) {
  const { theme, toggleTheme } = useTheme();
  const { role } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<FlatArticle[]>([]);
  const [showSearchModal, setShowSearchModal] = useState(false);
  const [searchSelectedIdx, setSearchSelectedIdx] = useState(-1);
  const [recentlyViewed, setRecentlyViewed] = useState<{ title: string; path: string }[]>([]);
  const [shareCopied, setShareCopied] = useState(false);
  const [readProgress, setReadProgress] = useState(0);

  const mainScrollRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  const isSuperAdmin = role === "admin" || role === "super_admin";

  const allowedCategoryIds = getAllowedCategoryIds(role);
  const visibleCategories = HELP_CENTER.filter((c) => allowedCategoryIds.includes(c.id));

  // Reading progress bar — only on article pages
  useEffect(() => {
    const el = mainScrollRef.current;
    if (!el || !articleId) return;
    setReadProgress(0);
    const handleScroll = () => {
      const max = el.scrollHeight - el.clientHeight;
      setReadProgress(max > 0 ? Math.round((el.scrollTop / max) * 100) : 0);
    };
    el.addEventListener("scroll", handleScroll, { passive: true });
    return () => el.removeEventListener("scroll", handleScroll);
  }, [articleId, location.pathname]);

  // Ctrl+K global shortcut
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault();
        setShowSearchModal(true);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  // Track recently viewed articles
  useEffect(() => {
    if (title && location.pathname.startsWith("/help/")) {
      const item = { title, path: location.pathname };
      setRecentlyViewed((prev) => {
        const filtered = prev.filter((x) => x.path !== item.path);
        const updated = [item, ...filtered].slice(0, 5);
        localStorage.setItem("help_recent_views", JSON.stringify(updated));
        return updated;
      });
    }
  }, [location.pathname, title]);

  // Load recently viewed from storage
  useEffect(() => {
    try {
      const stored = localStorage.getItem("help_recent_views");
      if (stored) setRecentlyViewed(JSON.parse(stored));
    } catch {}
  }, []);

  const handleSearch = (q: string) => {
    setSearchQuery(q);
    setSearchSelectedIdx(-1);
    const results = q.trim()
      ? searchArticles(q).filter((a) => allowedCategoryIds.includes(a.categoryId)).slice(0, 10)
      : [];
    setSearchResults(results);
  };

  const navigateToResult = useCallback(
    (a: FlatArticle) => {
      setShowSearchModal(false);
      setSearchQuery("");
      setSearchResults([]);
      setSearchSelectedIdx(-1);
      navigate(`/help/${a.categoryId}/${a.slug}`);
    },
    [navigate]
  );

  // Keyboard navigation inside the search modal
  const handleSearchKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Escape") {
      setShowSearchModal(false);
      setSearchQuery("");
      setSearchResults([]);
      setSearchSelectedIdx(-1);
      return;
    }
    if (searchResults.length === 0) return;
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setSearchSelectedIdx((i) => Math.min(i + 1, searchResults.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setSearchSelectedIdx((i) => Math.max(i - 1, 0));
    } else if (e.key === "Enter" && searchSelectedIdx >= 0) {
      e.preventDefault();
      navigateToResult(searchResults[searchSelectedIdx]);
    }
  };

  const handleShare = () => {
    if (navigator.share && title) {
      navigator.share({ title: title + " — Help Center", url: window.location.href }).catch(() => {});
    } else {
      navigator.clipboard.writeText(window.location.href);
      setShareCopied(true);
      setTimeout(() => setShareCopied(false), 2000);
    }
  };

  const handlePrint = () => window.print();

  const currentPath = location.pathname;

  return (
    <div className="flex flex-1 min-h-0 bg-slate-50 dark:bg-slate-950/60 overflow-hidden relative">

      {/* Search Modal */}
      {showSearchModal && (
        <div
          className="fixed inset-0 bg-black/40 backdrop-blur-sm z-50 flex items-start justify-center pt-20 px-4"
          onClick={(e) => { if (e.target === e.currentTarget) { setShowSearchModal(false); setSearchQuery(""); setSearchResults([]); } }}
        >
          <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl max-w-2xl w-full shadow-2xl overflow-hidden">
            <div className="flex items-center gap-3 p-4 border-b border-slate-100 dark:border-slate-800">
              <Search className="h-5 w-5 text-slate-400 shrink-0" />
              <Input
                ref={searchInputRef}
                value={searchQuery}
                onChange={(e) => handleSearch(e.target.value)}
                onKeyDown={handleSearchKeyDown}
                placeholder="Search the entire documentation..."
                className="border-none focus-visible:ring-0 text-base shadow-none bg-transparent h-8 p-0"
                autoFocus
              />
              <button
                onClick={() => { setShowSearchModal(false); setSearchQuery(""); setSearchResults([]); }}
                className="text-xs font-semibold px-2 py-1 bg-slate-100 dark:bg-slate-800 text-slate-500 rounded-lg hover:text-slate-800 shrink-0"
              >
                ESC
              </button>
            </div>

            <div className="max-h-[400px] overflow-y-auto p-2 space-y-0.5">
              {searchResults.length > 0 ? (
                searchResults.map((a, idx) => (
                  <button
                    key={`${a.categoryId}-${a.slug}`}
                    onClick={() => navigateToResult(a)}
                    className={`w-full flex items-center justify-between gap-3 p-3 rounded-xl text-left transition-colors ${
                      idx === searchSelectedIdx
                        ? "bg-violet-50 dark:bg-violet-950/30"
                        : "hover:bg-slate-50 dark:hover:bg-slate-800"
                    }`}
                  >
                    <div className="min-w-0">
                      <div className="text-sm font-bold text-slate-800 dark:text-slate-200 truncate">{a.title}</div>
                      <div className="text-xs text-slate-400 mt-0.5 truncate">{a.categoryTitle} · {a.summary}</div>
                    </div>
                    <ChevronRight className="h-4 w-4 text-slate-400 shrink-0" />
                  </button>
                ))
              ) : searchQuery.trim() ? (
                <div className="text-center py-10 text-sm text-slate-400">No matching articles found.</div>
              ) : (
                <div className="p-3">
                  <div className="text-slate-400 text-xs font-bold uppercase tracking-wider mb-2">Popular Articles</div>
                  {visibleCategories.flatMap(c => c.articles.filter(a => a.popular)).slice(0, 5).map(a => {
                    const cat = visibleCategories.find(c => c.articles.some(x => x.slug === a.slug));
                    if (!cat) return null;
                    return (
                      <button
                        key={a.slug}
                        onClick={() => navigateToResult({ ...a, categoryId: cat.id, categoryTitle: cat.title })}
                        className="w-full flex items-center gap-3 p-2.5 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 text-left transition-colors"
                      >
                        <BookOpen className="h-3.5 w-3.5 text-violet-400 shrink-0" />
                        <span className="text-sm font-medium text-slate-700 dark:text-slate-300 truncate">{a.title}</span>
                      </button>
                    );
                  })}
                </div>
              )}
            </div>

            <div className="px-4 py-2.5 border-t border-slate-100 dark:border-slate-800 flex items-center gap-4 text-[10px] text-slate-400 font-semibold">
              <span className="flex items-center gap-1"><kbd className="px-1.5 py-0.5 bg-slate-100 dark:bg-slate-800 rounded text-[10px]">↑↓</kbd> navigate</span>
              <span className="flex items-center gap-1"><kbd className="px-1.5 py-0.5 bg-slate-100 dark:bg-slate-800 rounded text-[10px]">↵</kbd> open</span>
              <span className="flex items-center gap-1"><kbd className="px-1.5 py-0.5 bg-slate-100 dark:bg-slate-800 rounded text-[10px]">ESC</kbd> close</span>
            </div>
          </div>
        </div>
      )}

      {/* Mobile Sidebar Toggle */}
      <button
        onClick={() => setMobileSidebarOpen(true)}
        className="lg:hidden absolute bottom-6 right-6 h-12 w-12 rounded-full bg-violet-600 shadow-xl flex items-center justify-center text-white z-40"
      >
        <Menu className="h-5 w-5" />
      </button>

      {/* ── Left Sidebar ───────────────────────────────────────────── */}
      <aside
        className={`bg-white dark:bg-slate-900 border-r border-slate-200/80 dark:border-slate-800/80 flex-shrink-0 flex flex-col transition-all duration-200 z-30
          ${sidebarOpen ? "w-64" : "w-0 lg:w-16 overflow-hidden"}
          fixed inset-y-0 left-0 lg:static lg:block
          ${mobileSidebarOpen ? "translate-x-0 w-64" : "-translate-x-full lg:translate-x-0"}
        `}
      >
        {/* Sidebar Header */}
        <div className="h-16 px-4 border-b border-slate-100 dark:border-slate-800/60 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <BookOpen className="h-5 w-5 text-violet-600 shrink-0" />
            {sidebarOpen && <span className="font-black text-slate-800 dark:text-white text-base">Help Center</span>}
          </div>
          <div className="flex items-center gap-1.5">
            {isSuperAdmin && sidebarOpen && (
              <Link
                to="/help/cms"
                className="text-[10px] font-black uppercase tracking-widest px-2.5 py-1 bg-violet-50 text-violet-600 dark:bg-violet-950/40 dark:text-violet-400 rounded-lg"
              >
                CMS
              </Link>
            )}
            <button
              onClick={() => { setSidebarOpen(!sidebarOpen); setMobileSidebarOpen(false); }}
              className="h-8 w-8 hover:bg-slate-50 dark:hover:bg-slate-800 rounded-lg flex items-center justify-center text-slate-400 hover:text-slate-600"
            >
              {mobileSidebarOpen ? <X className="h-4 w-4" /> : sidebarOpen ? <ArrowLeft className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
            </button>
          </div>
        </div>

        {/* Search trigger */}
        {sidebarOpen && (
          <div className="px-4 py-3 shrink-0">
            <button
              onClick={() => setShowSearchModal(true)}
              className="w-full h-10 px-3 border border-slate-200 dark:border-slate-800 rounded-xl bg-slate-50 dark:bg-slate-900/50 flex items-center justify-between text-slate-400 hover:border-slate-300 dark:hover:border-slate-700 transition-colors"
            >
              <div className="flex items-center gap-2 text-xs">
                <Search className="h-3.5 w-3.5" />
                <span>Search docs...</span>
              </div>
              <span className="text-[10px] font-semibold bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 px-1.5 py-0.5 rounded shadow-sm">Ctrl+K</span>
            </button>
          </div>
        )}

        {/* Nav list */}
        <nav className="flex-1 overflow-y-auto py-2 space-y-0.5 px-3">
          {visibleCategories.map((cat) => {
            const isActiveCategory = categorySlug === cat.id;
            const Icon = (() => {
              if (cat.icon === "Rocket") return Rocket;
              if (cat.icon === "BookOpen") return BookOpen;
              if (cat.icon === "LayoutGrid") return LayoutGrid;
              if (cat.icon === "Cpu") return Cpu;
              if (cat.icon === "Code2") return Code2;
              if (cat.icon === "HelpCircle") return HelpCircle;
              if (cat.icon === "AlertTriangle") return AlertTriangle;
              if (cat.icon === "Sparkles") return Sparkles;
              if (cat.icon === "History") return History;
              return BookOpen;
            })();

            return (
              <div key={cat.id}>
                <Link
                  to={`/help/${cat.id}`}
                  className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition-colors
                    ${isActiveCategory
                      ? "bg-violet-50 dark:bg-violet-950/40 text-violet-600 dark:text-violet-400"
                      : "text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/60"
                    }`}
                >
                  <Icon className="h-4 w-4 shrink-0" />
                  {sidebarOpen && <span className="truncate flex-1">{cat.title}</span>}
                  {sidebarOpen && cat.articles.length > 0 && (
                    <span className="text-[10px] font-bold px-1.5 py-0.5 bg-slate-100 dark:bg-slate-800 text-slate-400 rounded-md">
                      {cat.articles.length}
                    </span>
                  )}
                </Link>

                {/* Sub-articles when category is active */}
                {sidebarOpen && isActiveCategory && cat.articles.length > 0 && (
                  <div className="pl-8 pr-2 space-y-0.5 border-l border-slate-100 dark:border-slate-800/80 ml-5 py-1">
                    {cat.articles.map((art) => {
                      const isArtActive = currentPath === `/help/${cat.id}/${art.slug}`;
                      return (
                        <Link
                          key={art.slug}
                          to={`/help/${cat.id}/${art.slug}`}
                          className={`block py-1.5 px-2 rounded-lg text-xs transition-colors truncate
                            ${isArtActive
                              ? "text-violet-600 dark:text-violet-400 font-bold bg-violet-50/50 dark:bg-violet-950/20"
                              : "text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200"
                            }`}
                        >
                          {art.title}
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </nav>
      </aside>

      {/* ── Main Content Area ───────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden relative">

        {/* Top Bar */}
        <header className="h-16 bg-white dark:bg-slate-900 border-b border-slate-200/80 dark:border-slate-800/80 flex items-center justify-between px-6 z-20 shrink-0 relative">
          {/* Breadcrumb */}
          <div className="flex items-center gap-2 min-w-0">
            <Link to="/help" className="text-slate-400 hover:text-slate-600 font-medium text-xs shrink-0">Help Center</Link>
            {categoryTitle && (
              <>
                <ChevronRight className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <Link to={`/help/${categorySlug}`} className="text-slate-400 hover:text-slate-600 font-medium text-xs truncate max-w-[120px]">{categoryTitle}</Link>
              </>
            )}
            {title && (
              <>
                <ChevronRight className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <span className="text-slate-800 dark:text-slate-200 font-bold text-xs truncate max-w-[200px]">{title}</span>
              </>
            )}
          </div>

          {/* Actions */}
          <div className="flex items-center gap-1 shrink-0">
            <button
              onClick={handlePrint}
              title="Print"
              className="h-9 w-9 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center justify-center text-slate-400 hover:text-slate-600 transition-colors print:hidden"
            >
              <Printer className="h-4 w-4" />
            </button>
            <button
              onClick={handleShare}
              title={shareCopied ? "Link copied!" : "Share"}
              className={`h-9 px-2.5 rounded-lg flex items-center gap-1.5 font-semibold text-xs transition-all print:hidden
                ${shareCopied
                  ? "bg-emerald-50 dark:bg-emerald-950/20 text-emerald-600"
                  : "hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-400 hover:text-slate-600"
                }`}
            >
              {shareCopied ? <Check className="h-4 w-4" /> : <Share2 className="h-4 w-4" />}
              {shareCopied && <span>Copied!</span>}
            </button>
            <button
              onClick={toggleTheme}
              className="h-9 w-9 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800 flex items-center justify-center text-slate-400 hover:text-slate-600 transition-colors"
            >
              {theme === "dark" ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            </button>
          </div>

          {/* Reading progress bar — rendered at bottom of header */}
          {articleId && (
            <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-slate-100 dark:bg-slate-800">
              <div
                className="h-full bg-violet-500 transition-all duration-100 ease-out"
                style={{ width: `${readProgress}%` }}
              />
            </div>
          )}
        </header>

        {/* Content + Right Sidebar */}
        <div className="flex-1 flex overflow-hidden">
          <main
            ref={mainScrollRef}
            className="flex-1 overflow-y-auto px-8 py-10 bg-white dark:bg-slate-900/40"
          >
            <div className="max-w-3xl mx-auto space-y-8">
              {children}
            </div>
          </main>

          {/* Right Sidebar — TOC + Recently Viewed */}
          {(toc.length > 0 || recentlyViewed.length > 0) && (
            <aside className="hidden xl:block w-64 bg-slate-50 dark:bg-slate-900/20 border-l border-slate-100 dark:border-slate-800/40 py-10 px-6 space-y-8 overflow-y-auto shrink-0">

              {/* Table of Contents */}
              {toc.length > 0 && (
                <div className="space-y-3">
                  <h4 className="text-[10px] font-black uppercase tracking-widest text-slate-400">On this page</h4>
                  <ul className="space-y-1.5 border-l border-slate-200 dark:border-slate-800">
                    {toc.map((t) => (
                      <li key={t.id} className="pl-4 -ml-px border-l border-transparent hover:border-violet-500 transition-colors">
                        <a
                          href={`#${t.id}`}
                          className="text-xs text-slate-500 hover:text-violet-600 dark:hover:text-violet-400 transition-colors leading-relaxed block"
                        >
                          {t.text}
                        </a>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Reading progress indicator */}
              {articleId && (
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <h4 className="text-[10px] font-black uppercase tracking-widest text-slate-400">Reading Progress</h4>
                    <span className="text-[10px] font-bold text-violet-600">{readProgress}%</span>
                  </div>
                  <div className="h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-violet-500 rounded-full transition-all duration-200"
                      style={{ width: `${readProgress}%` }}
                    />
                  </div>
                </div>
              )}

              {/* Recently Viewed */}
              {recentlyViewed.length > 0 && (
                <div className="space-y-3">
                  <h4 className="text-[10px] font-black uppercase tracking-widest text-slate-400">Recently Viewed</h4>
                  <ul className="space-y-2">
                    {recentlyViewed.map((item, idx) => (
                      <li key={idx} className="flex items-start gap-2">
                        <Eye className="h-3 w-3 text-slate-300 mt-1 shrink-0" />
                        <Link
                          to={item.path}
                          className="text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-violet-600 dark:hover:text-violet-400 leading-snug"
                        >
                          {item.title}
                        </Link>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Quick links */}
              <div className="space-y-3">
                <h4 className="text-[10px] font-black uppercase tracking-widest text-slate-400">Quick Resources</h4>
                <div className="flex flex-col gap-2">
                  <Link to="/help/getting-started/quick-start-guide" className="text-xs font-bold text-slate-500 hover:text-violet-600 flex items-center gap-1.5 transition-colors">
                    <Link2 className="h-3 w-3" /> Quick Start Manual
                  </Link>
                  <Link to="/help/faq/general-faq" className="text-xs font-bold text-slate-500 hover:text-violet-600 flex items-center gap-1.5 transition-colors">
                    <Link2 className="h-3 w-3" /> Common FAQs
                  </Link>
                </div>
              </div>
            </aside>
          )}
        </div>
      </div>

      {/* Mobile Backdrop */}
      {mobileSidebarOpen && (
        <div
          onClick={() => setMobileSidebarOpen(false)}
          className="fixed inset-0 bg-black/30 backdrop-blur-xs z-20 lg:hidden"
        />
      )}
    </div>
  );
}
