import '../../../core/api/api_client.dart';
import '../../plan/data/plan_models.dart';
import 'doctor_models.dart';

class DoctorRepository {
  const DoctorRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<DoctorPage<DoctorPatient>> fetchPatients({
    int? status = 1,
    String keyword = '',
    int page = 1,
    int pageSize = 50,
  }) async {
    final result = await _apiClient.getApi<DoctorPage<DoctorPatient>>(
      '/app/help/doctor/patients',
      queryParameters: {
        if (status != null) 'status': status,
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => DoctorPage.fromJson(value, DoctorPatient.fromJson),
    );
    return result.data ??
        const DoctorPage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<DoctorPatient> bindPatient(int memberId) async {
    final result = await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/doctor/patient/bind',
      data: {'member_id': memberId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value;
        }
        throw const FormatException('Unexpected doctor patient shape');
      },
    );
    final relation = result.data;
    if (relation == null) {
      throw const FormatException('患者绑定失败');
    }
    final patients = await fetchPatients(status: null, pageSize: 100);
    final patient = patients.list.cast<DoctorPatient?>().firstWhere(
      (item) => item?.memberId == memberId,
      orElse: () => null,
    );
    if (patient == null) {
      throw const FormatException('患者绑定成功，但列表刷新失败');
    }
    return patient;
  }

  Future<void> unbindPatient(int memberId) async {
    await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/doctor/patient/unbind',
      data: {'member_id': memberId},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value;
        }
        return const {};
      },
    );
  }

  Future<PlanPage<DailyTask>> fetchDailyTasks({
    required int memberId,
    String date = '',
    int planId = 0,
  }) async {
    final result = await _apiClient.getApi<PlanPage<DailyTask>>(
      '/app/help/doctor/daily-tasks',
      queryParameters: {
        'member_id': memberId,
        if (date.trim().isNotEmpty) 'date': date.trim(),
        if (planId > 0) 'plan_id': planId,
        'page_size': 100,
      },
      decode: (value) => PlanPage.fromJson(value, DailyTask.fromJson),
    );
    return result.data ??
        const PlanPage(list: [], total: 0, page: 1, pageSize: 100);
  }

  Future<List<DoctorTaskTemplateFolder>> fetchTaskTemplateFolders() async {
    final result = await _apiClient.getApi<List<DoctorTaskTemplateFolder>>(
      '/app/help/doctor/task-template-folders',
      decode: (value) => _decodeList(value, DoctorTaskTemplateFolder.fromJson),
    );
    return result.data ?? const [];
  }

  Future<List<DoctorTaskTemplate>> fetchTaskTemplates({
    String folderId = '',
    String stage = '',
    int? status = 1,
  }) async {
    final result = await _apiClient.getApi<List<DoctorTaskTemplate>>(
      '/app/help/doctor/task-templates',
      queryParameters: {
        if (folderId.trim().isNotEmpty) 'folder_id': folderId.trim(),
        if (stage.trim().isNotEmpty) 'stage': stage.trim(),
        if (status != null) 'status': status,
      },
      decode: (value) => _decodeList(value, DoctorTaskTemplate.fromJson),
    );
    return result.data ?? const [];
  }

  Future<List<DoctorAssessmentScale>> fetchAssessmentScales({
    String stage = '',
    String status = 'published',
  }) async {
    final result = await _apiClient.getApi<List<DoctorAssessmentScale>>(
      '/app/help/doctor/assessment-scales',
      queryParameters: {
        if (stage.trim().isNotEmpty) 'stage': stage.trim(),
        if (status.trim().isNotEmpty) 'status': status.trim(),
      },
      decode: (value) => _decodeList(value, DoctorAssessmentScale.fromJson),
    );
    return result.data ?? const [];
  }

  Future<DoctorAssessmentScale> saveAssessmentScale({
    String id = '',
    required String title,
    String stage = '',
    String description = '',
    int totalScore = 0,
  }) async {
    final result = await _apiClient.postApi<DoctorAssessmentScale>(
      '/app/help/doctor/assessment-scale',
      data: {
        if (id.trim().isNotEmpty) 'id': id.trim(),
        'title': title.trim(),
        if (stage.trim().isNotEmpty) 'stage': stage.trim(),
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'total_score': totalScore,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return DoctorAssessmentScale.fromJson(value);
        }
        throw const FormatException('Unexpected doctor assessment scale shape');
      },
    );
    final scale = result.data;
    if (scale == null || scale.id.isEmpty) {
      throw const FormatException('量表保存失败');
    }
    return scale;
  }

  Future<DoctorAssessmentScale> publishAssessmentScale(String id) async {
    final result = await _apiClient.postApi<DoctorAssessmentScale>(
      '/app/help/doctor/assessment-scale/publish',
      data: {'id': id},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return DoctorAssessmentScale.fromJson(value);
        }
        throw const FormatException('Unexpected doctor assessment scale shape');
      },
    );
    final scale = result.data;
    if (scale == null || scale.id.isEmpty) {
      throw const FormatException('量表发布失败');
    }
    return scale;
  }

  List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) decode,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(decode)
        .toList(growable: false);
  }
}
