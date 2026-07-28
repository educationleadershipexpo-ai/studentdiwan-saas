import type { UserGuide } from '@/lib/userGuides/types';

export const parentGuide: UserGuide = {
  id: 'parent',
  role: 'Parent / Guardian',
  title: 'Parent & Guardian Guide',
  tagline: "Stay connected to your child's school life — from grades to fee payments, all in one place.",
  audience: 'Parents and guardians of enrolled students',
  icon: 'Heart',
  gradient: 'from-pink-600 to-rose-600',
  accentHex: '#e11d48',
  badgeBg: 'bg-pink-100 dark:bg-pink-950/40',
  badgeText: 'text-pink-700 dark:text-pink-300',
  estimatedMinutes: 20,
  version: '1.0.0',
  lastUpdated: '2025-07-01',
  chapters: [
    {
      id: 'parent-intro',
      number: 1,
      title: 'Introduction to the Parent Portal',
      icon: 'Home',
      summary: 'Get an overview of everything Student Diwan offers parents and guardians.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Welcome to Student Diwan\n\nStudent Diwan is your school's all-in-one management platform. As a parent or guardian, your dedicated portal gives you real-time visibility into your child's academic journey — attendance, grades, fee statements, timetables, and direct communication with teachers — all from a single, secure interface.\n\nThis guide walks you through each feature step by step so you can get the most out of the portal from day one.",
        },
        {
          type: 'table',
          caption: 'Parent Portal Features & Permissions',
          headers: ['Feature', 'What You Can Do', 'Access Level'],
          rows: [
            ['Dashboard', 'View summary cards for attendance, fees, and announcements', 'Read'],
            ['Attendance', 'View daily attendance records and absence history', 'Read'],
            ['Grades & Results', 'View exam results, report cards, and subject-wise performance', 'Read'],
            ['Fee Management', 'View invoices, pay fees online, download receipts', 'Read & Pay'],
            ['Timetable', "View child's weekly class schedule", 'Read'],
            ['Messages', 'Send and receive messages with teachers and administration', 'Read & Write'],
            ['Notifications', 'Receive push/email alerts for absences, fees, and announcements', 'Read'],
            ['Profile', 'Update your contact information and notification preferences', 'Read & Write'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Multiple Children',
          body: 'If you have more than one child enrolled, you can switch between student profiles using the child-switcher dropdown in the top navigation bar. All data is kept separate per student.',
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
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
      id: 'parent-login',
      number: 2,
      title: 'Login & Dashboard',
      icon: 'KeyRound',
      summary: 'Sign in to your parent account and understand the dashboard layout.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Accessing the Portal\n\nYour school will send you a welcome email with your login credentials when your child is enrolled. Use those credentials to sign in at the school's Student Diwan URL (e.g., `yourschool.studentdiwan.com`).",
        },
        {
          type: 'steps',
          title: 'How to Log In',
          steps: [
            {
              title: 'Navigate to the Login Page',
              description: "Open your browser and go to your school's Student Diwan URL. You will see the role-selection portal cards.",
              tip: 'Bookmark the URL for quick access next time.',
            },
            {
              title: 'Select the Parent Role',
              description: 'Click on the "Parent / Guardian" card. This takes you to the parent-specific login form.',
            },
            {
              title: 'Enter Your Credentials',
              description: 'Type your registered email address and the password provided in your welcome email.',
            },
            {
              title: 'Click Sign In',
              description: 'Press the "Sign In" button. If you have two-factor authentication enabled, enter the OTP sent to your phone.',
            },
            {
              title: 'Change Your Password',
              description: 'On first login, you will be prompted to set a new personal password. Choose something strong and memorable.',
              tip: 'Use at least 8 characters including a number and a special character.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/login-portal.png',
          caption: 'The Student Diwan login portal showing role-selection cards.',
          alt: 'Login portal with role cards for Parent, Student, Accountant, and more',
          annotations: [
            {
              id: 1,
              x: 50,
              y: 52,
              label: 'Role Cards',
              description: 'Click the "Parent / Guardian" card to begin the login flow.',
            },
            {
              id: 2,
              x: 50,
              y: 45,
              label: 'Email Field',
              description: 'Enter the email address your school registered for you.',
            },
            {
              id: 3,
              x: 50,
              y: 58,
              label: 'Password Field',
              description: 'Enter your current password. Use the eye icon to toggle visibility.',
            },
            {
              id: 4,
              x: 50,
              y: 68,
              label: 'Sign In Button',
              description: 'Click here to authenticate and access your parent dashboard.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/parent-dashboard.png',
          caption: 'The parent dashboard showing key summary cards and quick links.',
          alt: 'Parent dashboard with attendance summary, fee status, and announcement cards',
          annotations: [
            {
              id: 1,
              x: 7,
              y: 50,
              label: 'Sidebar Navigation',
              description: 'Access all portal sections: Dashboard, Attendance, Grades, Fees, Timetable, Messages.',
            },
            {
              id: 2,
              x: 60,
              y: 5,
              label: 'Top Bar',
              description: 'Switch between enrolled children, view notifications, and access your profile settings.',
            },
            {
              id: 3,
              x: 30,
              y: 20,
              label: 'Stats Cards',
              description: 'At-a-glance summary of attendance percentage, outstanding fees, and upcoming events.',
            },
            {
              id: 4,
              x: 65,
              y: 45,
              label: 'Recent Activity',
              description: 'Latest grades posted, attendance events, and school announcements.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Forgot Your Password?',
          body: 'Click "Forgot Password" on the login page and enter your registered email. You will receive a reset link within a few minutes. Check your spam folder if it does not arrive.',
        },
      ],
    },
    {
      id: 'parent-progress',
      number: 3,
      title: "Monitoring Your Child's Progress",
      icon: 'TrendingUp',
      summary: "Track attendance, view grades, and stay on top of your child's academic performance.",
      blocks: [
        {
          type: 'text',
          markdown:
            "## Attendance & Grades at a Glance\n\nThe portal gives you live data on your child's attendance and academic results. You can drill down by subject, date range, or exam type to get a full picture of their progress.",
        },
        {
          type: 'steps',
          title: 'Viewing Attendance Records',
          steps: [
            {
              title: 'Open the Attendance Section',
              description: 'Click "Attendance" in the left sidebar to open the attendance module.',
            },
            {
              title: 'Select a Date Range',
              description: 'Use the date-picker at the top to filter attendance by week, month, or custom range.',
            },
            {
              title: 'Review Daily Status',
              description: 'Each school day is listed with a status: Present (green), Absent (red), Late (yellow), or Holiday (grey).',
              tip: 'Click on any absent day to see if a leave application was submitted.',
            },
            {
              title: 'Check the Attendance Summary',
              description: "The summary card at the top shows your child's overall attendance percentage for the selected period.",
            },
          ],
        },
        {
          type: 'steps',
          title: 'Viewing Grades & Results',
          steps: [
            {
              title: 'Navigate to Grades',
              description: 'Click "Grades & Results" in the sidebar.',
            },
            {
              title: 'Select an Exam Term',
              description: 'Choose the term or exam type (e.g., Mid-Term, Final) from the dropdown.',
            },
            {
              title: 'Review Subject-wise Scores',
              description: 'A table lists each subject with marks obtained, maximum marks, percentage, and grade.',
            },
            {
              title: 'Download the Report Card',
              description: 'Click "Download Report Card" to save a PDF copy for your records.',
              tip: 'Report cards are digitally signed and can be shared with tutors or other institutions.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Low Attendance Alert',
          body: `If your child's attendance falls below the school's minimum threshold (typically 75%), you will receive an automatic email and in-app notification. Address any ongoing absences promptly to avoid academic penalties.`,
        },
      ],
    },
    {
      id: 'parent-fees',
      number: 4,
      title: 'Fee Payments',
      icon: 'CreditCard',
      summary: 'View outstanding invoices, pay fees online, and download payment receipts.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Paying Fees Online\n\nStudent Diwan lets you view all pending fee invoices and pay them securely without visiting the school. Multiple payment methods are supported, and receipts are generated instantly.',
        },
        {
          type: 'steps',
          title: 'Making a Fee Payment',
          steps: [
            {
              title: 'Open the Fees Section',
              description: 'Click "Fee Payments" in the left sidebar to see all invoices.',
            },
            {
              title: 'Review Pending Invoices',
              description: 'Pending invoices appear at the top, each showing the fee type, amount, and due date.',
            },
            {
              title: 'Select an Invoice to Pay',
              description: 'Click "Pay Now" next to the invoice you want to settle.',
            },
            {
              title: 'Choose a Payment Method',
              description: 'Select from available options: Credit/Debit Card, Net Banking, or UPI. Enter your payment details on the secure checkout page.',
              tip: 'Your payment details are encrypted and never stored on Student Diwan servers.',
            },
            {
              title: 'Confirm & Download Receipt',
              description: 'After successful payment, a receipt is generated. Click "Download Receipt" to save a PDF copy.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/parent-fees.png',
          caption: 'The parent fee management page showing invoices and payment history.',
          alt: 'Parent fees page with pending invoices, pay buttons, and payment history table',
          annotations: [
            {
              id: 1,
              x: 25,
              y: 20,
              label: 'Outstanding Balance',
              description: 'Total amount due across all pending invoices.',
            },
            {
              id: 2,
              x: 65,
              y: 20,
              label: 'Payment History',
              description: 'Summary of all payments made this academic year.',
            },
            {
              id: 3,
              x: 80,
              y: 45,
              label: 'Pay Now Button',
              description: 'Click to initiate payment for the selected invoice.',
            },
            {
              id: 4,
              x: 80,
              y: 65,
              label: 'Download Receipt',
              description: 'Download a PDF receipt for any previously paid invoice.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'Instant Confirmation',
          body: 'Payment confirmation is sent to your registered email immediately after a successful transaction. The invoice status updates to "Paid" in real time on the portal.',
        },
      ],
    },
    {
      id: 'parent-communication',
      number: 5,
      title: 'Communication with School',
      icon: 'MessageSquare',
      summary: 'Send messages to teachers, receive school announcements, and manage notification settings.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Staying in Touch\n\nThe messaging feature allows you to communicate directly with your child's teachers and the school administration. Announcements from the school are published here, and you can configure how and when you receive alerts.",
        },
        {
          type: 'steps',
          title: 'Sending a Message to a Teacher',
          steps: [
            {
              title: 'Go to Messages',
              description: 'Click "Messages" in the sidebar to open the messaging centre.',
            },
            {
              title: 'Click "New Message"',
              description: 'Press the "Compose" or "New Message" button to start a new conversation.',
            },
            {
              title: 'Select the Recipient',
              description: "Search for the teacher by name or select from the list of your child's subject teachers.",
            },
            {
              title: 'Write Your Message',
              description: 'Type your message in the text field. You can attach files or images if needed.',
              tip: 'Keep messages professional and concise. Teachers typically respond within one school day.',
            },
            {
              title: 'Send',
              description: 'Click "Send". You will receive a notification when the teacher replies.',
            },
          ],
        },
        {
          type: 'steps',
          title: 'Configuring Notifications',
          steps: [
            {
              title: 'Open Profile Settings',
              description: 'Click your profile avatar in the top-right corner, then select "Settings".',
            },
            {
              title: 'Go to Notifications',
              description: 'Select the "Notifications" tab.',
            },
            {
              title: 'Toggle Alerts',
              description: 'Enable or disable email, SMS, or push notifications for each event type: attendance, fees, grades, and announcements.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'School Announcements',
          body: 'Important school-wide notices — holiday schedules, exam timetables, and events — appear on your dashboard and in the "Announcements" section. These are read-only and sent by school administration.',
        },
      ],
    },
    {
      id: 'parent-faq',
      number: 6,
      title: 'Frequently Asked Questions',
      icon: 'HelpCircle',
      summary: 'Answers to the most common questions from parents using Student Diwan.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Parent FAQ\n\nBelow are answers to the questions parents ask most often. If you cannot find what you need here, use the in-app \"Help & Support\" link to raise a ticket with your school's IT administrator.",
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'I forgot my password. How do I reset it?',
              a: 'Click "Forgot Password" on the login page, enter your registered email address, and follow the reset link sent to your inbox. The link expires after 30 minutes. If you do not receive the email, check your spam folder or contact your school administrator.',
            },
            {
              q: "Can I view my child's timetable?",
              a: `Yes. Navigate to "Timetable" in the sidebar to see your child's weekly class schedule, including subject, teacher name, room number, and timing for each period.`,
            },
            {
              q: 'I paid a fee but it still shows as pending. What should I do?',
              a: 'Payment status updates usually reflect within a few minutes. If it remains pending after 30 minutes, note your transaction reference number and contact the school finance office or raise a support ticket through the portal.',
            },
            {
              q: 'How do I update my phone number or email address?',
              a: `Click your profile avatar in the top-right corner, select "Profile", edit the relevant field, and click "Save Changes". Some fields may require administrator approval before the change takes effect.`,
            },
            {
              q: 'Can I access the portal on my phone?',
              a: 'Yes. The web portal is fully responsive and works on any smartphone browser. Your school may also offer a dedicated mobile app — check with the administration for download details.',
            },
            {
              q: 'Who do I contact if I see incorrect information (e.g., wrong attendance or grade)?',
              a: 'Use the in-app messaging feature to contact the relevant teacher or class coordinator. For data correction requests, the teacher or administrator can update records from their respective portals.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Need More Help?',
          body: `Click "Help & Support" in the sidebar at any time to access the full knowledge base or submit a support request to your school's system administrator.`,
        },
      ],
    },
    {
      id: 'parent-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Access your guide, get help with fees and attendance questions, and contact the school.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre at `/help` gives you access to the Parent & Guardian Guide and a library of articles covering everything from fee payments to communication with teachers. For academic questions about your child, the school's messaging feature is the fastest route to the right person.\n\nPress **Alt + Z** (Windows) or **⌘ Shift + Z** (Mac) from any page to open the Help Centre instantly.",
        },
        {
          type: 'steps',
          title: 'How to Get Help',
          steps: [
            {
              title: 'Open the Help Centre',
              description: 'Press Alt + Z (Windows) or ⌘ Shift + Z (Mac), or click the Help icon at the bottom of the sidebar, to open the Help Home page.',
            },
            {
              title: 'Read the Parent & Guardian Guide',
              description: 'Navigate to /help/guides/parent for your complete role guide — covering login, monitoring your child\'s progress, fee payments, and communication with the school.',
            },
            {
              title: 'Message the School',
              description: 'For questions about attendance records, grades, or fee invoices, go to Messages (/messages) and contact the relevant teacher or school administrator directly.',
            },
            {
              title: 'Report a Technical Issue',
              description: 'If a page will not load or something in the portal is broken, click the floating ✦ button (bottom-right) to report the issue to platform support.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to Parents & Guardians',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Parent & Guardian Guide — Chapter 3', 'Monitoring attendance records, viewing grades, and downloading report cards', '/help/guides/parent'],
            ['Parent & Guardian Guide — Chapter 4', 'Viewing invoices, making fee payments online, and downloading receipts', '/help/guides/parent'],
            ['Parent & Guardian Guide — Chapter 5', 'Sending messages to teachers, receiving school announcements, and managing notification settings', '/help/guides/parent'],
            ['Mobile App Guide', 'Stay connected to your child\'s school from your smartphone — notifications, grades, and fees on the go', '/help/guides/mobile-app'],
            ['Messages', 'Direct communication with teachers and school administration for academic or administrative queries', '/messages'],
            ['NeedHelp Widget', 'Report technical portal issues — broken pages, login problems, payment errors', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Best Channel for Each Type of Question',
          body: 'Use Messages (/messages) for anything school-related — attendance disputes, grade queries, meeting requests, or fee concerns. Use the NeedHelp widget (✦ button) only for technical portal problems such as pages not loading, payment failures, or login errors. This gets your question to the right team faster.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'My child\'s attendance shows an absence but they were at school. How do I dispute it?',
              a: "Send a message via /messages to your child's class teacher or school coordinator. Include the date and any supporting information. The teacher can update the record from their portal. Changes take effect immediately in your parent view.",
            },
            {
              q: 'I paid a fee but the portal still shows it as outstanding. What do I do?',
              a: 'Payment status usually updates within a few minutes. If it remains pending after 30 minutes, note your payment reference number and send a message to the school finance team via /messages, or contact them by phone. Do not pay again without confirming the first payment failed.',
            },
            {
              q: 'I cannot log in to the parent portal. How do I recover access?',
              a: "Click 'Forgot Password' on the login page and enter your registered email address. A reset link will arrive within a few minutes — check your spam folder if it does not appear. If your email address has changed, contact the school administration to update your account.",
            },
            {
              q: 'Can I access the portal and my child\'s information from my mobile phone?',
              a: 'Yes — the web portal is fully responsive and works in any smartphone browser. For a better mobile experience, your school may also offer a dedicated Student Diwan app. Read the Mobile App Guide at /help/guides/mobile-app for download and setup instructions.',
            },
          ],
        },
      ],
    },
  ],
};
