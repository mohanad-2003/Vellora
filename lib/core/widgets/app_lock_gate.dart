import 'package:flutter/material.dart';

import '../di/injection.dart';
import '../extensions/context_extensions.dart';
import '../security/biometric_service.dart';
import '../theme/app_spacing.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/user_session_cubit.dart';
import 'app_button.dart';
import 'vellora_logo.dart';

/// Covers the app with a lock screen until the user passes the fingerprint or
/// face check, when they turned biometric login on for the signed-in account.
///
/// It locks on a cold start and when the app returns from the background after
/// [lockAfter]. The system prompt itself backgrounds the app briefly, so
/// lifecycle changes while it is showing are ignored.
class AppLockGate extends StatefulWidget {
  const AppLockGate({
    super.key,
    required this.child,
    this.lockAfter = const Duration(seconds: 30),
  });

  final Widget child;
  final Duration lockAfter;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final _service = sl<BiometricService>();
  late bool _locked = _shouldLock();
  bool _authenticating = false;
  DateTime? _leftAt;

  bool _shouldLock() =>
      _service.isEnabledFor(sl<UserSessionCubit>().state?.email);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _leftAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        if (left != null &&
            DateTime.now().difference(left) >= widget.lockAfter &&
            _shouldLock() &&
            !_locked) {
          setState(() => _locked = true);
          _unlock();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    _authenticating = true;
    final ok = await _service.authenticate(context.l10n.biometricUnlockReason);
    _authenticating = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  Future<void> _signOut() async {
    await sl<AuthRepository>().logout();
    if (mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: _LockScreen(onUnlock: _unlock, onSignOut: _signOut),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.onUnlock, required this.onSignOut});

  final VoidCallback onUnlock;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: context.colors.surface,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: VelloraMark(size: 84, glow: true)),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.appLockedTitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.appLockedBody,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: l10n.unlock,
                    icon: Icons.fingerprint_rounded,
                    onPressed: onUnlock,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.logout,
                    variant: AppButtonVariant.text,
                    onPressed: onSignOut,
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
