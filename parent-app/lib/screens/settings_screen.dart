import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/biometric_service.dart';
import '../core/fcm_service.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

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
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppBackHeader(title: 'Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(children: [
          // Profile card
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.primaryGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.displayName ?? 'Parent', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 3),
                Text(user?.email ?? '', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: Text(user?.role?.toUpperCase() ?? 'PARENT',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                ),
              ])),
            ]),
          ),

          const SectionHeader(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            label: 'My Profile',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile editing — coming soon'))),
          ),
          _SettingsTile(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password change — coming soon'))),
          ),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notification Preferences',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification settings — coming soon'))),
          ),

          if (_biometricAvailable) ...[
            const SectionHeader(title: 'Security'),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
              child: SwitchListTile(
                value: _biometricEnabled,
                onChanged: (v) async {
                  await BiometricService.setEnabled(v);
                  setState(() => _biometricEnabled = v);
                },
                secondary: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 18),
                ),
                title: const Text('Biometric Login',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
                subtitle: const Text('Use fingerprint or face to sign in',
                  style: TextStyle(fontSize: 11, color: AppColors.text3)),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              ),
            ),
          ],

          const SectionHeader(title: 'App'),
          _SettingsTile(
            icon: Icons.language_rounded,
            label: 'Language',
            trailing: const Text('English', style: TextStyle(fontSize: 12, color: AppColors.text3)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Language selection — coming soon'))),
          ),
          _SettingsTile(
            icon: Icons.palette_outlined,
            label: 'Theme',
            trailing: const Text('System', style: TextStyle(fontSize: 12, color: AppColors.text3)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme selection — coming soon'))),
          ),
          _SettingsTile(
            icon: Icons.child_care_rounded,
            label: 'Switch Child',
            onTap: () => context.push('/children'),
          ),

          const SectionHeader(title: 'Support'),
          _SettingsTile(
            icon: Icons.help_outline_rounded,
            label: 'Help & FAQ',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            label: 'About',
            trailing: const Text('v1.0.0', style: TextStyle(fontSize: 12, color: AppColors.text3)),
            onTap: () {},
          ),

          const SizedBox(height: 24),
          // Logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () => _confirmLogout(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redLight,
                foregroundColor: AppColors.red,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.text3)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              clearCache();
              await FcmService.onLogout();
              await BiometricService.clearCredentials();
              ref.read(authProvider.notifier).logout();
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.primaryExtraLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text1)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (trailing != null) trailing!,
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.text3, size: 18),
        ]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
