import { useState, useEffect } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { 
  FileText, Plus, Edit, Trash2, Save, ArrowLeft, Eye, 
  Settings, CheckCircle, Clock, Globe, Lock, ShieldAlert, Sparkles, FolderOpen
} from "lucide-react";
import { HELP_CENTER, HelpArticle, getAllArticles } from "@/lib/helpCenter";
import { smartDb } from "@/lib/localDb";
import { useAuth } from "@/hooks/useAuth";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Card } from "@/components/ui/card";
import { HelpLayout } from "@/components/help/HelpLayout";
import { HelpRichContent } from "@/components/help/HelpRichContent";

export default function HelpCMS() {
  const { role, user } = useAuth();
  const navigate = useNavigate();

  const isSuperAdmin = role === "admin" || role === "super_admin";

  const [articles, setArticles] = useState<HelpArticle[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingArticle, setEditingArticle] = useState<Partial<HelpArticle> | null>(null);
  const [previewMode, setPreviewMode] = useState(false);
  
  // Form fields
  const [title, setTitle] = useState("");
  const [categoryId, setCategoryId] = useState("getting-started");
  const [slug, setSlug] = useState("");
  const [summary, setSummary] = useState("");
  const [content, setContent] = useState("");
  const [status, setStatus] = useState<"published" | "draft" | "archived">("draft");
  const [tags, setTags] = useState("");
  const [seoTitle, setSeoTitle] = useState("");
  const [seoDescription, setSeoDescription] = useState("");
  const [version, setVersion] = useState(1);
  const [changeNote, setChangeNote] = useState("");
  const [historyLogs, setHistoryLogs] = useState<any[]>([]);

  // Load articles (statically defined + custom database overrides)
  const fetchArticles = async () => {
    setLoading(true);
    try {
      // 1. Load default static articles
      const staticList = getAllArticles().map(a => ({
        ...a,
        status: "published" as const,
        version: a.version || 1
      }));
      
      // 2. Load custom DB-managed articles
      const dbArticles = await smartDb.getAll("HelpArticle") as HelpArticle[];
      
      // Merge: DB overrides static if slug+category matches
      const merged = [...dbArticles];
      staticList.forEach(sa => {
        const hasDbOverride = dbArticles.some(da => da.slug === sa.slug && da.categoryId === sa.categoryId);
        if (!hasDbOverride) {
          merged.push(sa);
        }
      });

      setArticles(merged);
    } catch {
      toast.error("Failed to load CMS articles database.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (isSuperAdmin) fetchArticles();
  }, [isSuperAdmin]);

  if (!isSuperAdmin) {
    return <Navigate to="/help" replace />;
  }

  // Auto-generate slug from title
  const handleTitleChange = (val: string) => {
    setTitle(val);
    if (!editingArticle?.id) {
      setSlug(val.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, ""));
    }
  };

  // Start creating new article
  const handleAddNew = () => {
    setEditingArticle({});
    setTitle("");
    setCategoryId("getting-started");
    setSlug("");
    setSummary("");
    setContent("");
    setStatus("draft");
    setTags("");
    setSeoTitle("");
    setSeoDescription("");
    setVersion(1);
    setChangeNote("");
    setHistoryLogs([]);
  };

  // Start editing article
  const handleEdit = async (art: HelpArticle) => {
    setEditingArticle(art);
    setTitle(art.title);
    setCategoryId(art.categoryId);
    setSlug(art.slug);
    setSummary(art.summary || "");
    setContent(art.content || "");
    setStatus(art.status || "published");
    setTags(art.tags?.join(", ") || "");
    setSeoTitle(art.seoTitle || "");
    setSeoDescription(art.seoDescription || "");
    setVersion(art.version || 1);
    setChangeNote("");

    // Load edit logs for this article
    try {
      const logs = await smartDb.getAll("HelpArticleHistory") as any[];
      const articleLogs = logs.filter(l => l.articleId === art.slug || (art.id && l.articleId === art.id));
      setHistoryLogs(articleLogs);
    } catch {
      setHistoryLogs([]);
    }
  };

  // Save changes
  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !slug.trim() || !content.trim()) {
      toast.error("Please fill in the title, slug, and content.");
      return;
    }

    try {
      const tagList = tags.split(",").map(t => t.trim()).filter(Boolean);
      const isNew = !editingArticle?.id && !editingArticle?.slug;
      
      const payload: Partial<HelpArticle> = {
        title,
        categoryId,
        slug,
        summary,
        content,
        status,
        tags: tagList,
        seoTitle,
        seoDescription,
        version: isNew ? 1 : version + 1,
        updatedBy: user?.email || "Admin",
        updatedAt: new Date().toISOString(),
        createdAt: editingArticle?.createdAt || new Date().toISOString()
      };

      if (editingArticle?.id) {
        // Edit existing DB article
        await smartDb.update("HelpArticle", editingArticle.id, payload);
        
        // Log history change
        await smartDb.create("HelpArticleHistory", {
          articleId: editingArticle.id,
          title,
          content,
          summary,
          version: version + 1,
          updatedBy: user?.email || "Admin",
          updatedAt: new Date().toISOString(),
          note: changeNote || "Updated content details"
        });
      } else {
        // Check if we are overriding a static article
        const staticMatch = getAllArticles().find(sa => sa.slug === slug && sa.categoryId === categoryId);
        if (staticMatch) {
          // Create custom override record
          await smartDb.create("HelpArticle", payload);
        } else {
          // Complete new custom article
          await smartDb.create("HelpArticle", payload);
        }
      }

      toast.success("Article saved successfully!");
      setEditingArticle(null);
      fetchArticles();
    } catch {
      toast.error("Failed to save changes.");
    }
  };

  // Delete article
  const handleDelete = async (id: string | undefined, slugVal: string) => {
    if (!confirm("Are you sure you want to delete this article?")) return;
    try {
      if (id) {
        await smartDb.delete("HelpArticle", id);
        toast.success("Custom article deleted.");
      } else {
        toast.warning("Static articles cannot be deleted directly, but can be customized.");
      }
      fetchArticles();
    } catch {
      toast.error("Failed to delete article.");
    }
  };

  return (
    <HelpLayout title="CMS Admin Dashboard">
      <div className="space-y-6">
        
        {/* Navigation / Header */}
        <div className="flex items-center justify-between border-b border-slate-100 dark:border-slate-800 pb-5">
          <div className="space-y-1">
            <h1 className="text-2xl font-black text-slate-800 dark:text-slate-200 flex items-center gap-2">
              <Settings className="h-5 w-5 text-violet-600 animate-spin-slow" />
              Documentation CMS
            </h1>
            <p className="text-xs text-slate-400 font-medium">
              Manage articles, draft status, tagging setups, and audit version history.
            </p>
          </div>
          
          {editingArticle ? (
            <button
              onClick={() => setEditingArticle(null)}
              className="h-10 px-4 rounded-xl border border-slate-200 text-slate-500 hover:bg-slate-50 text-xs font-bold flex items-center gap-1.5"
            >
              <ArrowLeft className="h-3.5 w-3.5" /> Back to Dashboard
            </button>
          ) : (
            <button
              onClick={handleAddNew}
              className="h-10 px-5 bg-violet-600 hover:bg-violet-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-lg shadow-violet-100 dark:shadow-none"
            >
              <Plus className="h-4 w-4" /> Create Article
            </button>
          )}
        </div>

        {/* ── Composing Screen (Edit Form) ──────────────────────── */}
        {editingArticle ? (
          <form onSubmit={handleSave} className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            
            {/* Editor Input Area */}
            <div className="lg:col-span-2 space-y-5">
              <Card className="p-6 space-y-4">
                <div className="grid gap-2">
                  <label className="text-[10px] font-black uppercase text-slate-400">Article Title</label>
                  <Input 
                    value={title}
                    onChange={(e) => handleTitleChange(e.target.value)}
                    placeholder="Enter descriptive title..."
                    className="h-11 rounded-xl"
                    required
                  />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <label className="text-[10px] font-black uppercase text-slate-400">Category Directory</label>
                    <select
                      value={categoryId}
                      onChange={(e) => setCategoryId(e.target.value)}
                      className="h-11 px-3 rounded-xl border border-slate-200 bg-transparent text-sm font-semibold focus:outline-none focus:ring-1 focus:ring-violet-500"
                    >
                      {HELP_CENTER.map(c => (
                        <option key={c.id} value={c.id}>{c.title}</option>
                      ))}
                    </select>
                  </div>

                  <div className="grid gap-2">
                    <label className="text-[10px] font-black uppercase text-slate-400">Slug path (URL)</label>
                    <Input 
                      value={slug}
                      onChange={(e) => setSlug(e.target.value)}
                      placeholder="e.g. initial-setup"
                      className="h-11 rounded-xl"
                      required
                    />
                  </div>
                </div>

                <div className="grid gap-2">
                  <label className="text-[10px] font-black uppercase text-slate-400">One-line Summary</label>
                  <textarea 
                    value={summary}
                    onChange={(e) => setSummary(e.target.value)}
                    placeholder="Brief description shown in index listings..."
                    className="w-full h-16 p-3 text-sm border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-violet-500 bg-transparent"
                  />
                </div>

                <div className="grid gap-2">
                  <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                    <label className="text-[10px] font-black uppercase text-slate-400">Markdown Content Body</label>
                    <button
                      type="button"
                      onClick={() => setPreviewMode(!previewMode)}
                      className="text-xs text-violet-600 font-bold hover:underline flex items-center gap-1"
                    >
                      <Eye className="h-3 w-3" /> {previewMode ? "Edit Markdown" : "Live Preview"}
                    </button>
                  </div>

                  {previewMode ? (
                    <div className="border border-slate-200 rounded-xl p-4 min-h-[300px] max-h-[500px] overflow-y-auto">
                      <HelpRichContent content={content || "*No content written yet.*"} />
                    </div>
                  ) : (
                    <textarea 
                      value={content}
                      onChange={(e) => setContent(e.target.value)}
                      placeholder="Compose markdown documentation..."
                      className="w-full min-h-[300px] p-4 text-sm font-mono border border-slate-200 rounded-xl focus:outline-none focus:ring-1 focus:ring-violet-500 bg-transparent leading-relaxed"
                      required
                    />
                  )}
                </div>
              </Card>
            </div>

            {/* Editor Sidebar Settings */}
            <div className="space-y-5">
              
              {/* Publication details */}
              <Card className="p-5 space-y-4">
                <h3 className="font-bold text-sm text-slate-800 border-b border-slate-100 pb-2">Publication Settings</h3>
                
                <div className="grid gap-1.5">
                  <label className="text-[10px] font-black uppercase text-slate-400">Status</label>
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value as any)}
                    className="h-10 px-3 rounded-xl border border-slate-200 bg-transparent text-xs font-semibold focus:outline-none focus:ring-1"
                  >
                    <option value="draft">Draft</option>
                    <option value="published">Published</option>
                    <option value="archived">Archived</option>
                  </select>
                </div>

                <div className="grid gap-1.5">
                  <label className="text-[10px] font-black uppercase text-slate-400">Tags (Comma separated)</label>
                  <Input 
                    value={tags}
                    onChange={(e) => setTags(e.target.value)}
                    placeholder="e.g. fees, invoicing, billing"
                    className="h-10 text-xs rounded-xl"
                  />
                </div>

                {!editingArticle?.id ? null : (
                  <div className="grid gap-1.5">
                    <label className="text-[10px] font-black uppercase text-slate-400">Audit Change Note</label>
                    <Input 
                      value={changeNote}
                      onChange={(e) => setChangeNote(e.target.value)}
                      placeholder="e.g. Fixed typo in code block"
                      className="h-10 text-xs rounded-xl"
                    />
                  </div>
                )}

                <Button 
                  type="submit"
                  className="w-full h-11 bg-violet-600 hover:bg-violet-700 text-white font-bold rounded-xl text-xs gap-1.5"
                >
                  <Save className="h-4 w-4" /> Save Article
                </Button>
              </Card>

              {/* SEO details */}
              <Card className="p-5 space-y-4">
                <h3 className="font-bold text-sm text-slate-800 border-b border-slate-100 pb-2">SEO Configurations</h3>
                
                <div className="grid gap-1.5">
                  <label className="text-[10px] font-black uppercase text-slate-400">Meta Title</label>
                  <Input 
                    value={seoTitle}
                    onChange={(e) => setSeoTitle(e.target.value)}
                    placeholder="Search engine meta title..."
                    className="h-10 text-xs rounded-xl"
                  />
                </div>

                <div className="grid gap-1.5">
                  <label className="text-[10px] font-black uppercase text-slate-400">Meta Description</label>
                  <textarea 
                    value={seoDescription}
                    onChange={(e) => setSeoDescription(e.target.value)}
                    placeholder="Short meta description..."
                    className="w-full h-16 p-3 text-xs border border-slate-200 rounded-xl bg-transparent"
                  />
                </div>
              </Card>

              {/* Edit Version History Logs */}
              {historyLogs.length > 0 && (
                <Card className="p-5 space-y-3">
                  <h3 className="font-bold text-sm text-slate-800 border-b border-slate-100 pb-2 flex items-center gap-1.5">
                    <Clock className="h-4 w-4 text-slate-400" /> Version History
                  </h3>
                  <div className="space-y-3 max-h-48 overflow-y-auto">
                    {historyLogs.map((log, idx) => (
                      <div key={idx} className="text-xs border-l-2 border-violet-500 pl-3 space-y-1">
                        <div className="font-bold text-slate-700">Version {log.version}</div>
                        <p className="text-slate-400">{log.note}</p>
                        <div className="text-[10px] text-slate-400">
                          {log.updatedBy} · {new Date(log.updatedAt).toLocaleDateString()}
                        </div>
                      </div>
                    ))}
                  </div>
                </Card>
              )}
            </div>
          </form>
        ) : (
          
          // ── Articles Directory Dashboard ───────────────────────
          <div className="space-y-4">
            
            {/* List Overview Card */}
            <Card className="overflow-hidden border-slate-200">
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-100 text-sm">
                  <thead className="bg-slate-50">
                    <tr>
                      <th className="px-6 py-4 text-left font-black uppercase tracking-wider text-[10px] text-slate-400">Article Title</th>
                      <th className="px-6 py-4 text-left font-black uppercase tracking-wider text-[10px] text-slate-400">Category Directory</th>
                      <th className="px-6 py-4 text-left font-black uppercase tracking-wider text-[10px] text-slate-400">Status</th>
                      <th className="px-6 py-4 text-left font-black uppercase tracking-wider text-[10px] text-slate-400">Version</th>
                      <th className="px-6 py-4 text-right font-black uppercase tracking-wider text-[10px] text-slate-400">Actions</th>
                    </tr>
                  </thead>
                  
                  <tbody className="divide-y divide-slate-100 bg-white">
                    {articles.map((art) => {
                      const catName = HELP_CENTER.find(c => c.id === art.categoryId)?.title || art.categoryId;
                      return (
                        <tr key={`${art.categoryId}-${art.slug}`} className="hover:bg-slate-50/50 transition-colors">
                          <td className="px-6 py-4">
                            <div className="font-bold text-slate-800">{art.title}</div>
                            <div className="text-xs text-slate-400 mt-0.5 truncate max-w-[280px]">/help/{art.categoryId}/{art.slug}</div>
                          </td>
                          
                          <td className="px-6 py-4 text-xs font-semibold text-slate-500">
                            {catName}
                          </td>
                          
                          <td className="px-6 py-4">
                            <Badge 
                              variant="outline" 
                              className={`text-[10px] uppercase font-black px-2 py-0.5
                                ${art.status === "published" 
                                  ? 'bg-emerald-50 text-emerald-600 border-emerald-200' 
                                  : 'bg-amber-50 text-amber-600 border-amber-200'}`}
                            >
                              {art.status || "published"}
                            </Badge>
                          </td>

                          <td className="px-6 py-4 text-xs font-bold text-slate-500">
                            v{art.version || 1}
                          </td>

                          <td className="px-6 py-4 text-right space-x-2">
                            <button
                              onClick={() => handleEdit(art)}
                              className="h-8 w-8 hover:bg-slate-100 rounded-lg inline-flex items-center justify-center text-slate-500 hover:text-slate-800 transition-colors"
                              title="Edit Article"
                            >
                              <Edit className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => handleDelete(art.id, art.slug)}
                              disabled={!art.id}
                              className="h-8 w-8 hover:bg-rose-50 rounded-lg inline-flex items-center justify-center text-slate-400 hover:text-rose-600 transition-colors disabled:opacity-30"
                              title={art.id ? "Delete Article" : "Static articles cannot be deleted directly"}
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </Card>
          </div>
        )}
      </div>
    </HelpLayout>
  );
}
