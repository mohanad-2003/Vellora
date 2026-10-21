import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/shipping/shipping_rules.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../checkout/data/delivery_remote_datasource.dart';

/// Help & support: how to reach the shop. The address and phone are the ones the
/// owner set in the admin website; the built-in address is the fallback.
class HelpSheet extends StatefulWidget {
  const HelpSheet({super.key});

  @override
  State<HelpSheet> createState() => _HelpSheetState();
}

class _HelpSheetState extends State<HelpSheet> {
  StoreInfo? _info;

  @override
  void initState() {
    super.initState();
    sl<DeliveryRemoteDataSource>().getStoreInfo().then((info) {
      if (mounted) setState(() => _info = info);
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = (_info?.supportEmail.isNotEmpty ?? false)
        ? _info!.supportEmail
        : AppConstants.supportEmail;
    final phone = _info?.supportPhone ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.helpBody, style: context.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        _ContactRow(
          icon: Icons.mail_outline_rounded,
          value: email,
          uri: Uri(scheme: 'mailto', path: email),
        ),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _ContactRow(
            icon: Icons.phone_outlined,
            value: phone,
            uri: Uri(
              scheme: 'tel',
              path: phone.replaceAll(RegExp(r'[^\d+]'), ''),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.value,
    required this.uri,
  });

  final IconData icon;
  final String value;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        try {
          await launchUrl(uri);
        } catch (_) {
          // No app to handle it: the text stays selectable.
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: context.colors.primary),
            const SizedBox(width: AppSpacing.md),
            // Addresses and numbers read left-to-right in every locale.
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  value,
                  textAlign: TextAlign.start,
                  style: context.textTheme.titleSmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
