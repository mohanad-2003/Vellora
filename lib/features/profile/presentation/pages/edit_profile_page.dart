import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/localization/l10n_lookup.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/input_validators.dart';
import '../../../../core/widgets/app_bar_widget.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../cubit/edit_profile_cubit.dart';
import '../widgets/profile_avatar.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key, this.user});

  final UserEntity? user;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditProfileCubit>(),
      child: _EditProfileView(user: user),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView({this.user});

  final UserEntity? user;

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(
    text: widget.user?.name ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.user?.email ?? '',
  );
  late final TextEditingController _phone = TextEditingController(
    text: widget.user?.phone ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.hideKeyboard();
    if (!_formKey.currentState!.validate()) return;
    context.read<EditProfileCubit>().save(
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBarWidget(title: l10n.editProfile),
      body: BlocConsumer<EditProfileCubit, EditProfileState>(
        listenWhen: (p, c) => p.status != c.status,
        listener: (context, state) {
          if (state.status == EditProfileStatus.success) {
            AppSnackbar.success(context, l10n.profileUpdated);
            context.pop(true);
          } else if (state.status == EditProfileStatus.error) {
            AppSnackbar.error(
              context,
              tr(context, state.failureKey ?? 'somethingWentWrong'),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.screenH),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: AppSpacing.vSm),
                        ProfileAvatar(
                          name: _name.text.isEmpty ? '?' : _name.text,
                          avatarUrl: widget.user?.avatarUrl,
                          size: 96,
                          editable: true,
                          onEdit: () => AppSnackbar.show(
                            context,
                            message: l10n.comingSoon,
                          ),
                        ),
                        SizedBox(height: AppSpacing.vXxl),
                        AppTextField(
                          controller: _name,
                          label: l10n.fullName,
                          hint: l10n.fullName,
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final key = InputValidators.name(v);
                            return key == null ? null : tr(context, key);
                          },
                        ),
                        SizedBox(height: AppSpacing.vLg),
                        AppTextField(
                          controller: _email,
                          label: l10n.email,
                          hint: l10n.email,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final key = InputValidators.email(v);
                            return key == null ? null : tr(context, key);
                          },
                        ),
                        SizedBox(height: AppSpacing.vLg),
                        AppTextField(
                          controller: _phone,
                          label: l10n.phoneNumber,
                          hint: l10n.phoneNumber,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.screenH),
                child: SafeArea(
                  top: false,
                  child: AppButton(
                    label: l10n.saveChanges,
                    icon: Icons.check_rounded,
                    isLoading: state.isSaving,
                    onPressed: () => _submit(context),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
