import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../core/app_settings.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

// Student Settings — mirrors the parent Settings surface in the student visual
// system (Diwan purple), minus the parent-only child switcher. Every option is
// real: profile edits and notification toggles write to the student's `users`
// row; Change Password hits POST /api/session/change-password; Theme/Language
// drive the app-wide themeModeProvider/localeProvider. No fake success anywhere.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(user),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  _buildSection('Account', Icons.person_outline_rounded, [
                    _settingsTile(Icons.person_outline_rounded, 'My Profile',
                        'Edit your name and phone number',
                        onTap: () => _showEditProfile(user)),
                    _divider(),
                    _settingsTile(Icons.lock_outline_rounded, 'Change Password',
                        'Update your account password',
                        onTap: _showChangePassword),
                    _divider(),
                    _settingsTile(Icons.notifications_outlined,
                        'Notification Preferences', 'Email & SMS alerts',
                        onTap: () => _showNotificationPrefs(user)),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Preferences', Icons.tune_rounded, [
                    _settingsTile(Icons.language_rounded, 'Language',
                        _languageLabel(locale),
                        onTap: _showLanguagePicker),
                    _divider(),
                    _settingsTile(Icons.palette_outlined, 'Theme',
                        _themeLabel(themeMode),
                        onTap: _showThemePicker),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Support', Icons.help_outline_rounded, [
                    _settingsTile(Icons.help_center_rounded, 'Help & FAQ',
                        'Answers to common questions', onTap: _showHelp),
                    _divider(),
                    _settingsTile(Icons.shield_outlined, 'Privacy Policy',
                        'How we handle your data', onTap: _showPrivacyPolicy),
                    _divider(),
                    _settingsTile(Icons.info_outline_rounded, 'About',
                        'Version 1.0.0',
                        onTap: () => showAboutDialog(
                              context: context,
                              applicationName: 'Student Diwan',
                              applicationVersion: '1.0.0',
                              applicationLegalese: '© 2026 Student Diwan',
                              children: const [
                                SizedBox(height: 12),
                                Text(
                                    'Your school in your pocket — timetable, homework, grades, attendance, fees and messages, all in one place.'),
                              ],
                            )),
                  ]),
                  const SizedBox(height: 20),
                  _buildLogout(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gradient header ────────────────────────────────────────────────────────
  Widget _buildHeader(UserProfile? user) {
    final name = user?.displayName.isNotEmpty == true ? user!.displayName : 'Student';
    final email = user?.email ?? '';
    final role = (user?.rawRole.isNotEmpty == true ? user!.rawRole : 'student').toUpperCase();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      ),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          bottom: 28,
          left: 20,
          right: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
              ),
              const Text('Settings',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: Text(user?.initials ?? 'S',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(name,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(email,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20)),
            child: Text(role,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }

  // ── Section + tile builders ────────────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.4)),
            ]),
          ),
          Material(
            type: MaterialType.transparency,
            child: Column(children: children),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.only(left: 64, right: 16),
        child: Divider(height: 1, color: Color(0xFFF0F0F6)),
      );

  Widget _settingsTile(IconData icon, String title, String subtitle,
      {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: AppColors.primaryExtraLight,
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 19),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.text3))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ── My Profile: edit real name + phone, persisted to the users row ─────────
  void _showEditProfile(UserProfile? user) {
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    var saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Icon(Icons.person_outline_rounded, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Edit Profile',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text1)),
                ]),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            setSheet(() => saving = true);
                            try {
                              await ref.read(authProvider.notifier).updateProfile(
                                    displayName: nameCtrl.text,
                                    phone: phoneCtrl.text,
                                  );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              _toast('Profile updated');
                            } catch (_) {
                              setSheet(() => saving = false);
                              if (!ctx.mounted) return;
                              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                  content: Text('Could not save. Please try again.'),
                                  behavior: SnackBarBehavior.floating));
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  // ── Change Password: real authenticated change (3-field) ───────────────────
  // Current + New + Confirm, verified and written server-side via
  // /api/session/change-password. No fake success — the button reflects the
  // real API result and surfaces the server's message on failure.
  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var saving = false;
    var obscureCurrent = true, obscureNew = true, obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.text1)),
          content: Form(
            key: formKey,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureCurrent
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20),
                        onPressed: () =>
                            setDlg(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Enter your current password'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20),
                        onPressed: () => setDlg(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20),
                        onPressed: () =>
                            setDlg(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) =>
                        (v != newCtrl.text) ? 'Passwords do not match' : null,
                  ),
                ]),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.text3))),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlg(() => saving = true);
                      try {
                        await ref.read(authProvider.notifier).changePassword(
                              currentPassword: currentCtrl.text,
                              newPassword: newCtrl.text,
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _toast('Password updated successfully');
                      } on DioException catch (e) {
                        setDlg(() => saving = false);
                        final msg = e.response?.data is Map &&
                                (e.response!.data['error'] != null)
                            ? e.response!.data['error'].toString()
                            : 'Could not change password. Please try again.';
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text(msg),
                            behavior: SnackBarBehavior.floating));
                      } catch (_) {
                        setDlg(() => saving = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text(
                                'Could not change password. Please try again.'),
                            behavior: SnackBarBehavior.floating));
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Update',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification Preferences: real email/sms toggles persisted to users ────
  void _showNotificationPrefs(UserProfile? user) {
    var email = user?.emailNotif ?? true;
    var sms = user?.smsNotif ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.notifications_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Notification Preferences',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: email,
                    activeColor: AppColors.primary,
                    title: const Text('Email alerts',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text1)),
                    subtitle: const Text(
                        'Attendance, grades, fees & announcements',
                        style: TextStyle(fontSize: 12, color: AppColors.text3)),
                    onChanged: (v) async {
                      setSheet(() => email = v);
                      await _saveNotif(emailNotif: v);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: sms,
                    activeColor: AppColors.primary,
                    title: const Text('SMS alerts',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text1)),
                    subtitle: const Text('Urgent notices to your phone',
                        style: TextStyle(fontSize: 12, color: AppColors.text3)),
                    onChanged: (v) async {
                      setSheet(() => sms = v);
                      await _saveNotif(smsNotif: v);
                    },
                  ),
                  const SizedBox(height: 8),
                ]),
          ),
        ),
      ),
    );
  }

  Future<void> _saveNotif({bool? emailNotif, bool? smsNotif}) async {
    try {
      await ref
          .read(authProvider.notifier)
          .updateNotifPrefs(emailNotif: emailNotif, smsNotif: smsNotif);
    } catch (_) {
      _toast('Could not save preference. Please try again.');
    }
  }

  // ── Theme picker (shared themeModeProvider — live app-wide) ────────────────
  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemePicker() {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose theme',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        ),
        _themeOption(ctx, ThemeMode.light, current, Icons.light_mode_rounded,
            'Light', 'Bright background'),
        _themeOption(ctx, ThemeMode.dark, current, Icons.dark_mode_rounded,
            'Dark', 'Easy on the eyes'),
        _themeOption(ctx, ThemeMode.system, current,
            Icons.settings_suggest_rounded, 'System', 'Match device setting'),
        const SizedBox(height: 12),
      ])),
    );
  }

  Widget _themeOption(BuildContext ctx, ThemeMode mode, ThemeMode current,
      IconData icon, String title, String subtitle) {
    final selected = mode == current;
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : AppColors.text3),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.text3)),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(themeModeProvider.notifier).set(mode);
        Navigator.pop(ctx);
      },
    );
  }

  // ── Language picker (shared localeProvider — English / Arabic RTL) ─────────
  String _languageLabel(Locale locale) =>
      locale.languageCode == 'ar' ? 'العربية' : 'English';

  void _showLanguagePicker() {
    final current = ref.read(localeProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose language',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        ),
        _languageOption(ctx, kEnglishLocale, current, 'English', 'English'),
        _languageOption(ctx, kArabicLocale, current, 'العربية', 'Arabic'),
        const SizedBox(height: 12),
      ])),
    );
  }

  Widget _languageOption(BuildContext ctx, Locale locale, Locale current,
      String native, String english) {
    final selected = locale.languageCode == current.languageCode;
    return ListTile(
      leading: Icon(Icons.translate_rounded,
          color: selected ? AppColors.primary : AppColors.text3),
      title: Text(native,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(english,
          style: const TextStyle(fontSize: 12, color: AppColors.text3)),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        ref.read(localeProvider.notifier).set(locale);
        Navigator.pop(ctx);
      },
    );
  }

  // ── Help & FAQ (static informational content — no fake ticket system) ──────
  static const List<(String, String)> _faqs = [
    ('Where do I see my timetable and homework?',
        'Open Timetable for your weekly schedule, and Homework for tasks set by your teachers with their due dates.'),
    ('How are my grades calculated?',
        'Open Gradebook to see your weighted subject grades — assignments, assessments and exams combined exactly as your school configured them. Only marked work counts.'),
    ('Where can I see exam results?',
        'Open Exams → Results tab for your published marks and overall average. Report cards are under Report Cards.'),
    ('How do I check attendance?',
        'Open Attendance to see your day-by-day record and your present/absent/late totals for the term.'),
    ('I\'m not getting notifications.',
        'Check Settings → Notification Preferences and make sure Email or SMS alerts are on, and that notifications are allowed for the app in your device settings.'),
    ('How do I change my password?',
        'Settings → Change Password. Enter your current password and your new one — it\'s updated securely on the spot.'),
  ];

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(children: const [
              Icon(Icons.help_outline_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Help & FAQ',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text1)),
            ]),
            const SizedBox(height: 16),
            ..._faqs.map((f) => _faqTile(f.$1, f.$2)),
          ],
        ),
      ),
    );
  }

  Widget _faqTile(String q, String a) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryExtraLight),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.text3,
            title: Text(q,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text1)),
            children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(a,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.text2, height: 1.45)))
            ],
          ),
        ),
      );

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: const [
          Icon(Icons.shield_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _policyPara('Data we handle',
                  'Student Diwan processes only the information needed for your studies: your name and contact details, and your timetable, attendance, grades, fees and school communications.'),
              _policyPara('How it is used',
                  'Your data powers the timetable, gradebook, attendance, fees and messaging features. We never sell it or share it with advertisers.'),
              _policyPara('Storage & security',
                  'Records are stored on your school\'s secured servers and sent over encrypted (HTTPS) connections. Access is limited to authorised school staff.'),
              _policyPara('Your rights',
                  'You can request a copy of your data or corrections through your school administrator at any time.'),
              _policyPara('Contact',
                  'Questions about privacy? Email support@studentdiwan.com and we\'ll respond within two business days.'),
            ],
          )),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _policyPara(String heading, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(heading,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.text1)),
          const SizedBox(height: 4),
          Text(body,
              style: const TextStyle(
                  fontSize: 13, height: 1.45, color: AppColors.text2)),
        ]),
      );

  Widget _buildLogout() {
    return InkWell(
      onTap: _confirmLogout,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.redLight.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.redLight),
        ),
        child: const Row(children: [
          Icon(Icons.logout_rounded, color: AppColors.red),
          SizedBox(width: 16),
          Text('Sign Out',
              style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
          Spacer(),
          Icon(Icons.chevron_right_rounded, color: AppColors.red),
        ]),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text1)),
        content: const Text('Are you sure you want to sign out?',
            style: TextStyle(color: AppColors.text2)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.text3))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              // The router watches authProvider and redirects to /login once the
              // session clears — no manual navigation needed.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
