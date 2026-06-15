import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/notifications/centered_notice.dart';
import '../application/doctor_controller.dart';
import '../data/doctor_models.dart';

class DoctorPatientsScreen extends ConsumerStatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  ConsumerState<DoctorPatientsScreen> createState() =>
      _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends ConsumerState<DoctorPatientsScreen> {
  final _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = DoctorPatientsQuery(keyword: _keyword);
    final patients = ref.watch(doctorPatientsProvider(query));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: Text(_t(context, '我的患者', 'My patients')),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _openAddPatientDialog,
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(doctorPatientsProvider(query));
            await ref.read(doctorPatientsProvider(query).future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              _SearchBar(
                controller: _searchController,
                onSearch: () =>
                    setState(() => _keyword = _searchController.text.trim()),
              ),
              const SizedBox(height: 18),
              patients.when(
                data: (page) {
                  if (page.list.isEmpty) {
                    return _EmptyCard(
                      title: _t(context, '还没有绑定患者', 'No patients yet'),
                      subtitle: _t(
                        context,
                        '通过右上角添加患者后，这里会显示你的患者列表。',
                        'Add a patient from the top-right action to build your patient list.',
                      ),
                      actionLabel: _t(context, '添加患者', 'Add patient'),
                      onAction: _openAddPatientDialog,
                    );
                  }
                  return Column(
                    children: [
                      for (final patient in page.list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PatientCard(
                            patient: patient,
                            onOpen: () => context.push(
                              '/doctor/plan?memberId=${patient.memberId}',
                            ),
                            onDelete: () => _unbindPatient(patient),
                          ),
                        ),
                    ],
                  );
                },
                error: (error, _) => _EmptyCard(
                  title: _t(context, '加载失败', 'Load failed'),
                  subtitle: error.toString(),
                  actionLabel: _t(context, '重试', 'Retry'),
                  onAction: () => ref.invalidate(doctorPatientsProvider(query)),
                ),
                loading: () => const _PatientsSkeleton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unbindPatient(DoctorPatient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, '解绑患者', 'Remove patient')),
        content: Text(
          _t(
            context,
            '确认将 ${patient.displayName} 从你的患者列表中移除吗？',
            'Remove ${patient.displayName} from your patient list?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t(context, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(_t(context, '确认', 'Confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref.read(doctorRepositoryProvider).unbindPatient(patient.memberId);
      ref.invalidate(doctorPatientsProvider);
      if (mounted) {
        context.showCenteredNotice(_t(context, '患者已解绑', 'Patient removed'));
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }

  Future<void> _openAddPatientDialog() async {
    final controller = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t(context, '添加患者', 'Add patient')),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: _t(context, '输入患者ID', 'Enter patient ID'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t(context, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(_t(context, '确认', 'Confirm')),
          ),
        ],
      ),
    );
    if (added != true) {
      controller.dispose();
      return;
    }
    final memberId = int.tryParse(controller.text.trim()) ?? 0;
    controller.dispose();
    if (memberId <= 0) {
      if (mounted) {
        context.showCenteredNotice(
          _t(context, '请输入有效患者ID', 'Enter a valid patient ID'),
        );
      }
      return;
    }
    try {
      await ref.read(doctorRepositoryProvider).bindPatient(memberId);
      ref.invalidate(doctorPatientsProvider);
      if (mounted) {
        context.showCenteredNotice(_t(context, '患者已添加', 'Patient added'));
      }
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    }
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSearch});

  final TextEditingController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                hintText: _t(context, '开始探索', 'Search patient'),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFFA1A6AF),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PatientCard extends ConsumerWidget {
  const _PatientCard({
    required this.patient,
    required this.onOpen,
    required this.onDelete,
  });

  final DoctorPatient patient;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarUrl = ref.watch(apiClientProvider).resolveUrl(patient.avatar);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onOpen,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        width: 66,
                        height: 66,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _PatientAvatarPlaceholder(),
                      )
                    : const _PatientAvatarPlaceholder(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.displayName,
                      style: const TextStyle(
                        color: Color(0xFF303236),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        _Meta(
                          label: _t(context, '年龄', 'Age'),
                          value: patient.ageLabel,
                        ),
                        _Meta(
                          label: _t(context, '性别', 'Gender'),
                          value: patient.genderLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFF29B87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientAvatarPlaceholder extends StatelessWidget {
  const _PatientAvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      color: const Color(0xFFEDEFF4),
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: Color(0xFF8C919A)),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.2),
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xFF96999F),
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: '  '),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.group_add_rounded,
            size: 36,
            color: Color(0xFF5A81DA),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF303236),
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8C919A),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9585),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _PatientsSkeleton extends StatelessWidget {
  const _PatientsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            height: 114,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
