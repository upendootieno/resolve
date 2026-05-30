import 'package:flutter/material.dart';

import '../services/auth_service.dart';

// ── Design tokens matching the HTML sign-up page ──────────────────────────────
const _primary = Color(0xFF001E40);
const _secondary = Color(0xFF065DB7);
const _surface = Color(0xFFFCF8F9);
const _surfaceContainerLowest = Color(0xFFFFFFFF);
const _outlineVariant = Color(0xFFC3C6D1);
const _onSurface = Color(0xFF1B1B1C);
const _onSurfaceVariant = Color(0xFF43474F);
const _tertiaryFixed = Color(0xFFDAE4EE);
const _onTertiaryFixedVariant = Color(0xFF3E4850);
const _onTertiaryContainer = Color(0xFF929CA6);
const _errorColor = Color(0xFFBA1A1A);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.onSignUpSuccess});

  final void Function(String patientName) onSignUpSuccess;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final patientName = await AuthService.register(
        fullName: name,
        email: email,
        password: pass,
      );
      widget.onSignUpSuccess(patientName);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');

      // If the email already exists, try logging in with the provided password
      // and continue to dashboard on success.
      if (message.toLowerCase().contains('email already registered')) {
        try {
          final patientName = await AuthService.login(email, pass);
          widget.onSignUpSuccess(patientName);
          return;
        } catch (_) {
          // Fall through and show the original registration error below.
        }
      }

      setState(() => _error = message);
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

          // ── Scrollable form ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Banner Image ───────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 192,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: _tertiaryFixed,
                                  border: Border.all(
                                      color: _outlineVariant, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              Image.network(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuCaDxZ8ZpRuFTri333MUGZu_M1eZIDoh5Qq7I-Qg0qqPCGQKtvSdGVJKhl09rRtrSroJStGS4I0gz2SKjcAtEDo4I9H6qElFNNJkxxsOBXHK-y4ZgjOgKSlraDkVaY1Yb3Kfw2Cqz5YsuyVm0bEi4nEr2a0RMZhIKCUgfI--35l4jPO7WNxMVFYsqBOph6VeC7tAs-oiD0LnFA3uzKsHny1z2lC23AweRTLlxzhWbqzkRGnBpjairXBwbJH6XvJforTO3J7GjoKHKg',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Heading ────────────────────────────────────────
                      const Text(
                        'Create Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Access your eye care records and schedule appointments with ease.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Full Name ──────────────────────────────────────
                      _FieldLabel('Full Name'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _nameCtrl,
                        hint: 'Enter your full name',
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 24),

                      // ── Email ──────────────────────────────────────────
                      _FieldLabel('Email Address'),
                      const SizedBox(height: 8),
                      _InputField(
                        controller: _emailCtrl,
                        hint: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),

                      // ── Password ───────────────────────────────────────
                      _FieldLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        style: const TextStyle(color: _onSurface, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'Min. 8 characters',
                          hintStyle: const TextStyle(
                              color: Color(0xFF737780), fontSize: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: _onSurfaceVariant,
                            ),
                            onPressed: () => setState(
                                () => _obscurePass = !_obscurePass),
                          ),
                          filled: true,
                          fillColor: _surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: _outlineVariant, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: _primary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Must include high-contrast characters for security.',
                        style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Accessibility Notice ───────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: _tertiaryFixed,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _outlineVariant, width: 2),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                color: _onTertiaryContainer, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This form is optimized for screen readers and high-contrast accessibility tools.',
                                style: TextStyle(
                                  color: _onTertiaryFixedVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Error ──────────────────────────────────────────
                      if (_error != null) ...[
                        const SizedBox(height: 12),
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

                      // ── Create Account Button ──────────────────────────
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _createAccount,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor:
                                _primary.withValues(alpha: 0.6),
                          ),
                          label: Text(
                            _loading ? 'Creating Account...' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: _outlineVariant, width: 2)),
              color: Color(0xFFF6F3F4),
            ),
            child: Column(
              children: [
                const Text(
                  '© 2024 VisionCare Medical Group',
                  style: TextStyle(
                    color: _onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          foregroundColor: _secondary,
                          padding: EdgeInsets.zero),
                      child: const Text(
                        'Privacy Policy',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 16),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                          foregroundColor: _secondary,
                          padding: EdgeInsets.zero),
                      child: const Text(
                        'Terms of Service',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                          color: _onSurfaceVariant,
                          fontSize: 16,
                          fontWeight: FontWeight.w400),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Login here',
                        style: TextStyle(
                          color: _secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: _secondary,
                        ),
                      ),
                    ),
                  ],
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
          color: _primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.32,
        ),
      );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _onSurface, fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF737780), fontSize: 18),
        filled: true,
        fillColor: _surfaceContainerLowest,
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
