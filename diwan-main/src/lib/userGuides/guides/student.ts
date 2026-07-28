import type { UserGuide } from '@/lib/userGuides/types';

export const studentGuide: UserGuide = {
  id: 'student',
  role: 'Student',
  title: 'Student Guide',
  tagline: 'Your academic life, organised — timetables, grades, library, and more at your fingertips.',
  audience: 'Students enrolled in any grade or class',
  icon: 'GraduationCap',
  gradient: 'from-cyan-600 to-sky-600',
  accentHex: '#0891b2',
  badgeBg: 'bg-cyan-100 dark:bg-cyan-950/40',
  badgeText: 'text-cyan-700 dark:text-cyan-300',
  estimatedMinutes: 20,
  version: '1.0.0',
  lastUpdated: '2025-07-01',
  chapters: [
    {
      id: 'student-intro',
      number: 1,
      title: 'Introduction to the Student Portal',
      icon: 'LayoutDashboard',
      summary: 'Discover what Student Diwan offers you as a student and how it fits your daily school life.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Welcome, Student!\n\nStudent Diwan is your personal school management hub. Through your student portal you can track your attendance, check your exam results, browse your timetable, borrow library books, and message your teachers — all without paperwork or waiting in queues.\n\nThis guide introduces each feature and shows you how to use it effectively so you can focus on what matters most: learning.',
        },
        {
          type: 'table',
          caption: 'Student Portal Features & Access Rights',
          headers: ['Feature', 'What You Can Do', 'Access Level'],
          rows: [
            ['Dashboard', 'View attendance summary, upcoming exams, and announcements', 'Read'],
            ['Timetable', 'View your weekly class schedule with teacher and room details', 'Read'],
            ['Attendance', 'View your attendance record and percentage by subject', 'Read'],
            ['Grades & Results', 'View exam marks, grade cards, and subject-wise performance trends', 'Read'],
            ['Library', 'Search the catalog, view your issued books, and check due dates', 'Read & Request'],
            ['Assignments', 'View assignments posted by teachers and submit your work', 'Read & Submit'],
            ['Messages', 'Send and receive messages with teachers and class coordinators', 'Read & Write'],
            ['Profile', 'View and update your contact information and photo', 'Read & Write'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Your Data is Private',
          body: 'Only you, your teachers, and your parents/guardians can view your academic records. Other students cannot access your grades, attendance, or personal information.',
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['Timetable', 'Alt + T', '⌘ Shift + T'],
            ['Library', 'Alt + L', '⌘ Shift + L'],
            ['Gradebook', 'Alt + J', '⌘ Shift + J'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
            ['Assignments', 'Alt + AM', '⌘ Shift + AM'],
            ['Assessments', 'Alt + AE', '⌘ Shift + AE'],
            ['Flashcards', 'Alt + FL', '⌘ Shift + FL'],
            ['Parent-Teacher Meetings', 'Alt + PT', '⌘ Shift + PT'],
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
      id: 'student-login',
      number: 2,
      title: 'Login & Dashboard',
      icon: 'KeyRound',
      summary: 'Sign in to your student account and navigate the dashboard confidently.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Getting Started\n\nYour school will provide your login credentials — usually your student ID or school email address and a temporary password. Use these to log in for the first time and then set your own password.',
        },
        {
          type: 'steps',
          title: 'How to Log In',
          steps: [
            {
              title: 'Open the Portal',
              description: "Go to your school's Student Diwan URL in any browser (Chrome, Safari, Firefox, Edge).",
            },
            {
              title: 'Choose "Student" on the Login Page',
              description: 'Click the "Student" card on the role-selection screen.',
            },
            {
              title: 'Enter Your Credentials',
              description: 'Type your student ID or school email and your password, then click "Sign In".',
              tip: 'If it is your first time, use the temporary password from your school admission letter.',
            },
            {
              title: 'Set a New Password',
              description: 'You will be prompted to create a new personal password on first login. Pick something you will remember but that others cannot guess.',
            },
            {
              title: 'Explore Your Dashboard',
              description: "After logging in, you land on your personalised dashboard showing today's classes, attendance, and recent announcements.",
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/student-dashboard.png',
          caption: "The student dashboard showing today's schedule, attendance, and quick links.",
          alt: 'Student dashboard with sidebar navigation, top bar, stats cards, and schedule widget',
          annotations: [
            {
              id: 1,
              x: 7,
              y: 50,
              label: 'Sidebar',
              description: 'Navigate to Timetable, Attendance, Grades, Library, Assignments, and Messages.',
            },
            {
              id: 2,
              x: 60,
              y: 4,
              label: 'Top Bar',
              description: 'Access notifications, profile settings, and the help menu.',
            },
            {
              id: 3,
              x: 25,
              y: 20,
              label: 'Attendance Card',
              description: 'Your current attendance percentage for the academic year.',
            },
            {
              id: 4,
              x: 60,
              y: 20,
              label: 'Upcoming Exams',
              description: 'Countdown to your next scheduled exam.',
            },
            {
              id: 5,
              x: 50,
              y: 50,
              label: "Today's Classes",
              description: 'Your class schedule for today, with room and teacher details.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Stay Logged In Safely',
          body: 'Avoid using "Remember Me" on shared or public computers. Always click "Log Out" from the profile menu when you finish your session on a shared device.',
        },
      ],
    },
    {
      id: 'student-timetable',
      number: 3,
      title: 'My Timetable & Classes',
      icon: 'CalendarDays',
      summary: 'View your weekly schedule, check room assignments, and never miss a class.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Your Weekly Schedule\n\nThe Timetable module gives you a clear view of every class period throughout the week. Each slot shows the subject, teacher name, classroom, and timing so you are always prepared.',
        },
        {
          type: 'steps',
          title: 'Viewing Your Timetable',
          steps: [
            {
              title: 'Open the Timetable Module',
              description: 'Click "Timetable" in the left sidebar.',
            },
            {
              title: 'Choose a View',
              description: "Switch between Day view and Week view using the toggle at the top. Day view shows today's periods in detail; Week view shows the full grid.",
            },
            {
              title: 'Check Period Details',
              description: 'Click on any period tile to see the full details: teacher name, room number, subject, and any notes.',
              tip: 'Periods highlighted in blue are happening now or coming up in the next 30 minutes.',
            },
            {
              title: 'Navigate Between Weeks',
              description: 'Use the arrow buttons to go to a previous or future week if you want to plan ahead.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/student-timetable.png',
          caption: 'The student weekly timetable with period details.',
          alt: 'Weekly timetable grid showing class periods, subjects, teachers, and rooms',
          annotations: [
            {
              id: 1,
              x: 15,
              y: 15,
              label: 'Day/Week Toggle',
              description: 'Switch between a single-day detail view and the full weekly grid.',
            },
            {
              id: 2,
              x: 50,
              y: 40,
              label: 'Period Tile',
              description: 'Each coloured tile represents one period. Click for full details.',
            },
            {
              id: 3,
              x: 85,
              y: 15,
              label: 'Week Navigation',
              description: 'Move forward or backward to view schedules for different weeks.',
            },
            {
              id: 4,
              x: 10,
              y: 55,
              label: 'Time Column',
              description: 'Period start and end times are shown on the left axis.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Timetable Changes',
          body: 'If a teacher is substituted or a class is rescheduled, your timetable updates automatically. You will receive a notification alerting you to the change.',
        },
      ],
    },
    {
      id: 'student-grades',
      number: 4,
      title: 'Grades & Results',
      icon: 'TrendingUp',
      summary: 'Check your exam scores, download report cards, and track your academic progress over time.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Understanding Your Results\n\nThe Grades module shows your marks for every exam and assessment. You can filter by subject or term, see your grade trends over time, and download official report cards.',
        },
        {
          type: 'steps',
          title: 'Viewing Your Grades',
          steps: [
            {
              title: 'Navigate to Grades & Results',
              description: 'Click "Grades & Results" in the sidebar.',
            },
            {
              title: 'Select a Term or Exam',
              description: 'Use the term selector to choose between Mid-Term, Final Exam, or unit tests.',
            },
            {
              title: 'Review the Results Table',
              description: 'Each row shows a subject with your marks obtained, maximum marks, percentage, and letter grade.',
            },
            {
              title: 'View Subject Trends',
              description: 'Click "Performance Graph" to see a chart of your scores across all terms for a subject.',
              tip: 'Use the trend graph to identify subjects where you are improving or need extra attention.',
            },
            {
              title: 'Download Your Report Card',
              description: 'Click "Download Report Card" to get a PDF of the official signed report for the selected term.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Results Are Read-Only',
          body: 'If you believe a grade has been recorded incorrectly, do not attempt to modify it. Instead, contact your subject teacher through the Messages module and request a review.',
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Exam Schedule',
          body: 'Check the "Exam Schedule" tab within the Grades module to see upcoming exam dates, subjects, and venue details so you can plan your revision effectively.',
        },
      ],
    },
    {
      id: 'student-library',
      number: 5,
      title: 'Library & Resources',
      icon: 'BookOpen',
      summary: 'Search the school library catalog, track borrowed books, and avoid late-return fines.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Using the School Library Online\n\nThe Library module lets you browse the school's entire book catalog, see which books are available, check your currently borrowed books and their due dates, and view your borrowing history.",
        },
        {
          type: 'steps',
          title: 'Searching & Borrowing Books',
          steps: [
            {
              title: 'Open the Library Module',
              description: 'Click "Library" in the left sidebar.',
            },
            {
              title: 'Search the Catalog',
              description: 'Use the search bar to find a book by title, author, or subject. You can also filter by category or grade level.',
            },
            {
              title: 'Check Availability',
              description: 'Books show their availability status. "Available" means you can borrow it; "Issued" means all copies are currently out.',
              tip: 'If a book is currently issued, click "Notify Me" and you will receive an alert when it is returned.',
            },
            {
              title: 'Visit the Library to Borrow',
              description: 'Physically go to the school library with your student ID. The librarian will issue the book and update your account.',
            },
            {
              title: 'Track Your Borrowed Books',
              description: 'Go to the "My Books" tab to see all currently issued books with due dates highlighted in red if they are overdue.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/library-books.png',
          caption: 'The library catalog showing book listings with availability status.',
          alt: 'Library catalog page with search bar, book cards, and availability badges',
          annotations: [
            {
              id: 1,
              x: 50,
              y: 12,
              label: 'Search Bar',
              description: 'Search by book title, author name, ISBN, or subject keyword.',
            },
            {
              id: 2,
              x: 15,
              y: 45,
              label: 'Filter Panel',
              description: 'Filter results by category, grade level, language, or availability.',
            },
            {
              id: 3,
              x: 55,
              y: 40,
              label: 'Book Card',
              description: 'Shows title, author, cover image, and current availability status.',
            },
            {
              id: 4,
              x: 80,
              y: 55,
              label: 'Availability Badge',
              description: 'Green "Available" means the book is in stock; red "Issued" means all copies are out.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Avoid Late Fines',
          body: 'Books are due back by the date shown in the "My Books" tab. Late returns incur a daily fine as set by your school library policy. Return books on time or request an extension through the librarian.',
        },
      ],
    },
    {
      id: 'student-faq',
      number: 6,
      title: 'Frequently Asked Questions',
      icon: 'HelpCircle',
      summary: 'Quick answers to common student questions about using Student Diwan.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Student FAQ\n\nThese are the questions students ask most. If you still need help, use the \"Help & Support\" option in the sidebar to contact your school's support team.",
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'I cannot log in. What should I do?',
              a: 'First, make sure you are using the correct student ID or school email and that Caps Lock is off. If you still cannot log in, click "Forgot Password" and follow the reset steps. If the problem persists, contact your class teacher or school IT administrator.',
            },
            {
              q: 'My attendance seems wrong. How do I get it corrected?',
              a: 'Send a message to your class teacher through the Messages module explaining the discrepancy and the date(s) involved. Your teacher can raise a correction request with the administrator.',
            },
            {
              q: 'Can I submit assignments through the portal?',
              a: 'Yes. Navigate to "Assignments" in the sidebar, select the assignment your teacher posted, and use the "Submit" button to upload your work before the deadline.',
            },
            {
              q: 'How many books can I borrow at the same time?',
              a: 'The borrowing limit is set by your school library policy — commonly 2 to 3 books per student. Your "My Books" tab shows how many slots you have used.',
            },
            {
              q: 'My grades have not appeared yet. When are results published?',
              a: 'Results are published by your teacher after exams are marked and reviewed. If you believe results should have been published by now, check with your subject teacher via the Messages module.',
            },
            {
              q: 'Can my parents see everything I see on the portal?',
              a: 'Your parents can view your attendance, grades, timetable, and fee information. They cannot read your direct messages with teachers or submit assignments on your behalf.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'Well Done for Getting Started!',
          body: 'You now know how to use all the key features of your student portal. Revisit this guide any time you need a refresher. Good luck with your studies!',
        },
      ],
    },
    {
      id: 'student-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Find quick answers, access your guide, and get help when something is not working.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre at `/help` gives you access to the Student Guide, a searchable article library, and a way to report problems. If you are confused about a feature, cannot find your timetable, or see incorrect grades, the Help Centre and your teacher's messaging inbox are the right places to start.\n\nPress **Alt + Z** (Windows) or **⌘ Shift + Z** (Mac) from any page to open the Help Centre instantly.",
        },
        {
          type: 'steps',
          title: 'How to Get Help',
          steps: [
            {
              title: 'Open the Help Centre',
              description: 'Press Alt + Z (Windows) or ⌘ Shift + Z (Mac), or click the Help icon at the bottom of the left sidebar, to open the Help Home page.',
            },
            {
              title: 'Read the Student Guide',
              description: 'Go to /help/guides/student to find your full guide — covering timetables, grades, library, assignments, and more — with step-by-step instructions.',
            },
            {
              title: 'Message Your Teacher or Admin',
              description: 'For questions about grades, attendance, or assignments, go to Messages (/messages) and send a message directly to your teacher or class coordinator.',
            },
            {
              title: 'Use the NeedHelp Widget',
              description: 'If you encounter a technical error in the portal (something is broken, data is missing, or a page will not load), click the floating ✦ button to report it to platform support.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to Students',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Student Guide — Chapter 3', 'My Timetable & Classes: reading your weekly schedule and class rooms', '/help/guides/student'],
            ['Student Guide — Chapter 4', 'Grades & Results: viewing marks, downloading report cards, understanding your performance', '/help/guides/student'],
            ['Student Guide — Chapter 5', 'Library & Resources: borrowing books, checking due dates, and paying fines', '/help/guides/student'],
            ['Mobile App Guide', 'Using Student Diwan on your phone — notifications, offline access, and mobile features', '/help/guides/mobile-app'],
            ['Messages', 'Direct messaging with teachers, coordinators, and school administration', '/messages'],
            ['NeedHelp Widget', 'Report technical errors or broken pages to the platform support team', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Academic Questions vs Technical Issues',
          body: 'If something seems wrong with your grades, attendance record, or assignment marks, message your teacher via /messages — they can correct data errors. If a page will not load, an error appears on screen, or a feature is completely missing, use the NeedHelp widget to report a technical issue to the support team.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'I cannot see my timetable. What should I do?',
              a: 'Make sure the current academic term has been set up and the timetable has been published by your School Admin. If other students in your class can see the timetable and you cannot, log out, clear your browser cache, and log back in. If the problem continues, message your class coordinator.',
            },
            {
              q: 'My grade looks wrong. How do I get it corrected?',
              a: 'Send a message to your subject teacher via /messages explaining which assessment you believe is incorrect and what you expected. Only teachers and administrators can edit grade records — students do not have write access to the gradebook.',
            },
            {
              q: 'I borrowed a library book but the due date is not showing in my account. What do I do?',
              a: 'Go to Library (/library) → My Borrowed Books. If the book is not listed, the librarian may not have recorded the issue in the system. Visit the library in person and ask the librarian to confirm the transaction in Student Diwan.',
            },
            {
              q: 'The portal is loading slowly or showing an error. What can I try?',
              a: 'First, refresh the page (Ctrl+R on Windows, ⌘+R on Mac). If the issue continues, try a different browser or clear your browser cache (Settings → Clear Browsing Data). If it still does not work, click the ✦ button to report the technical issue.',
            },
          ],
        },
      ],
    },
  ],
};
