import type { HelpArticle } from "../types";

export const gettingStartedArticles: HelpArticle[] = [
  {
    slug: "welcome",
    title: "Welcome to Student Diwan",
    categoryId: "getting-started",
    summary: "An introduction to the Student Diwan School ERP and portal guidelines.",
    popular: true,
    status: "published",
    version: 1,
    content: `
# Welcome to Student Diwan

:::info
**Welcome!** Student Diwan is a premium, bilingual (English & Arabic) School Management System designed to unify operations, finance, academics, and communication in one connected platform.
:::

## Purpose
This guide introduces new users to the Student Diwan ecosystem, outlining the portal layouts, system capabilities, and how to begin navigating the interface.

## Who Can Access
* **All Roles**: Admins, Owners, Principals, Teachers, Students, Parents, Accountants, HR Managers, Librarians, Transport Managers, and Receptionists.

## Prerequisites
* A modern web browser (Google Chrome, Safari, Mozilla Firefox, or Microsoft Edge).
* Active login credentials provided by your school's administration.

## Overview
Student Diwan is structured as a multi-portal ERP that segregates operational panels depending on user roles. The system has three main entry interfaces:
1. **Staff Portal**: For teachers, administrators, finance officers, and HR personnel.
2. **Student Portal**: For student assignments, timetables, study materials, and report cards.
3. **Parent Portal**: For child tracking, fee payments, and attendance review.

## Step-by-Step Instructions
1. Navigate to the login screen of your school's instance.
2. Choose your designated portal card (e.g., Staff Portal).
3. Type in your registered email or login ID.
4. Input your password and click **Sign In**.
5. Upon successful authentication, the system will route you to your role-specific dashboard.

## Important Notes
* Password reset requests can be initiated from the login screen via the **Forgot Password?** link.
* For multi-branch institutions, ensure your branch selector (top bar) is set to the correct branch.

## Best Practices
* **Keep Sessions Secure**: Always sign out of your account when using shared computers in staff rooms or libraries.
* **Update Passwords**: Change your auto-generated temporary password immediately on your first login.

## Common Mistakes
* **Incorrect Portal Card**: Trying to sign in with a teacher account on the Student Portal card. Always click the correct portal type first.

## Frequently Asked Questions
### Q: Can I access the system on my mobile device?
A: Yes, Student Diwan features a fully responsive design optimized for tablet and mobile browser viewpoints.

## Related Articles
* [Quick Start Guide](/help/getting-started/quick-start-guide)
* [First Login Procedures](/help/getting-started/first-login)
`,
    keywords: ["welcome", "getting started", "introduction", "login", "portal"]
  },
  {
    slug: "quick-start-guide",
    title: "Quick Start Guide",
    categoryId: "getting-started",
    summary: "A rapid setup manual for new schools, departments, and administrators.",
    popular: true,
    status: "published",
    version: 1,
    content: `
# Quick Start Guide

:::tip
**Tip:** This guide is designed for school administrators who need to get the basic school structure up and running in under 30 minutes.
:::

## Purpose
To provide a fast-track sequence for setting up classes, importing students, and configuring key modules.

## Who Can Access
* **Super Admin**
* **School Owner**
* **School Admin**

## Prerequisites
* Active administrator account access.
* Basic details of grades, sections, and teachers.

## Overview
Getting started involves five core steps: defining academic terms, setting up grades/sections, enrolling staff, onboarding students, and configuring parent links.

## Step-by-Step Instructions
1. Navigate to **Settings** → **Academic Setup** and establish the active academic year.
2. Go to **Academics** → **Classes** and create your grades (e.g. Grade 1, Grade 2) and add sections (A, B, C).
3. Go to **Staff & HR** → **Staff Onboarding** and register teachers.
4. Go to **Student Management** → **Admissions** and import students using the bulk CSV uploader.
5. Setup **Finance** → **Fees** by creating fee categories (e.g., Tuition, Transport) to initialize parent billing.

## Important Notes
* Double-check class names during setup. Section labels should match the naming convention used in your physical school rosters (e.g. A, B, C).

## Best Practices
* Utilize CSV import sheets for student databases to save time. Download the CSV template from the Admissions screen before upload.

## Common Mistakes
* **Seeding without Academic Year**: Trying to create classes before setting up an active academic year, which orphans student enrollment records.

## Related Articles
* [School Setup Checklist](/help/getting-started/school-setup-checklist)
* [First Login Procedures](/help/getting-started/first-login)
`,
    keywords: ["quick start", "fast path", "setup steps", "admin start"]
  },
  {
    slug: "first-login",
    title: "First Login Procedures",
    categoryId: "getting-started",
    summary: "How to complete your first authentication step and secure your user profile.",
    status: "published",
    version: 1,
    content: `
# First Login Procedures

:::warning
**Security Notice:** Your temporary password is valid for initial login only. You must replace it to protect student records.
:::

## Purpose
Guiding new users through entering the system for the first time, resetting temporary passwords, and completing profiles.

## Who Can Access
* **All Roles**

## Prerequisites
* Welcome email or sheet containing login ID and temporary password.

## Overview
When an administrator provisions your account, the system generates a random temporary password. Your first login requires entering this token and setting a new, secure secret.

## Step-by-Step Instructions
1. Navigate to your school portal landing page.
2. Select your portal category (Staff, Student, or Parent).
3. Enter your login ID and temporary password.
4. Click **Sign In**. You will be prompted to choose a new password.
5. Input a new password (minimum 6 characters), confirm it, and submit.
6. Verify your profile details (phone, email) on the onboarding welcome modal.

## Important Notes
* If your email is incorrect, you will not receive password reset links. Contact your school administrator to correct it in the system.

## Best Practices
* Use a passphrase containing letters, numbers, and symbols.
* Do not reuse credentials from public email platforms.

## Common Mistakes
* **Typing spaces**: Copying the temporary password and accidentally adding an extra space before or after the password.

## Related Articles
* [Welcome to Student Diwan](/help/getting-started/welcome)
`,
    keywords: ["first login", "change password", "profile setup", "credentials"]
  },
  {
    slug: "initial-setup",
    title: "Initial System Setup",
    categoryId: "getting-started",
    summary: "Configuring system settings, currency, translations, and multi-branch variables.",
    status: "published",
    version: 1,
    content: `
# Initial System Setup

## Purpose
To establish institution-wide configurations, regional localizations, default currency codes, and branch allocations.

## Who Can Access
* **Super Admin**
* **School Owner**

## Prerequisites
* Initial system build deployed.
* Central database seeded.

## Overview
Before departments begin using Student Diwan, central system settings must be configured to ensure currency formats, receipts, and localized date settings align with regional compliance.

## Step-by-Step Instructions
1. Navigate to **Settings** → **System Settings**.
2. Set your **School Name**, **Contact Details**, and **Official Address**.
3. Choose the default currency (e.g. BHD, QAR, OMR) and date formatting criteria.
4. Configure **Localization Defaults** (Language switcher toggle settings).
5. Input your institutional logo in the **Branding** tab for automated PDF invoice generation.
6. Save settings to apply configurations globally.

## Important Notes
* Changing currency parameters mid-term does not retrospectively recalculate paid receipts; set currency once before financial transactions begin.

## Best Practices
* Prepare high-resolution PNG logos with transparent backgrounds to ensure PDF invoice receipts render clearly.

## Related Articles
* [School Setup Checklist](/help/getting-started/school-setup-checklist)
`,
    keywords: ["system setup", "currency", "branding", "settings"]
  },
  {
    slug: "school-setup-checklist",
    title: "School Setup Checklist",
    categoryId: "getting-started",
    summary: "A step-by-step master checklist to guide admins through initial onboarding.",
    status: "published",
    version: 1,
    content: `
# School Setup Checklist

## Purpose
A chronological master checklist verifying system configurations before opening portals to students and parents.

## Who Can Access
* **Super Admin**
* **School Admin**

## Prerequisites
* Core system installed and accessible.

## Overview
This list guarantees that prerequisite data exists across all related modules, ensuring smooth portal operations.

## Step-by-Step Instructions
Confirm that the following tasks are completed in order:
* [ ] **Active Term**: Configure the academic calendar and terms.
* [ ] **Roster Structure**: Setup Grades, Sections, and assigned Classrooms.
* [ ] **Staff Accounts**: Onboard teachers, accountants, and coordinators.
* [ ] **Student Records**: Bulk import students and assign sections.
* [ ] **Subject Registry**: Create subjects and allocate them to teachers.
* [ ] **Timetable Grid**: Build clash-free schedules for all sections.
* [ ] **Fee Structure**: Set up tuition plans and invoice templates.
* [ ] **Security Settings**: Active roles mapped to staff users.

## Best Practices
* Run database backups before running bulk imports or clearing databases.

## Related Articles
* [Initial System Setup](/help/getting-started/initial-setup)
`,
    keywords: ["checklist", "setup checklist", "steps", "tasks"]
  }
];
