import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';
import 'review_photo_uploader.dart';

/// A picture chosen for the profile, read into memory so it can be sent.
class ProfilePhoto {
  const ProfilePhoto(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Asks for one picture from the gallery or the camera; null when cancelled or
/// when the phone refuses (no camera, permission denied).
Future<ProfilePhoto?> pickProfilePhoto(ImageSource source) async {
  try {
    final file = await ImagePicker().pickImage(
      source: source,
      // A profile picture is shown small; no need to send more.
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file == null) return null;
    return ProfilePhoto(file.name, await file.readAsBytes());
  } catch (_) {
    return null;
  }
}

/// Sends a profile picture to the shop's Cloudinary account and returns its
/// address. Like [ReviewPhotoUploader] it uses its own plain [Dio], so the
/// shop's API token never goes to another service; the preset holds the rules.
class ProfilePhotoUploader {
  ProfilePhotoUploader({Dio? dio})
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

  /// Throws if the upload fails or the answer has no address.
  Future<String> upload(Uint8List bytes, {String filename = 'avatar.jpg'}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ReviewPhotoUploader.endpoint,
      data: FormData.fromMap({
        'upload_preset': AppConstants.avatarUploadPreset,
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
