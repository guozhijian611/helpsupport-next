import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/l10n_extensions.dart';
import '../../../core/i18n/language_switcher.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/auth_controller.dart';
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

  bool _isSubmitting = false;
  int _gender = 1;
  DateTime? _birthday;

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthdayController.dispose();
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

    return AuthPageFrame(
      title: context.l10n.profileCompleteTitle,
      subtitle: context.l10n.profileCompleteSubtitle,
      trailing: const LanguageSwitcher(onDark: true),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthTextField(
              controller: _nicknameController,
              enabled: !_isSubmitting,
              textInputAction: TextInputAction.next,
              label: context.l10n.profileDisplayName,
              icon: Icons.person_outline_rounded,
              validator: _validateNickname,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              value: _gender,
              decoration: _fieldDecoration(
                context,
                label: context.l10n.profileGender,
                icon: Icons.wc_rounded,
              ),
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text(context.l10n.genderMale),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(context.l10n.genderFemale),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(context.l10n.genderPrivate),
                ),
              ],
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _gender = value);
                      }
                    },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _birthdayController,
              readOnly: true,
              enabled: !_isSubmitting,
              decoration: _fieldDecoration(
                context,
                label: context.l10n.profileBirthday,
                icon: Icons.cake_outlined,
                suffix: const Icon(Icons.chevron_right_rounded),
              ),
              onTap: _pickBirthday,
            ),
            const SizedBox(height: 18),
            AuthPrimaryButton(
              onPressed: _submit,
              isLoading: _isSubmitting,
              icon: Icons.arrow_forward_rounded,
              label: _isSubmitting
                  ? context.l10n.profileSaving
                  : context.l10n.enterAppAction,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: const Color(0xFFF3F5FA),
      prefixIcon: Icon(icon, color: const Color(0xFF7D828C)),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF8E80)),
      ),
    );
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
          );
      if (!mounted) {
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
