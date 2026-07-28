import type { UserGuide } from '@/lib/userGuides/types';

export const mobileAppGuide: UserGuide = {
  id: 'mobile-app',
  role: 'All Users',
  title: 'Mobile App Guide',
  tagline: 'Access Student Diwan on the go — stay connected to school from any smartphone.',
  audience: 'Parents, students, and staff who want to use Student Diwan on a mobile device',
  icon: 'Smartphone',
  gradient: 'from-slate-700 to-gray-800',
  accentHex: '#475569',
  badgeBg: 'bg-slate-100 dark:bg-slate-800',
  badgeText: 'text-slate-700 dark:text-slate-300',
  estimatedMinutes: 15,
  version: '1.0.0',
  lastUpdated: '2025-07-01',
  chapters: [
    {
      id: 'mobile-intro',
      number: 1,
      title: 'Introduction to the Mobile App',
      icon: 'Smartphone',
      summary: 'Understand what the Student Diwan mobile app offers and who it is designed for.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Student Diwan on Your Phone\n\nThe Student Diwan mobile app brings the full power of the school management portal to your smartphone. Whether you are a parent checking your child's attendance during a commute, a student reviewing tomorrow's timetable, or a teacher marking homework — the app keeps you connected wherever you are.\n\nThe app is available for iOS (iPhone, iPad) and Android devices and is designed for speed, simplicity, and offline resilience.",
        },
        {
          type: 'table',
          caption: 'Mobile App Features by Role',
          headers: ['Feature', 'Parent', 'Student', 'Teacher / Staff'],
          rows: [
            ['Dashboard', 'Yes', 'Yes', 'Yes'],
            ['Attendance (View)', 'Yes', 'Yes', 'Yes'],
            ['Attendance (Mark)', 'No', 'No', 'Yes'],
            ['Grades & Results', 'Yes (child)', 'Yes (own)', 'Yes (class)'],
            ['Fee Payments', 'Yes', 'No', 'No'],
            ['Timetable', 'Yes (child)', 'Yes (own)', 'Yes (own)'],
            ['Messages', 'Yes', 'Yes', 'Yes'],
            ['Push Notifications', 'Yes', 'Yes', 'Yes'],
            ['Library Catalog Search', 'Yes', 'Yes', 'No'],
            ['Offline Mode', 'Partial', 'Partial', 'Partial'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Same Account, All Devices',
          body: 'Your Student Diwan login credentials work on the web portal and the mobile app. No separate registration is needed. You can be signed in on multiple devices simultaneously.',
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'No Keyboard Shortcuts on Mobile',
          body: `The mobile app is touch-optimised and does not use keyboard shortcuts. On the web portal (accessed from a desktop browser), press ? to see all available keyboard shortcuts, or Ctrl + K (⌘ K on Mac) to search any page by name.`,
        },
      ],
    },
    {
      id: 'mobile-download-login',
      number: 2,
      title: 'Getting the App & Logging In',
      icon: 'Download',
      summary: 'Download the app, install it, and sign in to your account.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Downloading and Setting Up the App\n\nThe Student Diwan app is available on both the Apple App Store and the Google Play Store. Download it for free — no in-app purchases are required for any core feature.',
        },
        {
          type: 'steps',
          title: 'Installing and Logging In',
          steps: [
            {
              title: 'Download the App',
              description: `Open the App Store (iOS) or Google Play Store (Android), search for "Student Diwan", and tap "Install". The app is free to download.`,
            },
            {
              title: 'Open the App',
              description: 'Tap the Student Diwan icon on your home screen to launch the app.',
            },
            {
              title: 'Enter Your School URL or Code',
              description: `On first launch, you will be asked for your school's URL or a short school code provided by your administrator. This connects the app to your school's instance.`,
              tip: 'Your school code is usually on your welcome letter or can be obtained from the school office.',
            },
            {
              title: 'Select Your Role and Sign In',
              description: 'Select your role (Parent, Student, or Staff), enter your email and password, and tap "Sign In". Use the same credentials as the web portal.',
            },
            {
              title: 'Allow Notifications',
              description: 'When prompted, tap "Allow" to enable push notifications. This is recommended so you never miss important school alerts.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/mobile-login.png',
          caption: 'The Student Diwan mobile app login screen on a smartphone.',
          alt: 'Mobile app login screen showing school code input, role selector, and sign-in fields',
          annotations: [
            {
              id: 1,
              x: 50,
              y: 25,
              label: 'School Code Field',
              description: "Enter your school's unique code or full URL to connect to the right school instance.",
            },
            {
              id: 2,
              x: 50,
              y: 45,
              label: 'Role Selector',
              description: 'Tap your role: Parent, Student, or Staff.',
            },
            {
              id: 3,
              x: 50,
              y: 60,
              label: 'Email & Password',
              description: 'Enter the same credentials you use on the web portal.',
            },
            {
              id: 4,
              x: 50,
              y: 75,
              label: 'Sign In Button',
              description: 'Tap to authenticate and open your personalised dashboard.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Biometric Login',
          body: 'After your first sign-in, enable biometric authentication (Face ID or fingerprint) in App Settings for faster, password-free access on subsequent opens.',
        },
      ],
    },
    {
      id: 'mobile-dashboard',
      number: 3,
      title: 'Dashboard & Navigation',
      icon: 'LayoutDashboard',
      summary: 'Understand the mobile dashboard layout and how to navigate between modules.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Finding Your Way Around\n\nThe mobile app is designed for one-handed use. The bottom navigation bar gives instant access to your most-used sections, while the hamburger menu exposes all available modules.',
        },
        {
          type: 'steps',
          title: 'Navigating the App',
          steps: [
            {
              title: 'Bottom Navigation Bar',
              description: 'The bar at the bottom shows shortcuts to Home, Attendance, Messages, and Profile. Tap any icon to switch instantly.',
            },
            {
              title: 'Dashboard Cards',
              description: "The home screen shows summary cards tailored to your role. Parents see child attendance and fee status; students see today's classes and recent grades.",
            },
            {
              title: 'All Modules Menu',
              description: 'Tap the grid icon (top-right) or the hamburger menu to see all available modules. From here, access Timetable, Grades, Library, Fees, and Settings.',
            },
            {
              title: 'Search',
              description: 'Tap the magnifying glass icon to search across all modules — find a specific class, book, or message quickly.',
              tip: 'Pull down on any list screen to manually refresh the data from the server.',
            },
            {
              title: 'Switch Child (Parents Only)',
              description: "If you have multiple enrolled children, tap your current child's name at the top of the dashboard to switch between profiles.",
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/mobile-dashboard.png',
          caption: 'The Student Diwan mobile dashboard showing summary cards and bottom navigation.',
          alt: "Mobile dashboard with summary cards for attendance, fees, and today's schedule; bottom nav bar visible",
          annotations: [
            {
              id: 1,
              x: 50,
              y: 8,
              label: 'School Name & Child',
              description: 'Displays the current school and active child profile. Tap to switch.',
            },
            {
              id: 2,
              x: 85,
              y: 8,
              label: 'Notifications Bell',
              description: 'Tap to see all recent push notifications and in-app alerts.',
            },
            {
              id: 3,
              x: 30,
              y: 35,
              label: 'Attendance Card',
              description: 'Current attendance percentage with a quick trend indicator.',
            },
            {
              id: 4,
              x: 70,
              y: 35,
              label: 'Fee Status Card',
              description: 'Outstanding fee balance with a "Pay Now" shortcut.',
            },
            {
              id: 5,
              x: 50,
              y: 90,
              label: 'Bottom Navigation',
              description: 'Home, Attendance, Messages, and Profile — one tap away at all times.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Dark Mode',
          body: "The app follows your device's system theme automatically. To force light or dark mode independently, go to Profile > App Settings > Theme.",
        },
      ],
    },
    {
      id: 'mobile-features',
      number: 4,
      title: 'Key Features',
      icon: 'Star',
      summary: 'Make the most of attendance tracking, fee payments, timetable, and messaging on mobile.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Core Features on Mobile\n\nMost features available on the web portal are also accessible on the mobile app. Here are the ones used most frequently and how to access them quickly.',
        },
        {
          type: 'steps',
          title: 'Paying Fees on Mobile (Parents)',
          steps: [
            {
              title: 'Tap the Fee Status Card',
              description: 'From the dashboard, tap the Fee Status card or navigate to Fees from the menu.',
            },
            {
              title: 'Select a Pending Invoice',
              description: 'Tap the invoice you want to pay.',
            },
            {
              title: 'Tap "Pay Now"',
              description: 'Select your payment method. The app supports UPI, net banking, and card payments through the integrated payment gateway.',
            },
            {
              title: 'Authenticate and Confirm',
              description: "Complete authentication in your bank's app or enter your OTP. Once confirmed, a receipt is generated and emailed to you automatically.",
              tip: 'The payment is reflected in the parent portal immediately after confirmation.',
            },
          ],
        },
        {
          type: 'steps',
          title: 'Checking Grades on Mobile (Students)',
          steps: [
            {
              title: 'Open the Grades Module',
              description: 'From the home screen, tap the grid menu and select "Grades & Results".',
            },
            {
              title: 'Select a Term',
              description: 'Tap the term dropdown and choose the exam period you want to view.',
            },
            {
              title: 'View Scores',
              description: 'Swipe through the subject cards to see your marks, percentage, and grade for each subject.',
            },
            {
              title: 'Download Report Card',
              description: 'Tap "Download Report Card" to save a PDF to your device or share it via WhatsApp, email, or other apps.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Quick Shortcuts',
          body: 'Long-press the Student Diwan app icon on your home screen (iOS 3D Touch / Android long-press) to access quick shortcuts: View Attendance, Open Timetable, Check Fees, and Open Messages — without going through the full app.',
        },
      ],
    },
    {
      id: 'mobile-notifications',
      number: 5,
      title: 'Notifications & Offline Mode',
      icon: 'Bell',
      summary: 'Configure push notifications and understand how the app works without an internet connection.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Staying Informed with Push Notifications\n\nStudent Diwan sends push notifications directly to your phone for important events. Notifications are role-specific — parents receive absence alerts and fee reminders, while students get exam schedule updates and grade releases.',
        },
        {
          type: 'steps',
          title: 'Configuring Notification Preferences',
          steps: [
            {
              title: 'Go to Profile',
              description: 'Tap "Profile" in the bottom navigation bar.',
            },
            {
              title: 'Open Notification Settings',
              description: 'Tap "Notification Preferences".',
            },
            {
              title: 'Toggle Notification Types',
              description: 'Enable or disable notifications per category: Attendance, Fees, Grades, Announcements, Messages, and Exam Schedules.',
              tip: 'You can set "Quiet Hours" (e.g., 10 PM – 7 AM) so notifications are batched and delivered in the morning instead of interrupting your sleep.',
            },
            {
              title: 'Save Preferences',
              description: 'Tap "Save". Your preferences sync across all devices where you are logged in.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/mobile-dashboard.png',
          caption: 'Mobile dashboard illustrating notification badge and offline status indicator.',
          alt: 'Mobile dashboard showing notification badge count and a subtle offline mode banner',
          annotations: [
            {
              id: 1,
              x: 85,
              y: 8,
              label: 'Notification Badge',
              description: 'Red badge shows count of unread notifications. Tap the bell to view all.',
            },
            {
              id: 2,
              x: 50,
              y: 15,
              label: 'Offline Banner',
              description: 'When offline, a banner appears here to confirm you are viewing cached data.',
            },
            {
              id: 3,
              x: 50,
              y: 50,
              label: 'Cached Data',
              description: 'Previously loaded dashboards remain visible offline so you can still check timetables or grades.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Offline Mode',
          body: 'The app caches your dashboard, timetable, and last-viewed pages for offline access. Cached data is clearly marked with a "Last updated" timestamp. New data syncs automatically when your connection is restored. Payments and messages require an active internet connection.',
        },
      ],
    },
    {
      id: 'mobile-faq',
      number: 6,
      title: 'Frequently Asked Questions',
      icon: 'HelpCircle',
      summary: 'Quick answers to common mobile app questions from parents and students.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Mobile App FAQ\n\nBelow are the most common questions about the Student Diwan mobile app. For issues not resolved here, use the "Help & Support" option in the app or contact your school administrator.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'The app shows data from yesterday, not today. How do I refresh?',
              a: 'Pull down on any list or dashboard screen to trigger a manual refresh. If the issue persists, check your internet connection. If you are online but data is still stale, log out and log back in to force a full sync.',
            },
            {
              q: 'I am not receiving push notifications even though they are enabled in the app.',
              a: "First, check your device's system settings: go to Settings > Notifications > Student Diwan and ensure notifications are allowed at the system level. If that looks correct, try logging out of the app and back in to re-register the push token. If the issue continues, contact your school IT administrator.",
            },
            {
              q: 'Can I use the app on a tablet?',
              a: 'Yes. The app is optimised for both phone and tablet form factors. On tablets, you will see a two-column layout that makes better use of the larger screen on the dashboard and timetable views.',
            },
            {
              q: 'The app keeps asking me to log in again. How do I stay logged in?',
              a: 'Enable biometric login (Face ID or fingerprint) in Profile > App Settings > Security. With biometrics enabled, the app stays logged in securely and you authenticate with your face or fingerprint rather than re-entering your password.',
            },
            {
              q: 'I cannot find a feature that is available on the web portal. Is it on the app?',
              a: `Most web portal features are on the app, but a few advanced or administrative functions are web-only (e.g., generating certain reports or bulk admin tasks). If you need one of these, open your school's Student Diwan URL in your phone's browser — the web portal is fully mobile-responsive.`,
            },
            {
              q: 'How do I update the app?',
              a: "The app updates through your device's App Store or Play Store. Enable automatic updates for Student Diwan in your store settings to always have the latest version. Updates usually include bug fixes, speed improvements, and new features aligned with the web portal.",
            },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'App Version Check',
          body: 'To confirm you are on the latest app version, go to Profile > About. If your version is outdated, the page will display a prompt to update. Running the latest version ensures you have all security patches and feature improvements.',
        },
      ],
    },
    {
      id: 'mobile-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Get help with the mobile app, access role guides on your phone, and report issues.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre on Mobile\n\nThe full Help Centre is accessible from the mobile app — tap the **Help** icon in the bottom navigation bar or the sidebar menu to open it. All role guides, the category browser, and the NeedHelp support widget are fully mobile-optimised.\n\nIf something in the app is not working — notifications not arriving, a page not loading, or data appearing incorrect — the Help Centre and the NeedHelp widget are your first steps toward a resolution.",
        },
        {
          type: 'steps',
          title: 'How to Get Help on Mobile',
          steps: [
            {
              title: 'Tap the Help Icon in the App',
              description: 'In the mobile app, tap the Help icon in the sidebar or bottom menu to open the Help Home page. All documentation is mobile-optimised and loads without an internet connection for recently cached pages.',
            },
            {
              title: 'Read Your Role Guide',
              description: 'Go to Help → Role Guides and tap your role card to open your guide. All chapters are available, including keyboard shortcuts for desktop users who switch between devices.',
            },
            {
              title: 'Tap the NeedHelp Widget',
              description: 'The floating ✦ button appears on every page. Tap it to report a technical issue, describe a missing feature, or ask a question — a support response will be sent to your registered email.',
            },
            {
              title: 'Contact Your School via Messages',
              description: 'For academic or administrative questions (grades, attendance, fees), use the Messages feature in the app to contact your teacher or school coordinator directly.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available on the Mobile App',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Mobile App Guide', 'Full guide to the Student Diwan mobile app — download, login, features, notifications, and offline mode', '/help/guides/mobile-app'],
            ['Student Guide', 'Timetable, grades, assignments, and library — for students using the app', '/help/guides/student'],
            ['Parent & Guardian Guide', 'Fee payments, attendance monitoring, messaging — for parents using the app', '/help/guides/parent'],
            ['Teacher Guide', 'Attendance, gradebook, and communication features available on mobile', '/help/guides/teacher'],
            ['Help Category Browser', 'Searchable knowledge base — works on mobile browsers at /help', '/help'],
            ['NeedHelp Widget', 'Report app crashes, notification failures, login issues, or data errors to the support team', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Desktop vs Mobile Features',
          body: 'Most Student Diwan features are available on both mobile and desktop. Some advanced admin functions — such as bulk imports, system configuration, and payroll processing — are optimised for desktop screens and may be harder to use on a small screen. If you need to perform these tasks, switch to a desktop or laptop browser for the best experience.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'I am not receiving push notifications even though I enabled them. What should I check?',
              a: 'Check three things: (1) Notification permissions for the Student Diwan app in your phone settings (Settings → Apps → Student Diwan → Notifications — must be "Allowed"). (2) Notification settings inside the app (Profile → Settings → Notifications — make sure the relevant types are toggled on). (3) Battery saver or Do Not Disturb mode on your device, which can suppress all app notifications.',
            },
            {
              q: 'The app is showing old data even though I know it has been updated. How do I refresh?',
              a: 'Pull down on the screen to trigger a manual refresh on list pages. If the data is still stale, go to Profile → Settings → Clear Cache and confirm. This forces the app to re-fetch all data from the server. Your login session and settings will be preserved.',
            },
            {
              q: 'I installed the app but it shows a blank screen after login. What do I do?',
              a: 'First try force-closing the app and reopening it. If the blank screen persists, go to your phone settings, clear the app cache and data, and log in again. If the problem continues, uninstall the app, download the latest version from your app store, and reinstall. If none of these work, tap the ✦ NeedHelp button from the web portal (on your browser) and report the issue with your device model and OS version.',
            },
            {
              q: 'Can I use Student Diwan on my phone without installing the app?',
              a: 'Yes. Open your phone browser (Chrome or Safari) and go to your school\'s Student Diwan URL. The web portal is fully responsive and works on any modern mobile browser — no app installation required. You will have access to all the same features as the app. For faster access, add the URL to your phone\'s home screen using your browser\'s "Add to Home Screen" option.',
            },
          ],
        },
      ],
    },
  ],
};
