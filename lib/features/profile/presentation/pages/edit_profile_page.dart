import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vellora/core/di/injection.dart';
import 'package:vellora/core/extensions/context_extensions.dart';
import 'package:vellora/core/localization/l10n_lookup.dart';
import 'package:vellora/core/media/profile_photo.dart';
import 'package:vellora/core/theme/app_spacing.dart';
import 'package:vellora/core/utils/input_validators.dart';
import 'package:vellora/core/widgets/app_bar_widget.dart';
import 'package:vellora/core/widgets/app_button.dart';
import 'package:vellora/core/widgets/app_text_field.dart';
import 'package:vellora/core/widgets/custom_bottom_sheet.dart';
import 'package:vellora/core/widgets/custom_snackbar.dart';
import 'package:vellora/features/auth/domain/entities/user_entity.dart';
import 'package:vellora/features/profile/presentation/cubit/edit_profile_cubit.dart';
import 'package:vellora/features/profile/presentation/widgets/profile_avatar.dart';

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

  late String? _avatarUrl = widget.user?.avatarUrl;
  bool _uploading = false;

  /// Asks where the picture comes from, uploads it and saves it on the account.
  /// It takes effect at once; it does not wait for Save.
  Future<void> _changePhoto() async {
    final cubit = context.read<EditProfileCubit>();
    final choice = await AppBottomSheet.show<_PhotoChoice>(
      context,
      title: context.l10n.changePhoto,
      child: _PhotoChoices(canRemove: _avatarUrl?.isNotEmpty ?? false),
    );
    if (choice == null || !mounted) return;

    setState(() => _uploading = true);
    ({String? failureKey, String? url}) result;
    if (choice == _PhotoChoice.remove) {
      result = await cubit.removeAvatar();
    } else {
      final photo = await pickProfilePhoto(
        choice == _PhotoChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (photo == null) {
        if (mounted) setState(() => _uploading = false);
        return;
      }
      result = await cubit.changeAvatar(photo.bytes, filename: photo.name);
    }
    if (!mounted) return;

    final l10n = context.l10n;
    setState(() {
      _uploading = false;
      if (result.failureKey == null) _avatarUrl = result.url;
    });
    if (result.failureKey != null) {
      AppSnackbar.error(context, tr(context, result.failureKey!));
    } else {
      AppSnackbar.success(
        context,
        result.url == null ? l10n.photoRemoved : l10n.photoUpdated,
      );
    }
  }

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
                          avatarUrl: _avatarUrl,
                          size: 96,
                          editable: true,
                          busy: _uploading,
                          onEdit: _changePhoto,
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
                          // The email is the account's login: shown, not editable.
                          enabled: false,
                          keyboardType: TextInputType.emailAddress,
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

enum _PhotoChoice { gallery, camera, remove }

/// The options in the "change photo" sheet. Taking a photo is hidden on
/// desktop and web, where there is no camera to open.
class _PhotoChoices extends StatelessWidget {
  const _PhotoChoices({required this.canRemove});

  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final phone =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    void pick(_PhotoChoice c) => Navigator.of(context).pop(c);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(l10n.chooseFromGallery),
          onTap: () => pick(_PhotoChoice.gallery),
        ),
        if (phone)
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l10n.takePhoto),
            onTap: () => pick(_PhotoChoice.camera),
          ),
        if (canRemove)
          ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.removePhoto,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => pick(_PhotoChoice.remove),
          ),
      ],
    );
  }
}
