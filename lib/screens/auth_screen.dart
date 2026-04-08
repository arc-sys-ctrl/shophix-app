import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/auth_provider.dart';
import 'main_layout.dart';

class AuthScreen extends StatefulWidget {
  final bool startWithRegister;
  const AuthScreen({super.key, this.startWithRegister = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _bgController;
  late AnimationController _formController;
  late Animation<double> _formSlide;
  late Animation<double> _formOpacity;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureLoginPassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.startWithRegister ? 1 : 0,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _animateForm();
        setState(() {});
      }
    });

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _formSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _formOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _formController.forward();
  }

  void _animateForm() {
    _formController.reset();
    _formController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bgController.dispose();
    _formController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _loginEmailController.dispose();
    _passwordController.dispose();
    _loginPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14),
        body: AnimatedBuilder(
          animation: _bgController,
          builder: (context, child) => Stack(
            children: [
              _buildBackgroundOrbs(),
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(child: _buildScrollableContent()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    final t = _bgController.value;
    return Stack(
      children: [
        Positioned(
          top: -60 + t * 40,
          right: -80,
          child: _glowOrb(260, const Color(0xFF00D1FF), 0.18),
        ),
        Positioned(
          top: 180 - t * 30,
          left: -100,
          child: _glowOrb(320, const Color(0xFF7C3AED), 0.13),
        ),
        Positioned(
          bottom: 100 + t * 20,
          right: -60,
          child: _glowOrb(200, const Color(0xFF00D1FF), 0.07),
        ),
      ],
    );
  }

  Widget _glowOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                Navigator.canPop(context) ? Navigator.pop(context) : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 15, color: Colors.white60),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D1FF), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text('S',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              Text('SOPHIX',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      color: Colors.white,
                      fontSize: 16)),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            _tabController.index == 0 ? 'Welcome\nBack.' : 'Create\nAccount.',
            style: GoogleFonts.outfit(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _tabController.index == 0
                ? 'Sign in to continue your experience'
                : 'Join Sophix and shop the future',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
          const SizedBox(height: 28),

          // Tab toggle
          _buildTabToggle(),
          const SizedBox(height: 28),

          // Social buttons
          _buildSocialButton(
            label: 'Continue with Google',
            icon: FontAwesomeIcons.google,
            bgColor: Colors.white,
            textColor: const Color(0xFF1F1F1F),
            iconColor: const Color(0xFF4285F4),
            onTap: _handleGoogleSignIn,
          ),
          const SizedBox(height: 12),
          _buildSocialButton(
            label: 'Continue with Apple',
            icon: FontAwesomeIcons.apple,
            bgColor: const Color(0xFF1C1C1E),
            textColor: Colors.white,
            iconColor: Colors.white,
            borderColor: Colors.white12,
            onTap: _handleAppleSignIn,
          ),
          const SizedBox(height: 28),

          // OR divider
          _buildOrDivider(),
          const SizedBox(height: 28),

          // Form (animated)
          AnimatedBuilder(
            animation: _formController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _formSlide.value),
                child: Opacity(
                  opacity: _formOpacity.value,
                  child: child,
                ),
              );
            },
            child: Consumer(
              builder: (context, ref, _) {
                final authState = ref.watch(authProvider);
                return Column(
                  children: [
                    _tabController.index == 0
                        ? _buildLoginForm(authState, ref)
                        : _buildRegisterForm(authState, ref),
                    // Error message
                    if (authState.error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBar(authState.error!),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00D1FF), Color(0xFF0099CC)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D1FF).withOpacity(0.35),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 14),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white38,
        tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required Color bgColor,
    required Color textColor,
    required Color iconColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with email',
            style: GoogleFonts.inter(color: Colors.white24, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
      ],
    );
  }

  Widget _buildLoginForm(AuthState authState, WidgetRef ref) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(
            controller: _loginEmailController,
            label: 'Email Address',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v!.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _loginPasswordController,
            label: 'Password',
            hint: '••••••••',
            obscure: _obscureLoginPassword,
            onToggle: () =>
                setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            validator: (v) =>
                v!.length >= 6 ? null : 'Minimum 6 characters',
          ),
          const SizedBox(height: 12),
          // Remember me + Forgot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _rememberMe = !_rememberMe),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _rememberMe
                            ? const Color(0xFF00D1FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _rememberMe
                              ? const Color(0xFF00D1FF)
                              : Colors.white20,
                        ),
                      ),
                      child: _rememberMe
                          ? const Icon(Icons.check,
                              size: 13, color: Colors.black)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text('Remember me',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 13)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showForgotPasswordSheet,
                style:
                    TextButton.styleFrom(padding: EdgeInsets.zero),
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF00D1FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton(
            label: 'Sign In',
            isLoading: authState.isLoading,
            onTap: () => _submitLogin(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(AuthState authState, WidgetRef ref) {
    return Form(
      key: _registerFormKey,
      child: Column(
        children: [
          _buildField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'John Doe',
            icon: Icons.person_outline_rounded,
            validator: (v) =>
                v!.isEmpty ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 16),
          _buildField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v!.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            obscure: _obscurePassword,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) =>
                v!.length >= 6 ? null : 'Minimum 6 characters',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: '••••••••',
            obscure: _obscureConfirm,
            onToggle: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            validator: (v) => v == _passwordController.text
                ? null
                : 'Passwords do not match',
          ),
          const SizedBox(height: 20),
          // Terms
          GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _agreedToTerms
                        ? const Color(0xFF00D1FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _agreedToTerms
                          ? const Color(0xFF00D1FF)
                          : Colors.white20,
                    ),
                  ),
                  child: _agreedToTerms
                      ? const Icon(Icons.check, size: 13, color: Colors.black)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                          color: Colors.white38, fontSize: 12),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF00D1FF),
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF00D1FF),
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildPrimaryButton(
            label: 'Create Account',
            isLoading: authState.isLoading,
            onTap: () => _submitRegister(ref),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white18, fontSize: 15),
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF00D1FF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white18, fontSize: 15),
            prefixIcon:
                const Icon(Icons.lock_outline_rounded, color: Colors.white24, size: 20),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white24,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFF00D1FF), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(
      {required String label,
      required bool isLoading,
      required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: EdgeInsets.zero,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isLoading
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF00D1FF), Color(0xFF0099BB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: isLoading ? Colors.white10 : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isLoading
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF00D1FF).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white60),
                  )
                : Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBar(String error) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error.replaceAll('Exception: ', ''),
              style: GoogleFonts.inter(
                  color: const Color(0xFFEF4444), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Handlers ───────────────────────────────────────────

  void _handleGoogleSignIn() {
    _showComingSoonSnack('Google Sign-In coming soon. Configure OAuth to enable.');
  }

  void _handleAppleSignIn() {
    _showComingSoonSnack('Apple Sign-In coming soon. Configure Sign in with Apple to enable.');
  }

  void _showComingSoonSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: const Color(0xFF1E2832),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: const Color(0xFF00D1FF),
          onPressed: () {},
        ),
      ),
    );
  }

  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Reset Password',
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Enter your email address and we\'ll send a reset link.',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.mail_outline,
                    color: Colors.white24, size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF00D1FF), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showComingSoonSnack('Password reset email sent (demo mode).');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D1FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Send Reset Link',
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogin(WidgetRef ref) async {
    if (!_loginFormKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).login(
          _loginEmailController.text.trim(),
          _loginPasswordController.text,
        );
    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    }
  }

  Future<void> _submitRegister(WidgetRef ref) async {
    if (!_registerFormKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showComingSoonSnack('Please agree to the Terms of Service to continue.');
      return;
    }
    final success = await ref.read(authProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created! Please sign in.',
              style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _tabController.animateTo(0);
    }
  }
}
