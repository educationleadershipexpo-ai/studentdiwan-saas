import { Link, useParams, Navigate } from "react-router-dom";
import { ArrowLeft, ArrowRight, Clock, User, FileText, ThumbsUp, ThumbsDown, Tag } from "lucide-react";
import { getArticle, getCategory, getRelatedArticles } from "@/lib/helpCenter";
import { HelpLayout } from "@/components/help/HelpLayout";
import { HelpRichContent } from "@/components/help/HelpRichContent";
import { Badge } from "@/components/ui/badge";
import { useState } from "react";

export default function HelpArticle() {
  const { categoryId, slug } = useParams<{ categoryId: string; slug: string }>();
  const category = categoryId ? getCategory(categoryId) : undefined;
  const article = category && slug ? getArticle(category.id, slug) : undefined;

  const [feedback, setFeedback] = useState<"helpful" | "not-helpful" | null>(null);

  if (!category || !article) return <Navigate to="/help" replace />;

  const currentIndex = category.articles.findIndex((a) => a.slug === slug);
  const prevArticle = currentIndex > 0 ? category.articles[currentIndex - 1] : null;
  const nextArticle = currentIndex < category.articles.length - 1 ? category.articles[currentIndex + 1] : null;

  const wordsCount = article.content.split(/\s+/).filter(Boolean).length;
  const readingTime = Math.max(1, Math.ceil(wordsCount / 200));

  const headerMatches = [...article.content.matchAll(/^##\s+(.*)$/gm)];
  const tocList = headerMatches.map((m) => {
    const text = m[1].trim();
    const id = text.toLowerCase().replace(/[^a-z0-9]+/g, "-");
    return { id, text };
  });

  const related = getRelatedArticles(category.id, article.slug, 4);

  const handleSingleDownload = () => {
    let output = `# ${article.title}\n\n`;
    output += `*Summary: ${article.summary}*\n`;
    output += `*Category: ${category.title}*\n`;
    output += `*Estimated Reading Time: ${readingTime} min*\n\n`;
    output += `---\n\n`;
    output += article.content;
    const blob = new Blob([output], { type: "text/markdown;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", `${article.slug}_guide.md`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <HelpLayout
      title={article.title}
      articleId={article.slug}
      categoryTitle={category.title}
      categorySlug={category.id}
      toc={tocList}
    >
      <div className="space-y-8 print:p-0">

        {/* Article Meta Header */}
        <div className="space-y-3 border-b border-slate-100 dark:border-slate-800 pb-6">
          <div className="flex flex-wrap items-center gap-2">
            <Badge variant="outline" className="text-[10px] font-black uppercase tracking-wider text-violet-600 dark:text-violet-400 bg-violet-50/50 dark:bg-violet-950/20 border-violet-200">
              {category.title}
            </Badge>
            {article.popular && (
              <Badge variant="secondary" className="text-[10px] font-bold bg-amber-50 text-amber-600 border-amber-200">
                Popular Topic
              </Badge>
            )}
            <button
              onClick={handleSingleDownload}
              className="ms-auto flex items-center gap-1 text-[10px] font-bold text-slate-400 hover:text-violet-600 transition-colors uppercase tracking-widest print:hidden"
            >
              <FileText className="h-3 w-3" /> Download (.md)
            </button>
          </div>

          <h1 className="text-3xl font-black tracking-tight text-slate-800 dark:text-slate-200 leading-tight">
            {article.title}
          </h1>

          <div className="flex flex-wrap items-center gap-4 text-xs text-slate-400">
            <span className="flex items-center gap-1.5 font-medium">
              <Clock className="h-3.5 w-3.5" />
              {readingTime} min read
            </span>
            <span className="flex items-center gap-1.5 font-medium">
              <User className="h-3.5 w-3.5" />
              {article.updatedBy || "Staff"}
            </span>
            {article.updatedAt && (
              <span className="font-medium">
                Updated {new Date(article.updatedAt).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })}
              </span>
            )}
          </div>

          <p className="text-slate-500 dark:text-slate-400 text-sm leading-relaxed font-semibold italic">
            {article.summary}
          </p>

          {/* Tags */}
          {article.tags && article.tags.length > 0 && (
            <div className="flex flex-wrap items-center gap-1.5 pt-1">
              <Tag className="h-3.5 w-3.5 text-slate-300 shrink-0" />
              {article.tags.map((tag) => (
                <span
                  key={tag}
                  className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 tracking-wide"
                >
                  {tag}
                </span>
              ))}
            </div>
          )}
        </div>

        {/* Article Body */}
        <div className="print:text-black">
          <HelpRichContent content={article.content} />
        </div>

        {/* Feedback Widget */}
        <div className="border-t border-slate-100 dark:border-slate-800/60 pt-8 print:hidden">
          {feedback === null ? (
            <div className="flex flex-col items-center gap-4 py-2">
              <p className="text-sm font-bold text-slate-500 dark:text-slate-400">Was this article helpful?</p>
              <div className="flex gap-3">
                <button
                  onClick={() => setFeedback("helpful")}
                  className="flex items-center gap-2 px-6 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/20 text-slate-500 hover:text-emerald-600 font-bold text-xs transition-all"
                >
                  <ThumbsUp className="h-4 w-4" /> Yes, helpful
                </button>
                <button
                  onClick={() => setFeedback("not-helpful")}
                  className="flex items-center gap-2 px-6 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/20 text-slate-500 hover:text-rose-600 font-bold text-xs transition-all"
                >
                  <ThumbsDown className="h-4 w-4" /> Not helpful
                </button>
              </div>
            </div>
          ) : feedback === "helpful" ? (
            <div className="flex flex-col items-center gap-2 py-4 rounded-2xl bg-emerald-50 dark:bg-emerald-950/20">
              <ThumbsUp className="h-5 w-5 text-emerald-600" />
              <p className="text-sm font-bold text-emerald-700 dark:text-emerald-400">Thanks for your feedback!</p>
              <p className="text-xs text-emerald-600/70 dark:text-emerald-400/70">We're glad this article was helpful.</p>
            </div>
          ) : (
            <div className="flex flex-col items-center gap-2 py-4 rounded-2xl bg-rose-50 dark:bg-rose-950/20">
              <ThumbsDown className="h-5 w-5 text-rose-500" />
              <p className="text-sm font-bold text-rose-700 dark:text-rose-400">Thanks for letting us know</p>
              <p className="text-xs text-rose-600/70 dark:text-rose-400/70">We'll work on improving this article.</p>
            </div>
          )}
        </div>

        {/* Related Articles */}
        {related.length > 0 && (
          <div className="space-y-4 border-t border-slate-100 dark:border-slate-800/60 pt-8 print:hidden">
            <h3 className="text-xs font-black uppercase tracking-widest text-slate-400">Related Articles</h3>
            <div className="grid gap-3 sm:grid-cols-2">
              {related.map((rel) => (
                <Link
                  key={`${rel.categoryId}-${rel.slug}`}
                  to={`/help/${rel.categoryId}/${rel.slug}`}
                  className="p-4 rounded-xl border border-slate-200 dark:border-slate-800 hover:border-violet-500/50 hover:bg-violet-50/30 dark:hover:bg-violet-950/10 transition-all group"
                >
                  <span className="text-[10px] font-black uppercase tracking-widest text-slate-400">{rel.categoryTitle}</span>
                  <h4 className="font-bold text-slate-700 dark:text-slate-300 text-sm mt-1 group-hover:text-violet-600 dark:group-hover:text-violet-400 transition-colors leading-snug">
                    {rel.title}
                  </h4>
                  <p className="text-xs text-slate-400 mt-1.5 line-clamp-2 leading-relaxed">{rel.summary}</p>
                </Link>
              ))}
            </div>
          </div>
        )}

        {/* Prev / Next Navigation */}
        <div className="flex flex-col sm:flex-row gap-4 pt-4 border-t border-slate-100 dark:border-slate-800/60 print:hidden">
          {prevArticle ? (
            <Link
              to={`/help/${category.id}/${prevArticle.slug}`}
              className="flex-1 flex flex-col items-start gap-1 p-4 rounded-xl border border-slate-200 hover:border-violet-500/50 hover:bg-slate-50/50 dark:border-slate-800 transition-all text-left group"
            >
              <span className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-1">
                <ArrowLeft className="h-3 w-3 group-hover:-translate-x-0.5 transition-transform" /> Previous Article
              </span>
              <span className="text-xs font-bold text-slate-700 dark:text-slate-300 truncate w-full mt-0.5">
                {prevArticle.title}
              </span>
            </Link>
          ) : (
            <div className="flex-1 hidden sm:block" />
          )}

          {nextArticle ? (
            <Link
              to={`/help/${category.id}/${nextArticle.slug}`}
              className="flex-1 flex flex-col items-end gap-1 p-4 rounded-xl border border-slate-200 hover:border-violet-500/50 hover:bg-slate-50/50 dark:border-slate-800 transition-all text-right group"
            >
              <span className="text-[10px] font-black uppercase tracking-widest text-slate-400 flex items-center gap-1">
                Next Article <ArrowRight className="h-3 w-3 group-hover:translate-x-0.5 transition-transform" />
              </span>
              <span className="text-xs font-bold text-slate-700 dark:text-slate-300 truncate w-full mt-0.5">
                {nextArticle.title}
              </span>
            </Link>
          ) : (
            <div className="flex-1 hidden sm:block" />
          )}
        </div>
      </div>
    </HelpLayout>
  );
}
