import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/media/review_photo_uploader.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/app_text_field.dart';
import 'package:vellora/core/widgets/auth_error_banner.dart';

/// A picture chosen for a review, read into memory so it can be shown and sent.
class PickedPhoto {
  const PickedPhoto(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// Asks the shopper for one picture from the gallery; null when they cancel.
Future<PickedPhoto?> pickReviewPhoto() async {
  try {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Smaller pictures upload faster and cost the shop less to keep.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return PickedPhoto(file.name, await file.readAsBytes());
  } catch (_) {
    return null;
  }
}

/// Bottom-sheet form for writing a product review: pick 1-5 stars, add a
/// comment and up to [AppConstants.maxReviewPhotos] pictures. The pictures are
/// uploaded when the review is sent. [onSubmit] returns a failure key, or null
/// once the review is saved.
class WriteReviewSheet extends StatefulWidget {
  const WriteReviewSheet({
    super.key,
    required this.onSubmit,
    required this.onDone,
    this.pickPhoto,
    this.uploadPhoto,
  });

  final Future<String?> Function(
    int rating,
    String comment,
    List<String> photos,
  )
  onSubmit;
  final VoidCallback onDone;

  /// Chooses a picture; defaults to the gallery.
  final Future<PickedPhoto?> Function()? pickPhoto;

  /// Uploads a picture and returns its address; defaults to Cloudinary.
  final Future<String> Function(PickedPhoto photo)? uploadPhoto;

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _busy = false;
  String? _fieldError;
  String? _failure;
  final List<PickedPhoto> _photos = [];

  /// Pictures already uploaded, so a retry does not send them twice.
  final Map<PickedPhoto, String> _uploaded = {};

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_busy || _photos.length >= AppConstants.maxReviewPhotos) return;
    final photo = await (widget.pickPhoto ?? pickReviewPhoto)();
    if (photo == null || !mounted) return;
    setState(() {
      _photos.add(photo);
      _failure = null;
    });
  }

  void _removePhoto(PickedPhoto photo) {
    if (_busy) return;
    setState(() {
      _photos.remove(photo);
      _uploaded.remove(photo);
    });
  }

  /// The addresses of all chosen pictures, uploading the ones not sent yet.
  /// Null when an upload failed (the ones that went through are kept).
  Future<List<String>?> _uploadPhotos() async {
    final upload =
        widget.uploadPhoto ??
        (PickedPhoto p) =>
            ReviewPhotoUploader().upload(p.bytes, filename: p.name);
    try {
      for (final photo in _photos) {
        _uploaded[photo] ??= await upload(photo);
      }
    } catch (_) {
      return null;
    }
    return [for (final p in _photos) _uploaded[p]!];
  }

  Future<void> _submit() async {
    final text = _comment.text.trim();
    String? problem;
    if (_rating == 0) {
      problem = 'ratingRequired';
    } else if (text.length < 3) {
      problem = 'reviewTooShort';
    }
    if (problem != null) {
      setState(() => _fieldError = problem);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
      _failure = null;
    });
    final urls = await _uploadPhotos();
    if (!mounted) return;
    if (urls == null) {
      setState(() {
        _busy = false;
        _failure = 'photoUploadFailed';
      });
      return;
    }
    final failure = await widget.onSubmit(_rating, text, urls);
    if (!mounted) return;
    if (failure == null) {
      widget.onDone();
    } else {
      setState(() {
        _busy = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.writeReview,
          style: context.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_failure != null) ...[
          AuthErrorBanner(
            failureKey: _failure!,
            onDismiss: () => setState(() => _failure = null),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Text(l10n.yourRating, style: context.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              Semantics(
                button: true,
                selected: i <= _rating,
                label: '$i',
                child: IconButton(
                  iconSize: 36,
                  // 48dp touch target around each star.
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: _busy
                      ? null
                      : () {
                          Haptics.selection();
                          setState(() {
                            _rating = i;
                            _fieldError = null;
                          });
                        },
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i <= _rating ? Colors.amber : colors.outline,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _comment,
          label: l10n.yourReview,
          hint: l10n.reviewHint,
          prefixIcon: Icons.rate_review_outlined,
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.addPhotos, style: context.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final photo in _photos)
              _PhotoThumb(photo: photo, onRemove: () => _removePhoto(photo)),
            if (_photos.length < AppConstants.maxReviewPhotos)
              Semantics(
                button: true,
                label: l10n.addPhotos,
                child: InkWell(
                  onTap: _busy ? null : _addPhoto,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            Text(l10n.photosHint, style: context.textTheme.bodySmall),
          ],
        ),
        if (_fieldError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            tr(context, _fieldError!),
            style: context.textTheme.bodySmall?.copyWith(color: colors.error),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: l10n.submitReview,
          icon: Icons.send_rounded,
          isLoading: _busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// A chosen picture with a button to take it off again.
class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.photo, required this.onRemove});

  final PickedPhoto photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(photo.bytes, fit: BoxFit.cover),
          ),
          PositionedDirectional(
            top: 2,
            end: 2,
            child: Semantics(
              button: true,
              label: context.l10n.removePhoto,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
