import 'package:flutter/widgets.dart';

// ── Translation accessor ──────────────────────────────────────────────────────
// Usage:  context.tr.home  /  context.tr.signIn  /  context.tr.attendance
// Automatically rebuilds when the user switches locale (reads from the
// Localizations InheritedWidget, which is driven by localeProvider).
extension TrX on BuildContext {
  Tr get tr => Tr(Localizations.localeOf(this));
}

class Tr {
  final Locale _l;
  const Tr(this._l);
  bool get _ar => _l.languageCode == 'ar';

  // ── Common actions ────────────────────────────────────────────────────────
  String get signIn        => _ar ? 'تسجيل الدخول'   : 'Sign In';
  String get signOut       => _ar ? 'تسجيل الخروج'   : 'Sign Out';
  String get logoutSecurely => _ar ? 'تسجيل الخروج بأمان' : 'Logout securely';
  String get confirmSignOut => _ar ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to sign out?';
  String get cancel        => _ar ? 'إلغاء'           : 'Cancel';
  String get save          => _ar ? 'حفظ'             : 'Save';
  String get saveChanges   => _ar ? 'حفظ التغييرات'   : 'Save Changes';
  String get close         => _ar ? 'إغلاق'           : 'Close';
  String get update        => _ar ? 'تحديث'           : 'Update';
  String get add           => _ar ? 'إضافة'           : 'Add';
  String get edit          => _ar ? 'تعديل'           : 'Edit';
  String get delete        => _ar ? 'حذف'             : 'Delete';
  String get retry         => _ar ? 'إعادة المحاولة'  : 'Retry';
  String get back          => _ar ? 'رجوع'            : 'Back';
  String get confirm       => _ar ? 'تأكيد'           : 'Confirm';
  String get submit        => _ar ? 'إرسال'           : 'Submit';
  String get search        => _ar ? 'بحث'             : 'Search';
  String get filter        => _ar ? 'تصفية'           : 'Filter';
  String get viewAll       => _ar ? 'عرض الكل'        : 'View All';
  String get noData        => _ar ? 'لا توجد بيانات'  : 'No data';
  String get loading       => _ar ? 'جارٍ التحميل…'  : 'Loading…';
  String get seeAll        => _ar ? 'عرض الجميع'      : 'See all';

  // ── Status labels ─────────────────────────────────────────────────────────
  String get present       => _ar ? 'حاضر'    : 'Present';
  String get absent        => _ar ? 'غائب'    : 'Absent';
  String get late          => _ar ? 'متأخر'   : 'Late';
  String get leave         => _ar ? 'إجازة'   : 'Leave';
  String get paid          => _ar ? 'مدفوع'   : 'Paid';
  String get pending       => _ar ? 'قيد الانتظار' : 'Pending';
  String get overdue       => _ar ? 'متأخر'   : 'Overdue';
  String get submitted     => _ar ? 'مُسلَّم' : 'Submitted';
  String get notSubmitted  => _ar ? 'لم يُسلَّم' : 'Not Submitted';
  String get completed     => _ar ? 'مكتمل'   : 'Completed';
  String get active        => _ar ? 'نشط'     : 'Active';

  // ── Student nav labels ────────────────────────────────────────────────────
  String get home          => _ar ? 'الرئيسية'    : 'Home';
  String get learn         => _ar ? 'التعلم'      : 'Learn';
  String get calendar      => _ar ? 'التقويم'     : 'Calendar';
  String get profile       => _ar ? 'الملف الشخصي' : 'Profile';

  // ── Student screen titles ─────────────────────────────────────────────────
  String get dashboard         => _ar ? 'لوحة التحكم'     : 'Dashboard';
  String get timetable         => _ar ? 'الجدول الدراسي'  : 'Timetable';
  String get homework          => _ar ? 'الواجبات'        : 'Homework';
  String get assignments       => _ar ? 'المهام'          : 'Assignments';
  String get gradebook         => _ar ? 'سجل الدرجات'     : 'Gradebook';
  String get attendance        => _ar ? 'الحضور والغياب'  : 'Attendance';
  String get fees              => _ar ? 'الرسوم'          : 'Fees';
  String get exams             => _ar ? 'الاختبارات'      : 'Exams';
  String get reportCards       => _ar ? 'كشوف الدرجات'    : 'Report Cards';
  String get notifications     => _ar ? 'الإشعارات'       : 'Notifications';
  String get messages          => _ar ? 'الرسائل'         : 'Messages';
  String get cafeteria         => _ar ? 'المقصف'          : 'Cafeteria';
  String get library           => _ar ? 'المكتبة'         : 'Library';
  String get transport         => _ar ? 'المواصلات'       : 'Transport';
  String get health            => _ar ? 'الصحة'           : 'Health';
  String get achievements      => _ar ? 'الإنجازات'       : 'Achievements';
  String get materials         => _ar ? 'المواد الدراسية' : 'Study Materials';
  String get flashcards        => _ar ? 'البطاقات التعليمية' : 'Flashcards';
  String get certificates      => _ar ? 'الشهادات'        : 'Certificates';
  String get assessments       => _ar ? 'التقييمات'       : 'Assessments';

  // ── Student profile ───────────────────────────────────────────────────────
  String get studentProfile    => _ar ? 'ملف الطالب'       : 'Student Profile';
  String get personalInfo      => _ar ? 'المعلومات الشخصية' : 'Personal Information';
  String get academicDetails   => _ar ? 'التفاصيل الأكاديمية' : 'Academic Details';
  String get contactFamily     => _ar ? 'جهة الاتصال والعائلة' : 'Contact & Family';
  String get fullName          => _ar ? 'الاسم الكامل'    : 'Full Name';
  String get dateOfBirth       => _ar ? 'تاريخ الميلاد'   : 'Date of Birth';
  String get gender            => _ar ? 'الجنس'           : 'Gender';
  String get nationality       => _ar ? 'الجنسية'         : 'Nationality';
  String get bloodGroup        => _ar ? 'فصيلة الدم'      : 'Blood Group';
  String get grade             => _ar ? 'الصف'            : 'Grade';
  String get rollNumber        => _ar ? 'رقم القيد'       : 'Roll Number';
  String get schoolEmail       => _ar ? 'البريد المدرسي'  : 'School Email';
  String get address           => _ar ? 'العنوان'         : 'Address';
  String get phone             => _ar ? 'الهاتف'          : 'Phone';
  String get father            => _ar ? 'الأب'            : 'Father';
  String get mother            => _ar ? 'الأم'            : 'Mother';

  // ── Settings ──────────────────────────────────────────────────────────────
  String get settings              => _ar ? 'الإعدادات'           : 'Settings';
  String get account               => _ar ? 'الحساب'              : 'Account';
  String get preferences           => _ar ? 'التفضيلات'           : 'Preferences';
  String get support               => _ar ? 'الدعم'               : 'Support';
  String get editProfile           => _ar ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get changePassword        => _ar ? 'تغيير كلمة المرور'  : 'Change Password';
  String get notificationPrefs     => _ar ? 'تفضيلات الإشعارات'  : 'Notification Preferences';
  String get language              => _ar ? 'اللغة'               : 'Language';
  String get theme                 => _ar ? 'المظهر'              : 'Theme';
  String get helpFaq               => _ar ? 'المساعدة والأسئلة الشائعة' : 'Help & FAQ';
  String get privacyPolicy         => _ar ? 'سياسة الخصوصية'     : 'Privacy Policy';
  String get about                 => _ar ? 'حول التطبيق'         : 'About';
  String get updateNamePhone       => _ar ? 'تحديث اسمك ورقم هاتفك' : 'Update your name and phone number';
  String get updatePassword        => _ar ? 'تحديث كلمة مرور حسابك' : 'Update your account password';
  String get emailSmAlerts         => _ar ? 'تنبيهات البريد والرسائل' : 'Email & SMS alerts';
  String get themeLight            => _ar ? 'فاتح'     : 'Light';
  String get themeDark             => _ar ? 'داكن'     : 'Dark';
  String get themeSystem           => _ar ? 'النظام'   : 'System';
  String get chooseTheme           => _ar ? 'اختر المظهر'  : 'Choose theme';
  String get chooseLanguage        => _ar ? 'اختر اللغة'   : 'Choose language';
  String get brightBackground      => _ar ? 'خلفية مضيئة' : 'Bright background';
  String get easyOnEyes            => _ar ? 'مريح للعين'  : 'Easy on the eyes';
  String get matchDeviceSetting    => _ar ? 'مطابقة إعداد الجهاز' : 'Match device setting';
  String get currentPassword       => _ar ? 'كلمة المرور الحالية' : 'Current Password';
  String get newPassword           => _ar ? 'كلمة المرور الجديدة' : 'New Password';
  String get confirmNewPassword    => _ar ? 'تأكيد كلمة المرور الجديدة' : 'Confirm New Password';
  String get atLeast6Chars         => _ar ? '6 أحرف على الأقل'   : 'At least 6 characters';
  String get passwordsNoMatch      => _ar ? 'كلمتا المرور غير متطابقتين' : 'Passwords do not match';
  String get enterCurrentPassword  => _ar ? 'أدخل كلمة مرورك الحالية' : 'Enter your current password';
  String get passwordUpdated       => _ar ? 'تم تحديث كلمة المرور' : 'Password updated successfully';
  String get profileUpdated        => _ar ? 'تم تحديث الملف الشخصي' : 'Profile updated';
  String get couldNotSave          => _ar ? 'تعذّر الحفظ. حاول مجدداً.' : 'Could not save. Please try again.';
  String get emailAlertsTitle      => _ar ? 'تنبيهات البريد الإلكتروني' : 'Email alerts';
  String get emailAlertsSubtitle   => _ar ? 'الحضور والدرجات والرسوم والإعلانات' : 'Attendance, grades, fees & announcements';
  String get smsAlertsTitle        => _ar ? 'تنبيهات الرسائل القصيرة' : 'SMS alerts';
  String get smsAlertsSubtitle     => _ar ? 'إشعارات عاجلة على هاتفك' : 'Urgent notices to your phone';
  String get version               => _ar ? 'الإصدار 1.0.0' : 'Version 1.0.0';

  // ── Greeting ──────────────────────────────────────────────────────────────
  String get goodMorning    => _ar ? 'صباح الخير'   : 'Good Morning';
  String get goodAfternoon  => _ar ? 'مساء الخير'   : 'Good Afternoon';
  String get goodEvening    => _ar ? 'مساء النور'   : 'Good Evening';
  String greetingFor(int hour) {
    if (hour < 12) return goodMorning;
    if (hour < 17) return goodAfternoon;
    return goodEvening;
  }

  // ── Login screen ──────────────────────────────────────────────────────────
  String get welcomeBack     => _ar ? 'مرحباً بعودتك'         : 'Welcome Back';
  String get selectPortal    => _ar ? 'اختر بوابة الدخول'    : 'Select your portal to continue';
  String get student         => _ar ? 'طالب'                  : 'Student';
  String get parent          => _ar ? 'ولي الأمر'             : 'Parent';
  String get staff           => _ar ? 'موظف'                  : 'Staff';
  String get emailAddress    => _ar ? 'البريد الإلكتروني'     : 'Email Address';
  String get password        => _ar ? 'كلمة المرور'           : 'Password';
  String get emailRequired   => _ar ? 'البريد الإلكتروني مطلوب' : 'Email is required';
  String get invalidEmail    => _ar ? 'بريد إلكتروني غير صالح'  : 'Enter a valid email';
  String get passwordRequired => _ar ? 'كلمة المرور مطلوبة'   : 'Password is required';
  String get loginFailed     => _ar ? 'فشل تسجيل الدخول'      : 'Login failed';
  String get checkCredentials => _ar ? 'تحقق من بيانات الدخول' : 'Check your credentials and try again';

  // ── Dashboard sections ────────────────────────────────────────────────────
  String get todaySchedule   => _ar ? 'جدول اليوم'            : 'Today\'s Schedule';
  String get upcomingHW      => _ar ? 'الواجبات القادمة'      : 'Upcoming Homework';
  String get recentGrades    => _ar ? 'الدرجات الأخيرة'       : 'Recent Grades';
  String get quickActions    => _ar ? 'إجراءات سريعة'         : 'Quick Actions';
  String get myClasses       => _ar ? 'فصولي'                 : 'My Classes';
  String get pendingTasks    => _ar ? 'المهام المعلقة'        : 'Pending Tasks';
  String get announcements   => _ar ? 'الإعلانات'             : 'Announcements';
  String get noClassesToday  => _ar ? 'لا توجد حصص اليوم'    : 'No classes today';
  String get noHomework      => _ar ? 'لا توجد واجبات قادمة' : 'No upcoming homework';
  String get noGrades        => _ar ? 'لا توجد درجات بعد'    : 'No grades yet';
  String get noAnnouncements => _ar ? 'لا توجد إعلانات'      : 'No announcements';

  // ── Parent portal ─────────────────────────────────────────────────────────
  String get parentPortal    => _ar ? 'بوابة ولي الأمر'   : 'Parent Portal';
  String get myChildren      => _ar ? 'أبنائي'             : 'My Children';
  String get children        => _ar ? 'الأبناء'            : 'Children';
  String get more            => _ar ? 'المزيد'             : 'More';
  String get noChildren      => _ar ? 'لا يوجد أبناء مرتبطون' : 'No Children Linked';
  String get noChildrenSub   => _ar ? 'حسابك غير مرتبط بأي طالب. تواصل مع إدارة المدرسة.' : 'Your account is not linked to any students. Contact the school admin.';
  String get selectChild     => _ar ? 'اختر طالباً'        : 'Select Student';
  String get ptm             => _ar ? 'اجتماعات الأهل'    : 'Parent-Teacher Meetings';
  String get documents       => _ar ? 'المستندات'          : 'Documents';
  String get behaviour       => _ar ? 'السلوك'             : 'Behaviour';
  String get studyMaterials  => _ar ? 'مواد الدراسة'       : 'Study Materials';
  String get totalDue        => _ar ? 'المبلغ المستحق'     : 'Total Due';
  String get attendanceRate  => _ar ? 'معدل الحضور'        : 'Attendance Rate';
  String get pendingAssignments => _ar ? 'مهام معلقة'      : 'Pending Assignments';
  String get thisMonth       => _ar ? 'هذا الشهر'          : 'This Month';

  // ── Teacher portal ────────────────────────────────────────────────────────
  String get teacherPortal   => _ar ? 'بوابة المعلم'        : 'Teacher Portal';
  String get classes         => _ar ? 'الفصول'              : 'Classes';
  String get students        => _ar ? 'الطلاب'              : 'Students';
  String get gradebookTitle  => _ar ? 'سجل الدرجات'         : 'Gradebook';
  String get behavior        => _ar ? 'السلوك'              : 'Behavior';
  String get lms             => _ar ? 'نظام إدارة التعلم'   : 'LMS';
  String get results         => _ar ? 'النتائج'             : 'Results';
  String get reports         => _ar ? 'التقارير'            : 'Reports';
  String get leaveRequest    => _ar ? 'طلب إجازة'           : 'Leave Request';
  String get helpCenter      => _ar ? 'مركز المساعدة'       : 'Help Center';
  String get projectReports  => _ar ? 'تقارير المشاريع'     : 'Project Reports';
  String get mySchedule      => _ar ? 'جدولي'               : 'My Schedule';
  String get myStudents      => _ar ? 'طلابي'               : 'My Students';
  String get totalStudents   => _ar ? 'إجمالي الطلاب'       : 'Total Students';
  String get classesToday    => _ar ? 'الحصص اليوم'         : 'Classes Today';
  String get pendingGrading  => _ar ? 'بانتظار التقييم'     : 'Pending Grading';

  // ── Common section labels ─────────────────────────────────────────────────
  String get today           => _ar ? 'اليوم'               : 'Today';
  String get yesterday       => _ar ? 'أمس'                 : 'Yesterday';
  String get thisWeek        => _ar ? 'هذا الأسبوع'         : 'This Week';
  String get dueDate         => _ar ? 'تاريخ الاستحقاق'     : 'Due Date';
  String get subject         => _ar ? 'المادة'              : 'Subject';
  String get teacher         => _ar ? 'المعلم'              : 'Teacher';
  String get total           => _ar ? 'الإجمالي'            : 'Total';
  String get amount          => _ar ? 'المبلغ'              : 'Amount';
  String get score           => _ar ? 'النتيجة'             : 'Score';
  String get average         => _ar ? 'المتوسط'             : 'Average';
  String get section         => _ar ? 'الشعبة'              : 'Section';
  String get term            => _ar ? 'الفصل الدراسي'       : 'Term';
  String get year            => _ar ? 'السنة'               : 'Year';
  String get from            => _ar ? 'من'                  : 'From';
  String get to              => _ar ? 'إلى'                 : 'To';
  String get note            => _ar ? 'ملاحظة'              : 'Note';
  String get description     => _ar ? 'الوصف'               : 'Description';
  String get title           => _ar ? 'العنوان'              : 'Title';
  String get type            => _ar ? 'النوع'               : 'Type';
  String get status          => _ar ? 'الحالة'              : 'Status';
  String get date            => _ar ? 'التاريخ'             : 'Date';
  String get time            => _ar ? 'الوقت'               : 'Time';
  String get day             => _ar ? 'اليوم'               : 'Day';
  String get week            => _ar ? 'الأسبوع'             : 'Week';
  String get month           => _ar ? 'الشهر'               : 'Month';
  String get all             => _ar ? 'الكل'                : 'All';
  String get details         => _ar ? 'التفاصيل'            : 'Details';

  // ── Error / empty states ──────────────────────────────────────────────────
  String get failedToLoad    => _ar ? 'تعذّر تحميل البيانات' : 'Failed to load data';
  String get tryAgain        => _ar ? 'حاول مجدداً'          : 'Try again';
  String get noInternet      => _ar ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection';
  String get somethingWrong  => _ar ? 'حدث خطأ ما'           : 'Something went wrong';
  String get noResults       => _ar ? 'لا توجد نتائج'        : 'No results found';
  String get pullToRefresh   => _ar ? 'اسحب للتحديث'         : 'Pull to refresh';
}
