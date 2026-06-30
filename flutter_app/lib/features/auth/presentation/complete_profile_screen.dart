import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/auth_controller.dart';
import '../data/auth_models.dart';
import '../data/auth_protocol.dart';
import '../data/auth_repository.dart';
import 'auth_page_frame.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  bool _isSubmitting = false;
  bool _hydratedFromSession = false;
  int _gender = 1;
  DateTime? _birthday;
  String _memberRole = 'patient';

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          context.push('/protocol/${AuthProtocolType.terms.routeValue}');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () =>
          context.push('/protocol/${AuthProtocolType.privacy.routeValue}');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthdayController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final currentSession = authState.hasValue ? authState.value : null;
    final submitGap = (MediaQuery.sizeOf(context).height * 0.06)
        .clamp(44.0, 88.0)
        .toDouble();
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
      title: context.l10n.profileCompleteTitle,
      subtitle: '',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProfileTextFieldRow(
              label: context.l10n.profileDisplayName,
              controller: _nicknameController,
              enabled: !_isSubmitting,
              validator: _validateNickname,
            ),
            const SizedBox(height: 14),
            _ProfileSelectRow(
              label: context.l10n.profileGender,
              value: _genderLabel(context, _gender),
              enabled: !_isSubmitting,
              onTap: _pickGender,
            ),
            const SizedBox(height: 14),
            _ProfileSelectRow(
              label: context.l10n.profileBirthday,
              value: _birthdayController.text.isEmpty
                  ? context.l10n.profileBirthday
                  : _birthdayController.text,
              enabled: !_isSubmitting,
              onTap: _pickBirthday,
            ),
            const SizedBox(height: 14),
            _ProfileSelectRow(
              label: context.l10n.memberRoleLabel,
              value: _memberRoleLabel(context, _memberRole),
              enabled: !_isSubmitting,
              onTap: _pickMemberRole,
            ),
            SizedBox(height: submitGap),
            AuthPrimaryButton(
              onPressed: _isSubmitting ? null : _submit,
              isLoading: _isSubmitting,
              height: 60,
              borderRadius: 22,
              backgroundColor: const Color(0xFFFF9585),
              disabledBackgroundColor: const Color(0xFFFFD4CF),
              label: _isSubmitting
                  ? context.l10n.profileSaving
                  : _memberRole == 'doctor'
                  ? context.l10n.continueLabel
                  : context.l10n.enterAppAction,
            ),
            const SizedBox(height: 30),
            _ProtocolNotice(
              termsRecognizer: _termsRecognizer,
              privacyRecognizer: _privacyRecognizer,
            ),
          ],
        ),
      ),
    );
  }

  void _hydrateFromSession(AuthSession session) {
    _hydratedFromSession = true;
    final member = session.member;
    final profile = session.profile;

    final nickname = (member['nickname'] ?? profile['nickname'] ?? '')
        .toString()
        .trim();
    final gender = int.tryParse((profile['gender'] ?? '').toString());
    final birthdayText = (profile['birthday'] ?? '').toString().trim();
    final memberRole = session.profileRole;

    if (nickname.isNotEmpty) {
      _nicknameController.text = nickname;
    }
    if (gender != null && [1, 2, 3].contains(gender)) {
      _gender = gender;
    }
    if (birthdayText.isNotEmpty) {
      _birthdayController.text = birthdayText;
      _birthday = DateTime.tryParse(birthdayText);
    }
    if (memberRole == 'doctor' || memberRole == 'patient') {
      _memberRole = memberRole;
    }
  }

  String _genderLabel(BuildContext context, int gender) {
    return switch (gender) {
      2 => context.l10n.genderFemale,
      3 => context.l10n.genderPrivate,
      _ => context.l10n.genderMale,
    };
  }

  String _memberRoleLabel(BuildContext context, String memberRole) {
    return memberRole == 'doctor' ? context.l10n.doctor : context.l10n.patient;
  }

  Future<void> _pickGender() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _PickerSheet<int>(
          title: context.l10n.profileGender,
          currentValue: _gender,
          items: [
            _PickerItem(value: 1, label: context.l10n.genderMale),
            _PickerItem(value: 2, label: context.l10n.genderFemale),
            _PickerItem(value: 3, label: context.l10n.genderPrivate),
          ],
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _gender = selected);
    }
  }

  Future<void> _pickMemberRole() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _PickerSheet<String>(
          title: context.l10n.memberRoleLabel,
          currentValue: _memberRole,
          items: [
            _PickerItem(value: 'patient', label: context.l10n.patient),
            _PickerItem(value: 'doctor', label: context.l10n.doctor),
          ],
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _memberRole = selected);
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initialDate =
        _birthday ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _birthday = picked;
      _birthdayController.text = _dateFormat.format(picked);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .saveProfile(
            nickname: _nicknameController.text.trim(),
            gender: _gender,
            birthday: _birthdayController.text.trim().isEmpty
                ? null
                : _birthdayController.text.trim(),
            memberRole: _memberRole == 'doctor' ? null : _memberRole,
          );
      await ref.read(authControllerProvider.notifier).refreshCurrentSession();
      if (!mounted) {
        return;
      }
      if (_memberRole == 'doctor') {
        context.go('/register/doctor-certification');
        return;
      }
      context.go('/home');
    } on Object catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _validateNickname(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return context.l10n.requiredField;
    }
    return null;
  }

  void _showError(Object? error) {
    final text = error.toString();
    final message = text.isEmpty
        ? context.l10n.networkUnavailable
        : text
              .replaceFirst(RegExp(r'^.*message: '), '')
              .replaceFirst(RegExp(r', traceId: .*$'), '');
    context.showCenteredNotice(message);
  }
}

class _ProfileTextFieldRow extends StatelessWidget {
  const _ProfileTextFieldRow({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5FA),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9EA2AE),
                ),
              ),
            ),
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                textAlign: TextAlign.right,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF353740),
                ),
                decoration: InputDecoration(
                  hintText: label,
                  filled: false,
                  fillColor: Colors.transparent,
                  hintStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFB1B5BF),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
                validator: validator,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSelectRow extends StatelessWidget {
  const _ProfileSelectRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: enabled ? onTap : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5FA),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          child: Row(
            children: [
              SizedBox(
                width: 108,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9EA2AE),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF353740),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: enabled
                    ? const Color(0xFFC5C8D0)
                    : const Color(0xFFE3E5EA),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolNotice extends StatelessWidget {
  const _ProtocolNotice({
    required this.termsRecognizer,
    required this.privacyRecognizer,
  });

  final TapGestureRecognizer termsRecognizer;
  final TapGestureRecognizer privacyRecognizer;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF9B9EAA),
      height: 1.5,
      fontWeight: FontWeight.w500,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '${context.l10n.loginAgreementPrefix} '),
          TextSpan(
            text: context.l10n.termsOfUse,
            style: const TextStyle(
              color: Color(0xFFFF9585),
              fontWeight: FontWeight.w600,
            ),
            recognizer: termsRecognizer,
          ),
          TextSpan(text: ' ${context.l10n.loginAgreementJoin} '),
          TextSpan(
            text: context.l10n.privacyPolicy,
            style: const TextStyle(
              color: Color(0xFFFF9585),
              fontWeight: FontWeight.w600,
            ),
            recognizer: privacyRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _PickerItem<T> {
  const _PickerItem({required this.value, required this.label});

  final T value;
  final String label;
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({
    required this.title,
    required this.currentValue,
    required this.items,
  });

  final String title;
  final T currentValue;
  final List<_PickerItem<T>> items;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF353740),
              ),
            ),
            const SizedBox(height: 14),
            ...items.map((item) {
              final selected = item.value == currentValue;
              return ListTile(
                onTap: () => Navigator.of(context).pop(item.value),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                tileColor: selected
                    ? const Color(0xFFFFF1EE)
                    : const Color(0xFFF8F9FC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 4,
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFFFF9585)
                        : const Color(0xFF353740),
                  ),
                ),
                trailing: selected
                    ? const Icon(Icons.check_rounded, color: Color(0xFFFF9585))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
