import type { UserGuide } from '@/lib/userGuides/types';

export const libraryGuide: UserGuide = {
  id: 'library',
  role: 'Librarian',
  title: 'Librarian Guide',
  tagline: 'Manage the school library with ease — catalog, issue, return, and generate reports in minutes.',
  audience: 'School librarians and library assistants',
  icon: 'BookMarked',
  gradient: 'from-purple-600 to-violet-700',
  accentHex: '#7c3aed',
  badgeBg: 'bg-purple-100 dark:bg-purple-950/40',
  badgeText: 'text-purple-700 dark:text-purple-300',
  estimatedMinutes: 25,
  version: '1.0.0',
  lastUpdated: '2025-07-01',
  chapters: [
    {
      id: 'library-intro',
      number: 1,
      title: 'Introduction to Library Management',
      icon: 'Library',
      summary: 'Get an overview of the Student Diwan library module and your role as librarian.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Welcome to the Library Module\n\nThe Student Diwan library module is a full-featured integrated library system (ILS) for school libraries. It lets you maintain a digital catalog of every book and resource in your collection, manage book issues and returns, track member borrowing history, apply and waive fines, and generate usage reports.\n\nThe module is accessible to librarians via the web portal, while students and parents can search the catalog and view borrowing status from their own portals.',
        },
        {
          type: 'table',
          caption: 'Librarian Module Permissions',
          headers: ['Feature', 'What Librarians Can Do', 'Access Level'],
          rows: [
            ['Book Catalog', 'Add, edit, and deactivate book records; manage copies per title', 'Full'],
            ['Issue Books', 'Issue books to students and staff; set due dates', 'Full'],
            ['Return Books', 'Process returns, inspect condition, calculate fines', 'Full'],
            ['Renewals', 'Renew an issue if no reservation is pending for the title', 'Full'],
            ['Reservations', 'View and manage student reservations for unavailable titles', 'Full'],
            ['Members', 'View member profiles, borrowing history, and fine balances', 'Read & Update'],
            ['Fines', 'Apply, waive, and collect fines; generate fine receipts', 'Full'],
            ['Reports', 'Generate catalog, circulation, and fine reports', 'Read & Export'],
            ['Settings', 'Configure fine rates, borrowing limits, and loan periods', 'Admin only'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Catalog Visibility',
          body: 'The book catalog is visible to all students and parents in a read-only, search-only mode. Only librarians can add, edit, or remove books. Students cannot reserve books directly — they must request through the librarian.',
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['Library', 'Alt + L', '⌘ Shift + L'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'More Ways to Navigate',
          body: 'Press ? anywhere (when not typing) to open the full Keyboard Shortcuts guide. Use Ctrl + K (⌘ K on Mac) to open the Command Palette and jump to any page by name.',
        },
      ],
    },
    {
      id: 'library-login',
      number: 2,
      title: 'Login & Library Dashboard',
      icon: 'KeyRound',
      summary: 'Sign in to the librarian portal and understand the dashboard layout.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Accessing the Library Module\n\nYour school administrator will set up your librarian account. Log in via the "Librarian" role on the Student Diwan portal to access the full library management interface.',
        },
        {
          type: 'steps',
          title: 'Logging In',
          steps: [
            {
              title: 'Open the Portal',
              description: "Navigate to your school's Student Diwan URL in any modern browser.",
            },
            {
              title: 'Select "Librarian"',
              description: 'Click the "Librarian" card on the role-selection screen.',
            },
            {
              title: 'Enter Your Credentials',
              description: 'Input your email and password, then click "Sign In".',
            },
            {
              title: 'Review the Dashboard',
              description: 'Your dashboard displays: total books in catalog, books currently issued, books overdue, and pending reservations.',
              tip: 'Pay attention to the "Overdue Books" count every morning — these require follow-up with the borrower.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/library-books.png',
          caption: 'The library catalog page showing book listings with availability and quick-action buttons.',
          alt: 'Library catalog with search bar, book cards, availability badges, and issue/return actions',
          annotations: [
            {
              id: 1,
              x: 7,
              y: 50,
              label: 'Library Sidebar',
              description: 'Access Catalog, Issue, Return, Members, Fines, and Reports modules.',
            },
            {
              id: 2,
              x: 25,
              y: 18,
              label: 'Total Books',
              description: 'Total number of unique titles in the library catalog.',
            },
            {
              id: 3,
              x: 55,
              y: 18,
              label: 'Currently Issued',
              description: 'Number of book copies currently checked out by members.',
            },
            {
              id: 4,
              x: 80,
              y: 18,
              label: 'Overdue',
              description: 'Books whose due date has passed and have not yet been returned.',
            },
            {
              id: 5,
              x: 50,
              y: 55,
              label: 'Catalog Grid',
              description: 'Browse all books with their cover, title, author, category, and availability status.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Quick Search',
          body: 'Use the global search bar (Ctrl+K or Cmd+K) anywhere in the library module to instantly find a book by title, ISBN, or author without navigating to the catalog first.',
        },
      ],
    },
    {
      id: 'library-catalog',
      number: 3,
      title: 'Book Catalog Management',
      icon: 'Layers',
      summary: 'Add new books, manage copies, update book details, and organise the library collection.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Maintaining the Book Catalog\n\nThe catalog is the heart of the library system. Each record represents a unique title and holds all bibliographic information, including multiple copy records for titles you own more than one copy of.',
        },
        {
          type: 'steps',
          title: 'Adding a New Book',
          steps: [
            {
              title: 'Open the Catalog',
              description: 'Click "Catalog" in the sidebar, then press "+ Add Book".',
            },
            {
              title: 'Enter Bibliographic Details',
              description: 'Fill in: Title, Author(s), ISBN, Publisher, Year of Publication, Edition, Language, and Subject/Category.',
              tip: 'Enter the ISBN and click "Auto-fill" — the system will fetch bibliographic data from an online database, saving manual entry time.',
            },
            {
              title: 'Set Location Details',
              description: 'Assign the Dewey Decimal or school-specific call number, shelf location (row and bay), and subject section.',
            },
            {
              title: 'Add Copies',
              description: 'Indicate how many physical copies you have. Each copy gets a unique accession number. Enter those numbers or let the system auto-generate them.',
            },
            {
              title: 'Upload Cover Image',
              description: 'Optionally upload a cover image (JPG or PNG, max 2 MB) to make the catalog visually appealing for students browsing online.',
            },
            {
              title: 'Save the Record',
              description: 'Click "Save Book". The title is now live in the catalog and visible to students searching from their portal.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Deactivating vs. Deleting',
          body: 'Never delete a book record that has been issued in the past. Instead, deactivate it — this hides it from the catalog while preserving the full issue history. Deletion is permanent and will remove historical circulation records.',
        },
      ],
    },
    {
      id: 'library-issue-return',
      number: 4,
      title: 'Issue & Return',
      icon: 'ArrowLeftRight',
      summary: 'Check out books to members, process returns, handle renewals, and manage reservations.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Issuing and Returning Books\n\nThe issue and return workflow is the core daily operation of the library. Student Diwan makes it fast: search for the member, pick the book, and confirm — the system handles due date calculation and updates the catalog availability instantly.',
        },
        {
          type: 'steps',
          title: 'Issuing a Book to a Student',
          steps: [
            {
              title: 'Open the Issue Module',
              description: 'Click "Issue Book" in the sidebar.',
            },
            {
              title: 'Find the Member',
              description: 'Search by student name, ID, or scan their library card barcode.',
            },
            {
              title: 'Check Eligibility',
              description: "The system shows the member's current issued books, outstanding fines, and remaining borrowing slots. Resolve any outstanding fines before issuing a new book.",
              tip: "A member with an outstanding fine above the school's threshold will be blocked from borrowing until the fine is settled.",
            },
            {
              title: 'Select the Book',
              description: "Search for the book by title or ISBN, or scan the accession barcode on the book's back cover.",
            },
            {
              title: 'Confirm and Issue',
              description: 'Review the due date (calculated based on loan period settings) and click "Issue". Print or email the issue slip to the student.',
            },
          ],
        },
        {
          type: 'steps',
          title: 'Processing a Book Return',
          steps: [
            {
              title: 'Open the Return Module',
              description: 'Click "Return Book" in the sidebar.',
            },
            {
              title: 'Scan or Search the Book',
              description: "Scan the book's accession barcode or search by title to find the active issue record.",
            },
            {
              title: 'Inspect and Confirm Condition',
              description: `Note the book's physical condition. If damaged, select "Damaged" and add a description. Normal returns select "Good Condition".`,
            },
            {
              title: 'Calculate Fine (if any)',
              description: 'If the book is returned after the due date, the fine is calculated automatically. Collect the fine or apply a waiver with a reason.',
            },
            {
              title: 'Complete the Return',
              description: `Click "Confirm Return". The copy's status reverts to "Available" in the catalog immediately.`,
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/library-issues.png',
          caption: 'The issue management page showing active issues with member details and due dates.',
          alt: 'Library issues table with member name, book title, issue date, due date, and status columns',
          annotations: [
            {
              id: 1,
              x: 85,
              y: 10,
              label: 'Issue New Book',
              description: 'Start the checkout flow for a new borrower.',
            },
            {
              id: 2,
              x: 15,
              y: 40,
              label: 'Member Name',
              description: 'Name and student ID of the borrower.',
            },
            {
              id: 3,
              x: 50,
              y: 40,
              label: 'Due Date',
              description: 'Date by which the book must be returned. Turns red when overdue.',
            },
            {
              id: 4,
              x: 75,
              y: 40,
              label: 'Actions',
              description: 'Renew or Return buttons for each active issue.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Renewals',
          body: 'To renew a book, open the active issue record and click "Renew". The system extends the due date by the standard loan period. Renewals are blocked if another member has reserved the same title.',
        },
      ],
    },
    {
      id: 'library-members',
      number: 5,
      title: 'Members & Fines',
      icon: 'Users',
      summary: 'View member profiles, borrowing histories, and manage fine collection and waivers.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Managing Library Members\n\nEvery student and staff member who uses the library is a "Member" in the system. Their profile stores their borrowing history, current issues, fine balance, and membership status. Members are automatically created when a student or staff account is activated in Student Diwan.',
        },
        {
          type: 'steps',
          title: 'Viewing and Managing Member Accounts',
          steps: [
            {
              title: 'Open the Members Module',
              description: 'Click "Members" in the library sidebar.',
            },
            {
              title: 'Search for a Member',
              description: 'Find a student or staff member by name, ID, or class.',
            },
            {
              title: 'Review the Member Profile',
              description: 'The profile shows: active issues and their due dates, borrowing history (all past issues), current fine balance, and membership status (Active, Suspended).',
            },
            {
              title: 'Collect or Waive a Fine',
              description: 'In the "Fines" tab within the member profile, you can collect the fine (record cash payment or link to fee invoice), partially waive it, or fully waive it with a written reason.',
              tip: 'All waiver actions are logged with your user ID and require a reason. Repeated unexplained waivers may be reviewed by the administrator.',
            },
            {
              title: 'Suspend or Reinstate Membership',
              description: 'If a member has lost books or has persistent unpaid fines, click "Suspend Membership". They cannot borrow until the issue is resolved and you click "Reinstate".',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Fine Policy',
          body: 'Fine rates (e.g., per day per book) are configured by the school administrator in Library Settings. If the current rate seems incorrect or disputes arise, contact your administrator — do not manually adjust issue dates to circumvent fines.',
        },
      ],
    },
    {
      id: 'library-reports-faq',
      number: 6,
      title: 'Reports & FAQ',
      icon: 'FileBarChart',
      summary: 'Generate library usage reports and find answers to common librarian questions.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Library Reports\n\nThe Reports module gives you data-driven insights into library usage, circulation trends, and fine collection. Use these reports to manage the collection, justify new purchases, and present usage statistics to school management.',
        },
        {
          type: 'steps',
          title: 'Generating a Circulation Report',
          steps: [
            {
              title: 'Open Reports',
              description: 'Click "Reports" in the library sidebar.',
            },
            {
              title: 'Select the Report Type',
              description: 'Choose from: Circulation Summary, Overdue Books List, Most Borrowed Titles, Fine Collection Summary, or Catalog Inventory.',
            },
            {
              title: 'Set Filters',
              description: 'Apply filters: date range, class, category, or member type (student/staff).',
            },
            {
              title: 'Generate and Export',
              description: 'Click "Generate". Export the report to PDF for printing or Excel for further analysis.',
              tip: 'The "Most Borrowed Titles" report is useful at the end of the academic year to identify which books need replacement copies.',
            },
          ],
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A student says they returned a book but it still shows as issued. What do I do?',
              a: 'First, physically search the shelves for the book. If found, process the return manually in the system. If the book cannot be located, mark it as "Returned – Book Missing" in the issue record and notify the administrator. A fine for the replacement cost may be applied.',
            },
            {
              q: 'How do I remove a lost or damaged book from the catalog?',
              a: `Open the book's catalog record, find the specific copy"s accession entry, and set its status to "Lost" or "Damaged – Withdrawn". This removes it from available circulation but preserves the issue history. If all copies are withdrawn, deactivate the title record.`,
            },
            {
              q: 'Can I issue a book to a staff member?',
              a: 'Yes. Staff members appear in the Members list just like students. The same issue and return workflow applies. Staff borrowing limits and loan periods may differ from student limits — these are configured by the administrator in Library Settings.',
            },
            {
              q: 'A fine was applied in error. How do I remove it?',
              a: `Open the member's profile, go to the "Fines" tab, select the incorrect fine entry, and click "Waive". Enter the reason (e.g., "Applied in error — system date mismatch") and confirm. The waiver is logged against your user ID.`,
            },
            {
              q: 'How do I handle a book that a student bought to replace a lost copy?',
              a: `When a student brings in a replacement book: inspect that it is the same title and edition, accept it, and add it as a new copy in the catalog under the same title record. Then mark the original lost copy's fine as "Settled – Physical Replacement" in the member's fine record.`,
            },
            {
              q: 'How do I export the full catalog for a stock audit?',
              a: 'Go to Reports > Catalog Inventory. Set no date filter and click Generate. Export to Excel. The spreadsheet includes all titles, copy counts, accession numbers, and current status — ideal for a physical stock audit.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'Annual Stocktaking',
          body: 'At the end of each academic year, run a full Catalog Inventory report and cross-check it with a physical stocktake. Mark any unaccounted copies as "Lost" in the system and present the findings to the administrator for write-off approval.',
        },
      ],
    },
    {
      id: 'library-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Find library documentation, resolve catalog and circulation issues, and get platform support.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre at `/help` gives you access to the Librarian Guide covering catalog management, book issuing and returns, member management, and reporting. For technical issues such as barcode scanning failures, catalog import errors, or report generation problems, the NeedHelp widget connects you to platform support.\n\nPress **Alt + Z** (Windows) or **⌘ Shift + Z** (Mac) from any page to open the Help Centre instantly.",
        },
        {
          type: 'steps',
          title: 'How to Open the Help Centre',
          steps: [
            {
              title: 'Press Alt + Z or ⌘ Shift + Z',
              description: 'Open the Help Centre from any page in the app. Useful when you need a quick reference during a busy borrowing session.',
            },
            {
              title: 'Click Help in the Sidebar',
              description: 'The Help icon at the bottom of the left sidebar opens the Help Home page at /help.',
            },
            {
              title: 'Open the Librarian Guide',
              description: 'Go to /help/guides/library or select the Librarian card on the Guide Hub for your complete role manual covering all library workflows.',
            },
            {
              title: 'Report a System Issue',
              description: 'Click the floating ✦ button (bottom-right) to report technical issues such as catalog import failures, issue/return errors, or fine calculation discrepancies.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to Librarians',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Librarian Guide — Chapter 3', 'Book Catalog Management: adding books, editing records, ISBN lookup, and bulk import', '/help/guides/library'],
            ['Librarian Guide — Chapter 4', 'Issue & Return: issuing books to members, processing returns, and handling renewals', '/help/guides/library'],
            ['Librarian Guide — Chapter 5', 'Members & Fines: managing borrower accounts, calculating fines, and recording payments', '/help/guides/library'],
            ['Librarian Guide — Chapter 6', 'Reports & FAQ: overdue reports, inventory reports, and common troubleshooting steps', '/help/guides/library'],
            ['Help Category Browser', 'Searchable articles on library configuration, fine policies, and catalog data management', '/help'],
            ['NeedHelp Widget', 'Report catalog errors, import failures, fine calculation issues, or export problems to platform support', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Use the School Admin for Member Account Issues',
          body: 'If a student or staff member is missing from your library member list, or their profile shows incorrect details (wrong class, wrong name), the fix needs to come from the School Admin module — library member records are synced from the student and staff directories. Contact your School Admin to update the source record, and the library module will reflect the change automatically.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A book I issued to a student is not showing as borrowed in their account. What should I check?',
              a: 'Verify the issue was saved successfully — go to Library → Issue & Return → Issued Books and search for the student. If the book is not listed, the issue transaction may not have saved (possibly a network interruption). Re-issue the book to the student and save again. If the book has already been returned physically, mark it as returned in the catalog to keep stock accurate.',
            },
            {
              q: 'A student says they returned a book but the system still shows it as borrowed. How do I clear it?',
              a: 'Go to Library → Issue & Return, find the active loan record for that student and book, and click "Return". If you cannot find the loan, search for the book in the catalog and check its status — it may be linked to a different member profile. If the book was returned to a different librarian who forgot to process it, enter the return now with the correct date.',
            },
            {
              q: 'How do I add a large batch of new books to the catalog?',
              a: 'Go to Library → Catalog → Import Books. Download the CSV template provided, fill in the book details (ISBN, title, author, publisher, copies, category), and upload the file. The system validates each row and shows errors for any records that cannot be imported — fix the flagged rows and re-upload. For ISBN lookups during manual entry, use the "Fetch Book Details" button which auto-fills metadata from online databases.',
            },
            {
              q: 'The fine for an overdue book looks incorrect. How is it calculated?',
              a: 'Library fines are calculated based on the fine rate and grace period set by your School Admin in the library configuration (/settings → Library → Fine Policy). Go to the borrower\'s account, open the overdue loan, and check the daily rate and the number of overdue days shown. If the rate or grace period is wrong, ask your School Admin to update the fine policy settings.',
            },
          ],
        },
      ],
    },
  ],
};
