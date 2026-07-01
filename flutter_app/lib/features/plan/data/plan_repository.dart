import '../../../core/api/api_client.dart';
import 'plan_models.dart';

class PlanRepository {
  const PlanRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<TreatmentPlan>> fetchCurrentPlans() async {
    final result = await _apiClient.getApi<List<TreatmentPlan>>(
      '/app/help/plan/current',
      decode: (value) {
        if (value is! List) {
          return const [];
        }
        return value
            .whereType<Map<String, dynamic>>()
            .map(TreatmentPlan.fromJson)
            .toList(growable: false);
      },
    );
    return result.data ?? const [];
  }

  Future<PlanPage<DailyTask>> fetchTasks({String? date}) async {
    final result = await _apiClient.getApi<PlanPage<DailyTask>>(
      '/app/help/plan/tasks',
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
        'page_size': 50,
      },
      decode: (value) => PlanPage.fromJson(value, DailyTask.fromJson),
    );
    return result.data ??
        const PlanPage(list: [], total: 0, page: 1, pageSize: 50);
  }

  Future<DailyTask> updateTaskStatus({
    required int taskId,
    required int status,
    String completionNote = '',
    String feedbackContent = '',
  }) async {
    final result = await _apiClient.putApi<DailyTask>(
      '/app/help/plan/task/status',
      data: {
        'task_id': taskId,
        'status': status,
        if (completionNote.isNotEmpty) 'completion_note': completionNote,
        if (feedbackContent.isNotEmpty) 'feedback_content': feedbackContent,
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return DailyTask.fromJson(value);
        }
        throw const FormatException('Unexpected task response shape');
      },
    );
    final task = result.data;
    if (task == null || task.id <= 0) {
      throw const FormatException('任务状态更新失败');
    }
    return task;
  }

  Future<PlanPage<AssessmentResult>> fetchAssessmentResults() async {
    final result = await _apiClient.getApi<PlanPage<AssessmentResult>>(
      '/app/help/plan/assessment-results',
      queryParameters: const {'page_size': 10},
      decode: (value) => PlanPage.fromJson(value, AssessmentResult.fromJson),
    );
    return result.data ??
        const PlanPage(list: [], total: 0, page: 1, pageSize: 10);
  }

  Future<AssessmentTaskDetail> fetchAssessmentTaskDetail({
    required int taskId,
  }) async {
    final result = await _apiClient.getApi<AssessmentTaskDetail>(
      '/app/help/plan/assessment-task',
      queryParameters: {'task_id': taskId},
      decode: AssessmentTaskDetail.fromJson,
    );
    final detail = result.data;
    if (detail == null || detail.task.id <= 0 || detail.scale.id.isEmpty) {
      throw const FormatException('评估任务详情读取失败');
    }
    return detail;
  }

  Future<AssessmentResultDetail> saveAssessmentResult({
    required int taskId,
    required String assessmentId,
    required String assessmentTitle,
    required int questionCount,
    required int totalScore,
    required int achievedScore,
    required List<Map<String, dynamic>> answers,
    required Map<String, dynamic> assessmentSnapshot,
    String resultLevel = '',
    String suggestions = '',
  }) async {
    final result = await _apiClient.postApi<AssessmentResultDetail>(
      '/app/help/plan/assessment-result',
      data: {
        'task_id': taskId,
        'assessment_id': assessmentId,
        'assessment_title': assessmentTitle,
        'question_count': questionCount,
        'total_score': totalScore,
        'achieved_score': achievedScore,
        'answers': answers,
        'assessment_snapshot': assessmentSnapshot,
        if (resultLevel.trim().isNotEmpty) 'result_level': resultLevel.trim(),
        if (suggestions.trim().isNotEmpty) 'suggestions': suggestions.trim(),
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          return AssessmentResultDetail.fromJson(value);
        }
        throw const FormatException('Unexpected assessment result shape');
      },
    );
    final detail = result.data;
    if (detail == null || detail.id <= 0) {
      throw const FormatException('评估结果保存失败');
    }
    return detail;
  }
}
