import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'signup_screen.dart';

// ── Design tokens matching the HTML login page ────────────────────────────────
const _primary = Color(0xFF001E40);
const _secondary = Color(0xFF065DB7);
const _surface = Color(0xFFFCF8F9);
const _surfaceContainerLowest = Color(0xFFFFFFFF);
const _outlineVariant = Color(0xFFC3C6D1);
const _onSurface = Color(0xFF1B1B1C);
const _onSurfaceVariant = Color(0xFF43474F);
const _tertiaryFixed = Color(0xFFDAE4EE);
const _surfaceContainerLow = Color(0xFFF6F3F4);
const _errorColor = Color(0xFFBA1A1A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginSuccess});

  final void Function(String patientName) onLoginSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final name = await AuthService.login(email, pass);
      widget.onLoginSuccess(name);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          // ── Top App Bar ───────────────────────────────────────────────────
          _TopAppBar(),
          // ── Scrollable content ────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _outlineVariant, width: 2),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Heading
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: _primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to access your eye care dashboard.',
                          style: TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Clinic Image ───────────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 160,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Container(color: _tertiaryFixed),
                                Image.network(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuA59cJ0QskufwUomzpVYVNKtYr-vEPpsliBgTIgRjNIr1XbjpCpC3bXY6yuOP0QtsvuyuD5VRmOFur4bPZL8rz1tRWa61h2VaU4vawDqGiwJITv286gOtPNpHbn8uT7G0ikE3wM3BsGMa5eIeblKM4RsItUSrrkhnV4KsWNnb6pV2T06jglmyeFlCHTA5ZXPBjunoV1LPUjp92Mclc8o8D__mXwmV869nboAcwTJZJUZ26KnDte3KET9mcMFx8Y9jeGwyurCWvUCLA',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                                Container(color: _primary.withValues(alpha: 0.10)),
                                const Center(
                                  child: Icon(
                                    Icons.health_and_safety,
                                    size: 64,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Email ──────────────────────────────────────────
                        _FieldLabel('Email Address'),
                        const SizedBox(height: 8),
                        _TextField(
                          controller: _emailCtrl,
                          hint: 'name@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline,
                        ),
                        const SizedBox(height: 24),

                        // ── Password ───────────────────────────────────────
                        _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        _PasswordField(
                          controller: _passCtrl,
                          obscure: _obscurePass,
                          onToggle: () =>
                              setState(() => _obscurePass = !_obscurePass),
                          onSubmit: () => _signIn(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              foregroundColor: _secondary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 8),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // ── Error ──────────────────────────────────────────
                        if (_error != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: _errorColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // ── Sign In Button ─────────────────────────────────
                        SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: _loading ? null : _signIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              disabledBackgroundColor:
                                  _primary.withValues(alpha: 0.6),
                            ),
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: Text(
                              _loading ? 'Signing In...' : 'Sign In',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Divider ────────────────────────────────────────
                        const Divider(color: _outlineVariant, thickness: 2),
                        const SizedBox(height: 16),

                        const Text(
                          'Don\'t have an account?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _onSurfaceVariant,
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Create New Account Button ──────────────────────
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => SignUpScreen(
                                    onSignUpSuccess: widget.onLoginSuccess,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              side: const BorderSide(color: _primary, width: 2),
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Create New Account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.32,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FooterLink(icon: Icons.help_outline, label: 'Support'),
                    const SizedBox(width: 24),
                    _FooterLink(icon: Icons.info_outline, label: 'Terms & Privacy'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '© 2024 VisionCare Medical Services.',
                  style: TextStyle(
                    color: Color(0xFF737780),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _TopAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _outlineVariant, width: 2)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.visibility, color: _primary, size: 24),
          SizedBox(width: 8),
          Text(
            'VisionCare',
            style: TextStyle(
              color: _primary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: _onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.32,
        ),
      );
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: _onSurface, fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFF737780), fontSize: 18),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: _onSurfaceVariant)
            : null,
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _outlineVariant, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: (_) => onSubmit(),
      style: const TextStyle(color: _onSurface, fontSize: 18),
      decoration: InputDecoration(
        hintText: '••••••••',
        hintStyle:
            const TextStyle(color: Color(0xFF737780), fontSize: 18),
        prefixIcon: const Icon(Icons.lock_outline, color: _onSurfaceVariant),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: _onSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _outlineVariant, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _onSurfaceVariant,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
