import type { UserGuide } from '@/lib/userGuides/types';

export const accountantGuide: UserGuide = {
  id: 'accountant',
  role: 'Accountant',
  title: 'Accountant & Finance Guide',
  tagline: 'Manage school finances with precision — fee collection, expenses, and reports in one system.',
  audience: 'School accountants, finance officers, and bursar staff',
  icon: 'Wallet',
  gradient: 'from-green-600 to-emerald-700',
  accentHex: '#16a34a',
  badgeBg: 'bg-green-100 dark:bg-green-950/40',
  badgeText: 'text-green-700 dark:text-green-300',
  estimatedMinutes: 35,
  version: '1.0.0',
  lastUpdated: '2025-07-01',
  chapters: [
    {
      id: 'accountant-intro',
      number: 1,
      title: 'Introduction to Finance Management',
      icon: 'Landmark',
      summary: 'Understand the full scope of financial tools available in Student Diwan for accountants.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Welcome to the Finance Module\n\nStudent Diwan's finance module is purpose-built for school accountants and finance officers. It covers the complete financial lifecycle of a school: from raising fee invoices and collecting payments to recording expenses, reconciling accounts, and generating audit-ready reports.\n\nAll transactions are timestamped, user-attributed, and stored securely, giving you a full audit trail at all times.",
        },
        {
          type: 'table',
          caption: 'Accountant Module Permissions',
          headers: ['Module', 'Permitted Actions', 'Restricted From'],
          rows: [
            ['Fee Management', 'Create, edit, and void invoices; record payments; issue receipts', 'Deleting posted transactions'],
            ['Expense Recording', 'Log expenses, attach vouchers, categorise by cost centre', 'Approving capital expenditure (Admin only)'],
            ['Payroll', 'View payroll summaries and generate payslips', 'Modifying salary structures (HR/Admin only)'],
            ['Financial Reports', 'Generate P&L, cash flow, fee collection, and expense reports', 'Exporting data outside the portal without Admin approval'],
            ['Bank Reconciliation', 'Match transactions, mark reconciled, flag discrepancies', 'Editing bank master data'],
            ['Fee Structure', 'View fee structures per class and term', 'Modifying fee structures (Admin only)'],
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Audit Trail',
          body: 'Every action you take in the finance module — creating invoices, recording payments, or modifying records — is logged with your user ID and a timestamp. This log cannot be edited and is available to the school administrator for audit purposes.',
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['Finance & Fees', 'Alt + F', '⌘ Shift + F'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
            ['Fees', 'Alt + FE', '⌘ Shift + FE'],
            ['Transactions', 'Alt + TX', '⌘ Shift + TX'],
            ['Scholarships', 'Alt + SH', '⌘ Shift + SH'],
            ['Stock', 'Alt + ST', '⌘ Shift + ST'],
            ['Purchases', 'Alt + PU', '⌘ Shift + PU'],
            ['Vendors', 'Alt + VE', '⌘ Shift + VE'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'More Ways to Navigate',
          body: 'Hold Alt (Windows) or ⌘+Shift (Mac) then press the letter(s) shown above. For two-letter shortcuts like Alt + SM, keep holding Alt and press S then M in sequence. Press ? anywhere (when not typing) to open the full Keyboard Shortcuts guide.',
        },
      ],
    },
    {
      id: 'accountant-login',
      number: 2,
      title: 'Login & Finance Dashboard',
      icon: 'KeyRound',
      summary: 'Access the accountant portal and orient yourself on the finance dashboard.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Accessing the Finance Portal\n\nYour administrator will provision your accountant account and share your credentials. Log in using the accountant role on the Student Diwan portal and start from the Finance Dashboard.',
        },
        {
          type: 'steps',
          title: 'Logging In as an Accountant',
          steps: [
            {
              title: 'Navigate to the School Portal',
              description: "Open your browser and enter your school's Student Diwan URL.",
            },
            {
              title: 'Select the Accountant Role',
              description: 'Click the "Accountant" or "Finance" card on the role-selection page.',
            },
            {
              title: 'Enter Your Credentials',
              description: 'Input your registered email and password, then click "Sign In".',
            },
            {
              title: 'Review the Finance Dashboard',
              description: 'You land on the Finance Dashboard — a real-time overview of collections, outstanding fees, and recent transactions.',
              tip: 'The dashboard auto-refreshes every 5 minutes. Press F5 to force a manual refresh.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/finance-dashboard.png',
          caption: 'The Finance Dashboard showing collection summary, outstanding fees, and recent transactions.',
          alt: 'Finance dashboard with KPI cards for total collected, outstanding balance, and expense totals',
          annotations: [
            {
              id: 1,
              x: 7,
              y: 50,
              label: 'Finance Sidebar',
              description: 'Access Fees, Expenses, Payroll, Reports, and Reconciliation modules.',
            },
            {
              id: 2,
              x: 22,
              y: 20,
              label: 'Total Collected',
              description: 'Total fee amount collected in the current academic term.',
            },
            {
              id: 3,
              x: 50,
              y: 20,
              label: 'Outstanding Fees',
              description: 'Total amount pending across all unpaid invoices.',
            },
            {
              id: 4,
              x: 78,
              y: 20,
              label: 'Total Expenses',
              description: 'Total recorded school expenditure for the current period.',
            },
            {
              id: 5,
              x: 50,
              y: 55,
              label: 'Recent Transactions',
              description: 'Live feed of the latest payments received and expenses logged.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Daily Opening Check',
          body: 'Begin each working day by reviewing the Finance Dashboard for any failed payment notifications, overdue invoices, or pending expense approvals to ensure nothing falls through the cracks.',
        },
      ],
    },
    {
      id: 'accountant-fees',
      number: 3,
      title: 'Fee Collection & Invoicing',
      icon: 'Receipt',
      summary: 'Create invoices, record payments, issue receipts, and manage overdue accounts.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Managing Student Fees\n\nThe Fee Collection module lets you raise invoices for individual students or entire classes in bulk, record both online and offline payments, and issue official receipts. Overdue invoices are flagged automatically with configurable reminders sent to parents.',
        },
        {
          type: 'steps',
          title: 'Creating a Fee Invoice',
          steps: [
            {
              title: 'Go to Fee Management',
              description: 'Click "Fees" in the sidebar, then select "Invoices".',
            },
            {
              title: 'Click "New Invoice"',
              description: 'Press the "+ New Invoice" button in the top-right corner.',
            },
            {
              title: 'Select Student(s)',
              description: 'Search for a student by name, ID, or class. For bulk invoicing, select a class or grade and choose "Bulk Generate".',
              tip: 'Bulk invoice generation applies the class fee structure automatically — verify the structure is up to date before generating.',
            },
            {
              title: 'Select Fee Type and Term',
              description: 'Choose the fee category (Tuition, Transport, Library, etc.) and the academic term.',
            },
            {
              title: 'Review and Issue',
              description: 'Preview the invoice details, add any discounts or waivers if applicable, then click "Issue Invoice". The invoice is immediately visible in the parent portal.',
            },
          ],
        },
        {
          type: 'steps',
          title: 'Recording a Payment',
          steps: [
            {
              title: 'Open the Invoice',
              description: "Search for the student's invoice in the Invoices list and click it to open.",
            },
            {
              title: 'Click "Record Payment"',
              description: 'Press the "Record Payment" button on the invoice detail page.',
            },
            {
              title: 'Enter Payment Details',
              description: 'Select the payment method (Cash, Cheque, Online Transfer), enter the amount received, and add the transaction/cheque reference number.',
            },
            {
              title: 'Save and Issue Receipt',
              description: 'Click "Save". The invoice status changes to "Paid" and a receipt is generated automatically.',
              tip: 'Print the receipt for the parent or send it via email using the "Send Receipt" button.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/finance-fees.png',
          caption: 'The fee management page showing invoice list and payment recording panel.',
          alt: 'Finance fees page with invoice table, status filters, and record payment side panel',
          annotations: [
            {
              id: 1,
              x: 15,
              y: 15,
              label: 'Status Filter',
              description: 'Filter invoices by status: All, Pending, Paid, Overdue, or Voided.',
            },
            {
              id: 2,
              x: 85,
              y: 12,
              label: 'New Invoice Button',
              description: 'Create a single invoice or generate invoices in bulk for a class.',
            },
            {
              id: 3,
              x: 50,
              y: 45,
              label: 'Invoice Row',
              description: 'Each row shows student name, fee type, amount, due date, and current status.',
            },
            {
              id: 4,
              x: 82,
              y: 55,
              label: 'Record Payment',
              description: 'Opens the payment recording panel for the selected invoice.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'danger',
          title: 'Voiding an Invoice',
          body: 'Invoices can be voided (not deleted) if issued in error. A voided invoice remains on record with a "Voided" status and the reason you entered. You cannot void an invoice that has already been fully or partially paid — contact the administrator in that case.',
        },
      ],
    },
    {
      id: 'accountant-expenses',
      number: 4,
      title: 'Expense Management',
      icon: 'TrendingDown',
      summary: 'Log school expenditures, attach supporting vouchers, and track spending by category.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Recording School Expenses\n\nEvery school expenditure — from utility bills to stationery purchases — should be recorded in the Expenses module. This ensures an accurate picture of the school's financial position and simplifies end-of-year audits.",
        },
        {
          type: 'steps',
          title: 'Logging a New Expense',
          steps: [
            {
              title: 'Navigate to Expenses',
              description: 'Click "Expenses" in the Finance sidebar.',
            },
            {
              title: 'Click "+ Add Expense"',
              description: 'Press the "Add Expense" button to open the expense entry form.',
            },
            {
              title: 'Fill in Expense Details',
              description: 'Enter the expense date, category (Utilities, Maintenance, Salaries, Supplies, etc.), vendor name, and amount.',
            },
            {
              title: 'Attach a Voucher or Receipt',
              description: 'Upload a scanned copy or photo of the bill, receipt, or purchase order. Accepted formats: PDF, JPG, PNG (max 5 MB per file).',
              tip: 'Always attach supporting documentation. Expenses without vouchers may be flagged during audits.',
            },
            {
              title: 'Submit for Approval',
              description: 'Click "Save". Expenses above the pre-configured threshold are automatically routed to the administrator for approval before they are posted to the ledger.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Expense Categories',
          body: 'Expense categories are configured by your administrator. If you need a new category added (e.g., a new vendor type), contact the system administrator. Do not force-fit expenses into incorrect categories as this skews financial reports.',
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Recurring Expenses',
          body: 'For expenses that occur regularly (monthly rent, utility bills), use the "Recurring Expense" feature. Set the frequency and the system will generate the expense entry automatically each period, ready for your review and voucher attachment.',
        },
      ],
    },
    {
      id: 'accountant-reports',
      number: 5,
      title: 'Financial Reports',
      icon: 'BarChart2',
      summary: 'Generate fee collection reports, expense summaries, and audit-ready financial statements.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Generating Reports\n\nThe Reports module gives you configurable financial reports that can be exported to PDF or Excel. Whether you need a daily collection report for the principal or an annual statement for auditors, the module covers all standard school finance reporting needs.',
        },
        {
          type: 'steps',
          title: 'Generating a Fee Collection Report',
          steps: [
            {
              title: 'Open the Reports Module',
              description: 'Click "Reports" in the Finance sidebar.',
            },
            {
              title: 'Select Report Type',
              description: 'Choose from: Fee Collection Summary, Class-wise Collection, Outstanding Fees, Expense Summary, or Bank Reconciliation Statement.',
            },
            {
              title: 'Set the Date Range and Filters',
              description: 'Select the period (custom date range, month, term, or academic year) and any additional filters such as class, fee type, or payment method.',
            },
            {
              title: 'Generate the Report',
              description: 'Click "Generate". The report previews on screen within seconds.',
              tip: 'Use the "Schedule Report" option to have reports emailed to the principal or management automatically at a set frequency.',
            },
            {
              title: 'Export',
              description: 'Click "Export to PDF" for a printable version or "Export to Excel" for a spreadsheet you can analyse further.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'End-of-Term Checklist',
          body: 'At the end of each term, generate and archive: (1) Fee Collection Summary, (2) Outstanding Fees List, (3) Expense Summary, and (4) Bank Reconciliation Statement. Share these with the principal and retain copies for the audit file.',
        },
      ],
    },
    {
      id: 'accountant-faq',
      number: 6,
      title: 'Troubleshooting & FAQ',
      icon: 'HelpCircle',
      summary: 'Solutions to common issues accountants face in the Student Diwan finance module.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Finance Module FAQ\n\nFind answers to frequent accountant questions below. For issues not covered here, use the "Support" link in the portal or contact your system administrator.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A parent says they paid online but the invoice still shows as pending. What do I do?',
              a: 'Ask the parent for their payment transaction reference number. Search for it in the "Online Payments" reconciliation tab. If the payment is listed there as "Received" but not matched to an invoice, click "Match Manually" and select the correct invoice. If it is not listed at all, advise the parent to check with their bank.',
            },
            {
              q: 'I issued an invoice with the wrong fee amount. Can I correct it?',
              a: 'If the invoice has not been paid, void it and create a new invoice with the correct amount. If payment has already been received, you will need to raise a credit note and re-invoice — contact your administrator to assist with credit note creation.',
            },
            {
              q: 'How do I apply a fee concession or scholarship discount?',
              a: 'When creating or editing an invoice (before it is paid), use the "Discount / Concession" field to enter the discount amount or percentage. Add a note explaining the reason. The discount will be reflected on the invoice and parent-facing receipt.',
            },
            {
              q: 'The bank reconciliation shows a discrepancy. How do I investigate?',
              a: 'Go to Reports > Bank Reconciliation Statement and compare each transaction against your bank statement. Unmatched items are flagged in red. Click on a flagged item to see its details and manually match or flag it for review by the administrator.',
            },
            {
              q: 'Can I process a fee refund through the portal?',
              a: `Yes. Open the relevant paid invoice, click "Initiate Refund", enter the refund amount and reason, and submit. Refunds above the pre-configured limit require administrator approval before processing.`,
            },
            {
              q: 'How do I generate a receipt for a cash payment made at the counter?',
              a: 'Record the payment against the invoice using payment method "Cash" and enter the amount. The system generates a receipt immediately. You can print it or email it to the parent from the receipt view.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Escalation Path',
          body: 'For any transaction that cannot be resolved within the finance module — such as database errors, duplicate payment entries, or incorrect posted transactions — raise a ticket via the Help & Support portal and tag it as "Finance – Urgent". Your system administrator will assist within one business day.',
        },
      ],
    },
    {
      id: 'accountant-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Find finance documentation, resolve transaction issues, and escalate problems to the right team.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre at `/help` gives you access to the Accountant & Finance Guide, a searchable knowledge base covering fee structures and expense management, and a direct channel for reporting system errors.\n\nFor finance discrepancies that require data correction (wrong posted amounts, duplicate entries, or invoice mismatches), the NeedHelp widget connects you to platform support — and your Super Administrator can escalate urgent issues on your behalf.\n\nPress **Alt + Z** (Windows) or **⌘ Shift + Z** (Mac) from any page to open the Help Centre instantly.",
        },
        {
          type: 'steps',
          title: 'How to Open the Help Centre',
          steps: [
            {
              title: 'Press Alt + Z or ⌘ Shift + Z',
              description: 'Open the Help Centre from any page using this keyboard shortcut — no need to navigate away from your current task.',
            },
            {
              title: 'Click Help in the Sidebar',
              description: 'The Help icon at the bottom of the left sidebar opens the Help Home page at /help.',
            },
            {
              title: 'Open the Accountant Guide',
              description: 'Go to /help/guides/accountant or click the Accountant & Finance card on the Guide Hub for the full role manual.',
            },
            {
              title: 'Report a Finance System Error',
              description: 'For technical errors — pages not loading, incorrect calculations, or export failures — click the floating ✦ button to report the issue with full context.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to Accountants',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Accountant Guide — Chapter 3', 'Fee Collection & Invoicing: creating invoices, recording payments, and handling partial payments', '/help/guides/accountant'],
            ['Accountant Guide — Chapter 4', 'Expense Management: logging expenses, categorising outgoings, and managing suppliers', '/help/guides/accountant'],
            ['Accountant Guide — Chapter 5', 'Financial Reports: generating income statements, fee collection reports, and audit-ready exports', '/help/guides/accountant'],
            ['Accountant Guide — Chapter 6', 'Troubleshooting & FAQ: common finance errors, reconciliation steps, and escalation paths', '/help/guides/accountant'],
            ['Help Category Browser — Finance', 'Searchable articles on fee structures, payment gateways, tax settings, and invoice templates', '/help'],
            ['NeedHelp Widget', 'Report database errors, duplicate entries, or broken export features to platform support', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Finance Issues Need Fast Escalation',
          body: 'If you spot a transaction error that cannot be corrected within the Finance module — such as a payment posted to the wrong student, a duplicate invoice, or a balance that does not reconcile after a system update — use the NeedHelp widget immediately and tag your message "Finance – Urgent". Do not attempt to delete posted transactions manually; corrections should be made by platform support to preserve the audit trail.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'An invoice was generated with the wrong fee amount. Can I edit it?',
              a: 'Invoices in Student Diwan lock the amount at the time of creation to preserve the audit trail. To correct an error, cancel the original invoice (go to the invoice, click "Cancel Invoice"), then generate a new one with the correct amount. If the invoice has already been paid, contact your Super Administrator — a credit note or manual adjustment will be needed.',
            },
            {
              q: 'A parent says they paid but the system shows the invoice as outstanding. What do I do?',
              a: 'Ask the parent for their payment reference number or transaction ID. Check the payment gateway reconciliation report under Finance → Reports → Payment Reconciliation. If the payment is confirmed in the gateway but not reflected in Student Diwan, use the NeedHelp widget to report the discrepancy and include both the student ID and the payment reference.',
            },
            {
              q: 'The monthly fee collection report is showing a different total than what I calculated manually. Why?',
              a: 'Check whether the report date range includes only completed transactions or also pending ones. Partial payments and installments are sometimes counted differently. Also confirm whether any invoices were cancelled or credited during the period — cancelled invoices reduce the total. If the discrepancy remains after these checks, export the raw transaction list and compare line by line.',
            },
            {
              q: 'The CSV/Excel export is not downloading. What should I try?',
              a: 'First, try a different browser (Chrome or Firefox work best). Disable any browser extensions that block downloads. If the issue persists, try reducing the date range of the report — very large exports (thousands of rows) can time out. If nothing works, click the ✦ NeedHelp widget and report the export failure with the report type and date range you were trying to export.',
            },
          ],
        },
      ],
    },
  ],
};
