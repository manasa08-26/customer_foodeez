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

/// Email OTP login — matches web /customer/auth/login flow.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpStep = false;
  bool _loading = false;
  String? _error;
  String? _status;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
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
        _otpStep = true;
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
    if (_otpCtrl.text.trim().length < 4) {
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
            _otpCtrl.text.trim(),
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
                          'Sign in',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppDimensions.spacingXl),
                        if (!_otpStep) ...[
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'Email address',
                            hint: 'you@example.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                        ] else ...[
                          Text(
                            'OTP sent to the mobile linked to ${_emailCtrl.text}',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppDimensions.spacingMd),
                          AppTextField(
                            controller: _otpCtrl,
                            label: 'One-time password',
                            hint: 'Enter OTP',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: AppDimensions.spacingSm),
                          Text(
                            _error!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.error),
                          ),
                        ],
                        if (_status != null) ...[
                          const SizedBox(height: AppDimensions.spacingSm),
                          Text(
                            _status!,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: AppDimensions.spacingLg),
                        AppButton(
                          label: _otpStep
                              ? (_loading ? 'Verifying…' : 'Sign in')
                              : (_loading ? 'Sending…' : 'Send OTP'),
                          isLoading: _loading,
                          onPressed: _otpStep ? _login : _sendOtp,
                        ),
                        if (_otpStep) ...[
                          const SizedBox(height: AppDimensions.spacingSm),
                          AppButton(
                            label: 'Change email',
                            variant: AppButtonVariant.outline,
                            onPressed: _loading
                                ? null
                                : () => setState(() {
                                      _otpStep = false;
                                      _otpCtrl.clear();
                                      _error = null;
                                      _status = null;
                                    }),
                          ),
                        ],
                        const SizedBox(height: AppDimensions.spacingMd),
                        TextButton(
                          onPressed: () => context.push(RoutePaths.resetPassword),
                          child: const Text('Forgot password?'),
                        ),
                        TextButton(
                          onPressed: () => context.push(RoutePaths.signup),
                          child: const Text('Create an account'),
                        ),
                        TextButton(
                          onPressed: () => context.go(RoutePaths.discovery),
                          child: const Text('Browse without signing in'),
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
