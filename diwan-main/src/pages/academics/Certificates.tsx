import { useState, useMemo, useEffect, useRef } from "react";
import { DashboardLayout } from "@/components/layout/DashboardLayout";
import { useStudents } from "@/contexts/StudentContext";
import { smartDb } from "@/lib/localDb";
import { getPrincipalName } from "@/lib/reportCardStore";
import {
  Award, Download, Plus, Search, Printer, Eye, X, FileDown,
  ChevronDown, GraduationCap, Star, CheckCircle,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { toast } from "sonner";
import * as XLSX from "xlsx";
import jsPDF from "jspdf";
import { useTranslation } from "react-i18next";

// ── Constants ────────────────────────────────────────────────────────────────
const CERT_TYPES = [
  "Academic Excellence",
  "Perfect Attendance",
  "Sports Achievement",
  "Cultural Achievement",
  "Best Student",
  "Merit Certificate",
  "Participation",
  "Special Award",
];

// Default title autofill when a type is selected
const TYPE_DEFAULT_TITLES: Record<string, string> = {
  "Academic Excellence":  "Outstanding Academic Performance",
  "Perfect Attendance":   "100% Attendance Achievement",
  "Sports Achievement":   "Excellence in Sports",
  "Cultural Achievement": "Excellence in Cultural Activities",
  "Best Student":         "Best Student of the Year",
  "Merit Certificate":    "Merit Award for Excellence",
  "Participation":        "Active Participation Certificate",
  "Special Award":        "Special Recognition Award",
};

const CERT_TYPE_LABEL_KEYS: Record<string, string> = {
  "Academic Excellence":  "admin.academics.certificates.typeAcademicExcellence",
  "Perfect Attendance":   "admin.academics.certificates.typePerfectAttendance",
  "Sports Achievement":   "admin.academics.certificates.typeSportsAchievement",
  "Cultural Achievement": "admin.academics.certificates.typeCulturalAchievement",
  "Best Student":         "admin.academics.certificates.typeBestStudent",
  "Merit Certificate":    "admin.academics.certificates.typeMeritCertificate",
  "Participation":        "admin.academics.certificates.typeParticipation",
  "Special Award":        "admin.academics.certificates.typeSpecialAward",
};

const TYPE_COLORS: Record<string, string> = {
  "Academic Excellence":  "bg-yellow-100 text-yellow-700",
  "Perfect Attendance":   "bg-green-100 text-green-700",
  "Sports Achievement":   "bg-blue-100 text-blue-700",
  "Cultural Achievement": "bg-purple-100 text-purple-700",
  "Best Student":         "bg-rose-100 text-rose-700",
  "Merit Certificate":    "bg-indigo-100 text-indigo-700",
  "Participation":        "bg-slate-100 text-slate-600",
  "Special Award":        "bg-orange-100 text-orange-700",
};

const TYPE_ACCENT: Record<string, { primary: string; light: string; text: string }> = {
  "Academic Excellence":  { primary: "#d97706", light: "#fef3c7", text: "#92400e" },
  "Perfect Attendance":   { primary: "#16a34a", light: "#dcfce7", text: "#14532d" },
  "Sports Achievement":   { primary: "#2563eb", light: "#dbeafe", text: "#1e3a8a" },
  "Cultural Achievement": { primary: "#7c3aed", light: "#ede9fe", text: "#4c1d95" },
  "Best Student":         { primary: "#e11d48", light: "#ffe4e6", text: "#881337" },
  "Merit Certificate":    { primary: "#4f46e5", light: "#e0e7ff", text: "#312e81" },
  "Participation":        { primary: "#475569", light: "#f1f5f9", text: "#1e293b" },
  "Special Award":        { primary: "#ea580c", light: "#ffedd5", text: "#7c2d12" },
};

interface Certificate {
  id: string;
  studentId: string;
  studentName: string;
  grade: string;
  section: string;
  type: string;
  title: string;
  issuedDate: string;
  issuedBy: string;
  description: string;
  printed: boolean;
}

// ── Searchable Student Picker ─────────────────────────────────────────────────
function StudentPicker({
  students,
  value,
  onChange,
}: {
  students: any[];
  value: string;
  onChange: (id: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [gradeFilter, setGradeFilter] = useState("all");
  const ref = useRef<HTMLDivElement>(null);

  const grades = useMemo(
    () => Array.from(new Set(students.map((s) => s.grade || "").filter(Boolean))).sort(),
    [students]
  );

  const filtered = useMemo(() => {
    const q = query.toLowerCase();
    return students
      .filter((s) => gradeFilter === "all" || s.grade === gradeFilter)
      .filter(
        (s) =>
          !q ||
          (s.name || "").toLowerCase().includes(q) ||
          (s.rollNo || "").toString().toLowerCase().includes(q)
      )
      .slice(0, 60);
  }, [students, query, gradeFilter]);

  const selected = students.find((s) => (s.id || s.uid) === value);

  // Close on outside click
  useEffect(() => {
    function handle(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", handle);
    return () => document.removeEventListener("mousedown", handle);
  }, []);

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "w-full h-10 px-3 rounded-xl border text-sm text-left flex items-center justify-between outline-none transition-all",
          open
            ? "border-purple-400 ring-2 ring-purple-100"
            : "border-slate-200 hover:border-slate-300",
          value ? "text-slate-800" : "text-slate-400"
        )}
      >
        <span className="truncate">
          {selected ? `${selected.name} — ${selected.grade}${selected.section ? ` ${selected.section}` : ""}` : "Search and select student…"}
        </span>
        <ChevronDown className={cn("h-4 w-4 text-slate-400 flex-shrink-0 transition-transform", open && "rotate-180")} />
      </button>

      {open && (
        <div className="absolute z-50 top-full mt-1 left-0 right-0 bg-white border border-slate-200 rounded-xl shadow-xl overflow-hidden">
          {/* Filters */}
          <div className="p-2 border-b border-slate-100 space-y-2">
            <div className="relative">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400" />
              <input
                autoFocus
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search by name or roll no…"
                className="w-full h-8 pl-8 pr-3 rounded-lg border border-slate-200 text-sm outline-none focus:ring-2 focus:ring-purple-200"
              />
            </div>
            <select
              value={gradeFilter}
              onChange={(e) => setGradeFilter(e.target.value)}
              className="w-full h-8 px-2 rounded-lg border border-slate-200 text-xs text-slate-700 outline-none focus:ring-2 focus:ring-purple-200 bg-white"
            >
              <option value="all">All Grades</option>
              {grades.map((g) => (
                <option key={g} value={g}>{g}</option>
              ))}
            </select>
          </div>
          {/* Results */}
          <div className="max-h-48 overflow-y-auto">
            {filtered.length === 0 ? (
              <div className="px-4 py-3 text-sm text-slate-400 text-center">No students found</div>
            ) : (
              filtered.map((s) => (
                <button
                  key={s.id || s.uid}
                  type="button"
                  onClick={() => { onChange(s.id || s.uid); setOpen(false); setQuery(""); }}
                  className={cn(
                    "w-full text-left px-3 py-2 text-sm hover:bg-purple-50 flex items-center justify-between transition-colors",
                    (s.id || s.uid) === value && "bg-purple-50"
                  )}
                >
                  <span className="font-medium text-slate-800">{s.name}</span>
                  <span className="text-xs text-slate-400">{s.grade}{s.section ? ` · ${s.section}` : ""}</span>
                </button>
              ))
            )}
          </div>
          {filtered.length === 60 && (
            <div className="px-4 py-2 border-t border-slate-100 text-xs text-slate-400 text-center">
              Showing first 60 results — refine your search
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ── Premium PDF Generator ─────────────────────────────────────────────────────
function generateCertificatePDF(cert: Certificate) {
  const doc = new jsPDF({ orientation: "landscape", unit: "mm", format: "a4" });
  const W = doc.internal.pageSize.getWidth();   // 297mm
  const H = doc.internal.pageSize.getHeight();  // 210mm

  const accent = TYPE_ACCENT[cert.type] || TYPE_ACCENT["Merit Certificate"];
  const [pr, pg, pb] = hexToRgb(accent.primary);
  const [lr, lg, lb] = hexToRgb(accent.light);

  // ── Background wash ────────────────────────────────────────────────────────
  doc.setFillColor(lr, lg, lb);
  doc.rect(0, 0, W, H, "F");

  // ── Outer double border ────────────────────────────────────────────────────
  doc.setDrawColor(pr, pg, pb);
  doc.setLineWidth(5);
  doc.rect(6, 6, W - 12, H - 12);
  doc.setLineWidth(1.2);
  doc.rect(11, 11, W - 22, H - 22);

  // ── Corner ornament squares ────────────────────────────────────────────────
  const corners = [[14, 14], [W - 22, 14], [14, H - 22], [W - 22, H - 22]] as const;
  corners.forEach(([cx, cy]) => {
    doc.setFillColor(pr, pg, pb);
    doc.rect(cx, cy, 8, 8, "F");
  });

  // ── Top decorative band ────────────────────────────────────────────────────
  doc.setFillColor(pr, pg, pb);
  doc.rect(11, 11, W - 22, 14, "F");

  // School name in band
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(9);
  doc.setFont("helvetica", "bold");
  doc.text("STUDENT DIWAN — ACADEMIC EXCELLENCE PROGRAM", W / 2, 20, { align: "center" });

  // ── Certificate type ribbon ────────────────────────────────────────────────
  const typeText = cert.type.toUpperCase();
  doc.setFontSize(10);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(pr, pg, pb);
  doc.text(typeText, W / 2, 38, { align: "center" });

  // Decorative lines around type
  const typeW = doc.getTextWidth(typeText);
  doc.setDrawColor(pr, pg, pb);
  doc.setLineWidth(0.5);
  doc.line(W / 2 - typeW / 2 - 15, 38, W / 2 - typeW / 2 - 5, 38);
  doc.line(W / 2 + typeW / 2 + 5, 38, W / 2 + typeW / 2 + 15, 38);

  // ── Main heading ───────────────────────────────────────────────────────────
  doc.setFontSize(36);
  doc.setFont("times", "bold");
  doc.setTextColor(30, 30, 30);
  doc.text("Certificate", W / 2, 56, { align: "center" });

  // Underline flourish
  doc.setDrawColor(pr, pg, pb);
  doc.setLineWidth(1.5);
  doc.line(W / 2 - 38, 59, W / 2 + 38, 59);

  // ── Presented to ──────────────────────────────────────────────────────────
  doc.setFontSize(11);
  doc.setFont("times", "italic");
  doc.setTextColor(80, 80, 80);
  doc.text("This is proudly presented to", W / 2, 70, { align: "center" });

  // ── Student name ───────────────────────────────────────────────────────────
  doc.setFontSize(28);
  doc.setFont("times", "bold");
  doc.setTextColor(pr, pg, pb);
  doc.text(cert.studentName, W / 2, 84, { align: "center" });

  // Student info
  doc.setFontSize(11);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(100, 100, 100);
  const gradeText = cert.grade + (cert.section ? ` · Section ${cert.section}` : "");
  doc.text(gradeText, W / 2, 92, { align: "center" });

  // ── Award title ────────────────────────────────────────────────────────────
  doc.setFontSize(13);
  doc.setFont("times", "bold");
  doc.setTextColor(40, 40, 40);
  doc.text(`for ${cert.title}`, W / 2, 106, { align: "center" });

  // ── Description ────────────────────────────────────────────────────────────
  if (cert.description) {
    doc.setFontSize(10);
    doc.setFont("times", "italic");
    doc.setTextColor(100, 100, 100);
    const lines = doc.splitTextToSize(cert.description, W - 80);
    doc.text(lines, W / 2, 116, { align: "center" });
  }

  // ── Signature section ──────────────────────────────────────────────────────
  const sigY = H - 38;
  // Left: Principal
  doc.setDrawColor(100, 100, 100);
  doc.setLineWidth(0.6);
  doc.line(40, sigY, 105, sigY);
  doc.setFontSize(10);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(40, 40, 40);
  doc.text(cert.issuedBy, 72, sigY + 7, { align: "center" });
  doc.setFontSize(8.5);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(120, 120, 120);
  doc.text("Principal / Authorized Signatory", 72, sigY + 13, { align: "center" });

  // Center seal placeholder
  doc.setDrawColor(pr, pg, pb);
  doc.setLineWidth(1.5);
  doc.circle(W / 2, sigY + 3, 12);
  doc.setFontSize(6);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(pr, pg, pb);
  doc.text("OFFICIAL", W / 2, sigY + 1.5, { align: "center" });
  doc.text("SEAL", W / 2, sigY + 5.5, { align: "center" });

  // Right: Date
  doc.setDrawColor(100, 100, 100);
  doc.setLineWidth(0.6);
  doc.line(W - 105, sigY, W - 40, sigY);
  doc.setFontSize(10);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(40, 40, 40);
  doc.text(cert.issuedDate, W - 72, sigY + 7, { align: "center" });
  doc.setFontSize(8.5);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(120, 120, 120);
  doc.text("Date of Issue", W - 72, sigY + 13, { align: "center" });

  // ── Bottom band ────────────────────────────────────────────────────────────
  doc.setFillColor(pr, pg, pb);
  doc.rect(11, H - 22, W - 22, 11, "F");
  doc.setFontSize(7.5);
  doc.setFont("helvetica", "normal");
  doc.setTextColor(255, 255, 255);
  doc.text(`Certificate ID: ${cert.id}   ·   Issued by Student Diwan ERP   ·   portal.studentdiwan.com`, W / 2, H - 15.5, { align: "center" });

  return doc;
}

function hexToRgb(hex: string): [number, number, number] {
  const h = hex.replace("#", "");
  const n = parseInt(h, 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

// ── Main Component ────────────────────────────────────────────────────────────
export default function Certificates() {
  const { t } = useTranslation();
  const { students } = useStudents();
  const [certs, setCerts] = useState<Certificate[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    setLoading(true);
    smartDb
      .getAll("Certificate")
      .then((rows) => {
        if (active)
          setCerts((rows as Certificate[]).sort((a, b) => b.issuedDate.localeCompare(a.issuedDate)));
      })
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, []);

  const [searchTerm, setSearchTerm] = useState("");
  const [gradeFilter, setGradeFilter] = useState("all");
  const [typeFilter, setTypeFilter] = useState("all");
  const [showForm, setShowForm] = useState(false);
  const [previewCert, setPreviewCert] = useState<Certificate | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Form state
  const [fStudentId, setFStudentId] = useState("");
  const [fType, setFType] = useState(CERT_TYPES[0]);
  const [fTitle, setFTitle] = useState(TYPE_DEFAULT_TITLES[CERT_TYPES[0]]);
  const [fIssuedDate, setFIssuedDate] = useState(new Date().toISOString().slice(0, 10));
  const [fIssuedBy, setFIssuedBy] = useState("Principal");
  const [fDescription, setFDescription] = useState("");

  // Auto-fill principal name
  useEffect(() => {
    getPrincipalName().then((name) => { if (name) setFIssuedBy(name); });
  }, []);

  // Auto-fill title when type changes
  function handleTypeChange(newType: string) {
    setFType(newType);
    // Only overwrite title if it was auto-filled (matches a default) or is empty
    const isAutoFilled = Object.values(TYPE_DEFAULT_TITLES).includes(fTitle) || !fTitle.trim();
    if (isAutoFilled) setFTitle(TYPE_DEFAULT_TITLES[newType] || "");
  }

  function resetForm() {
    setFStudentId("");
    setFType(CERT_TYPES[0]);
    setFTitle(TYPE_DEFAULT_TITLES[CERT_TYPES[0]]);
    setFDescription("");
    setFIssuedDate(new Date().toISOString().slice(0, 10));
  }

  const grades = useMemo(
    () => Array.from(new Set(students.map((s) => s.grade || "").filter(Boolean))).sort(),
    [students]
  );

  const filtered = useMemo(
    () =>
      certs.filter((c) => {
        const matchSearch =
          !searchTerm ||
          c.studentName.toLowerCase().includes(searchTerm.toLowerCase()) ||
          c.title.toLowerCase().includes(searchTerm.toLowerCase());
        const matchGrade = gradeFilter === "all" || c.grade === gradeFilter;
        const matchType = typeFilter === "all" || c.type === typeFilter;
        return matchSearch && matchGrade && matchType;
      }),
    [certs, searchTerm, gradeFilter, typeFilter]
  );

  async function handleIssue() {
    if (!fStudentId) {
      toast.error("Please select a student.");
      return;
    }
    if (!fTitle.trim()) {
      toast.error("Please enter a certificate title.");
      return;
    }
    const student = students.find((s) => (s.id || s.uid) === fStudentId) as any;
    if (!student) {
      toast.error("Selected student not found. Please try again.");
      return;
    }

    const newCert: Omit<Certificate, "id"> = {
      studentId: fStudentId,
      studentName: student.name || "",
      grade: student.grade || "",
      section: student.section || "",
      type: fType,
      title: fTitle.trim(),
      issuedDate: fIssuedDate,
      issuedBy: fIssuedBy,
      description: fDescription,
      printed: false,
    };

    setSubmitting(true);
    try {
      const created = await smartDb.create("Certificate", newCert);
      setCerts((prev) => [created as Certificate, ...prev]);
      setShowForm(false);
      resetForm();
      toast.success(`Certificate issued to ${student.name}!`);
    } catch (err: any) {
      console.error("Certificate issue error:", err);
      toast.error(err?.message || "Failed to issue certificate. Please try again.");
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id: string) {
    try {
      await smartDb.delete("Certificate", id);
      setCerts((prev) => prev.filter((c) => c.id !== id));
      toast.success("Certificate deleted.");
    } catch {
      toast.error("Failed to delete certificate.");
    }
  }

  async function markPrinted(id: string) {
    try {
      await smartDb.update("Certificate", id, { printed: true });
      setCerts((prev) => prev.map((c) => (c.id === id ? { ...c, printed: true } : c)));
      toast.success("Marked as printed.");
    } catch {
      toast.error("Failed to update status.");
    }
  }

  function downloadPDF(cert: Certificate) {
    const doc = generateCertificatePDF(cert);
    doc.save(`${cert.studentName.replace(/\s+/g, "_")}_${cert.type.replace(/\s+/g, "_")}.pdf`);
    toast.success("Certificate PDF downloaded.");
  }

  function exportExcel() {
    const rows = filtered.map((c) => ({
      "Certificate ID": c.id,
      "Student Name": c.studentName,
      Grade: c.grade,
      Section: c.section,
      Type: c.type,
      Title: c.title,
      "Issued Date": c.issuedDate,
      "Issued By": c.issuedBy,
      Description: c.description,
      Printed: c.printed ? "Yes" : "No",
    }));
    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, "Certificates");
    XLSX.writeFile(wb, "certificates.xlsx");
    toast.success("Exported to Excel.");
  }

  const stats = [
    { label: "Total Issued", value: certs.length, color: "bg-blue-50 text-blue-700 border-blue-100", icon: Award },
    { label: "This Month", value: certs.filter((c) => c.issuedDate?.startsWith(new Date().toISOString().slice(0, 7))).length, color: "bg-emerald-50 text-emerald-700 border-emerald-100", icon: Star },
    { label: "Printed", value: certs.filter((c) => c.printed).length, color: "bg-purple-50 text-purple-700 border-purple-100", icon: CheckCircle },
    { label: "Pending Print", value: certs.filter((c) => !c.printed).length, color: "bg-amber-50 text-amber-700 border-amber-100", icon: Printer },
  ];

  return (
    <DashboardLayout>
      <div className="space-y-5">
        {/* Header */}
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-yellow-400 to-amber-500 flex items-center justify-center flex-shrink-0 shadow-md">
              <Award className="h-5 w-5 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-slate-900">Certificates</h1>
              <p className="text-sm text-slate-400">Issue and manage student certificates</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={exportExcel}
              className="flex items-center gap-2 h-10 px-4 rounded-lg border border-slate-200 text-sm font-semibold text-slate-700 hover:bg-slate-50 transition-colors"
            >
              <Download className="h-4 w-4 text-slate-500" /> Export Excel
            </button>
            <button
              onClick={() => { resetForm(); setShowForm(true); }}
              className="flex items-center gap-2 h-10 px-4 rounded-lg bg-[#9810fa] hover:bg-[#8710dc] text-white text-sm font-semibold shadow-sm transition-colors"
            >
              <Plus className="h-4 w-4" /> Issue Certificate
            </button>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-3">
          {stats.map((s, i) => (
            <div key={i} className={cn("bg-white border rounded-xl p-4 shadow-sm", s.color.includes("border") ? "" : "border-slate-100")}>
              <div className={cn("inline-flex items-center gap-1.5 text-xs font-semibold px-2.5 py-1 rounded-lg mb-3 border", s.color)}>
                <s.icon className="h-3.5 w-3.5" /> {s.label}
              </div>
              <p className="text-3xl font-bold text-slate-900">{s.value}</p>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div className="bg-white border border-slate-100 rounded-xl shadow-sm px-4 py-3 flex flex-wrap items-end gap-3">
          <div className="flex-1 min-w-48">
            <label className="text-[11px] font-medium text-slate-500 block mb-1">Search</label>
            <div className="relative">
              <Search className="absolute start-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400" />
              <input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Student name or title…"
                className="w-full h-9 ps-8 pe-3 rounded-lg border border-slate-200 text-sm text-slate-700 outline-none focus:ring-2 focus:ring-yellow-300 bg-white"
              />
            </div>
          </div>
          <div>
            <label className="text-[11px] font-medium text-slate-500 block mb-1">Grade</label>
            <select
              value={gradeFilter}
              onChange={(e) => setGradeFilter(e.target.value)}
              className="h-9 px-3 rounded-lg border border-slate-200 bg-white text-sm font-medium text-slate-700 outline-none focus:ring-2 focus:ring-yellow-300"
            >
              <option value="all">All Grades</option>
              {grades.map((g) => (
                <option key={g}>{g}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="text-[11px] font-medium text-slate-500 block mb-1">Type</label>
            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              className="h-9 px-3 rounded-lg border border-slate-200 bg-white text-sm font-medium text-slate-700 outline-none focus:ring-2 focus:ring-yellow-300"
            >
              <option value="all">All Types</option>
              {CERT_TYPES.map((ct) => (
                <option key={ct} value={ct}>
                  {t(CERT_TYPE_LABEL_KEYS[ct] || ct)}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Table */}
        <div className="bg-white border border-slate-100 rounded-xl shadow-sm overflow-hidden">
          <div className="px-5 py-3 border-b border-slate-100 flex items-center justify-between">
            <span className="text-sm font-semibold text-slate-700">
              {filtered.length} certificate{filtered.length !== 1 ? "s" : ""}
            </span>
            {loading && (
              <span className="text-xs text-slate-400 animate-pulse">Loading…</span>
            )}
          </div>
          {filtered.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-slate-400">
              <Award className="h-10 w-10 mb-3 opacity-30" />
              <p className="font-medium">No certificates found</p>
              <p className="text-sm mt-1">Issue a certificate using the button above.</p>
            </div>
          ) : (
            <table className="w-full text-sm">
              <thead className="bg-slate-50 border-b border-slate-100">
                <tr>
                  {["Student", "Grade", "Type", "Title", "Issued Date", "Issued By", "Status", "Actions"].map(
                    (h) => (
                      <th
                        key={h}
                        className="px-4 py-3 text-start text-xs font-semibold text-slate-500 uppercase tracking-wide"
                      >
                        {h}
                      </th>
                    )
                  )}
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-50">
                {filtered.map((cert) => (
                  <tr key={cert.id} className="hover:bg-slate-50/50 transition-colors">
                    <td className="px-4 py-3 font-semibold text-slate-800">{cert.studentName}</td>
                    <td className="px-4 py-3 text-slate-600">
                      {cert.grade}
                      {cert.section ? ` · ${cert.section}` : ""}
                    </td>
                    <td className="px-4 py-3">
                      <span
                        className={cn(
                          "text-xs font-semibold px-2 py-0.5 rounded-md",
                          TYPE_COLORS[cert.type] || "bg-slate-100 text-slate-600"
                        )}
                      >
                        {t(CERT_TYPE_LABEL_KEYS[cert.type] || cert.type)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-slate-700 max-w-[200px] truncate">{cert.title}</td>
                    <td className="px-4 py-3 text-slate-500">{cert.issuedDate}</td>
                    <td className="px-4 py-3 text-slate-500 max-w-[120px] truncate">{cert.issuedBy}</td>
                    <td className="px-4 py-3">
                      <span
                        className={cn(
                          "text-xs font-semibold px-2 py-0.5 rounded-md",
                          cert.printed
                            ? "bg-green-100 text-green-700"
                            : "bg-amber-100 text-amber-700"
                        )}
                      >
                        {cert.printed ? "Printed" : "Pending"}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <button
                          onClick={() => setPreviewCert(cert)}
                          title="Preview"
                          className="h-7 w-7 rounded-lg border border-slate-200 flex items-center justify-center text-slate-500 hover:bg-slate-100 transition-colors"
                        >
                          <Eye className="h-3.5 w-3.5" />
                        </button>
                        <button
                          onClick={() => downloadPDF(cert)}
                          title="Download PDF"
                          className="h-7 w-7 rounded-lg border border-blue-200 flex items-center justify-center text-blue-500 hover:bg-blue-50 transition-colors"
                        >
                          <FileDown className="h-3.5 w-3.5" />
                        </button>
                        {!cert.printed && (
                          <button
                            onClick={() => markPrinted(cert.id)}
                            title="Mark Printed"
                            className="h-7 w-7 rounded-lg border border-green-200 flex items-center justify-center text-green-600 hover:bg-green-50 transition-colors"
                          >
                            <Printer className="h-3.5 w-3.5" />
                          </button>
                        )}
                        <button
                          onClick={() => handleDelete(cert.id)}
                          title="Delete"
                          className="h-7 w-7 rounded-lg border border-rose-200 flex items-center justify-center text-rose-500 hover:bg-rose-50 transition-colors"
                        >
                          <X className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* ── Issue Certificate Modal ─────────────────────────────────────────── */}
      {showForm && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4"
          onClick={() => setShowForm(false)}
        >
          <div
            className="bg-white rounded-2xl shadow-2xl w-full max-w-lg max-h-[90vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal header */}
            <div className="flex items-center justify-between px-6 py-5 border-b border-slate-100">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-yellow-400 to-amber-500 flex items-center justify-center">
                  <Award className="h-4 w-4 text-white" />
                </div>
                <h2 className="text-lg font-bold text-slate-900">Issue Certificate</h2>
              </div>
              <button
                onClick={() => setShowForm(false)}
                className="w-8 h-8 rounded-lg border border-slate-200 flex items-center justify-center text-slate-400 hover:bg-slate-100 transition-colors"
              >
                <X className="h-4 w-4" />
              </button>
            </div>

            <div className="p-6 space-y-4 overflow-y-auto flex-1">
              {/* Student picker */}
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  Student <span className="text-rose-500">*</span>
                  {students.length > 0 && (
                    <span className="ml-2 text-xs font-normal text-slate-400">({students.length} students)</span>
                  )}
                </label>
                {students.length === 0 ? (
                  <div className="flex items-center gap-2 h-10 px-3 rounded-xl border border-slate-200 bg-slate-50 text-sm text-slate-400">
                    <GraduationCap className="h-4 w-4" />
                    <span className="animate-pulse">Loading students…</span>
                  </div>
                ) : (
                  <StudentPicker
                    students={students}
                    value={fStudentId}
                    onChange={setFStudentId}
                  />
                )}
              </div>

              {/* Certificate type */}
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  Certificate Type
                </label>
                <select
                  value={fType}
                  onChange={(e) => handleTypeChange(e.target.value)}
                  className="w-full h-10 px-3 rounded-xl border border-slate-200 bg-white text-sm outline-none focus:ring-2 focus:ring-yellow-400 transition-all"
                >
                  {CERT_TYPES.map((ct) => (
                    <option key={ct} value={ct}>
                      {t(CERT_TYPE_LABEL_KEYS[ct] || ct)}
                    </option>
                  ))}
                </select>
              </div>

              {/* Certificate title */}
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  Certificate Title <span className="text-rose-500">*</span>
                  <span className="ml-2 text-xs font-normal text-slate-400">auto-filled from type</span>
                </label>
                <input
                  value={fTitle}
                  onChange={(e) => setFTitle(e.target.value)}
                  placeholder="e.g. Outstanding Academic Performance"
                  className="w-full h-10 px-3 rounded-xl border border-slate-200 text-sm outline-none focus:ring-2 focus:ring-yellow-400 transition-all"
                />
              </div>

              {/* Date + Issued By */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1">Issue Date</label>
                  <input
                    type="date"
                    value={fIssuedDate}
                    onChange={(e) => setFIssuedDate(e.target.value)}
                    className="w-full h-10 px-3 rounded-xl border border-slate-200 text-sm outline-none focus:ring-2 focus:ring-yellow-400 transition-all"
                  />
                </div>
                <div>
                  <label className="block text-sm font-semibold text-slate-700 mb-1">Issued By</label>
                  <input
                    value={fIssuedBy}
                    onChange={(e) => setFIssuedBy(e.target.value)}
                    placeholder="Principal name"
                    className="w-full h-10 px-3 rounded-xl border border-slate-200 text-sm outline-none focus:ring-2 focus:ring-yellow-400 transition-all"
                  />
                </div>
              </div>

              {/* Description */}
              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  Description <span className="text-slate-400 text-xs font-normal">(optional)</span>
                </label>
                <textarea
                  value={fDescription}
                  onChange={(e) => setFDescription(e.target.value)}
                  rows={2}
                  placeholder="e.g. In recognition of consistent hard work and dedication throughout the academic year."
                  className="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm outline-none focus:ring-2 focus:ring-yellow-400 resize-none transition-all"
                />
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100">
              <button
                onClick={() => setShowForm(false)}
                className="h-10 px-4 rounded-lg border border-slate-200 text-sm font-semibold text-slate-700 hover:bg-slate-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleIssue}
                disabled={submitting || students.length === 0}
                className="h-10 px-6 rounded-lg bg-[#9810fa] hover:bg-[#8710dc] disabled:opacity-50 disabled:cursor-not-allowed text-white text-sm font-semibold transition-colors flex items-center gap-2"
              >
                {submitting ? (
                  <>
                    <span className="h-3.5 w-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    Issuing…
                  </>
                ) : (
                  <>
                    <Award className="h-4 w-4" /> Issue Certificate
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── Preview Modal ───────────────────────────────────────────────────── */}
      {previewCert && (() => {
        const accent = TYPE_ACCENT[previewCert.type] || TYPE_ACCENT["Merit Certificate"];
        return (
          <div
            className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4"
            onClick={() => setPreviewCert(null)}
          >
            <div
              className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl overflow-hidden"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Modal header */}
              <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100">
                <h2 className="text-lg font-bold text-slate-900">Certificate Preview</h2>
                <button
                  onClick={() => setPreviewCert(null)}
                  className="w-8 h-8 rounded-lg border border-slate-200 flex items-center justify-center text-slate-400 hover:bg-slate-100 transition-colors"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              {/* Certificate body */}
              <div
                className="m-5 rounded-2xl overflow-hidden relative"
                style={{ background: accent.light, border: `4px solid ${accent.primary}` }}
              >
                {/* Top band */}
                <div
                  className="py-2 px-4 text-center text-xs font-bold tracking-widest text-white"
                  style={{ background: accent.primary }}
                >
                  STUDENT DIWAN — ACADEMIC EXCELLENCE PROGRAM
                </div>

                <div className="p-8 text-center">
                  {/* Type */}
                  <div
                    className="text-xs font-bold uppercase tracking-widest mb-2"
                    style={{ color: accent.primary }}
                  >
                    {previewCert.type}
                  </div>

                  {/* Main heading */}
                  <h2 className="text-3xl font-bold text-slate-900 mb-1" style={{ fontFamily: "serif" }}>
                    Certificate
                  </h2>
                  <div className="mx-auto mb-4 h-0.5 w-20 rounded-full" style={{ background: accent.primary }} />

                  <p className="text-sm text-slate-500 italic mb-3">This is proudly presented to</p>

                  {/* Student name */}
                  <p className="text-3xl font-bold mb-1" style={{ color: accent.primary, fontFamily: "serif" }}>
                    {previewCert.studentName}
                  </p>
                  <p className="text-sm text-slate-500 mb-4">
                    {previewCert.grade}
                    {previewCert.section ? ` · Section ${previewCert.section}` : ""}
                  </p>

                  {/* Title */}
                  <p className="text-base font-bold text-slate-800 mb-2">for {previewCert.title}</p>

                  {previewCert.description && (
                    <p className="text-sm text-slate-500 italic mb-6 max-w-md mx-auto">
                      {previewCert.description}
                    </p>
                  )}

                  {/* Signatures */}
                  <div className="flex items-end justify-between mt-8 pt-5 border-t" style={{ borderColor: accent.primary + "40" }}>
                    <div className="text-center">
                      <div className="h-px w-28 mb-1 mx-auto" style={{ background: "#94a3b8" }} />
                      <p className="text-xs font-semibold text-slate-700">{previewCert.issuedBy}</p>
                      <p className="text-[10px] text-slate-400">Principal</p>
                    </div>
                    <div
                      className="w-14 h-14 rounded-full border-2 flex flex-col items-center justify-center text-[8px] font-bold"
                      style={{ borderColor: accent.primary, color: accent.primary }}
                    >
                      <span>OFFICIAL</span>
                      <span>SEAL</span>
                    </div>
                    <div className="text-center">
                      <div className="h-px w-28 mb-1 mx-auto" style={{ background: "#94a3b8" }} />
                      <p className="text-xs font-semibold text-slate-700">{previewCert.issuedDate}</p>
                      <p className="text-[10px] text-slate-400">Date of Issue</p>
                    </div>
                  </div>
                </div>

                {/* Bottom band */}
                <div
                  className="py-2 px-4 text-center text-[10px] text-white"
                  style={{ background: accent.primary }}
                >
                  Certificate ID: {previewCert.id} · portal.studentdiwan.com
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-slate-100">
                <button
                  onClick={() => downloadPDF(previewCert)}
                  className="flex items-center gap-2 h-10 px-4 rounded-lg border border-blue-200 text-blue-700 text-sm font-semibold hover:bg-blue-50 transition-colors"
                >
                  <FileDown className="h-4 w-4" /> Download PDF
                </button>
                <button
                  onClick={() => { markPrinted(previewCert.id); setPreviewCert(null); }}
                  className="flex items-center gap-2 h-10 px-4 rounded-lg bg-slate-800 text-white text-sm font-semibold hover:bg-slate-700 transition-colors"
                >
                  <Printer className="h-4 w-4" /> Mark as Printed
                </button>
              </div>
            </div>
          </div>
        );
      })()}
    </DashboardLayout>
  );
}
