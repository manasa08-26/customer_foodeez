import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/auth_model.dart';
import '../../widgets/common/customer_logo.dart';
import '../../widgets/common/google_icon.dart';
import '../../router/app_router.dart';
import '../../router/route_paths.dart';

/// Sign-in — purple header + white sheet, OTP flow behind email/OTP fields.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  bool _rememberMe = false;
  bool _obscureSecret = true;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _status = 'Sending OTP…';
    });
    try {
      await ref.read(authControllerProvider.notifier).sendOtp(
            _emailCtrl.text.trim(),
            OtpPurpose.login,
          );
      setState(() {
        _otpSent = true;
        _secretCtrl.clear();
        _status = 'OTP sent to your registered mobile number.';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to send OTP. Check your email.');
    } finally {
      setState(() {
        _loading = false;
        if (_error != null) _status = null;
      });
    }
  }

  Future<void> _login() async {
    if (_secretCtrl.text.trim().length < 4) {
      setState(() => _error = 'Enter a valid OTP');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            _emailCtrl.text.trim(),
            _secretCtrl.text.trim(),
          );
      if (!mounted) return;
      navigateAfterAuth(context, ref);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSignIn() async {
    if (!_otpSent) {
      await _sendOtp();
    } else {
      await _login();
    }
  }

  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider sign-in coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secretLabel = _otpSent ? 'One-time password' : 'Password';
    final secretHint =
        _otpSent ? 'Enter OTP' : 'Enter password or tap Sign in for OTP';
    final topInset = MediaQuery.paddingOf(context).top;
    final sheetTop = topInset + 148;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryLight,
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: AppDimensions.spacingMd),
                    Container(
                      width: CustomerLogoSizes.splashIconBox,
                      height: CustomerLogoSizes.splashIconBox,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const CustomerLogo.splashIcon(
                        asset: AppAssets.customerLight,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    Text(
                      'CUSTOMER APP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                        letterSpacing: 2.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: sheetTop,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spacingXl,
                  AppDimensions.spacingMd,
                  AppDimensions.spacingXl,
                  AppDimensions.spacingLg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXs),
                      Text(
                        'Sign in to keep the cravings coming.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingLg),
                      _AuthField(
                        controller: _emailCtrl,
                        hint: 'Email address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_loading,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      _AuthField(
                        controller: _secretCtrl,
                        hint: secretHint,
                        label: secretLabel,
                        icon: Icons.lock_outline_rounded,
                        keyboardType:
                            _otpSent ? TextInputType.number : TextInputType.text,
                        obscureText: _obscureSecret && !_otpSent,
                        enabled: !_loading,
                        maxLength: _otpSent ? 6 : null,
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscureSecret = !_obscureSecret,
                          ),
                          icon: Icon(
                            _obscureSecret
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: _loading
                                  ? null
                                  : (v) =>
                                      setState(() => _rememberMe = v ?? false),
                              activeColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingXs),
                          Text(
                            'Remember me',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () => context.push(RoutePaths.resetPassword),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppDimensions.spacingSm),
                        Text(
                          _error!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                      if (_status != null) ...[
                        const SizedBox(height: AppDimensions.spacingSm),
                        Text(
                          _status!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingLg),
                      _GradientSignInButton(
                        label: _loading
                            ? (_otpSent ? 'Verifying…' : 'Sending…')
                            : 'Sign in',
                        loading: _loading,
                        onPressed: _loading ? null : _onSignIn,
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: AppDimensions.spacingSm),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _otpSent = false;
                                    _secretCtrl.clear();
                                    _error = null;
                                    _status = null;
                                  }),
                          child: const Text('Change email'),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingLg),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR CONTINUE WITH',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHint,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              label: 'Google',
                              icon: const GoogleIcon(),
                              onPressed: () => _showComingSoon('Google'),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.spacingMd),
                          Expanded(
                            child: _SocialButton(
                              label: 'Apple',
                              icon: const Icon(
                                Icons.apple,
                                size: 20,
                                color: AppColors.textPrimary,
                              ),
                              onPressed: () => _showComingSoon('Apple'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'New here?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push(RoutePaths.signup),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Create an account',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go(RoutePaths.discovery),
                          child: Text(
                            'Browse without signing in',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.textHint,
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
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.label,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLength,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLength;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      maxLength: maxLength,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        labelText: label,
        counterText: maxLength != null ? '' : null,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F7FB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _GradientSignInButton extends StatelessWidget {
  const _GradientSignInButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 52,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
