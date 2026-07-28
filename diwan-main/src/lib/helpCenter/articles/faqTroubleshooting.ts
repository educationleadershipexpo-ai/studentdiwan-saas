import type { HelpArticle } from "../types";

export const faqTroubleshootingArticles: HelpArticle[] = [
  {
    slug: "general-faq",
    title: "General FAQ",
    categoryId: "faq",
    summary: "Frequently asked questions about system usage, access rules, and roles.",
    status: "published",
    version: 1,
    content: `
# General FAQ

## Q: How do I change the interface language to Arabic?
A: Click the **Language Selector** (marked as "EN" or "AR" globe icon) in the top-right corner of the top navigation bar to toggle between English and Arabic layouts.

## Q: Why is my dashboard view different from my colleague's view?
A: Student Diwan uses strict Role-Based Access Control (RBAC). Your dashboard is tailored to show only the metrics and shortcuts relevant to your assigned role (e.g., Accountant vs. Teacher).
`,
    keywords: ["faq", "help", "language", "arabic", "dashboard"]
  },
  {
    slug: "finance-faq",
    title: "Finance & Fee Payments FAQ",
    categoryId: "faq",
    summary: "Questions regarding invoicing schedules, online credit card payments, and receipts.",
    status: "published",
    version: 1,
    content: `
# Finance & Fee Payments FAQ

## Q: Which online payment gateways are supported for paying school fees?
A: Parents can pay fees using **Stripe** or **PayTabs** payment gateways. These can be configured by the Super Admin inside integration settings.

## Q: How are sibling discounts applied?
A: Sibling discounts are calculated automatically during the invoicing process if the children share linked parent emails in their profiles.
`,
    keywords: ["faq", "finance", "fees", "payments", "sibling discount"]
  },
  {
    slug: "login-troubleshooting",
    title: "Sign In & Login Issues",
    categoryId: "troubleshooting",
    summary: "Troubleshooting steps for forgotten credentials, session errors, and redirects.",
    status: "published",
    version: 1,
    content: `
# Sign In & Login Issues

## Purpose
Resolving login blockages, credential errors, and loop redirects.

## Overview
Login failures generally occur due to selecting the wrong portal card, mistyping credentials, or IP rate-limiting.

## Step-by-Step Instructions
1. Confirm you have clicked the correct portal card (Staff, Student, or Parent) on the login screen.
2. If your account is rate-limited (too many failed attempts), wait 60 seconds for the IP block to clear.
3. Click the **Forgot Password?** link to request a reset link if you cannot remember your password.
`,
    keywords: ["troubleshooting", "login error", "password reset", "rate limit"]
  },
  {
    slug: "class-roster-troubleshooting",
    title: "Empty Class & Enrollment Issues",
    categoryId: "troubleshooting",
    summary: "Why a class directory shows zero students and how to verify rosters.",
    status: "published",
    version: 1,
    content: `
# Empty Class & Enrollment Issues

## Purpose
Fixing missing student assignments on class lists or timetables.

## Step-by-Step Instructions
1. Navigate to **Student Management** -> **Student Directory** and verify that the student is active.
2. Select **Academics** -> **Classes** and check the section list.
3. If the student has not been assigned an active **Enrollment** record for the term, create one to assign them to a class section.
`,
    keywords: ["troubleshooting", "empty class", "enrollment", "missing students"]
  }
];
