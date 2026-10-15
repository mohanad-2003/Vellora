import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vellora/core/localization/l10n/app_localizations.dart';
import 'package:vellora/core/media/review_photo_uploader.dart';
import 'package:vellora/core/network/api_mappers.dart';
import 'package:vellora/core/theme/app_theme.dart';
import 'package:vellora/features/product/presentation/widgets/write_review_sheet.dart';

/// A real 1x1 picture, so the thumbnails can be decoded.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

String _address(String name) =>
    'https://res.cloudinary.com/oswjzdto/image/upload/v1/$name';

Widget _host(Widget child) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

/// The sheet shows a spinner while it works (and stays that way here, where nothing closes it),
/// so a few frames are pumped instead of waiting for the screen to settle.
Future<void> _afterSend(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('writing a review with photos', () {
    late List<List<String>> sent;
    late List<String> uploads;
    late int picks;
    late Set<String> failing;

    Widget sheet() => _host(
          WriteReviewSheet(
            pickPhoto: () async => PickedPhoto('p${++picks}.jpg', _png),
            uploadPhoto: (photo) async {
              if (failing.contains(photo.name)) throw Exception('offline');
              uploads.add(photo.name);
              return _address(photo.name);
            },
            onSubmit: (rating, comment, photos) async {
              sent.add(photos);
              return null;
            },
            onDone: () {},
          ),
        );

    setUp(() {
      sent = [];
      uploads = [];
      picks = 0;
      failing = {};
    });

    Future<void> addPhotos(WidgetTester tester, int n) async {
      for (var i = 0; i < n; i++) {
        await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
        await tester.pumpAndSettle();
      }
    }

    Future<void> fillAndSend(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Lovely lamp');
      await tester.tap(find.text('Submit review'));
      await _afterSend(tester);
    }

    testWidgets('at most three pictures, uploaded and sent with the review', (tester) async {
      await tester.pumpWidget(sheet());
      expect(find.text('Up to 3 pictures'), findsOneWidget);

      await addPhotos(tester, 3);
      expect(find.byType(Image), findsNWidgets(3));
      expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing, reason: 'the limit is reached');

      await fillAndSend(tester);
      expect(uploads, ['p1.jpg', 'p2.jpg', 'p3.jpg']);
      expect(sent.single, [_address('p1.jpg'), _address('p2.jpg'), _address('p3.jpg')]);
    });

    testWidgets('a picture can be taken off again, and a review needs none', (tester) async {
      await tester.pumpWidget(sheet());
      await addPhotos(tester, 1);
      expect(find.byType(Image), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNothing);

      await fillAndSend(tester);
      expect(uploads, isEmpty);
      expect(sent.single, isEmpty);
    });

    testWidgets('a failed upload saves nothing, and a retry only uploads what is missing', (tester) async {
      failing = {'p2.jpg'};
      await tester.pumpWidget(sheet());
      await addPhotos(tester, 2);

      await fillAndSend(tester);
      expect(sent, isEmpty, reason: 'nothing is saved without its pictures');
      expect(find.text('Could not upload the photos. Check your connection and try again.'), findsOneWidget);
      expect(uploads, ['p1.jpg']);

      failing = {};
      await tester.tap(find.text('Submit review'));
      await _afterSend(tester);
      expect(sent.single, [_address('p1.jpg'), _address('p2.jpg')]);
      expect(uploads, ['p1.jpg', 'p2.jpg'], reason: 'the first was not sent twice');
    });
  });

  test('a review brings its photos from the API (none for older reviews)', () {
    final withPhotos = ApiMappers.review({
      'author': 'Sara',
      'rating': 5,
      'comment': 'Great',
      'createdAt': '2026-10-14T10:00:00.000Z',
      'photos': [_address('a.jpg')],
    });
    expect(withPhotos.photos, [_address('a.jpg')]);

    final older = ApiMappers.review({
      'author': 'Sam',
      'rating': 4,
      'comment': 'Fine',
      'createdAt': '2026-10-14T10:00:00.000Z',
    });
    expect(older.photos, isEmpty);
  });

  group('the Cloudinary upload', () {
    Dio shop(Response<dynamic> Function(RequestOptions) reply, void Function(RequestOptions) seen) => Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            seen(options);
            handler.resolve(reply(options));
          },
        ),
      );

    test('goes to the shop account with the preset and returns the secure address', () async {
      RequestOptions? seen;
      final dio = shop(
        (o) => Response(requestOptions: o, statusCode: 200, data: <String, dynamic>{'secure_url': _address('x.jpg')}),
        (o) => seen = o,
      );

      final url = await ReviewPhotoUploader(dio: dio).upload(_png, filename: 'x.jpg');

      expect(url, _address('x.jpg'));
      expect(seen!.uri.toString(), 'https://api.cloudinary.com/v1_1/oswjzdto/image/upload');
      final form = seen!.data as FormData;
      expect(Map.fromEntries(form.fields)['upload_preset'], 'vellora_reviews');
      expect(form.files.single.key, 'file');
      expect(seen!.headers.containsKey('Authorization'), isFalse, reason: 'the shop token never goes to another service');
    });

    test('an answer without an address is an error', () async {
      final dio = shop(
        (o) => Response(requestOptions: o, statusCode: 200, data: <String, dynamic>{}),
        (_) {},
      );
      await expectLater(ReviewPhotoUploader(dio: dio).upload(_png), throwsA(isA<FormatException>()));
    });
  });
}
