import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:vellora/core/auth/google_id_token.dart';
import 'package:vellora/core/errors/exception_mapper.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/auth/domain/entities/user_entity.dart';
import 'package:vellora/features/auth/domain/repositories/auth_repository.dart';
import 'package:vellora/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:vellora/features/auth/domain/usecases/get_cached_user_usecase.dart';
import 'package:vellora/features/auth/domain/usecases/login_usecase.dart';
import 'package:vellora/features/auth/domain/usecases/logout_usecase.dart';
import 'package:vellora/features/auth/domain/usecases/register_usecase.dart';
import 'package:vellora/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:vellora/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:vellora/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vellora/features/auth/presentation/widgets/social_login_buttons.dart';

class _FakeAuth extends Fake implements AuthRepository {
  String? sentToken;
  Either<Failure, UserEntity> answer = const Right(
    UserEntity(id: 'u1', name: 'Sara', email: 'sara@gmail.com', token: 't'),
  );

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle({
    required String idToken,
  }) async {
    sentToken = idToken;
    return answer;
  }
}

AuthBloc _bloc(_FakeAuth repo) => AuthBloc(
  LoginUseCase(repo),
  RegisterUseCase(repo),
  ForgotPasswordUseCase(repo),
  VerifyOtpUseCase(repo),
  ResetPasswordUseCase(repo),
  GetCachedUserUseCase(repo),
  LogoutUseCase(repo),
);

Widget _app(AuthBloc bloc, Locale locale) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(
    body: BlocProvider.value(
      value: bloc,
      child: const Center(child: SocialLoginButtons()),
    ),
  ),
);

void main() {
  final realSource = googleIdTokenSource;
  tearDown(() => googleIdTokenSource = realSource);

  test('the Google token goes to the server, not the password form', () async {
    final repo = _FakeAuth();
    final result = await LoginUseCase(repo)(
      const LoginParams(email: '', password: '', googleIdToken: 'id-token'),
    );
    expect(result.isRight(), isTrue);
    expect(repo.sentToken, 'id-token');
  });

  test(
    'the bloc signs in with the token, and asks for the code when two-factor is on',
    () async {
      final repo = _FakeAuth();
      final bloc = _bloc(repo);
      bloc.add(const AuthGoogleSubmitted(idToken: 'a'));
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
      expect(bloc.state.user?.email, 'sara@gmail.com');

      repo.answer = const Left(
        Failure.validation(message: 'challenge-1', code: twoFactorRequiredCode),
      );
      bloc.add(const AuthGoogleSubmitted(idToken: 'b'));
      await bloc.stream.firstWhere(
        (s) => s.status == AuthStatus.twoFactorRequired,
      );
      expect(bloc.state.twoFactorToken, 'challenge-1');

      repo.answer = const Left(Failure.network(message: 'offline'));
      bloc.add(const AuthGoogleSubmitted(idToken: 'c'));
      await bloc.stream.firstWhere((s) => s.status == AuthStatus.failure);
      expect(bloc.state.failureKey, isNotNull);
      await bloc.close();
    },
  );

  testWidgets(
    'tapping Google asks Google, then signs in with what it returned',
    (tester) async {
      final repo = _FakeAuth();
      final bloc = _bloc(repo);
      addTearDown(bloc.close);
      googleIdTokenSource = () async => 'token-from-google';
      await tester.pumpWidget(_app(bloc, const Locale('en')));

      await tester.tap(find.bySemanticsLabel('Continue with Google'));
      await tester.pumpAndSettle();
      expect(repo.sentToken, 'token-from-google');
      expect(bloc.state.status, AuthStatus.authenticated);
    },
  );

  testWidgets(
    'closing the account chooser does nothing, a broken Google says so',
    (tester) async {
      final repo = _FakeAuth();
      final bloc = _bloc(repo);
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc, const Locale('en')));

      googleIdTokenSource = () async => null;
      await tester.tap(find.bySemanticsLabel('Continue with Google'));
      await tester.pumpAndSettle();
      expect(repo.sentToken, isNull);
      expect(bloc.state.status, AuthStatus.initial);
      expect(
        find.textContaining('Could not sign in with Google'),
        findsNothing,
      );

      googleIdTokenSource = () async =>
          throw const GoogleSignInUnavailable('misconfigured');
      await tester.tap(find.bySemanticsLabel('Continue with Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(repo.sentToken, isNull);
      expect(
        find.textContaining('Could not sign in with Google'),
        findsOneWidget,
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));
    },
  );

  testWidgets('the other providers are still honest about not being ready', (
    tester,
  ) async {
    final bloc = _bloc(_FakeAuth());
    addTearDown(bloc.close);
    var asked = false;
    googleIdTokenSource = () async {
      asked = true;
      return null;
    };
    await tester.pumpWidget(_app(bloc, const Locale('ar')));
    await tester.tap(find.bySemanticsLabel('المتابعة باستخدام Facebook'));
    await tester.pump();
    expect(asked, isFalse);
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
