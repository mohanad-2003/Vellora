import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/media/cloudinary_url.dart';

/// Circular user avatar that renders [avatarUrl] when available, otherwise the
/// user's initials on a primary-colored disc. Optionally shows an edit badge.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 64,
    this.editable = false,
    this.onEdit,
    this.busy = false,
  });

  final String name;
  final String? avatarUrl;
  final double size;
  final bool editable;
  final VoidCallback? onEdit;

  /// A picture is being uploaded: the badge gives way to a spinner.
  final bool busy;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle),
      child: hasImage
          ? Image.network(
              avatarThumb(avatarUrl!, size: (size * 3).round()),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _initialsLabel(context),
            )
          : _initialsLabel(context),
    );

    if (!editable) return avatar;

    return Stack(
      children: [
        avatar,
        if (busy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x73000000),
              ),
              child: Center(
                child: SizedBox.square(
                  dimension: size * 0.32,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        Positioned.directional(
          textDirection: Directionality.of(context),
          end: 0,
          bottom: 0,
          child: Semantics(
            button: true,
            label: context.l10n.changePhoto,
            excludeSemantics: true,
            onTap: busy ? null : onEdit,
            child: GestureDetector(
              onTap: busy ? null : onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: colors.onPrimary,
              ),
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _initialsLabel(BuildContext context) {
    return Text(
      _initials,
      style: TextStyle(
        color: context.colors.onPrimary,
        fontWeight: FontWeight.w700,
        fontSize: size * 0.34,
      ),
    );
  }
}
