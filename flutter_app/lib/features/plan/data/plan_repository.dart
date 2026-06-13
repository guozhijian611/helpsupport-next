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
  }) async {
    final result = await _apiClient.putApi<DailyTask>(
      '/app/help/plan/task/status',
      data: {
        'task_id': taskId,
        'status': status,
        if (completionNote.isNotEmpty) 'completion_note': completionNote,
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
}
