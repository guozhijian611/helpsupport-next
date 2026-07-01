class AppointmentPage<T> {
  const AppointmentPage({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory AppointmentPage.fromJson(
    Object? json,
    T Function(Map<String, dynamic> item) decode,
  ) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Unexpected appointment page shape');
    }

    final rawList = json['list'];
    return AppointmentPage<T>(
      list: rawList is List
          ? rawList.whereType<Map<String, dynamic>>().map(decode).toList()
          : const [],
      total: _intValue(json['total']),
      page: _intValue(json['page'], fallback: 1),
      pageSize: _intValue(json['page_size'], fallback: 20),
    );
  }

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;
}

class AppointmentDoctor {
  const AppointmentDoctor({
    required this.doctorId,
    required this.realName,
    required this.title,
    required this.hospital,
    required this.department,
    required this.specialty,
    required this.approvedTime,
    required this.nickname,
    required this.avatar,
  });

  factory AppointmentDoctor.fromJson(Map<String, dynamic> json) {
    return AppointmentDoctor(
      doctorId: _intValue(json['doctor_id']),
      realName: _stringValue(json['real_name']),
      title: _stringValue(json['title']),
      hospital: _stringValue(json['hospital']),
      department: _stringValue(json['department']),
      specialty: _stringValue(json['specialty']),
      approvedTime: _stringValue(json['approved_time']),
      nickname: _stringValue(json['nickname']),
      avatar: _stringValue(json['avatar']),
    );
  }

  final int doctorId;
  final String realName;
  final String title;
  final String hospital;
  final String department;
  final String specialty;
  final String approvedTime;
  final String nickname;
  final String avatar;

  String get displayName {
    if (realName.trim().isNotEmpty) {
      return realName.trim();
    }
    if (nickname.trim().isNotEmpty) {
      return nickname.trim();
    }
    return '医生';
  }
}

class AppointmentSlot {
  const AppointmentSlot({
    required this.id,
    required this.doctorId,
    required this.scheduleDate,
    required this.timeSlot,
    required this.startTime,
    required this.endTime,
    required this.meetType,
    required this.meetLink,
    required this.price,
    required this.currency,
    required this.capacity,
    required this.bookedCount,
    required this.availableCount,
    required this.remark,
    required this.canUsePoints,
    required this.pointsCost,
    required this.paymentMethod,
    required this.cashPrice,
    required this.cashCurrency,
  });

  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      id: _intValue(json['id']),
      doctorId: _intValue(json['doctor_id']),
      scheduleDate: _stringValue(json['schedule_date']),
      timeSlot: _stringValue(json['time_slot']),
      startTime: _stringValue(json['start_time']),
      endTime: _stringValue(json['end_time']),
      meetType: _stringValue(json['meet_type']),
      meetLink: _stringValue(json['meet_link']),
      price: _doubleValue(json['price']),
      currency: _stringValue(json['currency']),
      capacity: _intValue(json['capacity']),
      bookedCount: _intValue(json['booked_count']),
      availableCount: _intValue(json['available_count']),
      remark: _stringValue(json['remark']),
      canUsePoints: _boolValue(json['can_use_points']),
      pointsCost: _intValue(json['points_cost']),
      paymentMethod: _stringValue(json['payment_method']),
      cashPrice: _doubleValue(json['cash_price']),
      cashCurrency: _stringValue(json['cash_currency']),
    );
  }

  final int id;
  final int doctorId;
  final String scheduleDate;
  final String timeSlot;
  final String startTime;
  final String endTime;
  final String meetType;
  final String meetLink;
  final double price;
  final String currency;
  final int capacity;
  final int bookedCount;
  final int availableCount;
  final String remark;
  final bool canUsePoints;
  final int pointsCost;
  final String paymentMethod;
  final double cashPrice;
  final String cashCurrency;

  bool get isPointsAppointment => canUsePoints && pointsCost > 0;
}

class AppointmentRecord {
  const AppointmentRecord({
    required this.id,
    required this.memberId,
    required this.doctorId,
    required this.scheduleId,
    required this.appointDate,
    required this.appointTimeSlot,
    required this.price,
    required this.currency,
    required this.status,
    required this.meetType,
    required this.meetLink,
    required this.confirmRemark,
    required this.remark,
    required this.cancelReason,
    required this.cancelBy,
    required this.confirmedAt,
    required this.finishedAt,
    required this.canceledAt,
    required this.createTime,
    required this.updateTime,
    required this.doctorName,
    required this.doctorTitle,
    required this.doctorHospital,
    required this.doctorAvatar,
    required this.paymentMethod,
    required this.pointsCost,
    required this.pointsLogId,
    required this.pointsRefundLogId,
  });

  factory AppointmentRecord.fromJson(Map<String, dynamic> json) {
    return AppointmentRecord(
      id: _intValue(json['id']),
      memberId: _intValue(json['member_id']),
      doctorId: _intValue(json['doctor_id']),
      scheduleId: _intValue(json['schedule_id']),
      appointDate: _stringValue(json['appoint_date']),
      appointTimeSlot: _stringValue(json['appoint_time_slot']),
      price: _doubleValue(json['price']),
      currency: _stringValue(json['currency']),
      status: _intValue(json['status']),
      meetType: _stringValue(json['meet_type']),
      meetLink: _stringValue(json['meet_link']),
      confirmRemark: _stringValue(json['confirm_remark']),
      remark: _stringValue(json['remark']),
      cancelReason: _stringValue(json['cancel_reason']),
      cancelBy: _stringValue(json['cancel_by']),
      confirmedAt: _stringValue(json['confirmed_at']),
      finishedAt: _stringValue(json['finished_at']),
      canceledAt: _stringValue(json['canceled_at']),
      createTime: _stringValue(json['create_time']),
      updateTime: _stringValue(json['update_time']),
      doctorName: _stringValue(json['doctor_name']),
      doctorTitle: _stringValue(json['doctor_title']),
      doctorHospital: _stringValue(json['doctor_hospital']),
      doctorAvatar: _stringValue(json['doctor_avatar']),
      paymentMethod: _stringValue(json['payment_method']),
      pointsCost: _intValue(json['points_cost']),
      pointsLogId: _intValue(json['points_log_id']),
      pointsRefundLogId: _intValue(json['points_refund_log_id']),
    );
  }

  final int id;
  final int memberId;
  final int doctorId;
  final int scheduleId;
  final String appointDate;
  final String appointTimeSlot;
  final double price;
  final String currency;
  final int status;
  final String meetType;
  final String meetLink;
  final String confirmRemark;
  final String remark;
  final String cancelReason;
  final String cancelBy;
  final String confirmedAt;
  final String finishedAt;
  final String canceledAt;
  final String createTime;
  final String updateTime;
  final String doctorName;
  final String doctorTitle;
  final String doctorHospital;
  final String doctorAvatar;
  final String paymentMethod;
  final int pointsCost;
  final int pointsLogId;
  final int pointsRefundLogId;

  AppointmentRecord copyWith({
    String? doctorName,
    String? doctorTitle,
    String? doctorHospital,
    String? doctorAvatar,
  }) {
    return AppointmentRecord(
      id: id,
      memberId: memberId,
      doctorId: doctorId,
      scheduleId: scheduleId,
      appointDate: appointDate,
      appointTimeSlot: appointTimeSlot,
      price: price,
      currency: currency,
      status: status,
      meetType: meetType,
      meetLink: meetLink,
      confirmRemark: confirmRemark,
      remark: remark,
      cancelReason: cancelReason,
      cancelBy: cancelBy,
      confirmedAt: confirmedAt,
      finishedAt: finishedAt,
      canceledAt: canceledAt,
      createTime: createTime,
      updateTime: updateTime,
      doctorName: doctorName ?? this.doctorName,
      doctorTitle: doctorTitle ?? this.doctorTitle,
      doctorHospital: doctorHospital ?? this.doctorHospital,
      doctorAvatar: doctorAvatar ?? this.doctorAvatar,
      paymentMethod: paymentMethod,
      pointsCost: pointsCost,
      pointsLogId: pointsLogId,
      pointsRefundLogId: pointsRefundLogId,
    );
  }

  String get displayDoctorName => doctorName.trim().isEmpty ? '医生' : doctorName;

  bool get isPointsAppointment => paymentMethod == 'points' && pointsCost > 0;
}

class AppointmentDoctorQuery {
  const AppointmentDoctorQuery({
    this.keyword = '',
    this.page = 1,
    this.pageSize = 20,
  });

  final String keyword;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is AppointmentDoctorQuery &&
        other.keyword == keyword &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(keyword, page, pageSize);
}

class AppointmentSlotQuery {
  const AppointmentSlotQuery({required this.doctorId, this.date = ''});

  final int doctorId;
  final String date;

  @override
  bool operator ==(Object other) {
    return other is AppointmentSlotQuery &&
        other.doctorId == doctorId &&
        other.date == date;
  }

  @override
  int get hashCode => Object.hash(doctorId, date);
}

class AppointmentMineQuery {
  const AppointmentMineQuery({this.status, this.page = 1, this.pageSize = 20});

  final int? status;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return other is AppointmentMineQuery &&
        other.status == status &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(status, page, pageSize);
}

int _intValue(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? fallback;
}

double _doubleValue(Object? value, {double fallback = 0}) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse('$value') ?? fallback;
}

String _stringValue(Object? value) {
  if (value == null) {
    return '';
  }
  return '$value'.trim();
}

bool _boolValue(Object? value) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  final text = _stringValue(value).toLowerCase();
  return text == '1' || text == 'true' || text == 'yes';
}
