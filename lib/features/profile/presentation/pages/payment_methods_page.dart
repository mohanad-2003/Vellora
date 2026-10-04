import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../../../checkout/presentation/widgets/checkout_tiles.dart';
import '../../data/wallet_remote_datasource.dart';
import '../cubit/payment_methods_cubit.dart';
import '../../../../core/widgets/failure_state_view.dart';
import '../../../../core/utils/card_input.dart';

class PaymentMethodsPage extends StatelessWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PaymentMethodsCubit>()..load(),
      child: const _PaymentMethodsView(),
    );
  }
}

class _PaymentMethodsView extends StatelessWidget {
  const _PaymentMethodsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBarWidget(title: l10n.paymentMethods),
      body: SafeArea(
        child: BlocBuilder<PaymentMethodsCubit, PaymentMethodsState>(
          builder: (context, state) {
            if (state.status == PaymentMethodsStatus.loading) {
              return const ListSkeleton(itemCount: 3);
            }
            if (state.status == PaymentMethodsStatus.error) {
              return FailureStateView(
                failureKey: state.failureKey,
                onRetry: () => context.read<PaymentMethodsCubit>().load(),
              );
            }
            if (state.methods.isEmpty) {
              return EmptyStateWidget(
                title: l10n.noPaymentTitle,
                message: l10n.noPaymentBody,
                icon: Icons.credit_card_off_outlined,
                actionLabel: l10n.addCard,
                onAction: () => _openForm(context),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.screenH),
                    itemCount: state.methods.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppSpacing.vMd),
                    itemBuilder: (_, i) {
                      final method = state.methods[i];
                      final isDefault = method.id == state.defaultId;
                      return Stack(
                        children: [
                          PaymentTile(
                            method: method,
                            selected: isDefault,
                            onTap: () => _run(
                              context,
                              context.read<PaymentMethodsCubit>().setDefault(
                                method.id,
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            top: 0,
                            end: 0,
                            child: _CardMenu(
                              isDefault: isDefault,
                              onSetDefault: () => _run(
                                context,
                                context.read<PaymentMethodsCubit>().setDefault(
                                  method.id,
                                ),
                              ),
                              onDelete: () => _run(
                                context,
                                context.read<PaymentMethodsCubit>().remove(
                                  method.id,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.screenH),
                  child: SafeArea(
                    top: false,
                    child: AppButton(
                      label: l10n.addCard,
                      icon: Icons.add_card_rounded,
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
    final cubit = context.read<PaymentMethodsCubit>();
    AppBottomSheet.show(
      context,
      child: CardForm(
        onSubmit: (card) async {
          final failure = await cubit.add(card);
          if (!context.mounted) return;
          Navigator.of(context).pop();
          if (failure == null) {
            AppSnackbar.success(context, context.l10n.cardAdded);
          } else {
            AppSnackbar.error(context, tr(context, failure));
          }
        },
      ),
    );
  }

  /// Runs a change and shows a message if it failed (null means it worked).
  Future<void> _run(BuildContext context, Future<String?> change) async {
    final failure = await change;
    if (failure != null && context.mounted) {
      AppSnackbar.error(context, tr(context, failure));
    }
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({
    required this.isDefault,
    required this.onSetDefault,
    required this.onDelete,
  });

  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 20),
      onSelected: (value) {
        if (value == 'default') onSetDefault();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (_) => [
        if (!isDefault)
          PopupMenuItem(value: 'default', child: Text(l10n.setAsDefault)),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            l10n.delete,
            style: TextStyle(color: context.colors.error),
          ),
        ),
      ],
    );
  }
}

@visibleForTesting
class CardForm extends StatefulWidget {
  const CardForm({super.key, required this.onSubmit});

  final ValueChanged<NewCard> onSubmit;

  @override
  State<CardForm> createState() => _CardFormState();
}

class _CardFormState extends State<CardForm> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _holder = TextEditingController();
  final _expiry = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    _holder.dispose();
    _expiry.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    final key = InputValidators.required(v);
    return key == null ? null : tr(context, key);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final digits = CardInput.digitsOnly(_number.text);
    // Only the brand, the last four digits and the expiry leave the form: the
    // card number is never stored or sent anywhere.
    widget.onSubmit(
      NewCard(
        brand: NewCard.brandOf(digits),
        last4: digits.substring(digits.length - 4),
        expiry: _expiry.text.trim(),
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
            l10n.addCard,
            style: context.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.vLg),
          AppTextField(
            controller: _number,
            label: l10n.cardNumber,
            hint: '1234 5678 9012 3456',
            prefixIcon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            // The keyboard must not learn or suggest card numbers.
            autocorrect: false,
            inputFormatters: [CardNumberFormatter()],
            validator: (v) => CardInput.isPlausibleNumber(v ?? '')
                ? null
                : tr(context, 'invalidCardNumber'),
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _holder,
            label: l10n.cardHolder,
            prefixIcon: Icons.person_outline_rounded,
            validator: _required,
          ),
          SizedBox(height: AppSpacing.vMd),
          AppTextField(
            controller: _expiry,
            label: l10n.expiryDate,
            hint: 'MM/YY',
            prefixIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            autocorrect: false,
            inputFormatters: [ExpiryFormatter()],
            validator: (v) {
              final value = (v ?? '').trim();
              if (!CardInput.isValidExpiryFormat(value)) {
                return tr(context, 'invalidExpiry');
              }
              return CardInput.isExpired(value) ? l10n.cardExpired : null;
            },
          ),
          SizedBox(height: AppSpacing.vXl),
          AppButton(
            label: l10n.saveCard,
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
