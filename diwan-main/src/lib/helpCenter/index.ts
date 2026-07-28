import type { HelpArticle, HelpCategory } from "./types";
import { HELP_CATEGORIES } from "./categories";
import { gettingStartedArticles } from "./articles/gettingStarted";
import { userGuidesArticles } from "./articles/userGuides";
import { modulesArticles } from "./articles/modules";
import { systemAdminArticles } from "./articles/systemAdmin";
import { developerDocsArticles } from "./articles/developerDocs";
import { faqTroubleshootingArticles } from "./articles/faqTroubleshooting";
import { releaseNotesChangelogArticles } from "./articles/releaseNotesChangelog";

const ARTICLES_BY_CATEGORY: Record<string, HelpArticle[]> = {
  "getting-started": gettingStartedArticles,
  "user-guides": userGuidesArticles,
  "modules": modulesArticles,
  "system-admin": systemAdminArticles,
  "developer-docs": developerDocsArticles,
  "faq": faqTroubleshootingArticles.filter(a => a.categoryId === "faq"),
  "troubleshooting": faqTroubleshootingArticles.filter(a => a.categoryId === "troubleshooting"),
  "release-notes": releaseNotesChangelogArticles.filter(a => a.categoryId === "release-notes"),
  "changelog": releaseNotesChangelogArticles.filter(a => a.categoryId === "changelog"),
};

export const HELP_CENTER: HelpCategory[] = HELP_CATEGORIES.map((cat) => ({
  ...cat,
  articles: ARTICLES_BY_CATEGORY[cat.id] || [],
}));

export function getCategory(categoryId: string): HelpCategory | undefined {
  return HELP_CENTER.find((c) => c.id === categoryId);
}

export function getArticle(categoryId: string, slug: string): HelpArticle | undefined {
  return getCategory(categoryId)?.articles.find((a) => a.slug === slug);
}

export interface FlatArticle extends HelpArticle {
  categoryId: string;
  categoryTitle: string;
}

export function getAllArticles(): FlatArticle[] {
  return HELP_CENTER.flatMap((cat) =>
    cat.articles.map((a) => ({ ...a, categoryId: cat.id, categoryTitle: cat.title }))
  );
}

export function getPopularArticles(limit = 6): FlatArticle[] {
  return getAllArticles().filter((a) => a.popular).slice(0, limit);
}

/** Case-insensitive substring search across title, summary, content, and keywords. */
export function searchArticles(query: string): FlatArticle[] {
  const q = query.trim().toLowerCase();
  if (!q) return [];
  return getAllArticles().filter((a) => {
    const haystack = [a.title, a.summary, a.content, a.categoryTitle, ...(a.keywords || [])].join(" ").toLowerCase();
    return haystack.includes(q);
  });
}

/** Returns up to `limit` articles related to the given article by shared tags/keywords. */
export function getRelatedArticles(categoryId: string, slug: string, limit = 4): FlatArticle[] {
  const article = getArticle(categoryId, slug);
  if (!article) return [];
  const sourceTags = new Set([...(article.tags ?? []), ...(article.keywords ?? [])]);

  const scored = getAllArticles()
    .filter(a => !(a.categoryId === categoryId && a.slug === slug))
    .map(a => {
      const aTags = [...(a.tags ?? []), ...(a.keywords ?? [])];
      return { a, score: aTags.filter(t => sourceTags.has(t)).length };
    });

  const withMatches = scored.filter(x => x.score > 0).sort((x, y) => y.score - x.score);
  const results = withMatches.slice(0, limit).map(x => x.a);

  // Fallback: fill with same-category articles if not enough matches
  if (results.length < limit) {
    const sameCat = getAllArticles()
      .filter(a => a.categoryId === categoryId && a.slug !== slug && !results.some(r => r.slug === a.slug));
    results.push(...sameCat.slice(0, limit - results.length));
  }

  return results;
}

export type { HelpArticle, HelpCategory };
