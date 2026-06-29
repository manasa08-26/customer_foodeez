import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/auth_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/auth_brand_header.dart';
import '../../widgets/common/responsive_page.dart';

/// Phone OTP reset password — mirrors web /customer/auth/reset-password.
class ResetPasswordView extends ConsumerStatefulWidget {
  const ResetPasswordView({super.key});

  @override
  ConsumerState<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends ConsumerState<ResetPasswordView> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _otpStep = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendOtp(
            phone: phone,
            purpose: OtpPurpose.resetPassword,
          );
      if (mounted) setState(() => _otpStep = true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_passCtrl.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            phone: _phoneCtrl.text.trim(),
            otp: _otpCtrl.text.trim(),
            newPassword: _passCtrl.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      context.go(RoutePaths.login);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptive.background,
      body: SafeArea(
        child: ResponsivePage(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AuthBrandHeader(
                    subtitle: 'RESET PASSWORD',
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  Text(
                    'Reset password',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppDimensions.spacingLg),
                  if (!_otpStep) ...[
                    AppTextField(
                      controller: _phoneCtrl,
                      label: 'Phone number',
                      hint: '+91 98765 43210',
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    AppButton(
                      label: _loading ? 'Sending…' : 'Send OTP',
                      isLoading: _loading,
                      onPressed: _sendOtp,
                    ),
                  ] else ...[
                    AppTextField(
                      controller: _otpCtrl,
                      label: 'OTP',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    AppTextField(
                      controller: _passCtrl,
                      label: 'New password',
                      obscureText: true,
                      prefixIcon: Icons.password_outlined,
                    ),
                    const SizedBox(height: AppDimensions.spacingSm),
                    AppTextField(
                      controller: _confirmCtrl,
                      label: 'Confirm password',
                      obscureText: true,
                      prefixIcon: Icons.password_outlined,
                    ),
                    const SizedBox(height: AppDimensions.spacingMd),
                    AppButton(
                      label: _loading ? 'Updating…' : 'Reset password',
                      isLoading: _loading,
                      onPressed: _reset,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppDimensions.spacingMd),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacingMd),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: const Text('Back to sign in'),
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
