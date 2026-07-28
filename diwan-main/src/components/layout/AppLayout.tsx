import { useEffect, useRef, useState } from "react";
import { SidebarProvider } from "@/components/ui/sidebar";
import { DashboardSidebar } from "@/components/dashboard/DashboardSidebar";
import { DashboardHeader } from "@/components/dashboard/DashboardHeader";
import { StudentDiwanAssistant } from "@/components/ai/StudentDiwanAssistant";
import { ImpersonationBanner } from "@/components/dashboard/ImpersonationBanner";
import { Outlet, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "@/hooks/useAuth";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Keyboard } from "lucide-react";
import { toast } from "sonner";
import { trackEvent } from "@/lib/analytics";

const PAGE_TITLES: Record<string, string> = {
  "/": "Dashboard",
  "/students": "Students",
  "/students/new": "New Student",
  "/staff": "Staff",
  "/attendance": "Attendance",
  "/finance/fees": "Fees Management",
  "/finance/scholarships": "Scholarships",
  "/academics/timetable": "Timetable",
  "/academics/lms": "LMS / Courses",
  "/transport": "Transport",
  "/transport/gps": "Live GPS Tracking",
  "/library": "Library",
  "/communication/messages": "Messages",
  "/communication/notifications": "Notifications",
  "/hr/ptm": "PTM Booking",
  "/hr/appraisal": "Staff Appraisal",
  "/hr/recruitment": "Recruitment",
  "/branches": "Branch Management",
  "/board": "Board Dashboard",
  "/reports/khda": "KHDA / MOE Reports",
  "/analytics/predictive": "Predictive Analytics",
  "/cafeteria": "Cafeteria",
  "/inventory/stock": "Stock Inventory",
  "/inventory/purchases": "Purchases",
  "/inventory/vendors": "Vendors",
  "/security/visitors": "Visitor Management",
  "/security/gate-pass": "Gate Pass",
  "/security/incidents": "Incident Management",
  "/coding": "Coding Assessment",
  "/plagiarism": "Plagiarism Checker",
  "/admissions": "Admissions",
  "/students/exit": "Student Exit / Withdrawal",
  "/settings": "Settings",
  "/system-settings": "System Settings",
  "/ai-center": "AI Centre",
};

// Paths that staff (class teachers) are allowed to visit. Includes the shared
// Communication routes (Messages/Announcements/Calendar) that the teacher
// sidebar (DashboardSidebar.tsx staffNavItems) links to directly — without
// these, every "staff"-role account gets bounced straight back to their
// dashboard the instant they open Messages or Announcements.
const STAFF_ALLOWED_PREFIXES = ["/teacher/", "/", "/communication/messages", "/communication/announcements", "/communication/calendar", "/coding"];

function StaffRouteGuard() {
  const { role } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();
  useEffect(() => {
    if (
      role === "staff" &&
      !STAFF_ALLOWED_PREFIXES.some(p =>
        p === "/" ? location.pathname === "/" : location.pathname.startsWith(p)
      )
    ) {
      navigate("/teacher/dashboard", { replace: true });
    }
  }, [role, location.pathname, navigate]);
  return null;
}

function PageTitleSync() {
  const { pathname } = useLocation();
  useEffect(() => {
    const label = PAGE_TITLES[pathname] ?? PAGE_TITLES[Object.keys(PAGE_TITLES).find(k => pathname.startsWith(k) && k !== "/") ?? ""] ?? "Student Diwan";
    document.title = `${label} — Student Diwan ERP`;
  }, [pathname]);
  return null;
}

// Fires one real page_view event per route change — the raw feed
// analyticsEngine.ts's feature-usage breakdown reads back. Skipped while
// auth is still resolving so a pre-login redirect bounce doesn't get logged
// under no uid.
function AnalyticsRouteListener() {
  const { pathname } = useLocation();
  const { user, role, loading } = useAuth();
  useEffect(() => {
    if (loading || !user?.uid) return;
    trackEvent({ type: "page_view", uid: user.uid, role: role || undefined, path: pathname });
  }, [pathname, user?.uid, role, loading]);
  return null;
}

// Chord-based navigation shortcuts.
// Windows: hold Alt + press letter(s). macOS: hold ⌘+Shift + press letter(s).
// Single-letter chords navigate immediately when unambiguous, or after 700 ms
// when the same letter is also a prefix of a two-letter chord.
// Two-letter chords: keep holding the modifier and press the second letter.
//
// Uses e.code (physical key, unaffected by OS layout/accent modifiers) so
// macOS dead-key combos (⌥+E = ´, etc.) never silently swallow shortcuts.
const CHORD_LOOKUP: Record<string, { path: string; label: string }> = {
  // General
  d:  { path: "/",                            label: "Dashboard" },
  // Students
  sm: { path: "/students",                    label: "Student Management" },
  as: { path: "/students",                    label: "All Students" },
  a:  { path: "/admissions",                  label: "Admissions" },
  w:  { path: "/attendance",                  label: "Attendance" },
  hr: { path: "/students/health",             label: "Health Records" },
  cd: { path: "/behavior",                    label: "Conduct & Discipline" },
  an: { path: "/students/alumni",             label: "Alumni Network" },
  g:  { path: "/graduates",                   label: "Graduates" },
  // Academics
  c:  { path: "/academics/classes",           label: "Classes" },
  t:  { path: "/timetable",                   label: "Timetable" },
  ai: { path: "/academics/ai-timetable",      label: "AI Timetable Generator" },
  s:  { path: "/academics/subjects",          label: "Subjects" },
  am: { path: "/assignments",                 label: "Assignments" },
  ae: { path: "/academics/assessments",       label: "Assessments" },
  j:  { path: "/academics/gradebook",         label: "Gradebook" },
  ac: { path: "/academics/achievements",      label: "Achievements" },
  fl: { path: "/academics/flashcards",        label: "Flashcards" },
  l:  { path: "/library",                     label: "Library" },
  rm: { path: "/academics/rooms",             label: "Room Management" },
  sc: { path: "/academics/subject-codes",     label: "Subject Codes" },
  pt: { path: "/hr/ptm",                      label: "Parent-Teacher Meetings" },
  // Exams & Reports
  eo: { path: "/exams/setup",                 label: "Exam Operations" },
  r:  { path: "/reports",                     label: "Reports" },
  rc: { path: "/academics/report-cards",      label: "Report Cards" },
  tr: { path: "/academics/transcripts",       label: "Transcripts" },
  ce: { path: "/academics/certificates",      label: "Certificates" },
  // Teaching & Learning
  k:  { path: "/coding/admin",                label: "Teaching & Learning" },
  cl: { path: "/coding/admin",                label: "Coding Lab" },
  pc: { path: "/plagiarism",                  label: "Plagiarism Checker" },
  // HR
  h:  { path: "/hr/staff",                    label: "HR / Staff" },
  py: { path: "/hr/payroll",                  label: "Payroll" },
  re: { path: "/hr/recruitment",              label: "Recruitment" },
  ap: { path: "/hr/appraisal",                label: "Appraisals" },
  // Finance
  f:  { path: "/finance/overview",            label: "Finance Overview" },
  tx: { path: "/finance/transactions",        label: "Transactions" },
  fe: { path: "/finance/fees",                label: "Fees" },
  sh: { path: "/finance/scholarships",        label: "Scholarships" },
  // Communication
  q:  { path: "/communication/announcements", label: "Announcements" },
  m:  { path: "/communication/messages",      label: "Messages" },
  n:  { path: "/communication/notifications", label: "Notifications" },
  x:  { path: "/communication/calendar",      label: "Calendar" },
  // Transport
  v:  { path: "/transport/overview",          label: "Transport" },
  vr: { path: "/transport/routes",            label: "Routes" },
  al: { path: "/transport/allocation",        label: "Allocations" },
  // Hostel & Cafeteria
  o:  { path: "/hostel/rooms",                label: "Hostel & Cafeteria" },
  // Security
  u:  { path: "/security/visitors",           label: "Security" },
  vi: { path: "/security/visitors",           label: "Visitors" },
  in: { path: "/security/incidents",          label: "Incidents" },
  // Inventory
  y:  { path: "/inventory/overview",          label: "Inventory" },
  st: { path: "/inventory/stock",             label: "Stock" },
  pu: { path: "/inventory/purchases",         label: "Purchases" },
  ve: { path: "/inventory/vendors",           label: "Vendors" },
  // Intelligence
  i:  { path: "/ai-center",                   label: "AI Center" },
  // Administration
  b:  { path: "/branches",                    label: "Branches" },
  p:  { path: "/portals/student",             label: "Portals" },
  z:  { path: "/help",                        label: "Help Center" },
};

const CHORD_CATEGORIES: { title: string; items: { chord: string; label: string }[] }[] = [
  {
    title: "General",
    items: [{ chord: "d", label: "Dashboard" }],
  },
  {
    title: "Students",
    items: [
      { chord: "sm", label: "Student Management" },
      { chord: "as", label: "All Students" },
      { chord: "a",  label: "Admissions" },
      { chord: "w",  label: "Attendance" },
      { chord: "hr", label: "Health Records" },
      { chord: "cd", label: "Conduct & Discipline" },
      { chord: "an", label: "Alumni Network" },
      { chord: "g",  label: "Graduates" },
    ],
  },
  {
    title: "Academics",
    items: [
      { chord: "c",  label: "Classes" },
      { chord: "t",  label: "Timetable" },
      { chord: "ai", label: "AI Timetable Generator" },
      { chord: "s",  label: "Subjects" },
      { chord: "am", label: "Assignments" },
      { chord: "ae", label: "Assessments" },
      { chord: "j",  label: "Gradebook" },
      { chord: "ac", label: "Achievements" },
      { chord: "fl", label: "Flashcards" },
      { chord: "l",  label: "Library" },
      { chord: "rm", label: "Room Management" },
      { chord: "sc", label: "Subject Codes" },
      { chord: "pt", label: "Parent-Teacher Meetings" },
    ],
  },
  {
    title: "Exams & Reports",
    items: [
      { chord: "eo", label: "Exam Operations" },
      { chord: "r",  label: "Reports" },
      { chord: "rc", label: "Report Cards" },
      { chord: "tr", label: "Transcripts" },
      { chord: "ce", label: "Certificates" },
    ],
  },
  {
    title: "Teaching & Learning",
    items: [
      { chord: "k",  label: "Teaching & Learning" },
      { chord: "cl", label: "Coding Lab" },
      { chord: "pc", label: "Plagiarism Checker" },
    ],
  },
  {
    title: "HR",
    items: [
      { chord: "h",  label: "HR / Staff" },
      { chord: "py", label: "Payroll" },
      { chord: "re", label: "Recruitment" },
      { chord: "ap", label: "Appraisals" },
    ],
  },
  {
    title: "Finance",
    items: [
      { chord: "f",  label: "Finance Overview" },
      { chord: "tx", label: "Transactions" },
      { chord: "fe", label: "Fees" },
      { chord: "sh", label: "Scholarships" },
    ],
  },
  {
    title: "Communication",
    items: [
      { chord: "q", label: "Announcements" },
      { chord: "m", label: "Messages" },
      { chord: "n", label: "Notifications" },
      { chord: "x", label: "Calendar" },
    ],
  },
  {
    title: "Transport",
    items: [
      { chord: "v",  label: "Transport" },
      { chord: "vr", label: "Routes" },
      { chord: "al", label: "Allocations" },
    ],
  },
  {
    title: "Operations",
    items: [
      { chord: "o",  label: "Hostel & Cafeteria" },
      { chord: "u",  label: "Security" },
      { chord: "vi", label: "Visitors" },
      { chord: "in", label: "Incidents" },
      { chord: "y",  label: "Inventory" },
      { chord: "st", label: "Stock" },
      { chord: "pu", label: "Purchases" },
      { chord: "ve", label: "Vendors" },
    ],
  },
  {
    title: "Intelligence & Admin",
    items: [
      { chord: "i", label: "AI Center" },
      { chord: "b", label: "Branches" },
      { chord: "p", label: "Portals" },
      { chord: "z", label: "Help Center" },
    ],
  },
];

function ShortcutRow({ chord, label, platform }: { chord: string; label: string; platform: "windows" | "mac" }) {
  const mod = platform === "mac" ? ["⌘", "⇧"] : ["Alt"];
  const letters = chord.toUpperCase().split("");
  return (
    <div className="flex items-center justify-between text-sm py-1.5 border-b border-slate-100 dark:border-slate-800/40">
      <span className="text-slate-500 dark:text-slate-400 text-xs">{label}</span>
      <div className="flex items-center gap-0.5">
        {mod.map((k, i) => (
          <kbd key={i} className="px-1.5 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200 border border-slate-200 dark:border-slate-700 shadow-sm text-[10px] font-bold font-mono">{k}</kbd>
        ))}
        <span className="text-slate-400 text-[10px] mx-0.5">+</span>
        {letters.map((k, i) => (
          <kbd key={i} className="px-1.5 py-0.5 rounded bg-violet-100 dark:bg-violet-900/40 text-violet-800 dark:text-violet-200 border border-violet-200 dark:border-violet-700/50 shadow-sm text-[10px] font-bold font-mono">{k}</kbd>
        ))}
      </div>
    </div>
  );
}

export const AppLayout = () => {
  const [isMac, setIsMac] = useState(false);
  const [shortcutsOpen, setShortcutsOpen] = useState(false);
  const [chordIndicator, setChordIndicator] = useState("");
  const chordRef = useRef("");
  const chordTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const navigate = useNavigate();

  useEffect(() => {
    if (typeof navigator !== "undefined") {
      setIsMac(/Mac|iPod|iPhone|iPad/.test(navigator.userAgent || navigator.platform));
    }
  }, []);

  useEffect(() => {
    const clearChord = () => {
      chordRef.current = "";
      setChordIndicator("");
      if (chordTimerRef.current) { clearTimeout(chordTimerRef.current); chordTimerRef.current = null; }
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      const activeEl = document.activeElement;
      const isInput = activeEl && (
        activeEl.tagName === "INPUT" ||
        activeEl.tagName === "TEXTAREA" ||
        activeEl.getAttribute("contenteditable") === "true"
      );

      if (e.key === "Escape") { clearChord(); return; }

      if (e.key === "?" && !isInput) {
        e.preventDefault();
        setShortcutsOpen((prev) => !prev);
        return;
      }

      // Windows: Alt+Letter (no Shift, Ctrl, Meta)
      // macOS: ⌘+Shift+Letter (Meta+Shift, no Alt, Ctrl)
      const isWinTrigger = !isMac && e.altKey && !e.shiftKey && !e.ctrlKey && !e.metaKey;
      const isMacTrigger = isMac && e.metaKey && e.shiftKey && !e.altKey && !e.ctrlKey;

      if ((!isWinTrigger && !isMacTrigger) || isInput) return;

      // e.code = "KeyA" → letter = "a"; skip non-letter keys
      if (!e.code.startsWith("Key")) return;
      const letter = e.code.slice(3).toLowerCase();

      e.preventDefault();

      const newChord = chordRef.current + letter;
      chordRef.current = newChord;

      const exactMatch = CHORD_LOOKUP[newChord];
      const isPossiblePrefix = Object.keys(CHORD_LOOKUP).some(k => k.startsWith(newChord) && k.length > newChord.length);

      if (exactMatch && !isPossiblePrefix) {
        // Unambiguous — navigate at once
        navigate(exactMatch.path);
        toast.success(`→ ${exactMatch.label}`);
        clearChord();
        return;
      }

      if (exactMatch && isPossiblePrefix) {
        // Ambiguous: show indicator and auto-navigate after 700 ms if no 2nd key
        setChordIndicator(newChord.toUpperCase());
        if (chordTimerRef.current) clearTimeout(chordTimerRef.current);
        chordTimerRef.current = setTimeout(() => {
          navigate(exactMatch.path);
          toast.success(`→ ${exactMatch.label}`);
          clearChord();
        }, 700);
        return;
      }

      if (!exactMatch && isPossiblePrefix) {
        // Prefix only — wait for more keys
        setChordIndicator(newChord.toUpperCase());
        if (chordTimerRef.current) clearTimeout(chordTimerRef.current);
        chordTimerRef.current = setTimeout(clearChord, 1500);
        return;
      }

      // Dead end
      clearChord();
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      if (chordTimerRef.current) clearTimeout(chordTimerRef.current);
    };
  }, [navigate, isMac]);

  return (
    <SidebarProvider>
      <PageTitleSync />
      <StaffRouteGuard />
      <AnalyticsRouteListener />
      <DashboardSidebar />
      <div className="flex-1 flex flex-col h-screen overflow-hidden bg-[#F9FAFB]/50 dark:bg-[#0E0E16] print:h-auto print:overflow-visible">
        <ImpersonationBanner />
        <DashboardHeader />
        <div className="flex-1 flex flex-col overflow-hidden min-h-0 print:overflow-visible">
          <Outlet />
        </div>
      </div>
      <StudentDiwanAssistant />

      {chordIndicator && (
        <div className="fixed bottom-8 left-1/2 -translate-x-1/2 z-[9999] flex items-center gap-2 px-4 py-2.5 bg-slate-900/95 dark:bg-slate-100/95 backdrop-blur-sm text-white dark:text-slate-900 rounded-2xl shadow-2xl border border-slate-700/50 dark:border-slate-200/50 pointer-events-none select-none">
          <span className="text-slate-400 dark:text-slate-500 text-xs font-medium">{isMac ? "⌘⇧" : "Alt"}</span>
          <div className="flex items-center gap-1">
            {chordIndicator.split("").map((c, i) => (
              <kbd key={i} className="px-2 py-1 rounded-lg bg-violet-600 text-white text-xs font-bold font-mono shadow-sm">{c}</kbd>
            ))}
          </div>
          <span className="text-slate-400 dark:text-slate-500 text-xs">→ next key…</span>
        </div>
      )}

      <Dialog open={shortcutsOpen} onOpenChange={setShortcutsOpen}>
        <DialogContent className="max-w-2xl rounded-2xl bg-white dark:bg-[#0F1424] border-none shadow-2xl p-6 font-sans">
          <DialogHeader className="border-b pb-4 mb-4">
            <DialogTitle className="text-xl font-black flex items-center gap-2.5 text-slate-900 dark:text-white">
              <Keyboard className="h-5.5 w-5.5 text-[#9810fa] dark:text-[#b388ff]" />
              Keyboard Shortcuts Guide
            </DialogTitle>
            <DialogDescription className="text-slate-400">
              Use these shortcuts to navigate the application instantly from anywhere.
            </DialogDescription>
          </DialogHeader>

          <Tabs defaultValue={isMac ? "mac" : "windows"} className="w-full">
            <TabsList className="grid w-full grid-cols-2 bg-slate-100 dark:bg-slate-800/50 p-1 rounded-xl mb-4">
              <TabsTrigger value="windows" className="rounded-lg py-2 text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-slate-800 dark:data-[state=active]:text-white shadow-sm">
                Windows / Linux
              </TabsTrigger>
              <TabsTrigger value="mac" className="rounded-lg py-2 text-xs font-bold transition-all data-[state=active]:bg-white dark:data-[state=active]:bg-slate-800 dark:data-[state=active]:text-white shadow-sm">
                macOS
              </TabsTrigger>
            </TabsList>

            {(["windows", "mac"] as const).map(platform => (
              <TabsContent key={platform} value={platform} className="outline-none max-h-[60vh] overflow-y-auto pr-1">
                <p className="text-xs text-slate-400 mb-3">
                  {platform === "mac"
                    ? "Hold ⌘ + ⇧ (Command + Shift), then press the key(s). Two-letter chords: keep holding ⌘⇧ and press both letters in sequence."
                    : "Hold Alt, then press the key(s). Two-letter chords: keep holding Alt and press both letters in sequence."}
                </p>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-4">
                  {CHORD_CATEGORIES.map(cat => (
                    <div key={cat.title}>
                      <h3 className="text-xs font-bold uppercase tracking-wider text-[#9810fa] dark:text-[#b388ff] mb-2">{cat.title}</h3>
                      <div className="space-y-0">
                        {cat.items.map(item => (
                          <ShortcutRow
                            key={item.chord}
                            chord={item.chord}
                            label={item.label}
                            platform={platform}
                          />
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </TabsContent>
            ))}
          </Tabs>

          <div className="border-t border-slate-100 dark:border-slate-800/40 pt-4 mt-4 flex items-center justify-between text-xs text-slate-400">
            <span className="flex items-center gap-1.5">
              <kbd className="px-1.5 py-0.5 rounded border bg-slate-50 dark:bg-slate-800 font-mono text-[10px] font-bold">Ctrl / ⌘</kbd> + <kbd className="px-1.5 py-0.5 rounded border bg-slate-50 dark:bg-slate-800 font-mono text-[10px] font-bold">K</kbd> Global Command Search
            </span>
            <span className="flex items-center gap-1.5">
              Press <kbd className="px-1.5 py-0.5 rounded border bg-slate-50 dark:bg-slate-800 font-mono text-[10px] font-bold">?</kbd> to open/close guide
            </span>
          </div>
        </DialogContent>
      </Dialog>
    </SidebarProvider>
  );
};
