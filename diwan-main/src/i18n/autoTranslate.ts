/**
 * Global DOM auto-translation layer.
 *
 * When Arabic is active, this walks the rendered DOM and replaces known
 * English strings (from the locale files + a comprehensive ERP dictionary)
 * with Arabic. A MutationObserver keeps newly rendered content translated,
 * so every module/page is covered without needing t() calls in each file.
 */
import en from './locales/en.json';
import ar from './locales/ar.json';
import uiExtras from './uiDictionary.json';
import { isNameCandidate, transliterateName } from './nameTranslit';

type JsonObj = { [k: string]: string | JsonObj };

// ---------- Build dictionary ----------
const dict = new Map<string, string>();

function addPair(enVal: string, arVal: string) {
  const key = enVal.trim();
  if (key && arVal && key !== arVal) dict.set(key.toLowerCase(), arVal);
}

function flattenPairs(enNode: JsonObj, arNode: JsonObj | undefined) {
  if (!arNode) return;
  for (const k of Object.keys(enNode)) {
    const e = enNode[k];
    const a = arNode[k];
    if (typeof e === 'string' && typeof a === 'string') addPair(e, a);
    else if (typeof e === 'object' && typeof a === 'object') flattenPairs(e, a as JsonObj);
  }
}
flattenPairs(en as unknown as JsonObj, ar as unknown as JsonObj);

// Comprehensive ERP / UI term dictionary (extends the locale files)
const MANUAL: Record<string, string> = {
  // Generic UI
  'Save': 'حفظ', 'Cancel': 'إلغاء', 'Delete': 'حذف', 'Edit': 'تعديل', 'Add': 'إضافة',
  'Create': 'إنشاء', 'Update': 'تحديث', 'Search': 'بحث', 'Filter': 'تصفية', 'Filters': 'التصفية',
  'Export': 'تصدير', 'Import': 'استيراد', 'Print': 'طباعة', 'Download': 'تنزيل', 'Upload': 'رفع',
  'Submit': 'إرسال', 'Close': 'إغلاق', 'Open': 'فتح', 'View': 'عرض', 'Details': 'التفاصيل',
  'Actions': 'الإجراءات', 'Action': 'إجراء', 'Status': 'الحالة', 'Active': 'نشط', 'Inactive': 'غير نشط',
  'Yes': 'نعم', 'No': 'لا', 'OK': 'موافق', 'Confirm': 'تأكيد', 'Back': 'رجوع', 'Next': 'التالي',
  'Previous': 'السابق', 'Loading...': 'جارٍ التحميل...', 'Loading': 'جارٍ التحميل',
  'No data': 'لا توجد بيانات', 'No results': 'لا توجد نتائج', 'No results found': 'لم يتم العثور على نتائج',
  'Total': 'الإجمالي', 'Name': 'الاسم', 'Email': 'البريد الإلكتروني', 'Phone': 'الهاتف',
  'Address': 'العنوان', 'Date': 'التاريخ', 'Time': 'الوقت', 'Type': 'النوع', 'Description': 'الوصف',
  'Amount': 'المبلغ', 'Notes': 'ملاحظات', 'Remarks': 'ملاحظات', 'Select': 'اختيار',
  'All': 'الكل', 'None': 'لا شيء', 'Other': 'أخرى', 'New': 'جديد', 'Apply': 'تطبيق',
  'Reset': 'إعادة تعيين', 'Refresh': 'تحديث', 'Retry': 'إعادة المحاولة', 'Send': 'إرسال',
  'Reply': 'رد', 'Approve': 'موافقة', 'Reject': 'رفض', 'Pending': 'قيد الانتظار',
  'Approved': 'تمت الموافقة', 'Rejected': 'مرفوض', 'Completed': 'مكتمل', 'In Progress': 'قيد التنفيذ',
  'Draft': 'مسودة', 'Published': 'منشور', 'Archived': 'مؤرشف', 'Overview': 'نظرة عامة',
  'Summary': 'الملخص', 'Profile': 'الملف الشخصي', 'Logout': 'تسجيل الخروج', 'Sign out': 'تسجيل الخروج',
  'Sign in': 'تسجيل الدخول', 'Password': 'كلمة المرور', 'Male': 'ذكر', 'Female': 'أنثى',
  'Today': 'اليوم', 'Yesterday': 'أمس', 'This Week': 'هذا الأسبوع', 'This Month': 'هذا الشهر',
  'This Year': 'هذه السنة', 'Monday': 'الاثنين', 'Tuesday': 'الثلاثاء', 'Wednesday': 'الأربعاء',
  'Thursday': 'الخميس', 'Friday': 'الجمعة', 'Saturday': 'السبت', 'Sunday': 'الأحد',
  'January': 'يناير', 'February': 'فبراير', 'March': 'مارس', 'April': 'أبريل', 'May': 'مايو',
  'June': 'يونيو', 'July': 'يوليو', 'August': 'أغسطس', 'September': 'سبتمبر',
  'October': 'أكتوبر', 'November': 'نوفمبر', 'December': 'ديسمبر',
  // People / roles
  'Student': 'طالب', 'Students': 'الطلاب', 'Teacher': 'معلم', 'Teachers': 'المعلمون',
  'Parent': 'ولي أمر', 'Parents': 'أولياء الأمور', 'Staff': 'الموظفون', 'Admin': 'مدير',
  'Administrator': 'المسؤول', 'Principal': 'مدير المدرسة', 'Accountant': 'محاسب',
  'Librarian': 'أمين المكتبة', 'Driver': 'سائق', 'User': 'مستخدم', 'Users': 'المستخدمون',
  'Guardian': 'ولي الأمر', 'Father': 'الأب', 'Mother': 'الأم',
  // Academic
  'Class': 'الفصل', 'Classes': 'الفصول', 'Section': 'الشعبة', 'Grade': 'الصف',
  'Subject': 'المادة', 'Subjects': 'المواد', 'Exam': 'امتحان', 'Exams': 'الامتحانات',
  'Marks': 'الدرجات', 'Result': 'النتيجة', 'Results': 'النتائج', 'Attendance': 'الحضور',
  'Present': 'حاضر', 'Absent': 'غائب', 'Late': 'متأخر', 'Excused': 'بعذر',
  'Timetable': 'الجدول الدراسي', 'Schedule': 'الجدول', 'Assignment': 'واجب',
  'Assignments': 'الواجبات', 'Homework': 'الواجب المنزلي', 'Syllabus': 'المنهج',
  'Curriculum': 'المنهج الدراسي', 'Semester': 'الفصل الدراسي', 'Term': 'الفصل',
  'Academic Year': 'العام الدراسي', 'Admission': 'القبول', 'Roll Number': 'رقم القيد',
  'Report Card': 'بطاقة التقرير', 'Certificate': 'شهادة', 'Library': 'المكتبة',
  'Book': 'كتاب', 'Books': 'الكتب', 'Lesson': 'درس', 'Lessons': 'الدروس',
  'Quiz': 'اختبار قصير', 'Test': 'اختبار', 'Score': 'النتيجة', 'Average': 'المتوسط',
  'Percentage': 'النسبة المئوية', 'Rank': 'الترتيب', 'Pass': 'ناجح', 'Fail': 'راسب',
  // Finance
  'Fee': 'الرسوم', 'Fees': 'الرسوم', 'Payment': 'الدفع', 'Payments': 'المدفوعات',
  'Invoice': 'فاتورة', 'Invoices': 'الفواتير', 'Receipt': 'إيصال', 'Balance': 'الرصيد',
  'Paid': 'مدفوع', 'Unpaid': 'غير مدفوع', 'Overdue': 'متأخر السداد', 'Discount': 'خصم',
  'Salary': 'الراتب', 'Payroll': 'الرواتب', 'Expense': 'مصروف', 'Expenses': 'المصروفات',
  'Revenue': 'الإيرادات', 'Income': 'الدخل', 'Budget': 'الميزانية', 'Tax': 'الضريبة',
  'Currency': 'العملة', 'Bank': 'البنك', 'Cash': 'نقدًا', 'Online': 'عبر الإنترنت',
  'Transaction': 'معاملة', 'Transactions': 'المعاملات', 'Due Date': 'تاريخ الاستحقاق',
  // Communication
  'Message': 'رسالة', 'Messages': 'الرسائل', 'Announcement': 'إعلان', 'Announcements': 'الإعلانات',
  'Notification': 'إشعار', 'Notifications': 'الإشعارات', 'Event': 'فعالية', 'Events': 'الفعاليات',
  'Meeting': 'اجتماع', 'Calendar': 'التقويم', 'Inbox': 'الوارد', 'Sent': 'المرسل',
  // Transport / hostel / misc
  'Transport': 'النقل', 'Route': 'المسار', 'Routes': 'المسارات', 'Vehicle': 'مركبة',
  'Vehicles': 'المركبات', 'Hostel': 'السكن الداخلي', 'Room': 'غرفة', 'Rooms': 'الغرف',
  'Visitor': 'زائر', 'Visitors': 'الزوار', 'Inventory': 'المخزون', 'Stock': 'المخزون',
  'Vendor': 'مورد', 'Vendors': 'الموردون', 'Purchase': 'شراء', 'Purchases': 'المشتريات',
  'Asset': 'أصل', 'Assets': 'الأصول', 'Department': 'القسم', 'Departments': 'الأقسام',
  'Branch': 'الفرع', 'Branches': 'الفروع', 'Reports': 'التقارير', 'Report': 'تقرير',
  'Analytics': 'التحليلات', 'Dashboard': 'لوحة التحكم', 'Settings': 'الإعدادات',
  'Permissions': 'الصلاحيات', 'Leave': 'إجازة', 'Holiday': 'عطلة', 'Holidays': 'العطلات',
  // Common composite phrases (page titles, stats, headers)
  'Total Students': 'إجمالي الطلاب', 'Total Staff': 'إجمالي الموظفين',
  'Total Marks': 'مجموع الدرجات', 'Total Revenue': 'إجمالي الإيرادات',
  'Total Expenses': 'إجمالي المصروفات', 'Total Records': 'إجمالي السجلات',
  'Total Allocated': 'إجمالي المخصص', 'Active Students': 'الطلاب النشطون',
  'Active Today': 'نشط اليوم', 'Present Today': 'الحاضرون اليوم',
  'New Admissions': 'القبول الجديد', 'Upcoming Exams': 'الامتحانات القادمة',
  'Class Average': 'متوسط الفصل', 'Pass Rate': 'نسبة النجاح',
  'Passing Marks': 'درجة النجاح', 'Pending Assignments': 'الواجبات المعلقة',
  'Take Attendance': 'تسجيل الحضور', 'Create Assignment': 'إنشاء واجب',
  'View Reports': 'عرض التقارير', 'View profile': 'عرض الملف الشخصي',
  'View List': 'عرض القائمة', 'View All': 'عرض الكل', 'View Details': 'عرض التفاصيل',
  'On Leave': 'في إجازة', 'On Duty': 'في الخدمة', 'Blood Group': 'فصيلة الدم',
  'Date of Birth': 'تاريخ الميلاد', 'Medical Certificate': 'شهادة طبية',
  'ID number': 'رقم الهوية', 'Select category': 'اختر الفئة',
  'Select grade': 'اختر الصف', 'Select Status': 'اختر الحالة',
  'Select vehicle': 'اختر المركبة', 'Select class': 'اختر الفصل',
  'Select subject': 'اختر المادة', 'Select section': 'اختر الشعبة',
  'All Statuses': 'جميع الحالات', 'All Classes': 'جميع الفصول',
  'All Grades': 'جميع الصفوف', 'All Sections': 'جميع الشعب',
  'All Subjects': 'جميع المواد', 'All Students': 'جميع الطلاب',
  'Student Directory': 'دليل الطلاب', 'Staff Directory': 'دليل الموظفين',
  'Student & ID': 'الطالب والرقم', 'In directory': 'في الدليل',
  'At Risk (AI)': 'في خطر (ذكاء اصطناعي)', 'At Risk Students': 'الطلاب المعرضون للخطر',
  'Low Attendance': 'حضور منخفض', 'AI Priority': 'أولوية الذكاء الاصطناعي',
  'AI Insight': 'رؤية الذكاء الاصطناعي', 'AI Command': 'أمر الذكاء الاصطناعي',
  'Central Database': 'قاعدة البيانات المركزية', 'Clean Up Credentials': 'تنظيف بيانات الاعتماد',
  'Fee Collection Overview': 'نظرة عامة على تحصيل الرسوم',
  'Student Distribution by Grade': 'توزيع الطلاب حسب الصف',
  'View full breakdown': 'عرض التفاصيل الكاملة',
  'No invoices generated yet': 'لم يتم إنشاء فواتير بعد',
  'awaiting review': 'في انتظار المراجعة', 'vs last month': 'مقارنة بالشهر الماضي',
  'Action needed': 'إجراء مطلوب', 'this month': 'هذا الشهر',
  'Attendance Overview': 'نظرة عامة على الحضور', 'Fee Collection': 'تحصيل الرسوم',
  'Table': 'جدول', 'Cards': 'بطاقات', 'List': 'قائمة', 'Grid': 'شبكة',
  'Questions': 'الأسئلة', 'Duration': 'المدة', 'Documents': 'المستندات',
  'Available': 'متاح', 'Upcoming': 'قادم', 'Submitted': 'تم التسليم',
  'Scheduled': 'مجدول', 'Enrolled': 'مسجل', 'Drafts': 'المسودات',
  'Trips': 'الرحلات', 'Reference': 'المرجع', 'Optional': 'اختياري',
  'Gender': 'الجنس', 'Theme': 'المظهر', 'Tests': 'الاختبارات',
  'LUNCH BREAK': 'استراحة الغداء', 'BREAK': 'استراحة',
  'School Admin': 'مدير المدرسة', 'Admin Demo': 'مدير تجريبي',
  'Search by student name, ID, parent contact': 'البحث باسم الطالب أو الرقم أو بيانات ولي الأمر',
  'Search students': 'البحث عن الطلاب',
  'Risk ≥ 75 or attendance < 75%': 'خطر ≥ 75 أو حضور < 75%',
  'Manage, monitor and automate student records with AI insights.': 'إدارة ومراقبة وأتمتة سجلات الطلاب برؤى الذكاء الاصطناعي.',
  'No records found': 'لم يتم العثور على سجلات', 'No students found': 'لم يتم العثور على طلاب',
  'Add Student': 'إضافة طالب', 'Add Staff': 'إضافة موظف', 'Add New': 'إضافة جديد',
  'Save Changes': 'حفظ التغييرات', 'Discard': 'تجاهل', 'Continue': 'متابعة',
  'First Name': 'الاسم الأول', 'Last Name': 'اسم العائلة', 'Full Name': 'الاسم الكامل',
  'Contact': 'جهة الاتصال', 'Nationality': 'الجنسية', 'Religion': 'الديانة',
  'Category': 'الفئة', 'Priority': 'الأولوية', 'High': 'مرتفع', 'Medium': 'متوسط', 'Low': 'منخفض',
  'Performance': 'الأداء', 'Progress': 'التقدم', 'Actions Required': 'الإجراءات المطلوبة',
  'Recent Activity': 'النشاط الأخير', 'Quick Links': 'روابط سريعة',
  'Academic': 'أكاديمي', 'Financial': 'مالي', 'General': 'عام',
  // Sidebar nav items (actual titles from navGroups.ts)
  'Conduct & Discipline': 'السلوك والانضباط', 'Alumni Network': 'شبكة الخريجين',
  'Withdrawal': 'الانسحاب', 'Room Management': 'إدارة الغرف',
  'Parent-Teacher Meetings': 'اجتماعات أولياء الأمور والمعلمين',
  'Exam Operations': 'عمليات الامتحانات', 'Coding Lab': 'مختبر البرمجة',
  'Plagiarism Checker': 'فاحص الانتحال', 'HR Dashboard': 'لوحة الموارد البشرية',
  'Staff Profiles': 'ملفات الموظفين', 'Staff Attendance': 'حضور الموظفين',
  'Appraisals': 'التقييمات الوظيفية', 'Staff Settings': 'إعدادات الموظفين',
  'Scholarships': 'المنح الدراسية', 'Automation': 'الأتمتة',
  'Fleet': 'الأسطول', 'Allocations': 'التخصيصات', 'Live Tracking': 'التتبع المباشر',
  'Operations': 'العمليات', 'Room Allocation': 'تخصيص الغرف',
  'Hostel Attendance': 'حضور السكن الداخلي', 'Visitor Log': 'سجل الزوار',
  'Mess & Menu': 'الكافيتيريا والقائمة', 'Incidents': 'الحوادث',
  'Purchase Orders': 'أوامر الشراء', 'Product Analytics': 'تحليلات المنتج',
  'Predictive Analytics': 'التحليلات التنبؤية', 'AI Tutor': 'المعلم الذكي',
  'Executive View': 'العرض التنفيذي', 'Compliance': 'الامتثال',
  'Users & Roles': 'المستخدمون والأدوار', 'Academic Config': 'الإعدادات الأكاديمية',
  'Finance Config': 'إعدادات المالية', 'System Settings': 'إعدادات النظام',
  'Toggle Sidebar': 'تبديل الشريط الجانبي',
  // Dashboard widgets
  'Application Pipeline (Admissions)': 'مسار الطلبات (القبول)',
  'View admission pipeline': 'عرض مسار القبول',
  'Inquiries': 'الاستفسارات', 'New Leads': 'عملاء جدد', 'Offers': 'العروض',
  'Top Performing Classes': 'الفصول الأفضل أداءً', 'View all classes': 'عرض جميع الفصول',
  'No exam marks recorded yet.': 'لم تُسجَّل درجات امتحانات بعد.',
  'Teacher Workload Overview': 'نظرة عامة على عبء عمل المعلمين',
  'View workload report': 'عرض تقرير عبء العمل',
  'No subject assignments recorded yet.': 'لم تُسجَّل مواد للمعلمين بعد.',
  'No recent activity recorded yet.': 'لا يوجد نشاط حديث بعد.',
  'View Calendar': 'عرض التقويم',
  'No upcoming events scheduled.': 'لا توجد فعاليات قادمة مجدولة.',
  'Approvals Overview': 'نظرة عامة على الموافقات',
  'Pending Leave': 'إجازات معلقة', 'Pending Purchase Orders': 'أوامر شراء معلقة',
  'Admission Reviews': 'مراجعات القبول', 'Approved Leave (30d)': 'إجازات معتمدة (30 يومًا)',
  'No active appraisal cycle yet.': 'لا توجد دورة تقييم نشطة بعد.',
  'Quick Access': 'وصول سريع', 'Fee Collection (BHD)': 'تحصيل الرسوم (دينار بحريني)',
  'BHD (Bahraini Dinar)': 'دينار بحريني',
  // Exams page
  'Create exam + subjects': 'إنشاء امتحان + مواد', 'Halls + seating plan': 'القاعات + خطة الجلوس',
  'Hall Tickets': 'بطاقات الدخول', 'Print admit cards': 'طباعة بطاقات الدخول',
  'Invigilators': 'المراقبون', 'Duty roster': 'جدول المناوبات',
  'Mark present/absent': 'تسجيل حاضر/غائب', 'Exam Type': 'نوع الامتحان',
  'Exam Dates': 'تواريخ الامتحان', 'Appeared': 'حضر', 'Continue to': 'المتابعة إلى',
  'setup': 'الإعداد',
  // HR page
  'Manage comprehensive staff profiles, contracts, and documents': 'إدارة ملفات الموظفين والعقود والمستندات بشكل شامل',
  'Add Staff Member': 'إضافة موظف', 'All Departments': 'جميع الأقسام',
  'Vice Principal': 'نائب المدير',
  'Staff Member': 'الموظف', 'Role & Dept': 'الدور والقسم',
  'Search by name, ID, or department': 'البحث بالاسم أو الرقم أو القسم',
  'Export CSV': 'تصدير CSV',
  // Misc
  'Page Not Found': 'الصفحة غير موجودة',
  "The page you are looking for doesn't exist or has been moved": 'الصفحة التي تبحث عنها غير موجودة أو تم نقلها',
  'Back to Dashboard': 'العودة إلى لوحة التحكم',
  // System Settings page (src/pages/SystemSettings.tsx — hardcoded, no t() calls)
  'Advanced developer tools and system configuration.': 'أدوات المطورين المتقدمة وإعدادات النظام.',
  'Clear Cache': 'مسح ذاكرة التخزين المؤقت',
  'Timetable — Teacher Workload Limits': 'الجدول الدراسي — حدود عبء عمل المعلمين',
  'Maximum periods per day each role can be assigned. Set to 0 to block assignment entirely. Changes apply the next time the Timetable page is opened.':
    'الحد الأقصى للحصص اليومية التي يمكن إسنادها لكل دور. اضبط على 0 لمنع الإسناد تمامًا. تُطبَّق التغييرات عند فتح صفحة الجدول الدراسي في المرة التالية.',
  'Reset defaults': 'استعادة الإعدادات الافتراضية',
  'Save limits': 'حفظ الحدود',
  'Subject Teacher': 'معلم مادة',
  'Regular teaching staff assigned to specific subjects': 'طاقم تدريس معتاد مُسنَد إلى مواد محددة',
  'Class Teacher': 'معلم الفصل',
  'Homeroom teacher also responsible for a section': 'معلم الفصل المسؤول أيضًا عن شعبة',
  'Grade Coordinator': 'منسق الصف',
  'Oversees a grade level; reduced teaching load': 'يشرف على مستوى صف دراسي؛ بعبء تدريسي مخفَّض',
  'Head of Department (HOD)': 'رئيس القسم',
  'Applies to all HOD roles (Maths, Science, English, Arabic, etc.)': 'ينطبق على جميع أدوار رؤساء الأقسام (الرياضيات، العلوم، الإنجليزية، العربية، إلخ.)',
  'Principal / Vice Principal': 'المدير / نائب المدير',
  'Administrative leadership; set to 0 to block teaching assignment': 'قيادة إدارية؛ اضبط على 0 لمنع الإسناد التدريسي',
  'Blocked': 'محظور',
  'Qatar Ministry guidelines (defaults): Subject Teacher 5 · Class Teacher 5 · Grade Coordinator 3 · HOD 4 · Principal 0':
    'إرشادات وزارة قطر (الإعدادات الافتراضية): معلم المادة 5 · معلم الفصل 5 · منسق الصف 3 · رئيس القسم 4 · المدير 0',
  'Security Configuration': 'إعدادات الأمان',
  'Manage system-wide security policies.': 'إدارة سياسات الأمان على مستوى النظام.',
  'Current User': 'المستخدم الحالي',
  'Role': 'الدور',
  'Security rules are currently enforced via Firestore. To modify them, edit the': 'قواعد الأمان مُطبَّقة حاليًا عبر Firestore. لتعديلها، حرِّر ملف',
  'file in the root directory.': 'في المجلد الجذر.',
  'Developer Logs': 'سجلات المطورين',
  'Most recent entries from the real audit log.': 'أحدث الإدخالات من سجل التدقيق الفعلي.',
  'No audit log entries yet.': 'لا توجد إدخالات في سجل التدقيق بعد.',
  'System Environment': 'بيئة النظام',
  'Real build mode, reported by Vite at build time.': 'وضع البناء الفعلي، كما يبلّغ عنه Vite وقت البناء.',
  'Environment': 'البيئة',
  'Production': 'الإنتاج',
  'Development': 'التطوير',
  'Mode': 'الوضع',
  'Access Denied': 'تم رفض الوصول',
  'Only administrators can access this panel.': 'يمكن للمسؤولين فقط الوصول إلى هذه اللوحة.',
  // Workload "N/day" badges on the System Settings timetable rules
  '1/day': '1/يوم', '2/day': '2/يوم', '3/day': '3/يوم', '4/day': '4/يوم',
  '5/day': '5/يوم', '6/day': '6/يوم', '7/day': '7/يوم', '8/day': '8/يوم',
  // Dashboard widgets / teacher workload / appraisal labels
  'Average Load': 'الحِمل المتوسط', 'Full Load': 'الحِمل الكامل',
  'Overall Completion': 'نسبة الإنجاز الإجمالية', 'Top Department': 'القسم الأعلى أداءً',
  'Needs Development': 'يحتاج إلى تطوير', 'Just now': 'الآن',
};

// Grade 1..12 / Grade-1..12 patterns
for (let g = 1; g <= 12; g++) {
  addPair(`Grade ${g}`, `الصف ${g}`);
  addPair(`Grade-${g}`, `الصف ${g}`);
  addPair(`Grade ${g} - A`, `الصف ${g} - أ`);
  addPair(`Grade ${g} - B`, `الصف ${g} - ب`);
}
for (const [e, a] of Object.entries(MANUAL)) addPair(e, a);

// Kindergarten level codes (used in class names / grade pickers)
addPair('Pre-KG', 'ما قبل الروضة');
addPair('LKG', 'الروضة الأولى');
addPair('UKG', 'الروضة الثانية');
addPair('KG', 'الروضة');

// ── System-generated / technical labels ─────────────────────────────────────
// Database status badge (admin-only)
addPair('Cloud MySQL', 'قاعدة بيانات سحابية');
addPair('Local Mode', 'الوضع المحلي');
addPair('Cloud Active', 'السحابة نشطة');
addPair('Local SQLite', 'قاعدة بيانات محلية');
addPair('Connecting…', 'جارٍ الاتصال…');
// Activity / audit-log entity & action types
addPair('AssistantMessage', 'رسالة المساعد');
addPair('Assistant Message', 'رسالة المساعد');
addPair('Appraisal', 'التقييم');
addPair('Notification', 'إشعار');
addPair('chat_query', 'استعلام محادثة');
addPair('daily_brief_query', 'استعلام الموجز اليومي');
addPair('Audit Log', 'سجل التدقيق');
addPair('Activity Log', 'سجل النشاط');
addPair('Created', 'أنشأ'); addPair('Updated', 'حدّث'); addPair('Deleted', 'حذف');
addPair('Viewed', 'عرض'); addPair('Exported', 'صدّر'); addPair('Imported', 'استورد');
addPair('Logged in', 'سجّل الدخول'); addPair('Logged out', 'سجّل الخروج');
// Status values
addPair('Verified', 'مُوثَّق'); addPair('Unverified', 'غير موثَّق');
addPair('Enrolled', 'مُسجَّل'); addPair('Graduated', 'متخرّج');
addPair('Suspended', 'موقوف'); addPair('Withdrawn', 'منسحب');
addPair('On Track', 'على المسار'); addPair('At Risk', 'في خطر');
addPair('On track', 'على المسار'); addPair('Action needed', 'إجراء مطلوب');

// ── Common seed / demo data values ──────────────────────────────────────────
// Subjects
addPair('Mathematics', 'الرياضيات'); addPair('Maths', 'الرياضيات'); addPair('Science', 'العلوم');
addPair('English', 'الإنجليزية'); addPair('Arabic', 'العربية'); addPair('Physics', 'الفيزياء');
addPair('Chemistry', 'الكيمياء'); addPair('Biology', 'الأحياء'); addPair('History', 'التاريخ');
addPair('Geography', 'الجغرافيا'); addPair('Computer Science', 'علوم الحاسوب');
addPair('Islamic Studies', 'التربية الإسلامية'); addPair('Physical Education', 'التربية البدنية');
addPair('Art', 'الفنون'); addPair('Music', 'الموسيقى'); addPair('Social Studies', 'الدراسات الاجتماعية');
// Departments
addPair('Human Resources', 'الموارد البشرية'); addPair('Administration', 'الإدارة');
addPair('Operations', 'العمليات'); addPair('Academics', 'الشؤون الأكاديمية');
// Nationalities
addPair('Omani', 'عُماني'); addPair('Indian', 'هندي'); addPair('Qatari', 'قطري');
addPair('Egyptian', 'مصري'); addPair('Jordanian', 'أردني'); addPair('Pakistani', 'باكستاني');
addPair('British', 'بريطاني'); addPair('American', 'أمريكي'); addPair('Filipino', 'فلبيني');
addPair('Bangladeshi', 'بنغلاديشي'); addPair('Syrian', 'سوري'); addPair('Lebanese', 'لبناني');
addPair('Sudanese', 'سوداني'); addPair('Yemeni', 'يمني'); addPair('Saudi', 'سعودي');
addPair('Kuwaiti', 'كويتي'); addPair('Bahraini', 'بحريني'); addPair('Emirati', 'إماراتي');
// Religions
addPair('Islam', 'الإسلام'); addPair('Muslim', 'مسلم'); addPair('Christianity', 'المسيحية');
addPair('Christian', 'مسيحي'); addPair('Hindu', 'هندوسي'); addPair('Hinduism', 'الهندوسية');
// Relationships
addPair('Brother', 'أخ'); addPair('Sister', 'أخت'); addPair('Uncle', 'عم'); addPair('Aunt', 'عمة');
addPair('Grandfather', 'جد'); addPair('Grandmother', 'جدة'); addPair('Son', 'ابن'); addPair('Daughter', 'ابنة');
// Marital status
addPair('Single', 'أعزب'); addPair('Married', 'متزوج'); addPair('Divorced', 'مطلّق'); addPair('Widowed', 'أرمل');

// ── Generated UI dictionary ─────────────────────────────────────────────────
// Hardcoded (non-t()) English strings harvested from page/component source and
// translated. Keeps this file lean; see src/i18n/uiDictionary.json.
for (const [e, a] of Object.entries(uiExtras as Record<string, string>)) addPair(e, a);

// ---------- Dynamic-pattern fallbacks ----------
// Composite strings the exact-match dictionary can't cover because they embed a
// number, date, currency code or section letter. Tried only after an exact
// lookup miss. Each fn returns the Arabic string, or null to decline.
const MONTHS_AR: Record<string, string> = {
  january: 'يناير', february: 'فبراير', march: 'مارس', april: 'أبريل',
  may: 'مايو', june: 'يونيو', july: 'يوليو', august: 'أغسطس',
  september: 'سبتمبر', october: 'أكتوبر', november: 'نوفمبر', december: 'ديسمبر',
  jan: 'يناير', feb: 'فبراير', mar: 'مارس', apr: 'أبريل', jun: 'يونيو',
  jul: 'يوليو', aug: 'أغسطس', sep: 'سبتمبر', sept: 'سبتمبر', oct: 'أكتوبر',
  nov: 'نوفمبر', dec: 'ديسمبر',
};
const SECTION_AR: Record<string, string> = {
  A: 'أ', B: 'ب', C: 'ج', D: 'د', E: 'هـ', F: 'و', G: 'ز', H: 'ح',
};

const PATTERNS: { re: RegExp; fn: (m: RegExpMatchArray) => string | null }[] = [
  // Relative time — "5 hours ago", "5h ago", "3 days ago", "2d ago", …
  { re: /^(\d+)\s*(?:minutes?|mins?|m)\s+ago$/i, fn: (m) => `منذ ${m[1]} دقيقة` },
  { re: /^(\d+)\s*(?:hours?|hrs?|h)\s+ago$/i,    fn: (m) => `منذ ${m[1]} ساعة` },
  { re: /^(\d+)\s*(?:days?|d)\s+ago$/i,          fn: (m) => `منذ ${m[1]} يوم` },
  { re: /^(\d+)\s*(?:weeks?|w)\s+ago$/i,         fn: (m) => `منذ ${m[1]} أسبوع` },
  { re: /^(\d+)\s*(?:months?|mos?)\s+ago$/i,     fn: (m) => `منذ ${m[1]} شهر` },
  { re: /^(\d+)\s*(?:years?|yrs?|y)\s+ago$/i,    fn: (m) => `منذ ${m[1]} سنة` },
  // Dates — "17 July 2026" and "July 17, 2026"
  { re: /^(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})$/, fn: (m) => { const mo = MONTHS_AR[m[2].toLowerCase()]; return mo ? `${m[1]} ${mo} ${m[3]}` : null; } },
  { re: /^([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})$/, fn: (m) => { const mo = MONTHS_AR[m[1].toLowerCase()]; return mo ? `${m[2]} ${mo} ${m[3]}` : null; } },
  // "as of 2026-07-04"
  { re: /^as of (.+)$/i, fn: (m) => `حتى ${m[1]}` },
  // "Fee Collection (QAR)" — keep the currency code
  { re: /^Fee Collection \((.+)\)$/i, fn: (m) => `تحصيل الرسوم (${m[1]})` },
  // Class names — "Grade 1 - C", "Pre-KG - B", "UKG - A"
  { re: /^(Grade \d+|Pre-KG|LKG|UKG|KG) - ([A-H])$/i, fn: (m) => {
      const grade = dict.get(m[1].toLowerCase()) ?? m[1];
      const sec = SECTION_AR[m[2].toUpperCase()] ?? m[2];
      return `${grade} - ${sec}`;
  } },
  // Activity-feed entity suffix — "— AssistantMessage", "— Appraisal"
  { re: /^—\s*(.+)$/, fn: (m) => { const t = dict.get(m[1].trim().toLowerCase()); return t ? `— ${t}` : null; } },
  // Daily operations brief toast
  { re: /^Student attendance: (\d+)% · Staff attendance: (\d+)% \((\d+)\/(\d+)\) · Pending leave requests: (\d+)$/,
    fn: (m) => `حضور الطلاب: ${m[1]}% · حضور الموظفين: ${m[2]}% (${m[3]}/${m[4]}) · طلبات الإجازة المعلقة: ${m[5]}` },
  // "Grade 3 · Section B" (class header composite)
  { re: /^(Grade \d+|Pre-KG|LKG|UKG|KG)\s*·\s*Section\s+([A-H])$/i, fn: (m) => {
      const grade = dict.get(m[1].toLowerCase()) ?? m[1];
      const sec = SECTION_AR[m[2].toUpperCase()] ?? m[2];
      return `${grade} · الشعبة ${sec}`;
  } },
  // Short date range — "03 Jul – 05 Jul 2026"
  { re: /^(\d{1,2})\s+([A-Za-z]{3,4})\s*[–-]\s*(\d{1,2})\s+([A-Za-z]{3,4})\s+(\d{4})$/,
    fn: (m) => {
      const mo1 = MONTHS_AR[m[2].toLowerCase()], mo2 = MONTHS_AR[m[4].toLowerCase()];
      return (mo1 && mo2) ? `${m[1]} ${mo1} – ${m[3]} ${mo2} ${m[5]}` : null;
    } },
  // "Max 100 · Pass 33"
  { re: /^Max (\d+)\s*·\s*Pass (\d+)$/i, fn: (m) => `الدرجة العظمى ${m[1]} · النجاح ${m[2]}` },
  // Fragments left over when the dynamic value (letter/number) is a separate
  // sibling DOM node/expression — the static text node is just "· Section "
  // or "· Pass " with nothing else.
  { re: /^·\s*Section\s*$/i, fn: () => '· الشعبة' },
  { re: /^·\s*Pass\s*$/i, fn: () => '· النجاح' },
];

function matchPattern(trimmed: string): string | null {
  for (const { re, fn } of PATTERNS) {
    const pm = trimmed.match(re);
    if (pm) { const r = fn(pm); if (r) return r; }
  }
  return null;
}

// ---------- Translation helpers ----------
function lookup(text: string): string | null {
  const trimmed = text.trim();
  if (!trimmed || /^[\d\s.,:%/+-]+$/.test(trimmed)) return null; // numbers/punctuation only
  const lower = trimmed.toLowerCase();
  const direct = dict.get(lower);
  if (direct) return direct;
  // Strip trailing punctuation (colon, ellipsis, asterisk, period) and retry
  const m = trimmed.match(/^(.*?)(\.{3}|[:…*.!?])\s*$/);
  if (m) {
    const base = dict.get(m[1].trim().toLowerCase());
    if (base) return base + m[2];
  }
  // Dynamic composite patterns (relative time, dates, class names, …)
  return matchPattern(trimmed);
}

function translateTextNode(node: Text) {
  const original = node.nodeValue;
  if (!original) return;
  const lead = original.match(/^\s*/)?.[0] ?? '';
  const trail = original.match(/\s*$/)?.[0] ?? '';
  const translated = lookup(original);
  if (translated) {
    // Preserve leading/trailing whitespace
    node.nodeValue = lead + translated + trail;
    return;
  }
  // No dictionary match — if the text is a person name (student/staff), render
  // it in Arabic script. isNameCandidate() is strict so UI text is untouched.
  const core = original.trim();
  if (isNameCandidate(core)) {
    node.nodeValue = lead + transliterateName(core) + trail;
  }
}

const ATTRS = ['placeholder', 'title', 'aria-label', 'alt'];

function translateElementAttrs(el: Element) {
  for (const attr of ATTRS) {
    const val = el.getAttribute(attr);
    if (val) {
      const translated = lookup(val);
      if (translated) el.setAttribute(attr, translated);
    }
  }
}

const SKIP_TAGS = new Set(['SCRIPT', 'STYLE', 'NOSCRIPT', 'TEXTAREA', 'CODE', 'PRE']);

function walk(root: Node) {
  if (root.nodeType === Node.TEXT_NODE) {
    translateTextNode(root as Text);
    return;
  }
  if (root.nodeType !== Node.ELEMENT_NODE) return;
  const el = root as Element;
  if (SKIP_TAGS.has(el.tagName)) return;
  if (el.getAttribute?.('data-no-translate') !== null && el.getAttribute?.('data-no-translate') !== undefined) return;
  translateElementAttrs(el);
  for (const child of Array.from(el.childNodes)) walk(child);
}

// ---------- Observer lifecycle ----------
let observer: MutationObserver | null = null;
let scheduled = false;
let pendingRoots: Set<Node> = new Set();

function flush() {
  scheduled = false;
  const roots = Array.from(pendingRoots);
  pendingRoots = new Set();
  for (const r of roots) {
    if (r.isConnected) walk(r);
  }
}

export function startAutoTranslate() {
  if (observer) return;
  // Initial full-page pass
  walk(document.body);
  observer = new MutationObserver((mutations) => {
    for (const mut of mutations) {
      if (mut.type === 'characterData' && mut.target) pendingRoots.add(mut.target);
      for (const node of Array.from(mut.addedNodes)) pendingRoots.add(node);
    }
    if (!scheduled && pendingRoots.size > 0) {
      scheduled = true;
      requestAnimationFrame(flush);
    }
  });
  observer.observe(document.body, { childList: true, subtree: true, characterData: true });
}

export function stopAutoTranslate() {
  if (observer) {
    observer.disconnect();
    observer = null;
  }
  pendingRoots = new Set();
}
