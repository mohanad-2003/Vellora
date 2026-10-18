import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vellora/core/constants/app_constants.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/extensions/num_extensions.dart';
import 'package:vellora/core/theme/app_radius.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/haptics.dart';
import 'package:vellora/core/widgets/custom_bottom_sheet.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/core/widgets/price_widget.dart';
import 'package:vellora/core/widgets/product_image.dart';
import 'package:vellora/features/home/domain/entities/product_entity.dart';

/// Opens the share sheet for [product]: what is being shared, one tap to
/// WhatsApp, Telegram or messages, the link with a copy button, and the
/// system share sheet for everything else.
Future<void> showShareProductSheet(
  BuildContext context,
  ProductEntity product,
) {
  return AppBottomSheet.show<void>(
    context,
    title: context.l10n.shareProduct,
    child: ShareProductSheet(product: product),
  );
}

/// The words that go out with the link.
String shareMessage(
  ProductEntity product,
  String link, {
  required String Function(String name, String price, String link) template,
}) => template(product.name, product.price.toPrice(), link);

class ShareProductSheet extends StatefulWidget {
  const ShareProductSheet({
    super.key,
    required this.product,
    this.launch = _launch,
    this.systemShare = _systemShare,
  });

  final ProductEntity product;

  /// Opens a link in another app; false when nothing could open it.
  final Future<bool> Function(Uri uri) launch;

  /// The system share sheet.
  final Future<void> Function(BuildContext context, String text) systemShare;

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  static Future<void> _systemShare(BuildContext context, String text) async {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  State<ShareProductSheet> createState() => _ShareProductSheetState();
}

class _ShareProductSheetState extends State<ShareProductSheet> {
  bool _copied = false;
  Timer? _reset;

  String get _link => AppConstants.productUrl(widget.product.id);

  String _message(BuildContext context) => shareMessage(
    widget.product,
    _link,
    template: (name, price, link) =>
        context.l10n.shareMessage(name, price, link),
  );

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    Haptics.selection();
    await Clipboard.setData(ClipboardData(text: _link));
    if (!mounted) return;
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
    AppSnackbar.show(context, message: context.l10n.linkCopied);
  }

  /// Opens [uri]; if no app can take it, falls back to the system sheet.
  Future<void> _via(Uri uri) async {
    Haptics.selection();
    final text = _message(context);
    final opened = await widget.launch(uri);
    if (!opened && mounted) await widget.systemShare(context, text);
  }

  Future<void> _more() async {
    Haptics.selection();
    await widget.systemShare(context, _message(context));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _message(context);
    final q = Uri.encodeComponent(text);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.lg,
        AppSpacing.screenH,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProductPreview(product: widget.product),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _ShareAction(
                icon: Icons.chat_rounded,
                label: l10n.shareWhatsApp,
                onTap: () => _via(Uri.parse('https://wa.me/?text=$q')),
              ),
              _ShareAction(
                icon: Icons.send_rounded,
                label: l10n.shareTelegram,
                onTap: () => _via(
                  Uri.parse(
                    'https://t.me/share/url?url=${Uri.encodeComponent(_link)}&text=${Uri.encodeComponent(widget.product.name)}',
                  ),
                ),
              ),
              _ShareAction(
                icon: Icons.sms_rounded,
                label: l10n.shareMessages,
                onTap: () =>
                    _via(Uri(scheme: 'sms', queryParameters: {'body': text})),
              ),
              _ShareAction(
                icon: Icons.more_horiz_rounded,
                label: l10n.shareMore,
                onTap: _more,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _LinkRow(link: _link, copied: _copied, onCopy: _copy),
        ],
      ),
    );
  }
}

/// The product being shared: photo, brand, name and price.
class _ProductPreview extends StatelessWidget {
  const _ProductPreview({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.rLg,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: AppRadius.rMd,
              child: SizedBox.square(
                dimension: 72,
                child: ProductImage(
                  path: product.imagePath,
                  semanticLabel: product.name,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelMedium?.copyWith(color: colors.primary),
                    ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  PriceWidget(
                    price: product.price,
                    originalPrice: product.originalPrice,
                    color: product.hasDiscount
                        ? context.vellora.sale
                        : colors.onSurface,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round brand-tinted button with its label underneath.
class _ShareAction extends StatelessWidget {
  const _ShareAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primaryContainer,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(icon, color: colors.primary, size: 26),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The link in a field-like row with a Copy button that confirms itself.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.link,
    required this.copied,
    required this.onCopy,
  });

  final String link;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.rMd,
        border: Border.all(color: colors.outlineVariant, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: AppSpacing.lg,
          end: AppSpacing.xs,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(Icons.link_rounded, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Directionality(
                // Addresses always read left to right.
                textDirection: TextDirection.ltr,
                child: Text(
                  link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: FilledButton.tonalIcon(
                key: ValueKey(copied),
                onPressed: onCopy,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: copied
                      ? context.vellora.success.withValues(alpha: 0.16)
                      : colors.primaryContainer,
                  foregroundColor: copied
                      ? context.vellora.success
                      : colors.primary,
                ),
                icon: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 18,
                ),
                label: Text(copied ? l10n.copied : l10n.copy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
