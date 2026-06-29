import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/auth_model.dart';
import '../../router/app_router.dart';
import '../../router/route_paths.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/auth_brand_header.dart';

/// Signup with email OTP — matches web /customer/auth/signup.
class SignupView extends ConsumerStatefulWidget {
  const SignupView({super.key});

  @override
  ConsumerState<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends ConsumerState<SignupView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).sendOtp(
            _emailCtrl.text.trim(),
            OtpPurpose.signup,
          );
      setState(() => _otpSent = true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to send OTP');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signup(
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            otp: _otpCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
          );
      if (!mounted) return;
      navigateAfterAuth(context, ref);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Signup failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptive.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.spacingXl),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AuthBrandHeader(),
                        const SizedBox(height: AppDimensions.spacingLg),
                        Text(
                          'Create account',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppDimensions.spacingXl),
                        AppTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        AppTextField(
                          controller: _nameCtrl,
                          label: 'Full name',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        AppTextField(
                          controller: _phoneCtrl,
                          label: 'Phone',
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: AppDimensions.spacingMd),
                          AppTextField(
                            controller: _otpCtrl,
                            label: 'OTP',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (v) =>
                                v == null || v.length < 4 ? 'Enter OTP' : null,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: AppDimensions.spacingSm),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                        const SizedBox(height: AppDimensions.spacingLg),
                        if (!_otpSent)
                          AppButton(
                            label: 'Send OTP',
                            isLoading: _loading,
                            onPressed: _sendOtp,
                          )
                        else
                          AppButton(
                            label: 'Sign up',
                            isLoading: _loading,
                            onPressed: _signup,
                          ),
                        TextButton(
                          onPressed: () => context.go(RoutePaths.login),
                          child: const Text('Already have an account? Sign in'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
