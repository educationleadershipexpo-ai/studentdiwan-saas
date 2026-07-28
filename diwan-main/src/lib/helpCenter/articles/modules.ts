import type { HelpArticle } from "../types";

export const modulesArticles: HelpArticle[] = [
  {
    slug: "dashboard",
    title: "Dashboard & Analytics Overview",
    categoryId: "modules",
    summary: "Managing administrative widgets, shortcuts, and core metric layouts.",
    popular: true,
    status: "published",
    version: 1,
    content: `
# Dashboard & Analytics Overview

## Purpose
Explaining widgets, real-time sync states, and user metric configurations.

## Who Can Access
* **All Roles** (Dashboard layouts adapt automatically based on role scope)

## Overview
The Dashboard serves as the central control panel, rendering summary analytics (e.g. total students, active today, revenue charts, behavior points) custom-tailored to the active user's permissions.

## Step-by-Step Instructions
1. View metrics at a glance upon initial authentication.
2. Select dashboard widget groupings to drill down into specific reports.
3. Review notifications and calendar alerts in the sidebar indicators.
`,
    keywords: ["dashboard", "home", "metrics"]
  },
  {
    slug: "admissions",
    title: "Admissions & Onboarding",
    categoryId: "modules",
    summary: "Processing new applications, lead stages, and bulk roster imports.",
    status: "published",
    version: 1,
    content: `
# Admissions & Onboarding

## Purpose
Managing the admissions pipeline, inquiries, parent allocations, and CSV uploader routines.

## Who Can Access
* **Super Admin**, **School Admin**, **Receptionist**

## Step-by-Step Instructions
1. Go to **Student Management** -> **Admissions**.
2. Select **New Student Application** to process manual entries, or click **Bulk Import** to upload a CSV file.
3. Match CSV columns to student data fields and confirm upload.
`,
    keywords: ["admissions", "import", "onboarding"]
  },
  {
    slug: "students",
    title: "Students Directory & Profiles",
    categoryId: "modules",
    summary: "Managing personal files, grade associations, and student settings.",
    status: "published",
    version: 1,
    content: `
# Students Directory & Profiles

## Purpose
Reviewing profile detail cards, editing contact information, and managing statuses.

## Who Can Access
* **Super Admin**, **School Admin**, **Principal**

## Step-by-Step Instructions
1. Navigate to **Student Directory**.
2. Search for student by name, ID, or phone number.
3. Click a student name to open the detailed drawer profile tab.
`,
    keywords: ["students", "directory", "profiles"]
  },
  {
    slug: "attendance",
    title: "Student & Staff Attendance Management",
    categoryId: "modules",
    summary: "Complete guide on recording daily roll-calls, tracking staff shifts, configuring late locks, and syncing real-time notifications.",
    status: "published",
    version: 1,
    content: `
# Student & Staff Attendance Management

:::info
**Outbound Notifications Enabled:** Saving a student's attendance as *Absent* or *Late* automatically queues SMS and email alerts to their registered parent profiles in real-time.
:::

## Purpose
Establishing a daily operational register to ensure precise attendance audits, automated delay tracking, parent safety notification compliance, and monthly staff payroll hr links.

## Who Can Access
Access levels depend on role specifications as outlined in the matrix below:

| Portal Role | Student Attendance | Staff Attendance | Settings & Configuration |
| :--- | :---: | :---: | :---: |
| **Super Admin** | Full (Read/Write) | Full (Read/Write) | Full Access |
| **School Admin** | Full (Read/Write) | Full (Read/Write) | Read-Only |
| **HR Manager** | Read-Only | Full (Read/Write) | Read-Only |
| **Teacher** | Scoped Sections | Read-Only | Blocked |
| **Parent / Student**| Read-Only (Own profile) | Blocked | Blocked |

## Prerequisites
* An active **Academic Year** and **Term** must be configured.
* Teachers must have class allocations set inside **Subject Allocation** to record rolls.
* Student profiles must possess assigned **Enrollments** to render on active section grids.

## Overview
Student Diwan provides a unified portal to track attendance, manage late-comers, and export analytical registers.

### Attendance Tracking Workflow
\`\`\`text
[Select Class Section] ➔ [Load Roster Grid] ➔ [Mark Present/Absent/Late] ➔ [Apply and Sync] ➔ [Auto Parent Alert]
\`\`\`

## Step-by-Step Instructions

### 1. Marking Student Attendance
1. Navigate to **Student Management** ➔ **Attendance**.
2. Select your target **Grade & Section** and choose the active date.
3. Click **Load Class Roster** to fetch students.
4. Click states to toggle: **Present** (green), **Absent** (red), or **Late** (orange).
5. Input any status notes (e.g. "Doctor appointment slip verified") by clicking the edit icon next to the name.
6. Click **Save Attendance** to submit the record.

:::tip
**Keyboard Shortcuts:** Navigate the roster grid using \`[Up-Arrow]\` and \`[Down-Arrow]\` keys. Toggle status using the \`[Space]\` bar. Click \`[Ctrl+S]\` to save.
:::

### 2. Marking Staff Attendance
1. Navigate to **Staff & HR** ➔ **Staff Attendance**.
2. Roster rows load dynamically based on active HR employee profiles.
3. Toggle check-in and check-out times, or select default shift codes (e.g. *Present*, *On Leave*, *Sick Leave*).
4. Save to sync attendance sheets directly to **Payroll Processing** calculations.

## Important Notes
:::warning
**Compliance Lock:** Daily student attendance grids lock at **11:59 PM** on the active calendar date. Retrospective edits beyond this window require Super Admin authorization overrides.
:::

## Best Practices
* **Mark Daily**: Complete roll-calls within the first 15 minutes of the morning session to prevent automated "unexcused absence" alerts from dispatching prematurely.
* **Review Exceptions**: Cross-reference the class ledger with **Leave Requests** before marking to ensure sick leaves are correctly categorized.

## Common Mistakes
* **Orphaned Rosters**: Trying to log attendance for a class that has no students enrolled for the current academic term. Always verify student enrollment registers first.

## Frequently Asked Questions
### Q: How can a parent submit an excuse notice?
A: Parents log in to the Parent Portal, open their child's profile, and click **Submit Excuse Note** to upload medical receipts or documentation.

### Q: Does the system check for double check-ins?
A: Yes, student check-ins are restricted to a single class section layout per day to prevent overlapping records.

## Related Articles
* [Teacher Portal Guide](/help/user-guides/teacher)
* [Parent Portal Guide](/help/user-guides/parent)
* [LMS & Class Scheduling](/help/modules/timetable)
`,
    keywords: ["attendance", "present", "absent", "late", "staff roster", "check-in"]
  },
  {
    slug: "behavior",
    title: "Behavior & Conduct Records",
    categoryId: "modules",
    summary: "Logging behavioral incidents, merit points, and safety issues.",
    status: "published",
    version: 1,
    content: `
# Behavior & Conduct Records

## Purpose
Maintaining behavioral points, tracking infraction patterns, and issuing alerts.

## Who Can Access
* **Teachers**, **Counselors**, **Admins**

## Step-by-Step Instructions
1. Navigate to the **Behavior** portal.
2. Select a student and click **Log Incident**.
3. Choose incident type: **Merit** (positive) or **Infraction** (negative) and assign points.
4. Input description notes and save.
`,
    keywords: ["behavior", "conduct", "points", "incidents"]
  },
  {
    slug: "health-records",
    title: "Student Health Records",
    categoryId: "modules",
    summary: "Recording medical background details, drug allergies, and clinic logs.",
    status: "published",
    version: 1,
    content: `
# Student Health Records

## Purpose
Maintaining secure health lists, medical clearances, and tracking clinic visits.

## Who Can Access
* **Nurse**, **Admins**

## Step-by-Step Instructions
1. Navigate to **Health Records** under **Student Management**.
2. Select student profile to add allergies, chronic details, or emergency contacts.
3. Register walk-in clinic visits with diagnostic logs.
`,
    keywords: ["health", "medical", "allergies", "nurse"]
  },
  {
    slug: "academics",
    title: "Academics & Curriculums",
    categoryId: "modules",
    summary: "Managing subjects list, syllabus milestones, and lesson plans.",
    status: "published",
    version: 1,
    content: `
# Academics & Curriculums

## Purpose
Configuring curriculum types, allocating classes, and publishing syllabi.

## Who Can Access
* **Academic Coordinator**, **Admins**

## Step-by-Step Instructions
1. Navigate to **Academics** -> **Advanced Curriculum**.
2. Establish grade subjects and define curriculum pathways (e.g. National, International).
3. Assign lesson plans and publish.
`,
    keywords: ["academics", "curriculum", "syllabus"]
  },
  {
    slug: "timetable",
    title: "Timetable & Scheduling",
    categoryId: "modules",
    summary: "Building clash-free scheduling calendars and teacher allocations.",
    status: "published",
    version: 1,
    content: `
# Timetable & Scheduling

## Purpose
Constructing section timetables, managing teacher schedules, and resolving clashes.

## Who Can Access
* **Academic Coordinator**, **School Admin**

## Step-by-Step Instructions
1. Navigate to **Timetable**.
2. Open a class slot grid and drag-and-drop subjects.
3. Resolve any highlighted teacher conflicts before saving.
`,
    keywords: ["timetable", "clash", "schedule", "periods"]
  },
  {
    slug: "gradebook",
    title: "Gradebook & Report Cards",
    categoryId: "modules",
    summary: "Entering marks, calculating GPA averages, and generating report cards.",
    status: "published",
    version: 1,
    content: `
# Gradebook & Report Cards

## Purpose
Entering assessment results, calculating final grades, and printing report cards.

## Who Can Access
* **Teachers**, **Principal**, **Admins**

## Step-by-Step Instructions
1. Navigate to **Gradebook**.
2. Select assessment category and grade/subject coordinates.
3. Input marks manually or upload marks spreadsheets.
4. Click **Publish Grades** to sync with student and parent portals.
`,
    keywords: ["gradebook", "marks", "report card", "grades"]
  },
  {
    slug: "finance",
    title: "Finance & Fee Collections",
    categoryId: "modules",
    summary: "Configuring tuition fees, recording invoice payments, and tracking budgets.",
    status: "published",
    version: 1,
    content: `
# Finance & Fee Collections

## Purpose
Establishing tuition frameworks, tracking payments, and running ledger reports.

## Who Can Access
* **Accountant**, **Admins**

## Step-by-Step Instructions
1. Navigate to **Finance** -> **Fees Management**.
2. Select **Generate Invoices** to bill students based on active structures.
3. Collect outstanding balances and issue PDF receipts.
`,
    keywords: ["finance", "fees", "invoices", "payments"]
  },
  {
    slug: "ai-center",
    title: "AI Center & Predictive Analytics",
    categoryId: "modules",
    summary: "Using AI models to calculate student risk scores and generate smart timetables.",
    status: "published",
    version: 1,
    content: `
# AI Center & Predictive Analytics

## Purpose
Analyzing cohort risks, calculating drop-out parameters, and querying the AI tutor.

## Who Can Access
* **Super Admin**, **Principal**, **Teachers**

## Step-by-Step Instructions
1. Go to **AI Center** or **Predictive Analytics**.
2. Review the **Priority Hub** displaying at-risk students.
3. Use the AI prompt query interface for suggestions.
`,
    keywords: ["ai center", "risk score", "predictive"]
  },
  {
    slug: "library",
    title: "Library Management",
    categoryId: "modules",
    summary: "Managing catalog inventory, circulation checkouts, and late fines.",
    status: "published",
    version: 1,
    content: `
# Library Management

## Purpose
Cataloging books, tracking lending cycles, and issuing checkouts.

## Who Can Access
* **Librarian**, **Admins**

## Step-by-Step Instructions
1. Go to **Library** -> **Inventory** to add new books.
2. Select **Check Out** to log a student lending record.
3. Process returns to complete check-in cycles.
`,
    keywords: ["library", "books", "checkout", "librarian"]
  }
];
