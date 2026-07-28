import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/biometric_service.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl   = TextEditingController();
  bool _obscure    = true;
  bool _emailFocused = false;
  bool _pwdFocused   = false;
  bool _biometricAvailable = false;

  late final AnimationController _anim;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  final _emailFocus = FocusNode();
  final _pwdFocus   = FocusNode();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));

    _emailFocus.addListener(() => setState(() => _emailFocused = _emailFocus.hasFocus));
    _pwdFocus.addListener(()   => setState(() => _pwdFocused   = _pwdFocus.hasFocus));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _anim.forward();
      final available = await BiometricService.isAvailable();
      final enabled   = await BiometricService.isEnabled();
      if (mounted) setState(() => _biometricAvailable = available && enabled);
      if (available && enabled) _tryBiometricLogin();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _anim.dispose();
    _emailFocus.dispose();
    _pwdFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pwd   = _pwdCtrl.text;
    if (email.isEmpty || pwd.isEmpty) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.lightImpact();
    final ok = await ref.read(authProvider.notifier).login(email, pwd);
    if (ok && mounted) {
      await BiometricService.saveCredentials(email);
      context.go('/home');
    }
  }

  Future<void> _tryBiometricLogin() async {
    final ok = await BiometricService.authenticate();
    if (!ok || !mounted) return;
    // Use stored token — navigate directly if still valid
    final creds = await BiometricService.getSavedCredentials();
    if (creds != null && mounted) {
      // Token still valid; let router handle redirect via authProvider
      final loaded = await ref.read(authProvider.notifier).loadFromStorage();
      if (loaded && mounted) context.go('/home');
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0C3B8A),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: LayoutBuilder(builder: (ctx, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(children: [

                        // ── Header ────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                          child: Column(children: [
                            // Shield + school icon
                            Stack(alignment: Alignment.center, children: [
                              Container(
                                width: 88, height: 88,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18), width: 1.5),
                                ),
                              ),
                              Container(
                                width: 68, height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1A56DB), Color(0xFF2E7DF5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1A56DB).withOpacity(0.5),
                                      blurRadius: 20, offset: const Offset(0, 6)),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.school_rounded,
                                  size: 34, color: Colors.white),
                              ),
                            ]),

                            const SizedBox(height: 18),

                            const Text(
                              'Student Diwan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Secure tag
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.lock_rounded,
                                size: 11,
                                color: Colors.white.withOpacity(0.55)),
                              const SizedBox(width: 5),
                              Text(
                                'SECURE PARENT PORTAL',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ]),
                          ]),
                        ),

                        // ── Login card ────────────────────────────────────────
                        Expanded(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4F7FC),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(32)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  // Card title
                                  const Text('Sign in to your account',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F1F3D),
                                      letterSpacing: -0.4,
                                    )),
                                  const SizedBox(height: 4),
                                  Text('Enter your credentials to continue',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: const Color(0xFF8FA3BF),
                                      fontWeight: FontWeight.w500,
                                    )),
                                  const SizedBox(height: 28),

                                  // Email field
                                  _Field(
                                    controller: _emailCtrl,
                                    focusNode: _emailFocus,
                                    label: 'Email Address',
                                    hint: 'parent@school.edu',
                                    icon: Icons.email_outlined,
                                    focused: _emailFocused,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    onSubmitted: (_) =>
                                        FocusScope.of(context).requestFocus(_pwdFocus),
                                  ),
                                  const SizedBox(height: 14),

                                  // Password field
                                  _Field(
                                    controller: _pwdCtrl,
                                    focusNode: _pwdFocus,
                                    label: 'Password',
                                    hint: '••••••••',
                                    icon: Icons.lock_outline_rounded,
                                    focused: _pwdFocused,
                                    obscureText: _obscure,
                                    autofillHints: const [AutofillHints.password],
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _login(),
                                    suffix: GestureDetector(
                                      onTap: () =>
                                          setState(() => _obscure = !_obscure),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: const Color(0xFF8FA3BF),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Forgot password?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        )),
                                    ),
                                  ),

                                  // Error banner
                                  if (auth.error != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: AppColors.redLight,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.red.withOpacity(0.2)),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.error_outline_rounded,
                                          color: AppColors.red, size: 17),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(auth.error!,
                                            style: const TextStyle(
                                              color: AppColors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            )),
                                        ),
                                      ]),
                                    ),
                                  ],

                                  const SizedBox(height: 24),

                                  // Sign-in button
                                  _SignInButton(
                                    onPressed: auth.isLoading ? null : _login,
                                    isLoading: auth.isLoading,
                                  ),

                                  // Biometric login button (shows only when enrolled)
                                  if (_biometricAvailable) ...[
                                    const SizedBox(height: 16),
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: _tryBiometricLogin,
                                        icon: const Icon(
                                          Icons.fingerprint_rounded,
                                          size: 22,
                                          color: AppColors.primary,
                                        ),
                                        label: const Text(
                                          'Use Biometrics',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const Spacer(),

                                  // Footer
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified_user_outlined,
                                          size: 13,
                                          color: const Color(0xFF8FA3BF)),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Authorised parents & guardians only',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFF8FA3BF),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      ]),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable input field ──────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool focused;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focused,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused
              ? AppColors.primary
              : const Color(0xFFDDE6F5),
          width: focused ? 2 : 1.5,
        ),
        boxShadow: focused
            ? [BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 10, offset: const Offset(0, 3))]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F1F3D),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(icon,
              color: focused ? AppColors.primary : const Color(0xFF8FA3BF),
              size: 20),
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          labelStyle: TextStyle(
            color: focused ? AppColors.primary : const Color(0xFF8FA3BF),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            color: focused ? AppColors.primary : const Color(0xFF8FA3BF),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFFB0C4D8), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
          filled: false,
        ),
      ),
    );
  }
}

// ── Sign-in button ────────────────────────────────────────────────────────────
class _SignInButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  const _SignInButton({this.onPressed, this.isLoading = false});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.onPressed != null && !widget.isLoading;
    return GestureDetector(
      onTapDown: (_)  { if (active) _press.reverse(); },
      onTapUp:   (_)  { _press.forward(); widget.onPressed?.call(); },
      onTapCancel: () => _press.forward(),
      child: ScaleTransition(
        scale: _press,
        child: Container(
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF0C3B8A), Color(0xFF1A56DB), Color(0xFF2E7DF5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFB0BEC5), Color(0xFFCFD8DC)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [BoxShadow(
                    color: const Color(0xFF1A56DB).withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.login_rounded,
                      color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      )),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ── Forgot Password dialog ────────────────────────────────────────────────────
class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _ctrl;
  bool _sending = false;
  bool _sent    = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email address.');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await ApiClient.instance.forgotPassword(email);
      if (mounted) setState(() { _sent = true; _sending = false; });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Failed to send reset email. Please try again.';
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      title: const Text('Reset Password',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
          color: Color(0xFF0F1F3D))),
      content: _sent
          ? Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.mark_email_read_outlined,
                  color: AppColors.green, size: 30)),
              const SizedBox(height: 14),
              const Text('Reset link sent!',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                  color: Color(0xFF0F1F3D))),
              const SizedBox(height: 6),
              Text('Check ${_ctrl.text.trim()} for the reset link.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8FA3BF),
                  height: 1.5),
                textAlign: TextAlign.center),
            ])
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your email and we\'ll send a reset link.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF8FA3BF),
                    height: 1.5)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ctrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined, size: 20))),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                    style: const TextStyle(
                      color: AppColors.red, fontSize: 11,
                      fontWeight: FontWeight.w600)),
                ],
              ]),
      actions: _sent
          ? [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11))),
                child: const Text('Done')),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF8FA3BF)))),
              ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11))),
                child: _sending
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Text('Send Link')),
            ],
    );
  }
}
