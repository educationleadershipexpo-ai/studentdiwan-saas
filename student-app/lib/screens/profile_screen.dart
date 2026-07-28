import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_settings.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../core/format.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _zoomController;
  late Animation<double> _avatarZoom;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _avatarZoom = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.elasticOut),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _zoomController, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );
    _zoomController.forward();
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profileAsync = ref.watch(studentProfileProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildProfile(user?.displayName ?? '', user?.email ?? '', null),
        data: (profile) => _buildProfile(profile.displayName, profile.email, profile),
      ),
    );
  }

  Widget _buildProfile(String name, String email, dynamic profile) {
    final user = ref.watch(authProvider).user;
    final initials = user?.initials ?? name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Profile Banner
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.headerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 30,
              left: 20,
              right: 20,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.home_rounded, color: Colors.white),
                      onPressed: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                    ),
                    Text(context.tr.studentProfile, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 16),

                // Zooming Avatar
                ScaleTransition(
                  scale: _avatarZoom,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryExtraLight,
                      child: Text(initials, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 4),
                if (profile != null) ...[
                  if (gradeLabel(profile.grade, profile.section).isNotEmpty)
                    Text(
                      gradeLabel(profile.grade, profile.section),
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  if (profile.rollNumber.trim().isNotEmpty)
                    Text(
                      profile.rollNumber.trim(),
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                ],
                const SizedBox(height: 2),
                Text(email, style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Real student data cards
          if (profile != null && profile.studentData != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(context.tr.personalInfo),
                  _InfoCard([
                    _InfoRow(Icons.person_rounded, context.tr.fullName, profile.displayName),
                    _InfoRow(Icons.cake_rounded, context.tr.dateOfBirth, profile.dateOfBirth),
                    _InfoRow(Icons.wc_rounded, context.tr.gender, profile.gender),
                    _InfoRow(Icons.flag_rounded, context.tr.nationality, profile.nationality),
                    _InfoRow(Icons.bloodtype_rounded, context.tr.bloodGroup, profile.bloodGroup),
                  ]),
                  const SizedBox(height: 16),
                  _SectionTitle(context.tr.academicDetails),
                  _InfoCard([
                    _InfoRow(Icons.school_rounded, context.tr.grade, gradeLabel(profile.grade, profile.section)),
                    _InfoRow(Icons.tag_rounded, context.tr.rollNumber, profile.rollNumber),
                    _InfoRow(Icons.email_rounded, context.tr.schoolEmail, profile.email),
                  ]),
                  const SizedBox(height: 16),
                  _SectionTitle(context.tr.contactFamily),
                  _InfoCard([
                    _InfoRow(Icons.location_on_rounded, context.tr.address, profile.address),
                    _InfoRow(Icons.phone_rounded, context.tr.phone, profile.phone),
                    _InfoRow(Icons.man_rounded, context.tr.father, profile.fatherName),
                    _InfoRow(Icons.woman_rounded, context.tr.mother, profile.motherName),
                  ]),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],

          // Settings / Actions
          AnimatedBuilder(
            animation: _cardFade,
            builder: (context, child) => Opacity(opacity: _cardFade.value, child: child),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Account
                  _buildSettingsSection(context.tr.account, Icons.person_outline_rounded, [
                    _settingsTile(Icons.person_outline_rounded, context.tr.editProfile,
                        context.tr.updateNamePhone,
                        onTap: () => _showEditProfile(user)),
                    _divider(),
                    _settingsTile(Icons.lock_outline_rounded, context.tr.changePassword,
                        context.tr.updatePassword,
                        onTap: _showChangePassword),
                    _divider(),
                    _settingsTile(Icons.notifications_outlined,
                        context.tr.notificationPrefs, context.tr.emailSmAlerts,
                        onTap: () => _showNotificationPrefs(user)),
                  ]),
                  const SizedBox(height: 12),

                  // Support
                  _buildSettingsSection(context.tr.support, Icons.help_outline_rounded, [
                    _settingsTile(Icons.help_center_rounded, context.tr.helpFaq,
                        'Answers to common questions', onTap: _showHelp),
                    _divider(),
                    _settingsTile(Icons.shield_outlined, context.tr.privacyPolicy,
                        'How we handle your data', onTap: _showPrivacyPolicy),
                    _divider(),
                    _settingsTile(Icons.info_outline_rounded, context.tr.about,
                        context.tr.version,
                        onTap: () => showAboutDialog(
                              context: context,
                              applicationName: 'Student Diwan',
                              applicationVersion: '1.0.0',
                              applicationLegalese: '© 2026 Student Diwan',
                              children: const [
                                SizedBox(height: 12),
                                Text('Your school in your pocket — timetable, homework, grades, attendance, fees and messages, all in one place.'),
                              ],
                            )),
                  ]),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _confirmLogout,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.redLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.redLight),
                      ),
                      child: Row(children: [
                        const Icon(Icons.logout_rounded, color: AppColors.red),
                        const SizedBox(width: 16),
                        Text(context.tr.logoutSecurely, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.red),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _SectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text1)),
  );

  Widget _InfoCard(List<Widget> rows) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(children: rows),
  );

  Widget _InfoRow(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.text3)),
        Text(value.isEmpty ? '—' : value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text1)),
      ])),
    ]),
  );

  Widget _buildSettingsSection(String title, IconData icon, List<Widget> children) {
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
            left: 20, right: 20, top: 20,
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
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text1)),
                ]),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
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
                                    displayName: nameCtrl.text, phone: phoneCtrl.text);
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

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
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text1)),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscureCurrent ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setDlg(() => obscureCurrent = !obscureCurrent),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your current password' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setDlg(() => obscureNew = !obscureNew),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 20),
                    onPressed: () => setDlg(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
                validator: (v) => (v != newCtrl.text) ? 'Passwords do not match' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppColors.text3))),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDlg(() => saving = true);
                      try {
                        await ref.read(authProvider.notifier).changePassword(
                              currentPassword: currentCtrl.text,
                              newPassword: newCtrl.text);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _toast('Password updated successfully');
                      } on DioException catch (e) {
                        setDlg(() => saving = false);
                        final msg = e.response?.data is Map && e.response!.data['error'] != null
                            ? e.response!.data['error'].toString()
                            : 'Could not change password. Please try again.';
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
                      } catch (_) {
                        setDlg(() => saving = false);
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Could not change password. Please try again.'),
                            behavior: SnackBarBehavior.floating));
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: const [
                Icon(Icons.notifications_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Notification Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: email, activeColor: AppColors.primary,
                title: const Text('Email alerts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                subtitle: const Text('Attendance, grades, fees & announcements',
                    style: TextStyle(fontSize: 12, color: AppColors.text3)),
                onChanged: (v) async { setSheet(() => email = v); await _saveNotif(emailNotif: v); },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: sms, activeColor: AppColors.primary,
                title: const Text('SMS alerts',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                subtitle: const Text('Urgent notices to your phone',
                    style: TextStyle(fontSize: 12, color: AppColors.text3)),
                onChanged: (v) async { setSheet(() => sms = v); await _saveNotif(smsNotif: v); },
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
      await ref.read(authProvider.notifier).updateNotifPrefs(emailNotif: emailNotif, smsNotif: smsNotif);
    } catch (_) { _toast('Could not save preference. Please try again.'); }
  }

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
        'Check Profile → Notification Preferences and make sure Email or SMS alerts are on.'),
    ('How do I change my password?',
        'Profile → Change Password. Enter your current password and your new one — it\'s updated securely on the spot.'),
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
              Text('Help & FAQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.text1)),
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
            title: Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text1)),
            children: [
              Align(alignment: Alignment.centerLeft,
                  child: Text(a, style: const TextStyle(fontSize: 13, color: AppColors.text2, height: 1.45)))
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
          Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _policyPara('Data we handle', 'Student Diwan processes only the information needed for your studies: your name, contact details, timetable, attendance, grades, fees and school communications.'),
              _policyPara('How it is used', 'Your data powers the timetable, gradebook, attendance, fees and messaging features. We never sell it or share it with advertisers.'),
              _policyPara('Storage & security', 'Records are stored on your school\'s secured servers and sent over encrypted (HTTPS) connections. Access is limited to authorised school staff.'),
              _policyPara('Your rights', 'You can request a copy of your data or corrections through your school administrator at any time.'),
              _policyPara('Contact', 'Questions about privacy? Email support@studentdiwan.com and we\'ll respond within two business days.'),
            ],
          )),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _policyPara(String heading, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(heading, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text1)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.text2)),
        ]),
      );

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
              child: const Text('Cancel', style: TextStyle(color: AppColors.text3))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
