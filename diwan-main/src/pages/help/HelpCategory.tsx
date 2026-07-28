import { useState } from "react";
import { Link, useParams, Navigate } from "react-router-dom";
import { ArrowRight, Sparkles, ChevronDown, ChevronUp, Search, Lock } from "lucide-react";
import { getCategory } from "@/lib/helpCenter";
import { HelpLayout } from "@/components/help/HelpLayout";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/hooks/useAuth";
import { canAccessCategory } from "@/lib/helpCenter/roleAccess";

export default function HelpCategory() {
  const { categoryId } = useParams<{ categoryId: string }>();
  const { role } = useAuth();
  const category = categoryId ? getCategory(categoryId) : undefined;

  const [openSlug, setOpenSlug] = useState<string | null>(null);
  const [faqSearch, setFaqSearch] = useState("");

  if (!category) return <Navigate to="/help" replace />;

  if (!canAccessCategory(role, category.id)) {
    return (
      <HelpLayout categoryTitle={category.title} categorySlug={category.id}>
        <div className="flex flex-col items-center justify-center py-24 text-center space-y-4">
          <div className="h-14 w-14 rounded-2xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
            <Lock className="h-6 w-6 text-slate-400" />
          </div>
          <h2 className="text-lg font-black text-slate-800 dark:text-slate-100">Access Restricted</h2>
          <p className="text-sm text-slate-500 dark:text-slate-400 max-w-xs leading-relaxed">
            The <strong>{category.title}</strong> section is not available for your current role.
            Contact your administrator if you need access.
          </p>
          <Link
            to="/help"
            className="inline-flex items-center gap-2 h-9 px-5 rounded-xl bg-violet-600 hover:bg-violet-500 text-white text-sm font-bold transition-colors"
          >
            Back to Help Center
          </Link>
        </div>
      </HelpLayout>
    );
  }

  const isFaq = category.id === "faq";

  const filteredArticles = isFaq && faqSearch.trim()
    ? category.articles.filter(
        (a) =>
          a.title.toLowerCase().includes(faqSearch.toLowerCase()) ||
          a.summary.toLowerCase().includes(faqSearch.toLowerCase())
      )
    : category.articles;

  return (
    <HelpLayout categoryTitle={category.title} categorySlug={category.id}>
      <div className="space-y-8">

        {/* Header */}
        <div className="space-y-2 border-b border-slate-100 dark:border-slate-800 pb-5">
          <h1 className="text-2xl font-black tracking-tight text-slate-800 dark:text-slate-200">
            {category.title}
          </h1>
          <p className="text-slate-500 dark:text-slate-400 text-sm leading-relaxed max-w-xl">
            {category.description}
          </p>
        </div>

        {category.articles.length === 0 ? (
          <div className="text-center py-16 rounded-2xl border border-dashed border-slate-200 dark:border-slate-800">
            <Sparkles className="h-8 w-8 text-slate-300 mx-auto mb-3" />
            <h3 className="font-bold text-slate-700 dark:text-slate-300 text-sm">No articles published yet</h3>
            <p className="text-xs text-slate-400 mt-1">Articles for this module will appear here once drafted and published.</p>
          </div>
        ) : isFaq ? (
          /* ── FAQ Accordion View ──────────────────────────────── */
          <div className="space-y-4">
            {/* Search within FAQ */}
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 pointer-events-none" />
              <Input
                value={faqSearch}
                onChange={(e) => { setFaqSearch(e.target.value); setOpenSlug(null); }}
                placeholder="Search FAQs..."
                className="pl-9 h-11 rounded-xl border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900"
              />
            </div>

            {filteredArticles.length === 0 ? (
              <div className="text-center py-10 text-sm text-slate-400">No FAQs match your search.</div>
            ) : (
              <div className="space-y-2">
                {filteredArticles.map((a) => {
                  const isOpen = openSlug === a.slug;
                  return (
                    <div
                      key={a.slug}
                      className={`border rounded-xl overflow-hidden transition-all duration-200 ${
                        isOpen
                          ? "border-violet-300 dark:border-violet-700 shadow-sm shadow-violet-100 dark:shadow-none"
                          : "border-slate-200 dark:border-slate-800 hover:border-slate-300 dark:hover:border-slate-700"
                      }`}
                    >
                      <button
                        onClick={() => setOpenSlug(isOpen ? null : a.slug)}
                        className="w-full flex items-center justify-between gap-4 px-5 py-4 text-left bg-white dark:bg-slate-900 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors"
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <span className={`text-xs font-black uppercase tracking-widest shrink-0 ${isOpen ? "text-violet-500" : "text-slate-400"}`}>
                            FAQ
                          </span>
                          <h3 className={`font-bold text-sm leading-snug ${isOpen ? "text-violet-700 dark:text-violet-300" : "text-slate-800 dark:text-slate-200"}`}>
                            {a.title}
                          </h3>
                        </div>
                        {isOpen
                          ? <ChevronUp className="h-4 w-4 text-violet-500 shrink-0" />
                          : <ChevronDown className="h-4 w-4 text-slate-400 shrink-0" />
                        }
                      </button>

                      {isOpen && (
                        <div className="px-5 pb-5 pt-1 bg-white dark:bg-slate-900 border-t border-slate-100 dark:border-slate-800/60">
                          <p className="text-sm text-slate-500 dark:text-slate-400 leading-relaxed mb-4">
                            {a.summary}
                          </p>
                          <Link
                            to={`/help/${category.id}/${a.slug}`}
                            className="inline-flex items-center gap-1.5 text-xs font-bold text-violet-600 dark:text-violet-400 hover:underline"
                          >
                            Read full article <ArrowRight className="h-3 w-3" />
                          </Link>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}

            {/* Link to all FAQ articles */}
            <p className="text-xs text-slate-400 text-center pt-2">
              Can't find your answer?{" "}
              <Link to="/help/troubleshooting" className="text-violet-600 dark:text-violet-400 font-bold hover:underline">
                Browse Troubleshooting →
              </Link>
            </p>
          </div>
        ) : (
          /* ── Standard Article Cards ──────────────────────────── */
          <div className="grid gap-4 sm:grid-cols-2">
            {category.articles.map((a) => (
              <Link key={a.slug} to={`/help/${category.id}/${a.slug}`}>
                <Card className="p-5 h-full flex flex-col gap-2 hover:border-violet-500/50 hover:shadow-lg hover:shadow-slate-100 dark:hover:shadow-none transition-all duration-200">
                  <div className="flex items-center justify-between">
                    <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Article</span>
                    {a.popular && (
                      <Badge variant="secondary" className="text-[10px] font-bold bg-violet-50 text-violet-600 dark:bg-violet-950/20 dark:text-violet-400">
                        Popular
                      </Badge>
                    )}
                  </div>
                  <h3 className="font-bold text-slate-800 dark:text-slate-200 text-base leading-snug">{a.title}</h3>
                  <p className="text-slate-500 dark:text-slate-400 text-xs leading-relaxed mt-0.5">{a.summary}</p>
                  <div className="mt-auto pt-3 flex items-center gap-1 text-[10px] font-bold text-violet-600 uppercase tracking-widest">
                    <span>Read Article</span>
                    <ArrowRight className="h-3 w-3" />
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        )}
      </div>
    </HelpLayout>
  );
}
