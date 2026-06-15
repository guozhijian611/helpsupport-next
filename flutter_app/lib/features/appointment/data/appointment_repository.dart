import '../../../core/api/api_client.dart';
import 'appointment_models.dart';

class AppointmentRepository {
  const AppointmentRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AppointmentPage<AppointmentDoctor>> fetchDoctors({
    String keyword = '',
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<AppointmentPage<AppointmentDoctor>>(
      '/app/help/appointment/doctors',
      queryParameters: {
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) =>
          AppointmentPage.fromJson(value, AppointmentDoctor.fromJson),
    );
    return result.data ??
        const AppointmentPage(list: [], total: 0, page: 1, pageSize: 20);
  }

  Future<AppointmentDoctor> fetchDoctorDetail(int doctorId) async {
    final directory = await _fetchDoctorsByIds({doctorId});
    final doctor = directory[doctorId];
    if (doctor == null) {
      throw const FormatException('医生不存在');
    }
    return doctor;
  }

  Future<List<AppointmentSlot>> fetchSlots({
    required int doctorId,
    String date = '',
  }) async {
    final result = await _apiClient.getApi<List<AppointmentSlot>>(
      '/app/help/appointment/slots',
      queryParameters: {
        'doctor_id': doctorId,
        if (date.trim().isNotEmpty) 'date': date.trim(),
      },
      decode: (value) {
        if (value is! List) {
          return const [];
        }
        return value
            .whereType<Map<String, dynamic>>()
            .map(AppointmentSlot.fromJson)
            .toList(growable: false);
      },
    );
    return result.data ?? const [];
  }

  Future<AppointmentPage<AppointmentRecord>> fetchAppointments({
    int? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await _apiClient.getApi<AppointmentPage<AppointmentRecord>>(
      '/app/help/appointment/list',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) =>
          AppointmentPage.fromJson(value, AppointmentRecord.fromJson),
    );
    final pageData =
        result.data ??
        const AppointmentPage(list: [], total: 0, page: 1, pageSize: 20);
    if (pageData.list.isEmpty) {
      return pageData;
    }

    final doctorMap = await _fetchDoctorsByIds(
      pageData.list.map((item) => item.doctorId).toSet(),
    );
    final records = pageData.list
        .map((record) {
          final doctor = doctorMap[record.doctorId];
          if (doctor == null) {
            return record;
          }
          return record.copyWith(
            doctorName: doctor.displayName,
            doctorTitle: doctor.title,
            doctorHospital: doctor.hospital,
            doctorAvatar: doctor.avatar,
          );
        })
        .toList(growable: false);
    return AppointmentPage(
      list: records,
      total: pageData.total,
      page: pageData.page,
      pageSize: pageData.pageSize,
    );
  }

  Future<AppointmentRecord> createAppointment({
    required int scheduleId,
    String remark = '',
  }) async {
    final result = await _apiClient.postApi<AppointmentRecord>(
      '/app/help/appointment',
      data: {
        'schedule_id': scheduleId,
        if (remark.trim().isNotEmpty) 'remark': remark.trim(),
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return AppointmentRecord.fromJson(value);
        }
        throw const FormatException('Unexpected appointment shape');
      },
    );
    final record = result.data;
    if (record == null || record.id <= 0) {
      throw const FormatException('预约失败');
    }
    return record;
  }

  Future<AppointmentRecord> cancelAppointment({
    required int appointmentId,
    String cancelReason = '',
  }) async {
    final result = await _apiClient.postApi<AppointmentRecord>(
      '/app/help/appointment/cancel',
      data: {
        'appointment_id': appointmentId,
        if (cancelReason.trim().isNotEmpty)
          'cancel_reason': cancelReason.trim(),
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return AppointmentRecord.fromJson(value);
        }
        throw const FormatException('Unexpected appointment shape');
      },
    );
    final record = result.data;
    if (record == null || record.id <= 0) {
      throw const FormatException('取消预约失败');
    }
    return record;
  }

  Future<Map<int, AppointmentDoctor>> _fetchDoctorsByIds(
    Set<int> doctorIds,
  ) async {
    if (doctorIds.isEmpty) {
      return const {};
    }

    final found = <int, AppointmentDoctor>{};
    var page = 1;
    const pageSize = 100;

    while (true) {
      final doctorPage = await fetchDoctors(page: page, pageSize: pageSize);
      for (final doctor in doctorPage.list) {
        if (doctorIds.contains(doctor.doctorId)) {
          found[doctor.doctorId] = doctor;
        }
      }
      if (found.length >= doctorIds.length) {
        break;
      }
      final loaded = doctorPage.page * doctorPage.pageSize;
      if (doctorPage.list.isEmpty || loaded >= doctorPage.total) {
        break;
      }
      page += 1;
    }

    return found;
  }
}
