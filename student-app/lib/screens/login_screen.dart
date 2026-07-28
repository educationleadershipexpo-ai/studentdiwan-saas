import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../core/strings.dart';
import '../core/server_config.dart';

// ── Brand tokens ──────────────────────────────────────────────────────────────
const _bg        = Color(0xFFF7F7FB);
const _dark      = Color(0xFF0F172A);
const _gray      = Color(0xFF64748B);
const _grayLight = Color(0xFF94A3B8);
const _border    = Color(0xFFE8E4F8);

// Portal definitions
const _portals = [
  _PortalDef(
    id: 'staff',
    label: 'Staff Portal',
    subtitle: 'Teachers, Admin & Support',
    icon: Icons.people_alt_rounded,
    gradientStart: Color(0xFF7C3AED),
    gradientEnd: Color(0xFF4F46E5),
  ),
  _PortalDef(
    id: 'student',
    label: 'Student Portal',
    subtitle: 'Access classes, results & assignments',
    icon: Icons.school_rounded,
    gradientStart: Color(0xFFE11D74),
    gradientEnd: Color(0xFF9333EA),
  ),
  _PortalDef(
    id: 'parent',
    label: 'Parent Portal',
    subtitle: 'Monitor your child\'s progress',
    icon: Icons.menu_book_rounded,
    gradientStart: Color(0xFF9333EA),
    gradientEnd: Color(0xFF7C3AED),
  ),
];

class _PortalDef {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  const _PortalDef({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN LOGIN SCREEN — portal selection
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: ServerConfig.baseUrlWithoutApi);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Server Settings',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specify the backend URL/IP to connect to.',
                style: GoogleFonts.inter(fontSize: 13, color: _gray)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://portal.studentdiwan.com',
                labelText: 'Server URL / IP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ServerConfig.setCustomUrl(null);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Server reset to default.'), behavior: SnackBarBehavior.floating),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ServerConfig.setCustomUrl(newUrl);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server URL set to: ${ServerConfig.baseUrlWithoutApi}'), behavior: SnackBarBehavior.floating),
                  );
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openPortalLogin(_PortalDef portal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoginSheet(portal: portal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F1A) : _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, top + 32, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Server Connection Config ─────────────────────────────────
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: IconButton(
                      icon: Icon(Icons.settings_ethernet_rounded, color: isDark ? Colors.white60 : _gray, size: 24),
                      tooltip: 'Server Connection Settings',
                      onPressed: _showServerConfigDialog,
                    ),
                  ),
                ),

                // ── Logo ───────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9333EA).withOpacity(0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset('assets/logo.png', fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.school_rounded, color: Color(0xFF9333EA), size: 48)),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Heading ────────────────────────────────────────────────
                Text('Welcome Back',
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white : _dark,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  )),
                const SizedBox(height: 6),
                Text('Select your portal to continue',
                  style: GoogleFonts.inter(
                    color: _gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  )),
                const SizedBox(height: 28),

                // ── Portal cards ────────────────────────────────────────────
                ..._portals.map((p) => _PortalCard(
                  portal: p,
                  onTap: () => _openPortalLogin(p),
                )),

                const SizedBox(height: 20),

                // ── Admin link ─────────────────────────────────────────────
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(fontSize: 13, color: _gray),
                      children: [
                        const TextSpan(text: 'Admin? '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => _openPortalLogin(
                              const _PortalDef(
                                id: 'staff',
                                label: 'Admin Sign-in',
                                subtitle: 'Admin & Management',
                                icon: Icons.admin_panel_settings_rounded,
                                gradientStart: Color(0xFF7C3AED),
                                gradientEnd: Color(0xFF4F46E5),
                              ),
                            ),
                            child: Text('Admin Sign-in',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9333EA),
                              )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Portal card ───────────────────────────────────────────────────────────────

class _PortalCard extends StatefulWidget {
  final _PortalDef portal;
  final VoidCallback onTap;
  const _PortalCard({required this.portal, required this.onTap});
  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); HapticFeedback.selectionClick(); },
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A40) : const Color(0xFFEEE8FC),
              width: 1.5,
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Gradient icon box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.portal.gradientStart, widget.portal.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.portal.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),

              // Label + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.portal.label,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : _dark,
                      )),
                    const SizedBox(height: 2),
                    Text(widget.portal.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: _gray,
                      )),
                  ],
                ),
              ),

              // Chevron
              Icon(Icons.chevron_right_rounded,
                color: _grayLight, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN BOTTOM SHEET — email + password form
// ─────────────────────────────────────────────────────────────────────────────

class _LoginSheet extends ConsumerStatefulWidget {
  final _PortalDef portal;
  const _LoginSheet({required this.portal});
  @override
  ConsumerState<_LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends ConsumerState<_LoginSheet>
    with SingleTickerProviderStateMixin {

  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  bool _obscure     = true;
  bool _rememberMe  = true;
  bool _loading     = false;
  String? _error;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  Color get _accent => widget.portal.gradientStart;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -7.0),  weight: 20),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0),   weight: 20),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: 0.0),    weight: 15),
    ]).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  bool _roleOk(AppRole r) {
    switch (widget.portal.id) {
      case 'staff':  return r == AppRole.teacher || r == AppRole.admin;
      case 'parent': return r == AppRole.parent;
      default:       return r == AppRole.student;
    }
  }

  String get _portalLabel => widget.portal.id;

  void _triggerError(String msg) {
    setState(() { _loading = false; _error = msg; });
    HapticFeedback.lightImpact();
    _shakeCtrl.forward(from: 0);
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      _triggerError('Please enter your email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final ok = await ref.read(authProvider.notifier).login(email, pass);
    if (!mounted) return;
    if (!ok) {
      _triggerError(ref.read(authProvider).error ?? 'Login failed.');
      return;
    }
    final role = ref.read(authProvider).role;
    if (!_roleOk(role)) {
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      _triggerError(
        'This is not a $_portalLabel account. '
        'Please pick the correct portal.',
      );
      return;
    }
    HapticFeedback.mediumImpact();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _forgotPassword() async {
    final ctrl = TextEditingController(text: _emailCtrl.text.trim());
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reset password',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 20)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enter your account email and we\'ll send a reset request.',
              style: GoogleFonts.inter(fontSize: 13, color: _gray)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'you@example.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (sent != true || !mounted) return;
    final email = ctrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final err = await ref.read(authProvider.notifier).forgotPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'If an account exists for $email, a reset request has been sent.'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A5C) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Portal icon + title
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.portal.gradientStart, widget.portal.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.portal.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.portal.label,
                  style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : _dark,
                  )),
                Text('Sign in to continue',
                  style: GoogleFonts.inter(fontSize: 12, color: _gray)),
              ]),
            ]),
            const SizedBox(height: 24),

            // Email
            _SheetField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              hint: 'Email or username',
              icon: Icons.person_outline_rounded,
              accent: _accent,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passFocus.requestFocus(),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Password
            _SheetField(
              controller: _passCtrl,
              focusNode: _passFocus,
              hint: 'Password',
              icon: Icons.lock_outline_rounded,
              accent: _accent,
              obscure: _obscure,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _loading ? null : _login(),
              isDark: isDark,
              trailing: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: _grayLight, size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 10),

            // Remember me + Forgot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(width: 20, height: 20,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? true),
                          activeColor: _accent,
                          checkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          side: BorderSide(color: _accent.withOpacity(0.4), width: 1.5),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Remember me',
                        style: GoogleFonts.inter(
                          color: _gray, fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
                TextButton(
                  onPressed: _forgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    minimumSize: const Size(44, 36),
                  ),
                  child: Text('Forgot Password?',
                    style: GoogleFonts.inter(
                      color: _accent, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Error + Sign In (shake together)
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, __) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: Column(children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeInOut,
                    child: _error != null
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(Icons.error_outline_rounded,
                                    color: Color(0xFFDC2626), size: 17),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF991B1B),
                                  fontSize: 13, fontWeight: FontWeight.w500, height: 1.45,
                                ))),
                            ]),
                          ),
                        )
                      : const SizedBox.shrink(),
                  ),

                  // Sign In button
                  _SignInButton(
                    loading: _loading,
                    onTap: _loading ? null : _login,
                    gradientStart: widget.portal.gradientStart,
                    gradientEnd: widget.portal.gradientEnd,
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Footer
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.verified_user_rounded,
                  color: _accent.withOpacity(0.6), size: 12),
              const SizedBox(width: 5),
              Text('Secure · Trusted · Empowering Education',
                style: GoogleFonts.inter(
                  color: _grayLight, fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Sheet text field ──────────────────────────────────────────────────────────

class _SheetField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final IconData icon;
  final Color accent;
  final bool obscure;
  final Widget? trailing;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final bool isDark;

  const _SheetField({
    required this.controller,
    this.focusNode,
    required this.hint,
    required this.icon,
    required this.accent,
    this.obscure = false,
    this.trailing,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    required this.isDark,
  });

  @override
  State<_SheetField> createState() => _SheetFieldState();
}

class _SheetFieldState extends State<_SheetField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => setState(() => _focused = widget.focusNode?.hasFocus ?? false);

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1E1E30) : Colors.white;
    final borderDefault = widget.isDark ? const Color(0xFF2E2E48) : _border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? widget.accent.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: _focused ? 18 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscure,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: GoogleFonts.inter(
          color: widget.isDark ? Colors.white : _dark, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(color: const Color(0xFFB0BAC9), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Icon(widget.icon,
              color: _focused ? widget.accent : _grayLight, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: widget.trailing,
          suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          filled: true,
          fillColor: bg,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderDefault, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: borderDefault, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: widget.accent, width: 2),
          ),
        ),
      ),
    );
  }
}

// ── Sign In button ────────────────────────────────────────────────────────────

class _SignInButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;
  final Color gradientStart;
  final Color gradientEnd;
  const _SignInButton({
    required this.loading,
    this.onTap,
    required this.gradientStart,
    required this.gradientEnd,
  });
  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) { setState(() => _pressed = false); widget.onTap?.call(); },
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.loading
                  ? [widget.gradientStart.withOpacity(0.4), widget.gradientEnd.withOpacity(0.4)]
                  : [widget.gradientStart, widget.gradientEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: (widget.loading || _pressed) ? [] : [
              BoxShadow(
                color: widget.gradientStart.withOpacity(0.36),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: widget.loading
              ? const Center(child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(context.tr.signIn,
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w800, letterSpacing: 0.4,
                    )),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                ]),
        ),
      ),
    );
  }
}
