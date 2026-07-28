import type { HelpArticle } from "../types";

export const systemAdminArticles: HelpArticle[] = [
  {
    slug: "installation-requirements",
    title: "Server & Installation Requirements",
    categoryId: "system-admin",
    summary: "Hardware specifications and software dependencies needed to host Student Diwan.",
    status: "published",
    version: 1,
    content: `
# Server & Installation Requirements

## Purpose
Establishing hardware and software prerequisites for deploying the ERP in cloud or local environments.

## Who Can Access
* **Super Admin**
* **DevOps Engineer**

## Prerequisites
* Cloud server instance (e.g. AWS EC2, DigitalOcean Droplet, VPS) or local server hardware.

## Overview
Student Diwan runs as a Node.js web application utilizing Vite on the frontend and Express on the backend. Database integration supports both SQLite (WAL mode) and MySQL.

## Specifications
* **Operating System**: Linux (Ubuntu 20.04+ recommended) or Windows Server.
* **Processor**: Minimum 2 Cores (4 Cores recommended).
* **RAM**: Minimum 4 GB (8 GB recommended for large campuses).
* **Storage**: 40 GB SSD (NVMe storage recommended for databases).
* **Dependencies**: Node.js (v18.x or v20.x), NPM or Yarn, and PM2.
`,
    keywords: ["installation", "requirements", "node version", "server specifications"]
  },
  {
    slug: "backup-restore",
    title: "Database Backup & Restore Protocols",
    categoryId: "system-admin",
    summary: "Creating SQL backups, scheduling dump files, and restoring database instances.",
    status: "published",
    version: 1,
    content: `
# Database Backup & Restore Protocols

## Purpose
Procedures for creating database dump files, establishing cron backups, and recovering data.

## Who Can Access
* **Super Admin**

## Step-by-Step Instructions
### SQLite Backups
Run the backup script via npm:
\`\`\`bash
npm run backup
\`\`\`
This creates a timestamped database backup copy under the \`backups/\` folder.

### Restore Database
Restore a previous database file:
\`\`\`bash
# Restore specific file
node scripts/restore-database.mjs backups/database-backup-timestamp.db
\`\`\`
`,
    keywords: ["backup", "restore", "sql dump", "database restore"]
  },
  {
    slug: "database",
    title: "Database Configurations (SQLite & MySQL)",
    categoryId: "system-admin",
    summary: "Switching database engines, mapping tables, and tuning connections.",
    status: "published",
    version: 1,
    content: `
# Database Configurations (SQLite & MySQL)

## Purpose
Configuring SQLite for lightweight instances and transitioning to MySQL for SaaS scaling.

## Who Can Access
* **Super Admin**

## Overview
The application supports a dual-engine architecture. By default, it operates on a local SQLite file (\`local_database.db\`). To scale to multiple schools and branches, configure the MySQL connection strings in the \`.env\` file.
`,
    keywords: ["sqlite", "mysql", "database connection", "env config"]
  },
  {
    slug: "gateways",
    title: "SMTP, SMS, & Payment Gateways",
    categoryId: "system-admin",
    summary: "Integrating outbound SMTP mail configurations, Twilio SMS, Stripe, and PayTabs.",
    status: "published",
    version: 1,
    content: `
# SMTP, SMS, & Payment Gateways

## Purpose
Configuring system gateways for outreach emails, transaction SMS alerts, and invoices.

## Who Can Access
* **Super Admin**

## Step-by-Step Instructions
1. Navigate to **Settings** -> **Integrations**.
2. **SMTP**: Enter your mail server address, port (e.g. 587/465), secure protocol (TLS/SSL), username, and password. Click **Test Mail**.
3. **Payments**: Input Stripe API credentials (Public/Secret keys) or PayTabs profiles to support card checkouts in parent portals.
`,
    keywords: ["smtp", "payment gateway", "sms gateway", "stripe", "paytabs"]
  }
];
