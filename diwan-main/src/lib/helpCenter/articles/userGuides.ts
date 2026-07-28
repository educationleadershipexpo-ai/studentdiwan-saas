import type { HelpArticle } from "../types";

export const userGuidesArticles: HelpArticle[] = [
  {
    slug: "super-admin",
    title: "Super Admin Guide",
    categoryId: "user-guides",
    summary: "System override configurations, tenant controls, and root settings.",
    status: "published",
    version: 1,
    content: `
# Super Admin Guide

## Purpose
Detailed guide for Super Admins to manage institutional setups, system configurations, and security overrides.

## Who Can Access
* **Super Admin**

## Prerequisites
* High-security administrative profile.

## Overview
The Super Admin role sits at the peak of the authorization hierarchy. Super Admins configure system-wide parameters, manage databases, establish backups, and assign root permissions.

## Step-by-Step Instructions
1. Access root configurations via **Settings** -> **System Settings**.
2. Modify operational frameworks (e.g. SMTP setups, payment integrations).
3. Access security parameters to configure global rate-limit protocols.
4. Execute full backups via the terminal command or dashboard utility.

## Important Notes
* Actions taken by a Super Admin are logged in the **Audit Logs** for security audits.

## Best Practices
* Do not share the root Super Admin credentials. Use individual Admin roles for day-to-day operations.
`,
    keywords: ["super admin", "root", "system administration"]
  },
  {
    slug: "school-admin",
    title: "School Admin Guide",
    categoryId: "user-guides",
    summary: "Daily administrative workflows, admissions, and settings.",
    status: "published",
    version: 1,
    content: `
# School Admin Guide

## Purpose
Guiding school administrators through daily student directories, registrations, and staff onboarding.

## Who Can Access
* **School Admin**

## Prerequisites
* Admin account privileges.

## Overview
School Admins coordinate student directory operations, class rosters, and staff scheduling, serving as the bridge between management and academic users.

## Step-by-Step Instructions
1. Navigate to **Student Management** to add, edit, or delete student profiles.
2. Select **Staff & HR** to coordinate employee directories.
3. Establish timetable matrices and approve section configurations.
`,
    keywords: ["school admin", "admissions", "staff onboarding"]
  },
  {
    slug: "principal",
    title: "Principal & Leadership Guide",
    categoryId: "user-guides",
    summary: "Academic approvals, student performance reports, and compliance.",
    status: "published",
    version: 1,
    content: `
# Principal & Leadership Guide

## Purpose
Academic monitoring, class observation logs, and performance oversight.

## Who Can Access
* **Principal**
* **Vice Principal**

## Prerequisites
* Leadership profile settings.

## Overview
Principals utilize read-only academic dashboards to monitor campus compliance, audit grading standards, and authorize final report card layouts.

## Step-by-Step Instructions
1. Access student academic metrics via **Analytics** -> **Academic Reports**.
2. Review grade distribution sheets under **Gradebook**.
3. Conduct class appraisals under **Staff & HR** -> **Appraisals**.
`,
    keywords: ["principal", "reports", "approvals"]
  },
  {
    slug: "teacher",
    title: "Teacher Portal Guide",
    categoryId: "user-guides",
    summary: "Class scheduling, daily attendance, marks entry, and assignment review.",
    status: "published",
    version: 1,
    content: `
# Teacher Portal Guide

## Purpose
Comprehensive instructions for daily attendance, schedule review, and grading.

## Who Can Access
* **Class Teacher**
* **Subject Teacher**

## Prerequisites
* Assigned subjects in **Subject Allocation**.

## Overview
Teachers manage student progress, gradebook inputs, behavior points, and assignments for classes allocated to them.

## Step-by-Step Instructions
1. Input daily class attendance under **Attendance** -> **Student Attendance**.
2. Create and distribute class tasks via **Academics** -> **Assignments**.
3. Log marks inside the **Gradebook** panel for examinations.
`,
    keywords: ["teacher", "grading", "attendance", "assignments"]
  },
  {
    slug: "student",
    title: "Student Portal Guide",
    categoryId: "user-guides",
    summary: "Viewing timetables, homework submissions, and flashcards.",
    status: "published",
    version: 1,
    content: `
# Student Portal Guide

## Purpose
Accessing schedules, studying resources, submitting tasks, and tracking grades.

## Who Can Access
* **Student**

## Prerequisites
* Student credential profile.

## Overview
Students view active timetables, submit homework assignments, practice revision flashcards, and communicate with instructors.

## Step-by-Step Instructions
1. Review classes for the day via **Timetable**.
2. Download study resources under **Study Materials**.
3. Review and submit homework under **Assignments**.
`,
    keywords: ["student", "homework", "grades", "timetable"]
  },
  {
    slug: "parent",
    title: "Parent Portal Guide",
    categoryId: "user-guides",
    summary: "Monitoring child progress, attendance alerts, and fee payments.",
    status: "published",
    version: 1,
    content: `
# Parent Portal Guide

## Purpose
Instructing parents on child progress audits, fee payments, and school comms.

## Who Can Access
* **Parent**

## Prerequisites
* Linked parent-student credential set.

## Overview
Parents review attendance logs, behavior logs, fee payment invoices, and report cards for their children.

## Step-by-Step Instructions
1. Review child attendance inside the **Attendance** summary card.
2. Select **Finance** -> **Payments** to view outstanding invoices and make credit card payments.
3. Review performance records in the **Report Cards** tab.
`,
    keywords: ["parent", "invoices", "child progress"]
  },
  {
    slug: "accountant",
    title: "Accountant Guide",
    categoryId: "user-guides",
    summary: "Billing setup, dynamic discount plans, and financial audits.",
    status: "published",
    version: 1,
    content: `
# Accountant Guide

## Purpose
Financial auditing, fee structure settings, and invoicing rules.

## Who Can Access
* **Accountant**

## Prerequisites
* Accountant profile authorization.

## Overview
Accountants configure fee frameworks, manage discount plans (scholarships, sibling reductions), and review ledgers.

## Step-by-Step Instructions
1. Set fee rules in **Finance** -> **Fees**.
2. Review banking transactions in **Transactions**.
3. Approve purchase budget limits in **Purchase Approvals**.
`,
    keywords: ["accountant", "finance", "fees", "reconciliation"]
  },
  {
    slug: "hr",
    title: "HR Portal Guide",
    categoryId: "user-guides",
    summary: "Staff payroll, recruitment panels, appraisals, and leave approvals.",
    status: "published",
    version: 1,
    content: `
# HR Portal Guide

## Purpose
Personnel directories, payroll processing, and staff schedule review.

## Who Can Access
* **HR Manager**

## Prerequisites
* HR profile settings.

## Overview
HR Managers manage the staff lifecycle: onboarding, leave management, monthly payroll processing, and annual performance appraisals.

## Step-by-Step Instructions
1. Access the staff directory via **Staff & HR** -> **Staff Directory**.
2. Process leave approvals in **Leave Management**.
3. Initiate payroll calculations in **Payroll Processing**.
`,
    keywords: ["hr", "payroll", "leave", "appraisals"]
  },
  {
    slug: "librarian",
    title: "Librarian Guide",
    categoryId: "user-guides",
    summary: "Library cataloging, book issue logs, and shelf management.",
    status: "published",
    version: 1,
    content: `
# Librarian Guide

## Purpose
Cataloging library books, checking materials in/out, and tracking fines.

## Who Can Access
* **Librarian**

## Prerequisites
* Librarian permissions.

## Overview
Librarians manage the media inventory, assign items to specific shelves, and issue checkout records.

## Step-by-Step Instructions
1. Register books in **Library** -> **Inventory**.
2. Select **Check Out** to log a student lending record.
3. Manage due alerts and issue fine invoices under **Library settings**.
`,
    keywords: ["librarian", "library", "books", "checkout"]
  },
  {
    slug: "transport-manager",
    title: "Transport Manager Guide",
    categoryId: "user-guides",
    summary: "Bus routing, student allocations, and route operations.",
    status: "published",
    version: 1,
    content: `
# Transport Manager Guide

## Purpose
Bus allocations, route mapping, and GPS tracking.

## Who Can Access
* **Transport Manager**

## Prerequisites
* Transport profile configurations.

## Overview
Transport Managers configure school bus fleets, assign drivers, establish stop coordinates, and allocate student riders.

## Step-by-Step Instructions
1. Map coordinates under **Transport** -> **Routes**.
2. Assign students to specific buses via **Transport** -> **Student Allocations**.
3. Monitor vehicle statuses in **Vehicles**.
`,
    keywords: ["transport", "routes", "vehicles", "drivers"]
  },
  {
    slug: "receptionist",
    title: "Receptionist & Front Desk Guide",
    categoryId: "user-guides",
    summary: "Lead follow-ups, visitor logs, and gate pass processing.",
    status: "published",
    version: 1,
    content: `
# Receptionist & Front Desk Guide

## Purpose
Visitor registration, visitor badge prints, and student check-ins.

## Who Can Access
* **Receptionist**

## Prerequisites
* Receptionist role permissions.

## Overview
Receptionists handle the school front desk: logging visitors, issuing gate passes, and recording inquiries.

## Step-by-Step Instructions
1. Register incoming walk-ins via **Security** -> **Visitor Log**.
2. Issue late arrival gate passes under **Gate Pass**.
3. Record new registration inquiries in **Admissions** -> **Inquiries**.
`,
    keywords: ["receptionist", "visitor", "gate pass"]
  }
];
