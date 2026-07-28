import type { HelpArticle } from "../types";

export const developerDocsArticles: HelpArticle[] = [
  {
    slug: "api-authentication",
    title: "API Authentication & Tokens",
    categoryId: "developer-docs",
    summary: "Generating tokens, authenticating endpoints via headers, and session lifecycles.",
    status: "published",
    version: 1,
    content: `
# API Authentication & Tokens

## Purpose
Explaining how developers can authenticate requests against the Student Diwan API using HMAC JWT-like tokens.

## Who Can Access
* **Super Admin**
* **External Integration Developers**

## Overview
Outbound API requests must include a valid bearer token in the Authorization header. Authentication is stateless, and signatures are verified using the system's \`SESSION_SECRET\`.

## Request Format
\`\`\`http
GET /api/data/Student HTTP/1.1
Host: school.studentdiwan.com
Authorization: Bearer <your_session_token>
Content-Type: application/json
\`\`\`
`,
    keywords: ["api auth", "bearer token", "jwt", "hmac signature"]
  },
  {
    slug: "api-endpoints",
    title: "Core API Endpoints Register",
    categoryId: "developer-docs",
    summary: "Register of RESTful JSON routes for student files, attendance logs, and billing.",
    status: "published",
    version: 1,
    content: `
# Core API Endpoints Register

## Purpose
Reference guide listing operational endpoints, supported parameters, and JSON responses.

## Overview
All database collections are accessible via RESTful resource calls under the \`/api/data/:entityName\` namespace.

### Student Management
* **GET** \`/api/data/Student\` — Fetch all students.
* **POST** \`/api/data/Student\` — Add a new student.
* **PUT** \`/api/data/Student/:id\` — Update a student record.
* **DELETE** \`/api/data/Student/:id\` — Delete a student profile.

### Attendance
* **GET** \`/api/data/AttendanceRecord\` — Fetch attendance sheets.
`,
    keywords: ["api endpoints", "rest api", "json routes", "methods"]
  },
  {
    slug: "environment-variables",
    title: "Environment Configuration Variables",
    categoryId: "developer-docs",
    summary: "Reference guide for all system environment variables (.env settings).",
    status: "published",
    version: 1,
    content: `
# Environment Configuration Variables

## Purpose
Reference guide detailing all supported parameters in the local \`.env\` configuration file.

## Variable Reference
* \`PORT\`: Express API server listening port (defaults to 3001).
* \`NODE_ENV\`: Application mode (\`development\` or \`production\`).
* \`SESSION_SECRET\`: HMAC signing secret (minimum 32 character hex string recommended).
* \`DB_HOST\`: MySQL host address (if empty, server defaults to SQLite mode).
* \`DB_USER\`: MySQL database username.
* \`DB_PASSWORD\`: MySQL database user password.
* \`DB_DATABASE\`: MySQL target database name.
`,
    keywords: ["env vars", "configuration", "database settings", "port"]
  }
];
