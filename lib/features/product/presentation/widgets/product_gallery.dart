import 'package:flutter/material.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/widgets/app_icon_button.dart';
import 'package:vellora/core/widgets/product_image.dart';

/// Swipeable product photo gallery with a page indicator and tap-to-zoom.
/// The first photo carries the [heroTag] shared with the card it came from.
class ProductGallery extends StatefulWidget {
  const ProductGallery({
    super.key,
    required this.images,
    this.heroTag,
    this.semanticLabel,
  });

  final List<String> images;
  final Object? heroTag;
  final String? semanticLabel;

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openZoom(int start) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) =>
            _ZoomViewer(images: widget.images, initialIndex: start),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            Widget photo = ProductImage(
              path: widget.images[i],
              semanticLabel: widget.semanticLabel,
            );
            if (i == 0 && widget.heroTag != null) {
              photo = Hero(tag: widget.heroTag!, child: photo);
            }
            return GestureDetector(onTap: () => _openZoom(i), child: photo);
          },
        ),
        if (widget.images.length > 1)
          PositionedDirectional(
            bottom: 14,
            start: 0,
            end: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? context.colors.primary
                        : context.colors.onSurface.withValues(alpha: 0.25),
                    borderRadius: AppRadius.rPill,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Full-screen pinch-to-zoom viewer.
class _ZoomViewer extends StatefulWidget {
  const _ZoomViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ZoomViewer> createState() => _ZoomViewerState();
}

class _ZoomViewerState extends State<_ZoomViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialIndex,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Product shots are on a plain, light background: show them on one.
    return Scaffold(
      backgroundColor: context.vellora.imageBackdrop,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  widget.images[i],
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, _, _) => Icon(
                    Icons.image_not_supported_outlined,
                    color: context.colors.outline,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: AppIconButton(
                icon: Icons.close_rounded,
                semanticLabel: MaterialLocalizations.of(
                  context,
                ).closeButtonLabel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
