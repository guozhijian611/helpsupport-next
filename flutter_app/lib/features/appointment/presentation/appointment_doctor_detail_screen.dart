import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notifications/centered_notice.dart';
import '../../../core/providers/app_providers.dart';
import '../application/appointment_controller.dart';
import '../data/appointment_models.dart';

class AppointmentDoctorDetailScreen extends ConsumerWidget {
  const AppointmentDoctorDetailScreen({super.key, required this.doctorId});

  final int doctorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctor = ref.watch(appointmentDoctorDetailProvider(doctorId));
    final slots = ref.watch(
      appointmentSlotsProvider(AppointmentSlotQuery(doctorId: doctorId)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: SafeArea(
        bottom: false,
        child: doctor.when(
          data: (item) => slots.when(
            data: (slotItems) =>
                _AppointmentDoctorDetailBody(doctor: item, slots: slotItems),
            error: (error, _) => _AppointmentDoctorDetailBody(
              doctor: item,
              slots: const [],
              slotError: error.toString(),
            ),
            loading: () => _AppointmentDoctorDetailBody(
              doctor: item,
              slots: const [],
              isSlotLoading: true,
            ),
          ),
          error: (error, _) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _AppointmentDoctorDetailBody extends ConsumerWidget {
  const _AppointmentDoctorDetailBody({
    required this.doctor,
    required this.slots,
    this.slotError,
    this.isSlotLoading = false,
  });

  final AppointmentDoctor doctor;
  final List<AppointmentSlot> slots;
  final String? slotError;
  final bool isSlotLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiClient = ref.watch(apiClientProvider);
    final avatarUrl = apiClient.resolveUrl(doctor.avatar);
    final minPrice = slots.isEmpty
        ? null
        : slots.map((item) => item.price).reduce(math.min);
    final specialtyItems = _specialtyItems(doctor.specialty);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/appointments/mine'),
                  icon: const Icon(Icons.calendar_month_rounded),
                ),
              ],
              expandedHeight: 320,
              flexibleSpace: FlexibleSpaceBar(
                background: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _DoctorHeroFallback(doctor: doctor),
                      )
                    : _DoctorHeroFallback(doctor: doctor),
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF4F5F9),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                doctor.displayName,
                                style: const TextStyle(
                                  color: Color(0xFF303236),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (minPrice != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Color(0xFFAAAFB7),
                                      fontSize: 16,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _t(context, '起价 ', 'From '),
                                      ),
                                      TextSpan(
                                        text: _formatPrice(minPrice, slots),
                                        style: const TextStyle(
                                          color: Color(0xFFFF9585),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            if (doctor.title.isNotEmpty) doctor.title,
                            if (doctor.hospital.isNotEmpty) doctor.hospital,
                            if (doctor.department.isNotEmpty) doctor.department,
                          ].join(' / '),
                          style: const TextStyle(
                            color: Color(0xFF70757D),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _DoctorInfoStrip(doctor: doctor, slots: slots),
                        const SizedBox(height: 24),
                        _SectionHeader(title: _t(context, '个人简介', 'Profile')),
                        const SizedBox(height: 12),
                        _ContentCard(
                          child: Text(
                            _doctorIntro(context, doctor),
                            style: const TextStyle(
                              color: Color(0xFF4A4D55),
                              fontSize: 16,
                              height: 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: _t(context, '擅长领域', 'Specialties'),
                        ),
                        const SizedBox(height: 12),
                        _ContentCard(
                          child: Column(
                            children: specialtyItems.isEmpty
                                ? [
                                    _SpecialtyTile(
                                      title: _t(
                                        context,
                                        '预约咨询',
                                        'Consultation support',
                                      ),
                                      subtitle: _t(
                                        context,
                                        '当前医生已开放预约，可进入时段列表查看具体安排。',
                                        'This doctor is available for booking. Open the schedule to view time slots.',
                                      ),
                                    ),
                                  ]
                                : specialtyItems
                                      .map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 14,
                                          ),
                                          child: _SpecialtyTile(
                                            title: item,
                                            subtitle: _specialtySubtitle(
                                              context,
                                              item,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(growable: false),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (slotError != null)
                          _InlineNotice(message: slotError!)
                        else if (isSlotLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (slots.isEmpty)
                          _InlineNotice(
                            message: _t(
                              context,
                              '当前还没有开放排班，请稍后再查看。',
                              'No schedule is open yet. Please check again later.',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: SafeArea(
            top: false,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9585),
                padding: const EdgeInsets.symmetric(vertical: 19),
              ),
              onPressed: slots.isEmpty
                  ? null
                  : () => _openSlotSheet(context, ref, doctor, slots),
              child: Text(
                _t(context, '选择时间', 'Choose time'),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openSlotSheet(
    BuildContext context,
    WidgetRef ref,
    AppointmentDoctor doctor,
    List<AppointmentSlot> slots,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentSlotSheet(doctor: doctor, slots: slots),
    );
    ref.invalidate(appointmentSlotsProvider);
  }

  List<String> _specialtyItems(String value) {
    final items = value
        .split(RegExp(r'[、，,；;|/]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return items.take(6).toList(growable: false);
  }

  String _doctorIntro(BuildContext context, AppointmentDoctor doctor) {
    final segments = <String>[];
    if (doctor.hospital.isNotEmpty || doctor.department.isNotEmpty) {
      segments.add(
        _t(
          context,
          '执业机构：${[doctor.hospital, doctor.department].where((item) => item.isNotEmpty).join(' / ')}。',
          'Institution: ${[doctor.hospital, doctor.department].where((item) => item.isNotEmpty).join(' / ')}.',
        ),
      );
    }
    if (doctor.specialty.isNotEmpty) {
      segments.add(
        _t(
          context,
          '专业方向：${doctor.specialty}。',
          'Specialty: ${doctor.specialty}.',
        ),
      );
    }
    if (doctor.approvedTime.isNotEmpty) {
      segments.add(
        _t(
          context,
          '平台审核通过时间：${doctor.approvedTime}。',
          'Approved on ${doctor.approvedTime}.',
        ),
      );
    }
    if (segments.isEmpty) {
      return _t(
        context,
        '当前已开放线上预约，你可以先查看可选时间段，再决定具体会面安排。',
        'Online booking is available. Review the time slots before confirming a session.',
      );
    }
    return segments.join('\n\n');
  }

  String _specialtySubtitle(BuildContext context, String item) {
    return _t(
      context,
      '围绕$item提供连续沟通与阶段性支持。',
      'Provides structured support around $item.',
    );
  }

  String _formatPrice(double price, List<AppointmentSlot> slots) {
    final currency = slots.first.currency.isEmpty
        ? 'USD'
        : slots.first.currency;
    return '$currency ${price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2)}';
  }
}

class _DoctorHeroFallback extends StatelessWidget {
  const _DoctorHeroFallback({required this.doctor});

  final AppointmentDoctor doctor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF1F3F7), Color(0xFFE1E6EF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: CircleAvatar(
          radius: 62,
          backgroundColor: Colors.white,
          child: Text(
            doctor.displayName.characters.first,
            style: const TextStyle(
              color: Color(0xFF7E8490),
              fontSize: 42,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorInfoStrip extends StatelessWidget {
  const _DoctorInfoStrip({required this.doctor, required this.slots});

  final AppointmentDoctor doctor;
  final List<AppointmentSlot> slots;

  @override
  Widget build(BuildContext context) {
    final firstSlot = slots.isEmpty ? null : slots.first;
    final approvedMonth = doctor.approvedTime.isEmpty
        ? '--'
        : doctor.approvedTime.split('-').take(2).join('-');

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6AB2F4), Color(0xFF5D88E8)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: approvedMonth,
              label: _t(context, '通过时间', 'Approved'),
            ),
          ),
          Expanded(
            child: _StatItem(
              value: '${slots.length}',
              label: _t(context, '开放时段', 'Open slots'),
            ),
          ),
          Expanded(
            child: _StatItem(
              value: doctor.department.isEmpty ? '--' : doctor.department,
              label: _t(context, '科室', 'Department'),
            ),
          ),
          Expanded(
            child: _StatItem(
              value: _meetTypeLabel(context, firstSlot?.meetType ?? ''),
              label: _t(context, '接诊方式', 'Meet type'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF0F5FF),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF303236),
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

class _SpecialtyTile extends StatelessWidget {
  const _SpecialtyTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF5A81DA),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF636872),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF7D828A),
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }
}

class _AppointmentSlotSheet extends ConsumerStatefulWidget {
  const _AppointmentSlotSheet({required this.doctor, required this.slots});

  final AppointmentDoctor doctor;
  final List<AppointmentSlot> slots;

  @override
  ConsumerState<_AppointmentSlotSheet> createState() =>
      _AppointmentSlotSheetState();
}

class _AppointmentSlotSheetState extends ConsumerState<_AppointmentSlotSheet> {
  AppointmentSlot? _selectedSlot;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupSlots(widget.slots);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        _t(context, '选择预约时间', 'Choose appointment time'),
                        style: const TextStyle(
                          color: Color(0xFF303236),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _t(
                    context,
                    '共${widget.slots.length}个时间段可选',
                    '${widget.slots.length} time slots available',
                  ),
                  style: const TextStyle(
                    color: Color(0xFF7D828A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: grouped.entries
                        .map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: _SlotDayBlock(
                              day: entry.key,
                              slots: entry.value,
                              selectedSlotId: _selectedSlot?.id,
                              onSelect: (slot) {
                                setState(() => _selectedSlot = slot);
                              },
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: const Color(0xFFFF9585),
                ),
                onPressed: _selectedSlot == null || _isSubmitting
                    ? null
                    : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _t(context, '选择时间', 'Confirm time'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, List<AppointmentSlot>> _groupSlots(List<AppointmentSlot> slots) {
    final grouped = <String, List<AppointmentSlot>>{};
    for (final slot in slots) {
      grouped
          .putIfAbsent(slot.scheduleDate, () => <AppointmentSlot>[])
          .add(slot);
    }
    return grouped;
  }

  Future<void> _submit() async {
    final slot = _selectedSlot;
    if (slot == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(_t(context, '确认', 'Confirm')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t(context, '您预约的时间段是', 'You are booking the following slot'),
              style: const TextStyle(color: Color(0xFF8C919A), fontSize: 16),
            ),
            const SizedBox(height: 18),
            _ConfirmRow(
              label: _t(context, '日期', 'Date'),
              value:
                  '${slot.scheduleDate} ${_weekdayLabel(context, slot.scheduleDate)}',
            ),
            const SizedBox(height: 10),
            _ConfirmRow(label: _t(context, '时间', 'Time'), value: slot.timeSlot),
          ],
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

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(appointmentRepositoryProvider)
          .createAppointment(scheduleId: slot.id);
      ref.invalidate(appointmentMineProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFFFF9585),
                  size: 58,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _t(context, '预约成功', 'Booking successful'),
                style: const TextStyle(
                  color: Color(0xFF303236),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _t(
                  context,
                  '已提交预约申请，你可以在“我的预约”里查看状态。',
                  'Your booking request has been submitted. You can track it in My bookings.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF8B9099),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/appointments/mine');
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9585),
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_t(context, '确认', 'Done')),
            ),
          ],
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        context.showCenteredNotice(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

class _SlotDayBlock extends StatelessWidget {
  const _SlotDayBlock({
    required this.day,
    required this.slots,
    required this.selectedSlotId,
    required this.onSelect,
  });

  final String day;
  final List<AppointmentSlot> slots;
  final int? selectedSlotId;
  final ValueChanged<AppointmentSlot> onSelect;

  @override
  Widget build(BuildContext context) {
    final parsedDay = DateTime.tryParse(day);
    final dateLabel = parsedDay == null
        ? day
        : DateFormat('MM-dd').format(parsedDay);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F9),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Text(
                _weekdayLabel(context, day),
                style: const TextStyle(
                  color: Color(0xFF7C818A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                dateLabel,
                style: const TextStyle(
                  color: Color(0xFF9AA0A8),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: slots
                .map((slot) {
                  final selected = selectedSlotId == slot.id;
                  return GestureDetector(
                    onTap: () => onSelect(slot),
                    child: Container(
                      width: 104,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFF9585)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFF9585)
                              : const Color(0xFFD7DCE4),
                        ),
                      ),
                      child: Text(
                        slot.timeSlot.replaceAll('-', '\n'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6D737D),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B9099), fontSize: 17),
        ),
        const SizedBox(width: 14),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF5A81DA),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

String _meetTypeLabel(BuildContext context, String value) {
  switch (value) {
    case 'phone':
      return _t(context, '电话', 'Phone');
    case 'address':
      return _t(context, '线下', 'In person');
    case 'link':
      return _t(context, '线上', 'Online');
    default:
      return '--';
  }
}

String _weekdayLabel(BuildContext context, String day) {
  final date = DateTime.tryParse(day);
  if (date == null) {
    return '--';
  }
  final labels = Localizations.localeOf(context).languageCode == 'zh'
      ? const ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      : const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return labels[date.weekday % 7];
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}
