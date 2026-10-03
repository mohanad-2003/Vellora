import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_radius.dart';
import 'product_image.dart';

/// Category tile: a photo with the category name beneath it. The tile scales
/// down slightly while pressed.
class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.size = 72,
    this.caption,
  });

  final String label;
  final String imagePath;
  final VoidCallback onTap;
  final double size;

  /// Optional second line (e.g. "12 products").
  final String? caption;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (mounted && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      button: true,
      label: widget.caption != null
          ? '${widget.label}, ${widget.caption}'
          : widget.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: widget.size + 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: AppRadius.rLg,
                  child: SizedBox.square(
                    dimension: widget.size,
                    child: ProductImage(path: widget.imagePath),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.labelMedium?.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
                if (widget.caption != null)
                  Text(
                    widget.caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Wide category tile for the Explore grid: photo with a scrim and the name
/// over it.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.label,
    required this.imagePath,
    required this.onTap,
    this.caption,
  });

  final String label;
  final String imagePath;
  final String? caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    return Semantics(
      button: true,
      label: caption != null ? '$label, $caption' : label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.rLg,
        child: ClipRRect(
          borderRadius: AppRadius.rLg,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(path: imagePath, fit: BoxFit.cover, padding: EdgeInsets.zero),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xB3000000)],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(color: Colors.white),
                      ),
                      if (caption != null)
                        Text(
                          caption!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
