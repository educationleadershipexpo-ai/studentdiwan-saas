import type { HelpArticle } from "../types";

export const releaseNotesChangelogArticles: HelpArticle[] = [
  {
    slug: "release-notes-v2",
    title: "Release Notes — Version 2.4.0",
    categoryId: "release-notes",
    summary: "Overview of changes, performance upgrades, and the new AI Priority Hub.",
    status: "published",
    version: 1,
    content: `
# Release Notes — Version 2.4.0

## Overview
Version 2.4.0 introduces the **AI Priority Hub**, featuring predictive student analysis, enhanced multi-branch security scopes, and automated student-parent login provisioning.

## What's New
* **AI Center**: Predictive student risk modeling based on class attendance, grades, and fee balances.
* **Auto Login Provisioning**: Automatic creation of matching student and parent credentials when a student profile is admitted.
* **Security & Session Layer**: Enforced timing-safe scrypt password checks and HMAC Authorization signatures on all API requests.
`,
    keywords: ["release notes", "new features", "version 2.4", "updates"]
  },
  {
    slug: "changelog",
    title: "System Changelog History",
    categoryId: "changelog",
    summary: "Chronological log of features, optimizations, bug fixes, and patch releases.",
    status: "published",
    version: 1,
    content: `
# System Changelog History

## v2.4.0 (2026-07-16)
* **Feature**: Integrated AI Priority Hub for student monitoring.
* **Feature**: Auto-provisioning of matching student and parent logins.
* **Security**: Upgraded session storage tokens to HMAC signed format.
* **Security**: Replaced plaintext passwords with timing-safe scrypt hashes.

## v2.3.5 (2026-06-10)
* **Fix**: Resolved Framer Motion rendering lag on the Student directory table.
* **Localization**: Aligned translation dictionaries for English and Arabic layouts.
`,
    keywords: ["changelog", "commits", "history", "version log"]
  }
];
