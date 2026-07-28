// Content model for the in-app Help Center (src/pages/help/*).
export interface HelpArticle {
  id?: string;
  /** Unique within its category; forms the URL /help/:categoryId/:slug */
  slug: string;
  title: string;
  categoryId: string;
  /** One-line description shown in listings and search results. */
  summary: string;
  /** Markdown body (rendered via ReactMarkdown). */
  content: string;
  /** Lowercased search keywords beyond title/summary (synonyms, feature names). */
  keywords?: string[];
  /** Shown in the Help Center home page's "Popular articles" rail. */
  popular?: boolean;
  /** Publishing state for CMS */
  status: 'published' | 'draft' | 'archived';
  /** Tags for organization and SEO search */
  tags?: string[];
  /** Document version number for history tracking */
  version: number;
  /** Audit tracking */
  updatedBy?: string;
  createdAt?: string;
  updatedAt?: string;
  /** SEO specific overrides */
  seoTitle?: string;
  seoDescription?: string;
}

export interface HelpCategory {
  id: string;
  title: string;
  /** Short description shown on the category card / header. */
  description: string;
  /** lucide-react icon component name, resolved in HelpHome/HelpCategory. */
  icon: string;
  articles: HelpArticle[];
}

export interface EditHistoryEntry {
  id: string;
  articleId: string;
  title: string;
  content: string;
  summary: string;
  version: number;
  updatedBy: string;
  updatedAt: string;
  note?: string;
}
