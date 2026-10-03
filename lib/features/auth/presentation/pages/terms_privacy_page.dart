import 'package:flutter/material.dart';
import 'package:vellora/core/responsive/responsive.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/widgets/app_bar_widget.dart';


class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sections = <(String, String)>[
      (l10n.termsSectionUseTitle, l10n.termsSectionUseBody),
      (l10n.termsSectionPurchasesTitle, l10n.termsSectionPurchasesBody),
      (l10n.termsSectionPrivacyTitle, l10n.termsSectionPrivacyBody),
      (l10n.termsSectionContactTitle, l10n.termsSectionContactBody),
    ];

    return Scaffold(
      appBar: AppBarWidget(title: l10n.termsPrivacyTitle),
      body: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 720,
          child: ListView.separated(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenH,
            vertical: AppSpacing.vXl,
          ),
          itemCount: sections.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.vXxl),
          itemBuilder: (context, i) {
            final (title, body) = sections[i];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textTheme.titleLarge),
                SizedBox(height: AppSpacing.vSm),
                Text(
                  body,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}
