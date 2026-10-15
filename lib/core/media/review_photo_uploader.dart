import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Sends one picture to the shop's Cloudinary account and returns its address.
///
/// Uses its own plain [Dio]: the shop's API token must never go to another
/// service. The unsigned preset holds all the rules (folder, pictures only,
/// largest size); nothing secret is in the app.
class ReviewPhotoUploader {
  ReviewPhotoUploader({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final Dio _dio;

  static String get endpoint =>
      'https://api.cloudinary.com/v1_1/${AppConstants.cloudinaryCloud}/image/upload';

  /// Throws if the upload fails or the answer has no address.
  Future<String> upload(Uint8List bytes, {String filename = 'photo.jpg'}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: FormData.fromMap({
        'upload_preset': AppConstants.reviewUploadPreset,
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final url = res.data?['secure_url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('Cloudinary sent no address');
    }
    return url;
  }
}
