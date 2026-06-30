import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/auth_controller.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import 'auth_page_frame.dart';

class DoctorCertificationScreen extends ConsumerStatefulWidget {
  const DoctorCertificationScreen({super.key});

  @override
  ConsumerState<DoctorCertificationScreen> createState() =>
      _DoctorCertificationScreenState();
}

class _DoctorCertificationScreenState
    extends ConsumerState<DoctorCertificationScreen> {
  static const _maxImages = 4;

  final _formKey = GlobalKey<FormState>();
  final _realNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _departmentController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _licenseNoController = TextEditingController();
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  bool _hydratedFromSession = false;
  List<_CertificationImageAttachment> _attachments = const [];

  @override
  void dispose() {
    _realNameController.dispose();
    _titleController.dispose();
    _hospitalController.dispose();
    _departmentController.dispose();
    _specialtyController.dispose();
    _licenseNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentSession = authState.hasValue ? authState.value : null;

    if (!authState.isLoading && currentSession == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/login');
        }
      });
    }
    if (!_hydratedFromSession && currentSession != null) {
      _hydrateFromSession(currentSession);
    }

    return AuthPageFrame(
      title: context.l10n.doctorCertificationTitle,
      subtitle: context.l10n.doctorCertificationSubtitle,
      leading: IconButton(
        onPressed: _isSubmitting
            ? null
            : () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/register/profile');
                }
              },
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        tooltip: context.l10n.backAction,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CertificationTextField(
              label: context.l10n.doctorCertificationRealName,
              controller: _realNameController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            _CertificationTextField(
              label: context.l10n.doctorCertificationJobTitle,
              controller: _titleController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _CertificationTextField(
              label: context.l10n.doctorCertificationHospital,
              controller: _hospitalController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _CertificationTextField(
              label: context.l10n.doctorCertificationDepartment,
              controller: _departmentController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _CertificationTextField(
              label: context.l10n.doctorCertificationSpecialty,
              controller: _specialtyController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _CertificationTextField(
              label: context.l10n.doctorCertificationLicenseNo,
              controller: _licenseNoController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.done,
              validator: _requiredValidator,
            ),
            const SizedBox(height: 16),
            _CertificationImageSection(
              attachments: _attachments,
              enabled: !_isSubmitting,
              onAdd: _pickImages,
              onRemove: _removeAttachment,
            ),
            const SizedBox(height: 16),
            _ReviewHint(text: context.l10n.doctorCertificationPending),
            const SizedBox(height: 22),
            AuthPrimaryButton(
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
              height: 58,
              borderRadius: 22,
              backgroundColor: const Color(0xFFFF9585),
              disabledBackgroundColor: const Color(0xFFFFD4CF),
              label: _isSubmitting
                  ? context.l10n.doctorCertificationSubmitting
                  : context.l10n.doctorCertificationSubmit,
            ),
          ],
        ),
      ),
    );
  }

  void _hydrateFromSession(AuthSession session) {
    _hydratedFromSession = true;
    final doctorProfile = session.doctorProfile;

    _realNameController.text = (doctorProfile['real_name'] ?? '').toString();
    _titleController.text = (doctorProfile['title'] ?? '').toString();
    _hospitalController.text = (doctorProfile['hospital'] ?? '').toString();
    _departmentController.text = (doctorProfile['department'] ?? '').toString();
    _specialtyController.text = (doctorProfile['specialty'] ?? '').toString();
    _licenseNoController.text = (doctorProfile['license_no'] ?? '').toString();

    final images = _stringList(doctorProfile['certification_images']);
    if (images.isNotEmpty) {
      _attachments = images
          .map(
            (url) => _CertificationImageAttachment(
              id: url,
              remoteUrl: url,
              localPath: '',
              isUploading: false,
            ),
          )
          .toList(growable: false);
    }
  }

  Future<void> _pickImages() async {
    if (_attachments.length >= _maxImages) {
      context.showCenteredNotice(context.l10n.doctorCertificationUploadLimit);
      return;
    }

    final permission = await ref
        .read(permissionServiceProvider)
        .requestMediaLibrary();
    final granted =
        permission == PermissionStatus.granted ||
        permission == PermissionStatus.limited;
    if (!granted) {
      if (mounted) {
        context.showCenteredNotice(
          context.l10n.doctorCertificationPhotoPermission,
        );
      }
      return;
    }

    final files = await _imagePicker.pickMultiImage(
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (files.isEmpty) {
      return;
    }

    final remaining = _maxImages - _attachments.length;
    final picked = files.take(remaining).toList(growable: false);
    final pending = picked
        .map(
          (file) => _CertificationImageAttachment(
            id: '${DateTime.now().microsecondsSinceEpoch}-${file.path}',
            localPath: file.path,
            remoteUrl: '',
            isUploading: true,
          ),
        )
        .toList(growable: false);

    setState(() {
      _attachments = [..._attachments, ...pending];
    });

    for (var index = 0; index < pending.length; index++) {
      await _uploadAttachment(picked[index], pending[index]);
    }

    if (files.length > remaining && mounted) {
      context.showCenteredNotice(context.l10n.doctorCertificationUploadLimit);
    }
  }

  Future<void> _uploadAttachment(
    XFile file,
    _CertificationImageAttachment attachment,
  ) async {
    try {
      final remoteUrl = await ref
          .read(authRepositoryProvider)
          .uploadDoctorCertificationImage(file: file);
      if (!mounted) {
        return;
      }
      _updateAttachment(
        attachment.id,
        (current) => current.copyWith(remoteUrl: remoteUrl, isUploading: false),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _attachments = _attachments
            .where((item) => item.id != attachment.id)
            .toList(growable: false);
      });
      context.showCenteredNotice(_errorText(error));
    }
  }

  void _removeAttachment(String id) {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _attachments = _attachments
          .where((item) => item.id != id)
          .toList(growable: false);
    });
  }

  void _updateAttachment(
    String id,
    _CertificationImageAttachment Function(
      _CertificationImageAttachment current,
    )
    transform,
  ) {
    setState(() {
      _attachments = _attachments
          .map((item) => item.id == id ? transform(item) : item)
          .toList(growable: false);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_attachments.any((item) => item.isUploading)) {
      context.showCenteredNotice(context.l10n.doctorCertificationUploading);
      return;
    }

    final imageUrls = _attachments
        .map((item) => item.remoteUrl.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (imageUrls.isEmpty) {
      context.showCenteredNotice(
        context.l10n.doctorCertificationRequiredImages,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .saveDoctorCertification(
            realName: _realNameController.text,
            title: _titleController.text,
            hospital: _hospitalController.text,
            department: _departmentController.text,
            specialty: _specialtyController.text,
            licenseNo: _licenseNoController.text,
            certificationImages: imageUrls,
          );
      await ref.read(authControllerProvider.notifier).refreshCurrentSession();
      if (!mounted) {
        return;
      }
      context.showCenteredNotice(context.l10n.doctorCertificationSubmitted);
      context.go('/home');
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(_errorText(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _requiredValidator(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return context.l10n.requiredField;
    }
    return null;
  }

  String _errorText(Object? error) {
    final text = error.toString();
    if (text.isEmpty) {
      return context.l10n.networkUnavailable;
    }
    return text
        .replaceFirst(RegExp(r'^.*message: '), '')
        .replaceFirst(RegExp(r', traceId: .*$'), '');
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}

class _CertificationTextField extends StatelessWidget {
  const _CertificationTextField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.textInputAction,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        textInputAction: textInputAction,
        validator: validator,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF353740),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9EA2AE),
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFF9585),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _CertificationImageSection extends StatelessWidget {
  const _CertificationImageSection({
    required this.attachments,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_CertificationImageAttachment> attachments;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.doctorCertificationImages,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF353740),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.doctorCertificationImageHint,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF96999F),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileSize = ((constraints.maxWidth - 24) / 3)
                    .clamp(76.0, 104.0)
                    .toDouble();
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ...attachments.map(
                      (item) => _CertificationImageTile(
                        attachment: item,
                        size: tileSize,
                        onRemove: () => onRemove(item.id),
                      ),
                    ),
                    if (attachments.length <
                        _DoctorCertificationScreenState._maxImages)
                      _AddCertificationImageTile(
                        size: tileSize,
                        enabled: enabled,
                        onTap: onAdd,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificationImageTile extends StatelessWidget {
  const _CertificationImageTile({
    required this.attachment,
    required this.size,
    required this.onRemove,
  });

  final _CertificationImageAttachment attachment;
  final double size;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final image = attachment.localPath.isNotEmpty
        ? Image.file(
            File(attachment.localPath),
            width: size,
            height: size,
            fit: BoxFit.cover,
          )
        : Image.network(
            attachment.remoteUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _ImageFallback(),
          );

    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (attachment.isUploading)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.38),
                child: const Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onRemove,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.56),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCertificationImageTile extends StatelessWidget {
  const _AddCertificationImageTile({
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final double size;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFC7BF), width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                size: 28,
                color: enabled
                    ? const Color(0xFFFF9585)
                    : const Color(0xFFD0D3DA),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  context.l10n.doctorCertificationAddImage,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: enabled
                        ? const Color(0xFFFF9585)
                        : const Color(0xFFD0D3DA),
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

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFECEFF5)),
      child: Icon(Icons.image_not_supported_rounded, color: Color(0xFF9EA2AE)),
    );
  }
}

class _ReviewHint extends StatelessWidget {
  const _ReviewHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.verified_user_rounded,
              size: 20,
              color: Color(0xFFFF9585),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7D828A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificationImageAttachment {
  const _CertificationImageAttachment({
    required this.id,
    required this.localPath,
    required this.remoteUrl,
    required this.isUploading,
  });

  final String id;
  final String localPath;
  final String remoteUrl;
  final bool isUploading;

  _CertificationImageAttachment copyWith({
    String? remoteUrl,
    bool? isUploading,
  }) {
    return _CertificationImageAttachment(
      id: id,
      localPath: localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}
