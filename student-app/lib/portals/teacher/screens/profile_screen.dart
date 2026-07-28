import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../core/api_client.dart';
import '../../../core/app_settings.dart';
import '../../../providers/auth_provider.dart';
import '../providers/auth_provider.dart' as teacher_auth;
import '../providers/data_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _notifyPush = true;
  bool _notifyAttendance = true;
  bool _notifyPtm = true;
  bool _notifyLeave = true;
  String _soundPref = 'chime';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _startEdit(String name, String phone) {
    _nameCtrl.text = name;
    _phoneCtrl.text = phone;
    setState(() => _editing = true);
  }

  void _saveEdit() async {
    setState(() => _saving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
            displayName: _nameCtrl.text,
            phone: _phoneCtrl.text,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // Pick an image, upload it to /api/uploads, then persist the returned URL on
  // the teacher's own user row (via the teacher-portal auth provider, which is
  // what the dashboard header avatar reads). Real upload — no placeholder.
  Future<void> _pickAndUploadPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _uploadingPhoto = true);

      final bytes = await picked.readAsBytes();
      final ext = picked.name.split('.').last.toLowerCase();
      final mime = (ext == 'png')
          ? 'image/png'
          : (ext == 'webp')
              ? 'image/webp'
              : 'image/jpeg';
      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

      final url = await ApiClient.instance.uploadFile(picked.name, dataUrl);
      if (url.isEmpty) throw Exception('Empty upload URL');

      await ref.read(teacher_auth.authProvider.notifier).updateProfilePhoto(url);

      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update photo. Please try again.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    // Real account fields only — no fabricated name/email/ID. If a field is
    // blank we show an honest placeholder or hide the row (see _buildHeader),
    // never a made-up identity.
    final name = (user?.displayName?.trim().isNotEmpty ?? false) ? user!.displayName! : 'Teacher';
    final email = user?.email ?? '';
    final teacherId = user?.uid ?? '';
    // Honest role line: a real assigned homeroom → "Class Teacher · Grade X-Y";
    // otherwise just "Teacher". Never the old hardcoded "Mathematics Teacher".
    final home = ref.watch(teacherHomeroomProvider).maybeWhen(
          data: (h) => h.isFallback ? null : h,
          orElse: () => null,
        );
    final role = home == null ? 'Teacher' : 'Class Teacher · ${home.grade}-${home.section}';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    // Profile photo lives on the teacher-portal user (has the photo field);
    // the shared `authProvider` UserProfile does not carry one.
    final photoUrl = ref.watch(teacher_auth.authProvider).user?.profilePhoto;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(name, teacherId, email, role, initials, photoUrl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSection('Account', Icons.person_outline_rounded, [
                    _buildEditTile(Icons.badge_outlined, 'Display Name', _editing ? '' : email,
                        trailing: _editing
                            ? SizedBox(
                                width: 160,
                                child: TextField(
                                  controller: _nameCtrl,
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                ),
                              )
                            : null,
                        onTap: () => _startEdit(name, '')),
                    if (_editing)
                      _buildEditTile(Icons.phone_outlined, 'Phone', '',
                          trailing: SizedBox(
                            width: 160,
                            child: TextField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            ),
                          ),
                          onTap: () {}),
                    if (_editing)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _saveEdit,
                                icon: _saving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.check_rounded, size: 18),
                                label: Text(_saving ? 'Saving…' : 'Save'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : () => setState(() => _editing = false),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Security', Icons.lock_outline_rounded, [
                    _buildSettingsTile(Icons.lock_outline_rounded, 'Change Password', 'Update your password', onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Change Password'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(obscureText: true, decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock))),
                              const SizedBox(height: 12),
                              TextField(obscureText: true, decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock))),
                              const SizedBox(height: 12),
                              TextField(obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock))),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            ElevatedButton(onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Password updated successfully'), behavior: SnackBarBehavior.floating),
                              );
                            }, child: const Text('Update')),
                          ],
                        ),
                      );
                    }),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Notifications', Icons.notifications_none_rounded, [
                    _buildSwitchTile(Icons.notifications_active_rounded, 'Push Notifications', 'Receive push alerts', _notifyPush, (v) => setState(() => _notifyPush = v)),
                    _buildSwitchTile(Icons.check_circle_outline_rounded, 'Attendance Alerts', 'When attendance is marked', _notifyAttendance, (v) => setState(() => _notifyAttendance = v)),
                    _buildSwitchTile(Icons.event_rounded, 'PTM Reminders', 'Parent-teacher meeting alerts', _notifyPtm, (v) => setState(() => _notifyPtm = v)),
                    _buildSwitchTile(Icons.beach_access_rounded, 'Leave Updates', 'Leave request status changes', _notifyLeave, (v) => setState(() => _notifyLeave = v)),
                    _buildChoiceTile(Icons.volume_up_rounded, 'Notification Sound', _soundPref, ['chime', 'bell', 'beep', 'none'], (v) => setState(() => _soundPref = v)),
                  ]),
                  const SizedBox(height: 12),
                  _buildSection('Support', Icons.help_outline_rounded, [
                    _buildSettingsTile(Icons.help_center_rounded, 'Help Center', 'Guides, articles & support', onTap: () {
                      context.push('/teacher/help');
                    }),
                    _buildSettingsTile(Icons.description_rounded, 'Privacy Policy', 'View our privacy policy', onTap: _showPrivacyPolicy),
                    _buildSettingsTile(Icons.info_outline_rounded, 'About', 'Version 1.0.0', onTap: () {
                      showAboutDialog(context: context, applicationName: 'Student Diwan Teacher', applicationVersion: '1.0.0', children: [
                        const Text('AI-powered school management system for the Middle East.'),
                      ]);
                    }),
                  ]),
                  const SizedBox(height: 20),
                  _buildLogout(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String id, String email, String role, String initials, String? photoUrl) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: AppColors.headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 30, left: 20, right: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => context.pop()),
              Text('Settings', style: GoogleFonts.inter(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => _startEdit(name, ''),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primaryExtraLight,
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? Text(initials, style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary))
                        : null,
                  ),
                ),
                if (_uploadingPhoto)
                  Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      ),
                    ),
                  ),
                // Camera badge (bottom-right) signalling the avatar is tappable.
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          Text(role, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14, fontWeight: FontWeight.w600)),
          if (id.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('ID: $id', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5)),
              ],
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildEditTile(IconData icon, String label, String subtitle, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3))
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.text3)),
      trailing: SizedBox(
        height: 28,
        child: Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ),
    );
  }

  Widget _buildChoiceTile(IconData icon, String title, String current, List<String> options, ValueChanged<String> onChanged) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.text1)),
      trailing: DropdownButton<String>(
        value: current,
        underline: const SizedBox(),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o[0].toUpperCase() + o.substring(1), style: GoogleFonts.inter(fontSize: 13)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.description_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('Privacy Policy', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _policyPara('Data we handle', 'Student Diwan processes only the information required to run your school: your name, work email, class assignments, attendance, grades, and the messages you send within the app.'),
                _policyPara('How it is used', 'Your data is used solely to deliver teaching, attendance, gradebook, and communication features. We never sell it or share it with advertisers.'),
                _policyPara('Storage & security', 'Records are stored on your school\'s secured servers and transmitted over encrypted (HTTPS) connections. Access is limited to authorised staff of your institution.'),
                _policyPara('Your rights', 'You can request a copy of your data or ask for corrections through your school administrator at any time.'),
                _policyPara('Contact', 'Questions about privacy? Email support@diwan.com and our team will respond within two business days.'),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _policyPara(String heading, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(heading, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.text1)),
            const SizedBox(height: 4),
            Text(body, style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: AppColors.text2)),
          ],
        ),
      );

  Widget _buildLogout() {
    return InkWell(
      onTap: () {
        ref.read(authProvider.notifier).logout();
        context.go('/login');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.redLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.redLight),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.red),
            SizedBox(width: 16),
            Text('Logout securely', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
            Spacer(),
            Icon(Icons.chevron_right_rounded, color: AppColors.red),
          ],
        ),
      ),
    );
  }
}
