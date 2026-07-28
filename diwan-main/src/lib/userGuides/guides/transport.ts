import type { UserGuide } from '@/lib/userGuides/types';

export const transportGuide: UserGuide = {
  id: 'transport',
  role: 'Transport Manager',
  title: 'Transport Manager Guide',
  tagline: 'Manage routes, vehicles, and student transport safely and efficiently every school day.',
  audience: 'Transport managers, fleet supervisors, and school bus coordinators',
  icon: 'Bus',
  gradient: 'from-yellow-600 to-orange-600',
  accentHex: '#d97706',
  badgeBg: 'bg-yellow-100 dark:bg-yellow-950/40',
  badgeText: 'text-yellow-700 dark:text-yellow-300',
  estimatedMinutes: 25,
  version: '1.0.0',
  lastUpdated: '2025-07-01',
  chapters: [
    {
      id: 'transport-intro',
      number: 1,
      title: 'Introduction to Transport Management',
      icon: 'Navigation',
      summary: 'Learn what the Student Diwan transport module covers and your responsibilities as transport manager.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Overview of Transport Management\n\nThe Student Diwan transport module gives you full control over your school's fleet and student transport operations. From building routes and assigning vehicles to tracking daily attendance on each bus, everything is managed from a single dashboard.\n\nThe module is designed to ensure student safety, operational efficiency, and clear accountability at every step.",
        },
        {
          type: 'table',
          caption: 'Transport Manager Permissions',
          headers: ['Module', 'Permitted Actions', 'Restricted From'],
          rows: [
            ['Routes', 'Create, edit, and deactivate routes; add stops and assign timing', 'Deleting a route with active student assignments'],
            ['Vehicles', 'Add vehicles, log maintenance, update driver details', 'Modifying insurance/registration records (Admin only)'],
            ['Student Assignment', 'Assign and unassign students to routes and stops', 'Viewing unrelated student personal data'],
            ['Attendance', 'Record and review daily bus attendance', 'Editing previously submitted attendance records'],
            ['Reports', 'Generate route utilisation, attendance, and maintenance reports', 'Exporting student data outside the portal'],
            ['Driver Management', 'Add driver profiles, assign to vehicles, log licence details', 'Approving driver background-check clearance (Admin only)'],
          ],
        },
        {
          type: 'callout',
          variant: 'warning',
          title: 'Student Safety First',
          body: 'Any changes to routes, stops, or student assignments must be communicated to parents via the school notification system before they take effect. Never remove a student from a route without confirming an alternative arrangement is in place.',
        },
        {
          type: 'table',
          caption: 'Keyboard Shortcuts — Quick Navigation',
          headers: ['Module', 'Windows / Linux', 'macOS'],
          rows: [
            ['Dashboard', 'Alt + D', '⌘ Shift + D'],
            ['Transport', 'Alt + V', '⌘ Shift + V'],
            ['Messages', 'Alt + M', '⌘ Shift + M'],
            ['Notifications', 'Alt + N', '⌘ Shift + N'],
            ['Calendar', 'Alt + X', '⌘ Shift + X'],
            ['Help Center', 'Alt + Z', '⌘ Shift + Z'],
            ['Routes', 'Alt + VR', '⌘ Shift + VR'],
            ['Allocations', 'Alt + AL', '⌘ Shift + AL'],
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
      id: 'transport-login',
      number: 2,
      title: 'Login & Transport Dashboard',
      icon: 'KeyRound',
      summary: 'Sign in to the transport portal and understand the dashboard layout.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Getting Into the System\n\nYour school administrator will create your transport manager account. Use the credentials provided to log in via the transport role on the Student Diwan portal.',
        },
        {
          type: 'steps',
          title: 'Logging In',
          steps: [
            {
              title: 'Go to the Portal URL',
              description: "Open your browser and navigate to your school's Student Diwan address.",
            },
            {
              title: 'Select the Transport Role',
              description: 'Click the "Transport Manager" card on the role-selection screen.',
            },
            {
              title: 'Enter Your Credentials',
              description: 'Type your email and password, then click "Sign In".',
            },
            {
              title: 'Review the Transport Dashboard',
              description: 'Your dashboard shows a live summary: total active routes, vehicles on the road, students assigned to transport, and any alerts for today.',
              tip: 'Check the "Alerts" card first thing each morning for vehicle breakdowns, driver absences, or route delays.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/transport-routes.png',
          caption: 'The transport dashboard displaying route map, vehicle status, and daily alerts.',
          alt: 'Transport dashboard with route list, vehicle status cards, and alert notifications',
          annotations: [
            {
              id: 1,
              x: 7,
              y: 50,
              label: 'Transport Sidebar',
              description: 'Access Routes, Vehicles, Student Assignment, Attendance, and Reports.',
            },
            {
              id: 2,
              x: 25,
              y: 20,
              label: 'Active Routes',
              description: 'Total number of routes currently active for the academic year.',
            },
            {
              id: 3,
              x: 55,
              y: 20,
              label: 'Vehicles on Road',
              description: 'Count of vehicles currently operational and assigned to routes.',
            },
            {
              id: 4,
              x: 80,
              y: 20,
              label: "Today's Alerts",
              description: 'Any urgent notifications: vehicle faults, driver absence, or route changes.',
            },
            {
              id: 5,
              x: 50,
              y: 55,
              label: 'Route Map',
              description: 'Visual map of all active routes and stop locations.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Dashboard Refresh',
          body: 'The transport dashboard updates in near real-time. Vehicle GPS data (if integrated) and attendance submissions from drivers refresh automatically every 2 minutes.',
        },
      ],
    },
    {
      id: 'transport-routes',
      number: 3,
      title: 'Route Management',
      icon: 'Route',
      summary: 'Create and manage bus routes, define stops, and set pickup/drop-off timings.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Building and Managing Routes\n\nRoutes define the path a school bus takes each day. Each route has a name, a list of ordered stops, associated timings for pickup and drop-off, and a vehicle and driver assignment.',
        },
        {
          type: 'steps',
          title: 'Creating a New Route',
          steps: [
            {
              title: 'Open Routes',
              description: 'Click "Routes" in the sidebar and then press "+ New Route".',
            },
            {
              title: 'Name the Route',
              description: 'Give the route a clear, identifiable name (e.g., "Route A – North Sector") and add a brief description.',
            },
            {
              title: 'Add Stops',
              description: 'Click "+ Add Stop" to add each bus stop in order of the route. For each stop, enter: stop name, landmark, pickup time (morning), and drop-off time (afternoon).',
              tip: 'Add stops in the order the bus will actually visit them to avoid confusion for drivers and parents.',
            },
            {
              title: 'Assign a Vehicle and Driver',
              description: 'Select the vehicle and primary driver for this route from the dropdown lists. If a relief driver is available, assign them as backup.',
            },
            {
              title: 'Save and Activate',
              description: 'Click "Save". The route starts in "Draft" status. Click "Activate" to make it live and visible to parents and students assigned to it.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Editing an Active Route',
          body: 'You can edit a route at any time. Changes to stop timings or stop locations trigger an automatic notification to all affected parents. Confirm the changes in the preview dialog before saving.',
        },
      ],
    },
    {
      id: 'transport-vehicles',
      number: 4,
      title: 'Vehicle Management',
      icon: 'Truck',
      summary: 'Maintain an accurate fleet registry, track maintenance schedules, and manage driver assignments.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Fleet & Vehicle Records\n\nThe Vehicles module is your central fleet registry. Every school bus or van should be registered here with its key details. This information feeds into route assignments, maintenance tracking, and compliance reporting.',
        },
        {
          type: 'steps',
          title: 'Adding a Vehicle',
          steps: [
            {
              title: 'Go to Vehicles',
              description: 'Click "Vehicles" in the sidebar, then press "+ Add Vehicle".',
            },
            {
              title: 'Enter Vehicle Details',
              description: 'Fill in: Vehicle Number/Registration Plate, Make and Model, Year of Manufacture, Seating Capacity, and Fuel Type.',
            },
            {
              title: 'Upload Documents',
              description: "Attach scanned copies of the vehicle's Fitness Certificate, Insurance Policy, and Registration Certificate.",
              tip: 'Set document expiry dates so the system can alert you before they lapse.',
            },
            {
              title: 'Assign a Primary Driver',
              description: 'Select the driver from your registered driver list. You can also assign a relief driver for this vehicle.',
            },
            {
              title: 'Save the Vehicle',
              description: 'Click "Save". The vehicle is now available for route assignment.',
            },
          ],
        },
        {
          type: 'screenshot',
          src: '/guide-screenshots/transport-vehicles.png',
          caption: 'The vehicle management page listing all registered fleet vehicles.',
          alt: 'Vehicle management table showing registration numbers, capacity, driver names, and status',
          annotations: [
            {
              id: 1,
              x: 85,
              y: 10,
              label: 'Add Vehicle',
              description: 'Open the form to register a new vehicle in the fleet.',
            },
            {
              id: 2,
              x: 20,
              y: 40,
              label: 'Registration Number',
              description: 'Unique vehicle identifier used for all route and maintenance records.',
            },
            {
              id: 3,
              x: 55,
              y: 40,
              label: 'Driver Assigned',
              description: 'Current primary driver for this vehicle.',
            },
            {
              id: 4,
              x: 75,
              y: 40,
              label: 'Document Status',
              description: 'Shows expiry status of insurance, fitness certificate, and registration.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'danger',
          title: 'Document Expiry Alerts',
          body: "When a vehicle's insurance or fitness certificate is within 30 days of expiry, the system sends an alert to the transport manager and school administrator. A vehicle with expired documents must not be operated — deactivate it in the system immediately.",
        },
      ],
    },
    {
      id: 'transport-students',
      number: 5,
      title: 'Student Assignment to Routes',
      icon: 'UserCheck',
      summary: 'Assign students to routes and stops, manage changes mid-term, and handle special requests.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Assigning Students to Bus Routes\n\nEach student who uses school transport must be assigned to a specific route and stop. This determines the bus they board, their pickup and drop-off location, and what parents see in their portal.',
        },
        {
          type: 'steps',
          title: 'Assigning a Student to a Route',
          steps: [
            {
              title: 'Open Student Assignment',
              description: 'Click "Student Assignment" in the sidebar.',
            },
            {
              title: 'Search for the Student',
              description: 'Use the search field to find the student by name, class, or student ID.',
            },
            {
              title: 'Click "Assign Route"',
              description: `Press "Assign Route" next to the student's name.`,
            },
            {
              title: 'Select Route and Stop',
              description: "Choose the applicable route from the dropdown, then select the specific stop nearest to the student's home address.",
              tip: 'Ensure the seating capacity of the assigned vehicle is not exceeded. The system will warn you if the vehicle is full.',
            },
            {
              title: 'Save the Assignment',
              description: `Click "Confirm Assignment". The student is added to the route roster and the parent's portal updates to show the bus route and timing.`,
            },
          ],
        },
        {
          type: 'callout',
          variant: 'info',
          title: 'Temporary Route Changes',
          body: `For temporary changes (e.g., a student needs to be dropped at a different address for one day), use the "Temporary Override" option. This applies only to the selected date and does not permanently change the student's route assignment.`,
        },
      ],
    },
    {
      id: 'transport-attendance',
      number: 6,
      title: 'Attendance & Reports',
      icon: 'ClipboardCheck',
      summary: 'Record daily bus attendance, handle absences, and generate transport reports.',
      blocks: [
        {
          type: 'text',
          markdown:
            '## Tracking Bus Attendance\n\nDrivers can record attendance via the mobile app, or the transport manager can enter it manually. Daily bus attendance records are linked to the main school attendance system for a complete picture of student whereabouts.',
        },
        {
          type: 'steps',
          title: 'Recording Bus Attendance',
          steps: [
            {
              title: 'Go to Attendance',
              description: 'Click "Attendance" in the transport sidebar.',
            },
            {
              title: 'Select Date and Route',
              description: "Choose today's date and the relevant route.",
            },
            {
              title: 'Mark Present or Absent',
              description: `The student roster for the route is displayed. Mark each student as "Boarded", "Absent", or "Early Pickup" as applicable.`,
              tip: 'If a student boards at an unexpected stop, add a note in the "Remarks" column.',
            },
            {
              title: 'Submit Attendance',
              description: 'Click "Submit". The record is saved and any absent students trigger an automated SMS alert to their parents.',
            },
          ],
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A driver did not submit attendance for a route. Can I enter it manually?',
              a: 'Yes. Go to Attendance, select the date and route, and enter the attendance manually. The system logs your user ID as the person who submitted the record, preserving the audit trail.',
            },
            {
              q: 'How do I generate a monthly transport utilisation report?',
              a: 'Navigate to Reports > Transport Reports and select "Route Utilisation". Set the date range to the desired month and click Generate. The report shows occupancy rates per route and vehicle.',
            },
            {
              q: 'A vehicle has broken down mid-route. What should I do in the system?',
              a: `In the Vehicles module, open the vehicle record and set its status to "Out of Service". Then use the route's "Emergency Reassign" feature to assign an available vehicle and driver, and notify parents via the system notification tool.`,
            },
            {
              q: 'Can parents track the bus live?',
              a: 'Live GPS tracking for parents is available if your school has enabled the GPS integration. The transport manager enables this per vehicle in the vehicle settings. Parents see the live location in their portal and mobile app.',
            },
            {
              q: 'How do I deactivate a route at the end of the academic year?',
              a: 'Open the route, click "Deactivate". The system will warn you if students are still assigned to the route. Remove all student assignments first, then deactivate. Historical records are preserved.',
            },
          ],
        },
        {
          type: 'callout',
          variant: 'success',
          title: 'End-of-Day Checklist',
          body: "Before closing for the day: confirm all routes have submitted attendance, check for any open vehicle fault reports, and review tomorrow's schedule for any driver absences or vehicle service appointments.",
        },
      ],
    },
    {
      id: 'transport-help',
      number: 7,
      title: 'Help Centre & Support',
      icon: 'LifeBuoy',
      summary: 'Find transport documentation, resolve route and vehicle issues, and get platform support.',
      blocks: [
        {
          type: 'text',
          markdown:
            "## Your Help Centre\n\nThe Help Centre at `/help` gives you access to the Transport Manager Guide covering routes, vehicles, student assignments, and attendance reporting. For technical errors — student lists not loading, attendance not saving, or route exports failing — the NeedHelp widget connects you directly to platform support.\n\nPress **Alt + Z** (Windows) or **⌘ Shift + Z** (Mac) from any page to open the Help Centre instantly.",
        },
        {
          type: 'steps',
          title: 'How to Open the Help Centre',
          steps: [
            {
              title: 'Press Alt + Z or ⌘ Shift + Z',
              description: 'Jump to the Help Centre from anywhere in the app — useful when you need to quickly check a route setup procedure without losing your current work.',
            },
            {
              title: 'Click Help in the Sidebar',
              description: 'The Help icon at the bottom of the left sidebar opens the Help Home page at /help.',
            },
            {
              title: 'Open the Transport Manager Guide',
              description: 'Go to /help/guides/transport or select the Transport Manager card on the Guide Hub for your complete role manual.',
            },
            {
              title: 'Report a System Issue',
              description: 'Click the floating ✦ button (bottom-right) to report technical problems such as missing students in route lists, attendance not saving, or export failures.',
            },
          ],
        },
        {
          type: 'table',
          caption: 'Help Resources Available to Transport Managers',
          headers: ['Resource', 'What It Covers', 'Where to Find It'],
          rows: [
            ['Transport Guide — Chapter 3', 'Route Management: creating routes, setting stops, and managing schedules', '/help/guides/transport'],
            ['Transport Guide — Chapter 4', 'Vehicle Management: adding vehicles, tracking maintenance, and logging fuel', '/help/guides/transport'],
            ['Transport Guide — Chapter 5', 'Student Assignment: assigning students to routes and managing stop changes', '/help/guides/transport'],
            ['Transport Guide — Chapter 6', 'Attendance & Reports: recording boarding/alighting, generating route attendance reports', '/help/guides/transport'],
            ['Help Category Browser', 'Searchable articles on transport setup, student route changes, and vehicle tracking', '/help'],
            ['NeedHelp Widget', 'Report missing students in route lists, attendance sync issues, or export errors to platform support', 'Floating ✦ button — any page'],
          ],
        },
        {
          type: 'callout',
          variant: 'tip',
          title: 'Contact School Admin for Student Assignment Changes',
          body: 'If a parent requests a permanent route change for their child, the School Admin must update the student profile first (/students → student profile → Transport tab). Once the School Admin confirms the update, the student will appear on the new route in your Transport module automatically. You do not need to manually reassign — just verify the change is reflected by the next school day.',
        },
        {
          type: 'faq',
          questions: [
            {
              q: 'A student is not appearing in the route list even though they have been assigned transport. Why?',
              a: "First confirm the student's transport assignment in their profile (/students → open student → Transport tab). If the assignment shows the correct route but the student is still missing from your route list, it may be a sync delay — refresh the page and try again. If the student is still not showing after 10 minutes, use the NeedHelp widget to report the issue with the student ID and route name.",
            },
            {
              q: 'A vehicle has a fault and cannot run tomorrow. How do I reassign the route?',
              a: "Go to the vehicle record (/transport/vehicles), open the vehicle, and log the fault with status 'Out of Service'. Then go to the affected route (/transport/routes), open the route, and change the assigned vehicle to an available one. If no spare vehicle is available, flag the situation to your School Admin so they can notify affected parents.",
            },
            {
              q: 'How do I generate an attendance report for a specific route over the past month?',
              a: 'Go to /reports → Transport → Route Attendance. Select the route name and date range, then click "Generate Report". The report shows daily attendance for each student on the route. Export it as CSV or PDF using the download button at the top of the report.',
            },
            {
              q: 'A driver is absent. How do I record this and manage the route?',
              a: "Record driver absences in the HR module (/hr/leave → Add Leave → select the driver). For the route, either assign a substitute driver in the route settings (/transport/routes → edit route → change driver) or mark the route as 'Suspended' for the day and notify the School Admin to alert affected parents.",
            },
          ],
        },
      ],
    },
  ],
};
