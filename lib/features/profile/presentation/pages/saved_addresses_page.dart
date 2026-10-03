import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../checkout/presentation/models/checkout_models.dart';
import '../cubit/addresses_cubit.dart';

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddressesCubit(),
      child: const _SavedAddressesView(),
    );
  }
}

class _SavedAddressesView extends StatelessWidget {
  const _SavedAddressesView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBarWidget(title: l10n.savedAddresses),
      body: SafeArea(
        child: BlocBuilder<AddressesCubit, AddressesState>(
          builder: (context, state) {
            if (state.addresses.isEmpty) {
              return EmptyStateWidget(
                title: l10n.noAddressesTitle,
                message: l10n.noAddressesBody,
                icon: Icons.location_off_outlined,
                actionLabel: l10n.addNewAddress,
                onAction: () => _openForm(context),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.screenH),
                    itemCount: state.addresses.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppSpacing.vMd),
                    itemBuilder: (_, i) {
                      final address = state.addresses[i];
                      return _AddressCard(
                        address: address,
                        isDefault: address.id == state.defaultId,
                        onSetDefault: () => context
                            .read<AddressesCubit>()
                            .setDefault(address.id),
                        onDelete: () => context
                            .read<AddressesCubit>()
                            .remove(address.id),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.screenH),
                  child: SafeArea(
                    top: false,
                    child: AppButton(
                      label: l10n.addNewAddress,
                      icon: Icons.add_location_alt_outlined,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _openForm(context),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openForm(BuildContext context) {
    final cubit = context.read<AddressesCubit>();
    AppBottomSheet.show(
      context,
      child: _AddressForm(
        onSubmit: (address) {
          cubit.add(address);
          Navigator.of(context).pop();
          AppSnackbar.success(context, context.l10n.addressAdded);
        },
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onSetDefault,
    required this.onDelete,
  });

  final ShippingAddress address;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.rLg,
        border: Border.all(
          color: isDefault ? colors.primary : colors.outlineVariant,
          width: isDefault ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: colors.primary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(address.label, style: context.textTheme.titleSmall),
              SizedBox(width: AppSpacing.sm),
              if (isDefault) _DefaultBadge(label: l10n.defaultLabel),
              const Spacer(),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 20),
                onSelected: (value) {
                  if (value == 'default') onSetDefault();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  if (!isDefault)
                    PopupMenuItem(
                      value: 'default',
                      child: Text(l10n.setAsDefault),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      l10n.delete,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.vSm),
          Text(address.recipient, style: context.textTheme.bodyMedium),
          SizedBox(height: 2),
          Text(
            '${address.line}\n${address.city}',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          SizedBox(height: 2),
          Text(
            address.phone,
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: AppRadius.rSm,
      ),
      child: Text(
        label,
        style: context.textTheme.labelSmall?.copyWith(color: colors.primary),
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({required this.onSubmit});

  final ValueChanged<ShippingAddress> onSubmit;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _recipient = TextEditingController();
  final _line = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _recipient.dispose();
    _line.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    final key = InputValidators.required(v);
    return key == null ? null : tr(context, key);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      ShippingAddress(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        label: _label.text.trim(),
        recipient: _recipient.text.trim(),
        line: _line.text.trim(),
        city: _city.text.trim(),
        phone: _phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.addNewAddress,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.vLg),
          AppTextField(
            controller: _label,
            label: l10n.addressLabel,
            hint: l10n.addressLabelHint,
            prefixIcon: Icons.bookmark_outline_rounded,
            validator: _required,
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _recipient,
            label: l10n.recipientName,
            prefixIcon: Icons.person_outline_rounded,
            validator: _required,
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _line,
            label: l10n.streetAddress,
            prefixIcon: Icons.home_outlined,
            validator: _required,
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _city,
            label: l10n.cityRegion,
            prefixIcon: Icons.location_city_rounded,
            validator: _required,
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _phone,
            label: l10n.phoneNumber,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _required,
          ),
          SizedBox(height: AppSpacing.vXl),
          AppButton(
            label: l10n.saveAddress,
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
