import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/routing/route_names.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/app_bar_widget.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/auth_error_banner.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/otp_input_field.dart';
import 'package:vellora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vellora/features/auth/presentation/widgets/auth_header.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const _resendSeconds = 30;

  String _code = '';
  bool _hasError = false;
  bool _bannerVisible = false;
  Timer? _timer;
  int _remaining = _resendSeconds;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _remaining = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 1) {
        t.cancel();
        setState(() => _remaining = 0);
      } else {
        setState(() => _remaining -= 1);
      }
    });
  }

  void _resend(BuildContext context, String email) {
    context.read<AuthBloc>().add(AuthForgotPasswordRequested(email: email));
    _startTimer();
    AppSnackbar.show(context, message: context.l10n.resendCode);
  }

  void _verify(BuildContext context) {
    context.hideKeyboard();
    if (_code.length < AppConstants.otpLength) return;
    setState(() {
      _hasError = false;
      _bannerVisible = false;
    });
    context.read<AuthBloc>().add(AuthOtpVerifyRequested(code: _code));
  }

  String get _timerLabel {
    final m = (_remaining ~/ 60).toString();
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: const AppBarWidget(),
      body: SafeArea(
        top: false,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.otpVerified) {
              context.pushNamed(RouteNames.nCreateNewPassword);
            } else if (state.status == AuthStatus.failure) {
              setState(() {
                _hasError = true;
                _bannerVisible = true;
              });
              AppSnackbar.error(context, l10n.invalidOtp);
            }
          },
          builder: (context, state) {
            final email = state.pendingEmail ?? '';
            return ResponsiveCenter(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                  vertical: AppSpacing.vSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(
                      icon: Icons.mark_email_read_outlined,
                      title: l10n.otpTitle,
                      subtitle: '${l10n.otpSubtitle} $email',
                    ),
                    if (_bannerVisible)
                      AuthErrorBanner(
                        failureKey: 'invalidOtp',
                        onDismiss: () => setState(() => _bannerVisible = false),
                      ),
                    SizedBox(height: AppSpacing.vLg),
                    OtpInputField(
                      hasError: _hasError,
                      onChanged: (v) => _code = v,
                      onCompleted: (v) {
                        _code = v;
                        _verify(context);
                      },
                    ),
                    SizedBox(height: AppSpacing.vXxl),
                    AppButton(
                      label: l10n.verify,
                      isLoading: state.isLoading,
                      onPressed: () => _verify(context),
                    ),
                    SizedBox(height: AppSpacing.vXl),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          l10n.didntReceiveCode,
                          style: context.textTheme.bodyMedium,
                        ),
                        _remaining > 0
                            ? Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: AppSpacing.sm,
                                ),
                                child: Text(
                                  l10n.resendIn(_timerLabel),
                                  style: context.textTheme.labelMedium
                                      ?.copyWith(
                                        color: context.colors.onSurfaceVariant,
                                      ),
                                ),
                              )
                            : TextButton(
                                onPressed: () => _resend(context, email),
                                child: Text(l10n.resendCode),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
