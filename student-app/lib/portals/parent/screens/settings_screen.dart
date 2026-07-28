import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/biometric_service.dart';
import '../core/constants.dart';
import '../core/fcm_service.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../../../core/app_settings.dart';
// The router watches the SHARED app-wide auth provider (lib/providers). Sign Out
// must clear THAT one to trigger the redirect to /login — clearing only the
// parent-portal provider leaves the router authenticated and does nothing.
import '../../../providers/auth_provider.dart' as app_auth;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled   = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricService.isAvailable();
    final enabled   = await BiometricService.isEnabled();
    if (mounted) setState(() { _biometricAvailable = available; _biometricEnabled = enabled; });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(user),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              child: Column(
                children: [
                  // ── My Children: inline switcher — pick a child right here and
                  // the whole app switches to their records, no extra screen. ──
                  _buildChildSwitcher(),
                  const SizedBox(height: 12),

                  _buildSection('Account', Icons.person_outline_rounded, [
                    _settingsTile(Icons.person_outline_rounded, 'My Profile',
                      'Edit your name and phone number', onTap: () => _showEditProfile(user)),
                    _divider(),
                    _settingsTile(Icons.lock_outline_rounded, 'Change Password',
                      'Send a reset link to your email', onTap: () => _showChangePassword(user)),
                    _divider(),
                    _settingsTile(Icons.notifications_outlined, 'Notification Preferences',
                      'Email & SMS alerts', onTap: () => _showNotificationPrefs(user)),
                  ]),

                  if (_biometricAvailable) ...[
                    const SizedBox(height: 12),
                    _buildSection('Security', Icons.shield_outlined, [
                      _switchTile(Icons.fingerprint_rounded, 'Biometric Login',
                        'Use fingerprint or face to sign in', _biometricEnabled, (v) async {
                          await BiometricService.setEnabled(v);
                          if (!mounted) return;
                          setState(() => _biometricEnabled = v);
                          _toast(v ? 'Biometric login enabled' : 'Biometric login disabled');
                        }),
                    ]),
                  ],

                  const SizedBox(height: 12),
                  _buildSection('Support', Icons.help_outline_rounded, [
                    _settingsTile(Icons.help_center_rounded, 'Help & FAQ',
                      'Answers to common questions', onTap: _showHelp),
                    _divider(),
                    _settingsTile(Icons.shield_outlined, 'Privacy Policy',
                      'How we handle your data', onTap: _showPrivacyPolicy),
                    _divider(),
                    _settingsTile(Icons.info_outline_rounded, 'About', 'Version 1.0.0',
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'Student Diwan — Parent',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2026 Student Diwan',
                        children: const [
                          SizedBox(height: 12),
                          Text('Stay connected with your child\'s school — attendance, grades, fees, messages and more, in one place.'),
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

  // ── Gradient header (matches staff Settings look) ──────────────────────────
  Widget _buildHeader(UserModel? user) {
    final name = user?.displayName.isNotEmpty == true ? user!.displayName : 'Parent';
    final email = user?.email ?? '';
    final role = (user?.role.isNotEmpty == true ? user!.role : 'parent').toUpperCase();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.primaryGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 12, bottom: 28, left: 20, right: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.pop(),
              ),
              const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: 84, height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            child: Text(user?.initials ?? 'P',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(email, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(role, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }

  // ── Inline child switcher ──────────────────────────────────────────────────
  // Horizontally-scrollable child cards. Tapping one selects that child app-wide
  // (selectChild → sets provider, clears caches, persists) so the parent lands
  // straight into that child's account. Real children only (childrenProvider).
  Widget _buildChildSwitcher() {
    final childrenAsync = ref.watch(childrenProvider);
    final selected = ref.watch(selectedChildProvider);

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.child_care_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('My Children', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.4)),
            const Spacer(),
            childrenAsync.maybeWhen(
              data: (kids) => kids.length > 1
                  ? Text('Tap to switch', style: TextStyle(fontSize: 11, color: AppColors.text3, fontWeight: FontWeight.w600))
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ]),
          const SizedBox(height: 12),
          childrenAsync.when(
            loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
            error: (_, __) => _childError(),
            data: (kids) {
              if (kids.isEmpty) {
                return Row(children: const [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.text3),
                  SizedBox(width: 8),
                  Expanded(child: Text('No children linked. Contact the school office.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.text3))),
                ]);
              }
              return SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: kids.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _childCard(kids[i], i, selected?.id == kids[i].id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const _avatarColors = [
    [Color(0xFF74B9FF), Color(0xFF0984E3)],
    [Color(0xFFA29BFE), Color(0xFF6C5CE7)],
    [Color(0xFF55EFC4), Color(0xFF00B894)],
    [Color(0xFFFF7675), Color(0xFFD63031)],
  ];

  Widget _childCard(StudentModel kid, int i, bool isSelected) {
    final colors = _avatarColors[i % _avatarColors.length];
    return GestureDetector(
      onTap: () {
        if (isSelected) {
          // Already active — go straight to that child's home.
          context.go('/parent/home');
          return;
        }
        selectChild(ref, kid);
        _toast('Now viewing ${kid.firstName}');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 108,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryExtraLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFECECF5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: colors)),
                  alignment: Alignment.center,
                  child: Text(kid.initials, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                if (isSelected)
                  Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(kid.firstName,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.text1)),
            const SizedBox(height: 1),
            Text(kid.gradeLabel,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.text3)),
          ],
        ),
      ),
    );
  }

  Widget _childError() => Row(children: [
    const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.red),
    const SizedBox(width: 8),
    const Expanded(child: Text('Could not load children.', style: TextStyle(fontSize: 12.5, color: AppColors.text3))),
    TextButton(onPressed: () => ref.invalidate(childrenProvider), child: const Text('Retry')),
  ]);

  // ── Section + tile builders (staff-style grouped cards) ────────────────────
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
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
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.4)),
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

  Widget _settingsTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 19),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.text3))
          : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
    );
  }

  Widget _switchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      secondary: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 19),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.text3)),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  // ── My Profile: edit real name + phone, persisted to the users row ─────────
  void _showEditProfile(UserModel? user) {
    final nameCtrl = TextEditingController(text: user?.displayName ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    var saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: const [
              Icon(Icons.person_outline_rounded, color: AppColors.primary),
              SizedBox(width: 10),
              Text('Edit Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text1)),
            ]),
            const SizedBox(height: 18),
            TextField(
              controller: nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
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
                      content: Text('Could not save. Please try again.'), behavior: SnackBarBehavior.floating));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Change Password: real authenticated change (same 3-field UX as staff) ──
  // Current + New + Confirm, verified and written server-side via
  // /api/session/change-password. No fake success — the button reflects the
  // real API result and surfaces the server's message on failure.
  void _showChangePassword(UserModel? user) {
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
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text1)),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.text3))),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDlg(() => saving = true);
                try {
                  await ApiClient.instance.changePassword(
                    currentPassword: currentCtrl.text,
                    newPassword: newCtrl.text,
                  );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _toast('Password updated successfully');
                } on DioException catch (e) {
                  setDlg(() => saving = false);
                  final msg = e.response?.data is Map && (e.response!.data['error'] != null)
                      ? e.response!.data['error'].toString()
                      : 'Could not change password. Please try again.';
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
                } catch (_) {
                  setDlg(() => saving = false);
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Could not change password. Please try again.'), behavior: SnackBarBehavior.floating));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Notification Preferences: real email/sms toggles persisted to users ────
  void _showNotificationPrefs(UserModel? user) {
    var email = user?.emailNotif ?? true;
    var sms   = user?.smsNotif ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.notifications_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Notification Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: email,
                activeColor: AppColors.primary,
                title: const Text('Email alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                subtitle: const Text('Attendance, grades, fees & announcements', style: TextStyle(fontSize: 12, color: AppColors.text3)),
                onChanged: (v) async { setSheet(() => email = v); await _saveNotif(emailNotif: v); },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: sms,
                activeColor: AppColors.primary,
                title: const Text('SMS alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text1)),
                subtitle: const Text('Urgent notices to your phone', style: TextStyle(fontSize: 12, color: AppColors.text3)),
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
    } catch (_) {
      _toast('Could not save preference. Please try again.');
    }
  }

  // ── Help & FAQ + real support tickets ─────────────────────────────────────
  // FAQ answers are static guidance (not fabricated data). "Raise a ticket" and
  // "My Tickets" are backed by the real support_tickets entity — genuine DB rows
  // scoped to the signed-in parent's uid.
  void _showHelp() {
    final user = ref.read(authProvider).user;
    final uid = user?.uid ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => StatefulBuilder(
          builder: (ctx, setSheet) {
            _ticketsFuture ??= _loadTickets(uid);
            return ListView(
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
                const SizedBox(height: 20),

                // ── Raise a ticket ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryExtraLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: const [
                      Icon(Icons.support_agent_rounded, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(child: Text('Still need help?',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text1))),
                    ]),
                    const SizedBox(height: 6),
                    const Text('Raise a support ticket and the school team will follow up with you.',
                      style: TextStyle(fontSize: 13, color: AppColors.text2, height: 1.4)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: uid.isEmpty ? null : () => _showRaiseTicket(uid, () {
                          setSheet(() => _ticketsFuture = _loadTickets(uid));
                        }),
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                        label: const Text('Raise a ticket', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 22),

                // ── My Tickets ──
                Row(children: [
                  const Text('My Tickets', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text1)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                    tooltip: 'Refresh',
                    onPressed: () => setSheet(() => _ticketsFuture = _loadTickets(uid)),
                  ),
                ]),
                const SizedBox(height: 4),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _ticketsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)));
                    }
                    final tickets = List<Map<String, dynamic>>.from(snap.data ?? const []);
                    if (tickets.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primaryExtraLight),
                        ),
                        child: const Center(child: Text("You haven't raised any tickets yet.",
                          style: TextStyle(color: AppColors.text3, fontSize: 13))),
                      );
                    }
                    tickets.sort((a, b) => (b['createdAt']?.toString() ?? '')
                        .compareTo(a['createdAt']?.toString() ?? ''));
                    return Column(children: tickets.map(_ticketCard).toList());
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>>? _ticketsFuture;

  Future<List<Map<String, dynamic>>> _loadTickets(String uid) {
    if (uid.isEmpty) return Future.value(const []);
    return ApiClient.instance.getAll(AppConstants.supportTickets, params: {'uid': uid});
  }

  static const List<String> _ticketCategories = [
    'General',
    'Account & Login',
    'Attendance',
    'Fees & Payments',
    'Grades & Results',
    'Homework & Assignments',
    'Transport',
    'Bug / Something broken',
  ];

  void _showRaiseTicket(String uid, VoidCallback onSubmitted) {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var category = 'General';
    var submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: const [
                Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                SizedBox(width: 10),
                Text('Raise a ticket', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.text1)),
              ]),
              const SizedBox(height: 16),
              TextFormField(
                controller: subjectCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.title_rounded)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please add a subject' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                items: _ticketCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSheet(() => category = v ?? 'General'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                minLines: 4, maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue', alignLabelWithHint: true,
                  prefixIcon: Padding(padding: EdgeInsets.only(bottom: 60), child: Icon(Icons.notes_rounded)),
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please describe the issue (at least 10 characters)' : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: submitting ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setSheet(() => submitting = true);
                    final user = ref.read(authProvider).user;
                    try {
                      await ApiClient.instance.createRecord(AppConstants.supportTickets, {
                        'subject': subjectCtrl.text.trim(),
                        'category': category,
                        'description': descCtrl.text.trim(),
                        'status': 'open',
                        'raisedByUid': uid,
                        'uid': uid,
                        'raisedByRole': user?.role ?? 'parent',
                        'raisedByName': user?.displayName ?? '',
                        'createdAt': DateTime.now().toIso8601String(),
                      });
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      onSubmitted();
                      _toast('Ticket submitted — we\'ll get back to you.');
                    } catch (_) {
                      setSheet(() => submitting = false);
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Could not submit ticket. Please try again.'), behavior: SnackBarBehavior.floating));
                    }
                  },
                  icon: submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(submitting ? 'Submitting…' : 'Submit ticket', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _ticketCard(Map<String, dynamic> t) {
    final status = (t['status']?.toString() ?? 'open').toLowerCase();
    final subject = t['subject']?.toString() ?? 'Untitled';
    final category = t['category']?.toString() ?? '';
    final createdAt = t['createdAt']?.toString() ?? '';

    Color statusColor;
    switch (status) {
      case 'resolved':
      case 'closed':
        statusColor = AppColors.green;
        break;
      case 'in_progress':
      case 'in progress':
        statusColor = AppColors.amber;
        break;
      default:
        statusColor = AppColors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryExtraLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(subject,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text1, fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(status.replaceAll('_', ' '),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ]),
        if (category.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(category, style: const TextStyle(color: AppColors.text2, fontSize: 12)),
        ],
        if (createdAt.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_formatTicketDate(createdAt), style: const TextStyle(color: AppColors.text3, fontSize: 11)),
        ],
      ]),
    );
  }

  String _formatTicketDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final l = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Raised ${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }

  static const List<(String, String)> _faqs = [
    ('How do I switch between my children?',
      'Open Settings and use the "My Children" cards at the top — tap a child to view their account. You can also use the child selector on the Home screen.'),
    ('Where can I see attendance and grades?',
      'From Home, tap Attendance or Results/Gradebook. Report cards are under More → Report Cards.'),
    ('How do I pay or view fees?',
      'Open Fees from Home to see invoices, due dates and payment history for the selected child.'),
    ('How do I contact a teacher?',
      'Use Messages to reach your child\'s teachers. You\'ll be notified here when they reply.'),
    ('I\'m not getting notifications.',
      'Check Settings → Notification Preferences and make sure Email or SMS alerts are on, and that notifications are allowed for the app in your device settings.'),
    ('How do I change my password?',
      'Settings → Change Password sends a secure reset link to your registered email.'),
  ];

  Widget _faqTile(String q, String a) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: context.cardColor,
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
        children: [Align(alignment: Alignment.centerLeft,
          child: Text(a, style: const TextStyle(fontSize: 13, color: AppColors.text2, height: 1.45)))],
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
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
            children: [
              _policyPara('Data we handle', 'Student Diwan processes only the information needed to keep you informed about your child: your name and contact details, and your child\'s attendance, grades, fees and school communications.'),
              _policyPara('How it is used', 'Your data powers the attendance, gradebook, fees and messaging features. We never sell it or share it with advertisers.'),
              _policyPara('Storage & security', 'Records are stored on your school\'s secured servers and sent over encrypted (HTTPS) connections. Access is limited to authorised school staff.'),
              _policyPara('Your rights', 'You can request a copy of your data or corrections through your school administrator at any time.'),
              _policyPara('Contact', 'Questions about privacy? Email support@studentdiwan.com and we\'ll respond within two business days.'),
            ],
          )),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
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

  Widget _buildLogout() {
    return InkWell(
      onTap: () => _confirmLogout(context, ref),
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
          Text('Sign Out', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
          Spacer(),
          Icon(Icons.chevron_right_rounded, color: AppColors.red),
        ]),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text1)),
        content: const Text('Are you sure you want to sign out of the Parent Portal?',
          style: TextStyle(color: AppColors.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.text3))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              clearCache();
              await FcmService.onLogout();
              await BiometricService.clearCredentials();
              // Clear the parent-portal session state…
              await ref.read(authProvider.notifier).logout();
              // …and the SHARED app-wide auth state the router watches, so the
              // redirect to /login actually fires (this was the missing piece —
              // clearing only the portal provider left the router authenticated).
              await ref.read(app_auth.authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
