export interface CategoryMeta {
  id: string;
  title: string;
  description: string;
  icon: string; // lucide-react icon name, resolved in the Help Center pages
}

export const HELP_CATEGORIES: CategoryMeta[] = [
  { 
    id: "getting-started", 
    title: "Getting Started", 
    description: "Welcome, quick start guides, first login steps, and initial setup workflows.", 
    icon: "Rocket" 
  },
  { 
    id: "user-guides", 
    title: "User Guides", 
    description: "Role-specific operational guides for Admins, Teachers, Students, Parents, Accountants, Librarians, and HR.", 
    icon: "BookOpen" 
  },
  { 
    id: "modules", 
    title: "Module Documentation", 
    description: "Deep-dives into specific application features (Dashboard, Admissions, Attendance, Timetable, Gradebook, AI Center, and Settings).", 
    icon: "LayoutGrid" 
  },
  { 
    id: "system-admin", 
    title: "System Administration", 
    description: "Installation, system specifications, backups, database settings, mail gateways, and security protocols.", 
    icon: "Cpu" 
  },
  { 
    id: "developer-docs", 
    title: "Developer Documentation", 
    description: "API authorization rules, endpoint registers, webhook triggers, error codes, and configuration variables.", 
    icon: "Code2" 
  },
  { 
    id: "faq", 
    title: "FAQ", 
    description: "Answers to common questions regarding operations, invoicing, grading configurations, and system behaviors.", 
    icon: "HelpCircle" 
  },
  { 
    id: "troubleshooting", 
    title: "Troubleshooting", 
    description: "Diagnostics, session recovery procedures, system access fixes, and browser compatibility solutions.", 
    icon: "AlertTriangle" 
  },
  { 
    id: "release-notes", 
    title: "Release Notes", 
    description: "Details on updates, system optimizations, patches, and feature additions.", 
    icon: "Sparkles" 
  },
  { 
    id: "changelog", 
    title: "Changelog", 
    description: "Chronological log of changes, versions, fixes, and updates across system iterations.", 
    icon: "History" 
  }
];
