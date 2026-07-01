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

  Future<DoctorPage<DoctorPatient>> searchPatientCandidates({
    String keyword = '',
    int page = 1,
    int pageSize = 10,
  }) async {
    final result = await _apiClient.getApi<DoctorPage<DoctorPatient>>(
      '/app/help/doctor/patient/candidates',
      queryParameters: {
        if (keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'page': page,
        'page_size': pageSize,
      },
      decode: (value) => DoctorPage.fromJson(value, DoctorPatient.fromJson),
    );
    return result.data ??
        const DoctorPage(list: [], total: 0, page: 1, pageSize: 10);
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

  Future<DoctorPatient> savePatientProfile({
    required int memberId,
    String? recoveryGoal,
    List<String>? triggerTags,
  }) async {
    final result = await _apiClient.postApi<DoctorPatient>(
      '/app/help/doctor/patient/profile',
      data: {
        'member_id': memberId,
        if (recoveryGoal != null) 'recovery_goal': recoveryGoal.trim(),
        if (triggerTags != null)
          'trigger_tags': triggerTags
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList(growable: false),
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return DoctorPatient.fromJson(value);
        }
        throw const FormatException('Unexpected doctor patient shape');
      },
    );
    final patient = result.data;
    if (patient == null || patient.memberId <= 0) {
      throw const FormatException('患者资料保存失败');
    }
    return patient;
  }

  Future<List<TreatmentPlan>> fetchPatientPlans({
    required int memberId,
    int? status,
  }) async {
    final result = await _apiClient.getApi<List<TreatmentPlan>>(
      '/app/help/doctor/patient/plans',
      queryParameters: {
        'member_id': memberId,
        if (status != null) 'status': status,
      },
      decode: (value) => _decodeList(value, TreatmentPlan.fromJson),
    );
    return result.data ?? const [];
  }

  Future<TreatmentPlan> saveTreatmentPlan({
    required int memberId,
    int id = 0,
    required String title,
    String description = '',
    String startDate = '',
    String endDate = '',
    int status = 1,
  }) async {
    final result = await _apiClient.postApi<TreatmentPlan>(
      '/app/help/doctor/treatment-plan',
      data: {
        'member_id': memberId,
        if (id > 0) 'id': id,
        'title': title.trim(),
        'description': description.trim(),
        'start_date': startDate.trim(),
        'end_date': endDate.trim(),
        'status': status,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return TreatmentPlan.fromJson(value);
        }
        throw const FormatException('Unexpected treatment plan shape');
      },
    );
    final plan = result.data;
    if (plan == null || plan.id <= 0) {
      throw const FormatException('治疗计划保存失败');
    }
    return plan;
  }

  Future<void> deleteTreatmentPlan({
    required int memberId,
    required int id,
  }) async {
    await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/doctor/treatment-plan/delete',
      data: {'member_id': memberId, 'id': id},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value;
        }
        return const {};
      },
    );
  }

  Future<TreatmentStage> saveTreatmentStage({
    required int memberId,
    required int planId,
    int id = 0,
    required String stageName,
    required String startDate,
    required String endDate,
    String stageTarget = '',
    int sort = 0,
    int status = 0,
  }) async {
    final result = await _apiClient.postApi<TreatmentStage>(
      '/app/help/doctor/treatment-stage',
      data: {
        'member_id': memberId,
        'plan_id': planId,
        if (id > 0) 'id': id,
        'stage_name': stageName.trim(),
        'start_date': startDate.trim(),
        'end_date': endDate.trim(),
        'stage_target': stageTarget.trim(),
        if (sort > 0) 'sort': sort,
        'status': status,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return TreatmentStage.fromJson(value);
        }
        throw const FormatException('Unexpected treatment stage shape');
      },
    );
    final stage = result.data;
    if (stage == null || stage.id <= 0) {
      throw const FormatException('治疗阶段保存失败');
    }
    return stage;
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

  Future<DailyTask> saveDailyTask({
    required int memberId,
    int id = 0,
    int planId = 0,
    int stageId = 0,
    required String taskDate,
    String startTime = '',
    String endTime = '',
    required String title,
    String description = '',
    String taskType = 'daily',
    String source = 'manual',
    String sourceId = '',
    List<String> attachments = const [],
    int pointsReward = 10,
    bool requiresFeedback = false,
    String feedbackPrompt = '',
    int status = 0,
  }) async {
    final result = await _apiClient.postApi<DailyTask>(
      '/app/help/doctor/daily-task',
      data: {
        'member_id': memberId,
        if (id > 0) 'id': id,
        if (planId > 0) 'plan_id': planId,
        if (stageId > 0) 'stage_id': stageId,
        'task_date': taskDate.trim(),
        'start_time': startTime.trim(),
        'end_time': endTime.trim(),
        'title': title.trim(),
        'description': description.trim(),
        'task_type': taskType,
        'source': source.trim(),
        if (sourceId.trim().isNotEmpty) 'source_id': sourceId.trim(),
        if (attachments.isNotEmpty) 'attachments': attachments,
        'points_reward': pointsReward,
        'requires_feedback': requiresFeedback ? 1 : 0,
        if (feedbackPrompt.trim().isNotEmpty)
          'feedback_prompt': feedbackPrompt.trim(),
        'status': status,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return DailyTask.fromJson(value);
        }
        throw const FormatException('Unexpected daily task shape');
      },
    );
    final task = result.data;
    if (task == null || task.id <= 0) {
      throw const FormatException('关键任务保存失败');
    }
    return task;
  }

  Future<List<DoctorTaskTemplateFolder>> fetchTaskTemplateFolders() async {
    final result = await _apiClient.getApi<List<DoctorTaskTemplateFolder>>(
      '/app/help/doctor/task-template-folders',
      decode: (value) => _decodeList(value, DoctorTaskTemplateFolder.fromJson),
    );
    return result.data ?? const [];
  }

  Future<DoctorTaskTemplateFolder> saveTaskTemplateFolder({
    String id = '',
    required String name,
    String color = '#5E8FE6',
    int sort = 100,
    int status = 1,
  }) async {
    final result = await _apiClient.postApi<DoctorTaskTemplateFolder>(
      '/app/help/doctor/task-template-folder',
      data: {
        if (id.trim().isNotEmpty) 'id': id.trim(),
        'name': name.trim(),
        'color': color,
        'sort': sort,
        'status': status,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return DoctorTaskTemplateFolder.fromJson(value);
        }
        throw const FormatException('Unexpected task template folder shape');
      },
    );
    final folder = result.data;
    if (folder == null || folder.id.isEmpty) {
      throw const FormatException('模板文件夹保存失败');
    }
    return folder;
  }

  Future<void> deleteTaskTemplateFolder(String id) async {
    await _apiClient.postApi<Map<String, dynamic>>(
      '/app/help/doctor/task-template-folder/delete',
      data: {'id': id.trim()},
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return value;
        }
        return const {};
      },
    );
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
    List<Map<String, dynamic>> questions = const [],
    List<Map<String, dynamic>> scoringRule = const [],
  }) async {
    final result = await _apiClient.postApi<DoctorAssessmentScale>(
      '/app/help/doctor/assessment-scale',
      data: {
        if (id.trim().isNotEmpty) 'id': id.trim(),
        'title': title.trim(),
        if (stage.trim().isNotEmpty) 'stage': stage.trim(),
        if (description.trim().isNotEmpty) 'description': description.trim(),
        'total_score': totalScore,
        if (questions.isNotEmpty) 'questions': questions,
        if (scoringRule.isNotEmpty) 'scoring_rule': scoringRule,
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
    final listValue = value is Map<String, dynamic> ? value['list'] : value;
    if (listValue is! List) {
      return const [];
    }

    return listValue
        .whereType<Map<String, dynamic>>()
        .map(decode)
        .toList(growable: false);
  }
}
