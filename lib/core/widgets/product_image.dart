import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Product photography on a neutral backdrop.
///
/// * Photos are network images (`http...`) served by the Vellora API.
/// * Lifestyle shots fill the frame (`cover`); plain-background packshots are
///   shown whole (`contain`) and blended into the backdrop so nothing is
///   cropped. Override with [fit].
/// * Failures fall back to a quiet placeholder icon — never a broken image.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.path,
    this.fit,
    this.padding,
    this.semanticLabel,
  });

  final String path;
  final BoxFit? fit;
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;

  static bool _isNetwork(String p) => p.startsWith('http');

  @override
  Widget build(BuildContext context) {
    // The API tags plain-background product shots with `?packshot=1`.
    final packshot = path.contains('packshot=1');
    final effectiveFit = fit ?? (packshot ? BoxFit.contain : BoxFit.cover);
    final backdrop = packshot
        ? const Color(0xFFF1F2F6)
        : context.vellora.imageBackdrop;
    final contain = effectiveFit == BoxFit.contain;

    final Widget image = _isNetwork(path)
        ? CachedNetworkImage(
            imageUrl: path,
            fit: effectiveFit,
            fadeInDuration: const Duration(milliseconds: 220),
            placeholder: (_, _) => ColoredBox(color: backdrop),
            errorWidget: (_, _, _) => _Fallback(color: backdrop),
          )
        : _Fallback(color: backdrop);

    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: ColoredBox(
        color: backdrop,
        child: Padding(
          padding: padding ??
              (contain ? const EdgeInsets.all(10) : EdgeInsets.zero),
          child: SizedBox.expand(child: image),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: context.colors.outline,
          size: 28,
        ),
      ),
    );
  }
}
