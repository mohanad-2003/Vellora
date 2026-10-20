import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vellora/core/errors/failures.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/media/cloudinary_url.dart';
import 'package:vellora/core/media/profile_photo.dart';
import 'package:vellora/features/auth/domain/entities/user_entity.dart';
import 'package:vellora/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:vellora/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:vellora/features/profile/presentation/widgets/profile_avatar.dart';

class _MockUpdateProfile extends Mock implements UpdateProfileUseCase {}

class _MockUpdateAvatar extends Mock implements UpdateAvatarUseCase {}

class _FakeUploader implements ProfilePhotoUploader {
  _FakeUploader({this.fail = false});

  final bool fail;
  int uploads = 0;

  @override
  Future<String> upload(Uint8List bytes, {String filename = 'avatar.jpg'}) async {
    uploads++;
    if (fail) throw StateError('offline');
    return 'https://res.cloudinary.com/oswjzdto/image/upload/v1/avatars/new.jpg';
  }
}

void main() {
  testWidgets('while uploading, the avatar shows a spinner and ignores taps',
      (tester) async {
    var taps = 0;
    Future<void> show({required bool busy}) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Scaffold(
          body: Center(
            child: ProfileAvatar(
              name: 'Sara B',
              editable: true,
              busy: busy,
              onEdit: () => taps++,
            ),
          ),
        ),
      ),
    );

    await show(busy: false);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    expect(taps, 1);

    await show(busy: true);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byIcon(Icons.camera_alt_rounded));
    expect(taps, 1);
  });

  group('avatarThumb', () {
    const url = 'https://res.cloudinary.com/oswjzdto/image/upload/v12/avatars/a.jpg';

    test('asks Cloudinary for a small face-centred square', () {
      expect(
        avatarThumb(url, size: 128),
        'https://res.cloudinary.com/oswjzdto/image/upload/'
        'c_fill,g_face,w_128,h_128,f_auto,q_auto/v12/avatars/a.jpg',
      );
    });

    test('leaves other addresses alone', () {
      expect(avatarThumb('https://example.com/me.jpg'), 'https://example.com/me.jpg');
      expect(avatarThumb(''), '');
    });
  });

  group('EditProfileCubit picture', () {
    late _MockUpdateAvatar updateAvatar;
    late EditProfileCubit cubit;
    final bytes = Uint8List.fromList([1, 2, 3]);
    const saved = UserEntity(
      id: '1',
      name: 'Sara',
      email: 's@t.com',
      avatarUrl: 'https://res.cloudinary.com/oswjzdto/image/upload/v1/avatars/new.jpg',
    );

    setUp(() {
      updateAvatar = _MockUpdateAvatar();
      cubit = EditProfileCubit(_MockUpdateProfile(), updateAvatar);
    });
    tearDown(() => cubit.close());

    test('uploads, then saves the address on the account', () async {
      final uploader = _FakeUploader();
      cubit.uploader = uploader;
      when(() => updateAvatar(any())).thenAnswer((_) async => const Right(saved));

      final r = await cubit.changeAvatar(bytes);

      expect(r.failureKey, isNull);
      expect(r.url, saved.avatarUrl);
      expect(uploader.uploads, 1);
      verify(() => updateAvatar(saved.avatarUrl)).called(1);
    });

    test('a failed upload never touches the account', () async {
      cubit.uploader = _FakeUploader(fail: true);

      final r = await cubit.changeAvatar(bytes);

      expect(r.failureKey, 'photoUploadFailed');
      verifyNever(() => updateAvatar(any()));
    });

    test('a refusal from the server is reported', () async {
      cubit.uploader = _FakeUploader();
      when(() => updateAvatar(any())).thenAnswer(
        (_) async => const Left(Failure.server(message: 'no')),
      );

      final r = await cubit.changeAvatar(bytes);

      expect(r.failureKey, isNotNull);
      expect(r.url, isNull);
    });

    test('removing saves a null address', () async {
      when(() => updateAvatar(null)).thenAnswer(
        (_) async => const Right(UserEntity(id: '1', name: 'Sara', email: 's@t.com')),
      );

      final r = await cubit.removeAvatar();

      expect(r.failureKey, isNull);
      expect(r.url, isNull);
      verify(() => updateAvatar(null)).called(1);
    });
  });
}
