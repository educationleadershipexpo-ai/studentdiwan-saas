/**
 * Person-name transliteration (Latin → Arabic script).
 *
 * Student/staff names are stored only in romanized Latin form in the database
 * (e.g. "Ahmad Salim Al-Kindi", "Priya Sharma"). When Arabic is the active
 * language the rest of the UI switches to Arabic but these proper names stayed
 * in Latin. This module renders them in Arabic script so names match the rest
 * of the interface.
 *
 * Two layers:
 *   1. TOKEN_MAP — a curated, hand-verified dictionary of the name parts that
 *      actually occur in the data (Gulf/Arabic + Indian names). Highest quality.
 *   2. ruleTransliterate() — a phonetic Latin→Arabic fallback for any token not
 *      in the dictionary (covers names beyond the seed data).
 *
 * The auto-translator (autoTranslate.ts) only calls transliterateName() on text
 * nodes that pass isNameCandidate() — a gate that recognises proper nouns by
 * excluding known English UI words (harvested from en.json), so ordinary
 * interface text is never transliterated into gibberish while ALL person /
 * school / proper names (seed data or live DB) do get transliterated.
 */
import en from './locales/en.json';

// ── Curated token dictionary ────────────────────────────────────────────────
// Keys are lower-cased, punctuation-stripped. Values are Arabic script.
const TOKEN_MAP: Record<string, string> = {
  // Honorifics
  "dr": "د.", "mr": "السيد", "mrs": "السيدة", "ms": "السيدة", "prof": "أ.د.", "eng": "م.",

  // ── Arabic / Gulf given names ──
  "ahmad": "أحمد", "ahmed": "أحمد", "abdullah": "عبد الله", "abraham": "إبراهيم",
  "aisha": "عائشة", "ayaan": "أيان", "fatima": "فاطمة", "faisal": "فيصل",
  "hassan": "حسن", "hind": "هند", "ibrahim": "إبراهيم", "khalid": "خالد",
  "maryam": "مريم", "nasser": "ناصر", "noor": "نور", "omar": "عمر",
  "rashid": "راشد", "saif": "سيف", "salim": "سالم", "salma": "سلمى",
  "sara": "سارة", "tariq": "طارق", "walid": "وليد", "yousef": "يوسف",

  // ── Arabic / Omani family names (Al-) ──
  "al-amri": "العامري", "al-balushi": "البلوشي", "al-busaidi": "البوسعيدي",
  "al-farsi": "الفارسي", "al-habsi": "الحبسي", "al-harthi": "الحارثي",
  "al-hinai": "الهنائي", "al-kindi": "الكندي", "al-maawali": "المعولي",
  "al-mahrouqi": "المحروقي", "al-mamari": "المعمري", "al-rawahi": "الرواحي",
  "al-zadjali": "الزدجالي",

  // ── Indian given names ──
  "aarav": "آراف", "aaryan": "آريان", "aavya": "آفيا", "aditi": "أديتي",
  "advait": "أدفايت", "amit": "أميت", "ananya": "أنانيا", "anita": "أنيتا",
  "anjali": "أنجالي", "anvi": "أنفي", "aradhya": "أرادهيا", "arjun": "أرجون",
  "atharv": "أثارف", "deepak": "ديباك", "ishaan": "إيشان", "ishani": "إيشاني",
  "ishita": "إيشيتا", "kabir": "كبير", "karan": "كاران", "kavita": "كافيتا",
  "kavya": "كافيا", "krishna": "كريشنا", "kumar": "كومار", "kyra": "كايرا",
  "laksh": "لاكش", "manish": "مانيش", "meenakshi": "ميناكشي", "meera": "ميرا",
  "myra": "مايرا", "neha": "نيها", "priya": "بريا", "priyanka": "بريانكا",
  "rahul": "راهول", "rajesh": "راجيش", "ramesh": "راميش", "reyansh": "ريانش",
  "riya": "ريا", "rohan": "روهان", "sangeeta": "سانجيتا", "sanjay": "سانجاي",
  "sanya": "سانيا", "shaurya": "شوريا", "shweta": "شويتا", "sia": "سيا",
  "siddharth": "سيدهارث", "sunil": "سونيل", "sunita": "سونيتا", "suresh": "سوريش",
  "tanvi": "تانفي", "vanya": "فانيا", "varun": "فارون", "vihaan": "فيهان",
  "vivaan": "فيفان", "vinay": "فيناي", "vikram": "فيكرام", "ziva": "زيفا",
  "zoya": "زويا", "kaur": "كور", "sia'": "سيا",

  // ── Indian family names ──
  "aggarwal": "أغاروال", "bakshi": "بخشي", "bansal": "بانسال", "bose": "بوس",
  "chaturvedi": "تشاتورفيدي", "chauhan": "تشوهان", "chopra": "تشوبرا",
  "choudhury": "تشودري", "das": "داس", "desai": "ديساي", "dubey": "دوبي",
  "dwivedi": "دفيدي", "garg": "غارغ", "gupta": "غوبتا", "iyer": "آير",
  "joshi": "جوشي", "kapoor": "كابور", "kapur": "كابور", "malhotra": "مالهوترا",
  "mehta": "ميهتا", "mishra": "ميشرا", "nair": "ناير", "pandey": "باندي",
  "patel": "باتيل", "pathak": "باثاك", "pillai": "بيلاي", "rao": "راو",
  "rathore": "راثور", "reddy": "ريدي", "sarin": "سارين", "seth": "سيث",
  "sharma": "شارما", "shukla": "شوكلا", "singh": "سينغ", "trivedi": "تريفيدي",
  "verma": "فيرما",
};

// Every token we recognise as "part of a person's name" — used by the gate.
const KNOWN_NAME_TOKENS = new Set(Object.keys(TOKEN_MAP));

// UI / interface words that must NEVER appear inside a name candidate. A Title-
// case pair like "Report Cards" or "Active Students" would otherwise slip past
// the name regex; any of these present ⇒ the node is treated as UI text, not a
// name, and left for the normal dictionary path.
const STOP_WORDS = new Set([
  "the", "and", "or", "of", "to", "in", "on", "for", "with", "by", "all", "new",
  "add", "edit", "view", "delete", "search", "filter", "export", "import", "print",
  "report", "reports", "card", "cards", "fee", "fees", "total", "active", "student",
  "students", "staff", "teacher", "teachers", "parent", "class", "classes", "section",
  "grade", "subject", "subjects", "exam", "exams", "attendance", "list", "details",
  "detail", "overview", "management", "dashboard", "settings", "profile", "profiles",
  "collection", "revenue", "expense", "expenses", "payment", "payments", "status",
  "action", "actions", "name", "email", "phone", "address", "date", "time", "type",
  "male", "female", "present", "absent", "pending", "approved", "rejected", "paid",
  "unpaid", "no", "yes", "select", "upcoming", "recent", "today", "week", "month",
  "year", "records", "record", "directory", "manage", "create", "update", "save",
  "cancel", "submit", "close", "assignments", "assignment", "results", "result",
]);

// ── Rule-based phonetic fallback ────────────────────────────────────────────
// Rough Latin→Arabic transliteration for tokens outside TOKEN_MAP. Digraphs are
// matched before single letters. Not perfect, but keeps unseen names in-script.
const DIGRAPHS: [RegExp, string][] = [
  [/^al-/, "ال"], [/sh/g, "ش"], [/ch/g, "تش"], [/th/g, "ث"], [/kh/g, "خ"],
  [/gh/g, "غ"], [/ph/g, "ف"], [/dh/g, "ذ"], [/oo/g, "و"], [/ou/g, "و"],
  [/ee/g, "ي"], [/aa/g, "ا"], [/ai/g, "اي"], [/ay/g, "اي"], [/ei/g, "ي"],
];
const LETTERS: Record<string, string> = {
  a: "ا", b: "ب", c: "ك", d: "د", e: "", f: "ف", g: "غ", h: "ه", i: "ي",
  j: "ج", k: "ك", l: "ل", m: "م", n: "ن", o: "و", p: "ب", q: "ق", r: "ر",
  s: "س", t: "ت", u: "و", v: "ف", w: "و", x: "كس", y: "ي", z: "ز",
};

function ruleTransliterate(token: string): string {
  let s = token.toLowerCase();
  for (const [re, rep] of DIGRAPHS) s = s.replace(re, rep);
  let out = "";
  for (const ch of s) {
    if (/[؀-ۿ]/.test(ch)) { out += ch; continue; } // already Arabic (from digraph)
    if (ch in LETTERS) out += LETTERS[ch];
    else if (ch === "'" || ch === "’" || ch === "-") continue;
    else out += ch;
  }
  return out || token;
}

function normalize(token: string): string {
  return token.toLowerCase().replace(/[.,]/g, "").trim();
}

function transliterateToken(token: string): string {
  const key = normalize(token);
  if (key in TOKEN_MAP) return TOKEN_MAP[key];
  return ruleTransliterate(key);
}

/** Transliterate a full person name, token by token. */
export function transliterateName(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .map(transliterateToken)
    .join(" ");
}

// 1–5 Title-case Latin words, allowing Al-, apostrophes and a trailing dot
// (honorifics like "Dr."). Anchored so partial matches inside a sentence fail.
const NAME_SHAPE = /^([A-Z][A-Za-z'’.-]*)(\s+[A-Z][A-Za-z'’.-]*){0,4}$/;

// ── English UI-word corpus ───────────────────────────────────────────────────
// Every word that appears in an English UI string (en.json). A Title-case Latin
// text node whose words are ALL in here is interface text (e.g. "Report Cards",
// "Active Students") — leave it for the dictionary path. A node with a word NOT
// in here contains a proper noun ("Bluewood", "Ahmad", "Al-Kindi") → transliterate.
const UI_WORDS = new Set<string>();
(function collectUiWords(node: unknown) {
  if (typeof node === 'string') {
    for (const w of node.toLowerCase().match(/[a-z]{2,}/g) ?? []) UI_WORDS.add(w);
  } else if (node && typeof node === 'object') {
    for (const v of Object.values(node as Record<string, unknown>)) collectUiWords(v);
  }
})(en);
// A few generic name-context words that legitimately appear in both names and UI;
// don't let them count as "UI" so full names built only from them still translate.
for (const w of ['al', 'bin', 'bint', 'abu', 'umm']) UI_WORDS.delete(w);

/**
 * Should this text node be transliterated as a proper noun (person / school /
 * place name)? True when it has the Title-case name shape, contains no hard UI
 * stop-word, and includes at least one word that is NOT part of the English UI
 * vocabulary — i.e. a genuine proper noun rather than an untranslated label.
 */
export function isNameCandidate(text: string): boolean {
  const trimmed = text.trim();
  if (!NAME_SHAPE.test(trimmed)) return false;
  const tokens = trimmed.split(/\s+/);
  let properNounTokens = 0;
  let alphaTokens = 0;
  for (const tok of tokens) {
    const n = normalize(tok);
    if (!n) continue;
    if (STOP_WORDS.has(n)) return false;
    alphaTokens++;
    // A token is a proper noun if it's a known name OR simply not a UI word.
    if (KNOWN_NAME_TOKENS.has(n) || !UI_WORDS.has(n)) properNounTokens++;
  }
  if (alphaTokens === 0) return false;
  // Single-word candidates only transliterate when explicitly a known name,
  // to avoid mangling stray codes/abbreviations. Multi-word: any proper noun.
  if (alphaTokens === 1) return KNOWN_NAME_TOKENS.has(normalize(tokens[0]));
  return properNounTokens >= 1;
}
