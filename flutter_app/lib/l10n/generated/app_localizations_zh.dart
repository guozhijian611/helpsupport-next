// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'HelpSupport';

  @override
  String get splashTitle => 'HelpSupport';

  @override
  String get splashSubtitle => '面向患者和医生的隐私心理支持应用。';

  @override
  String get continueLabel => '继续';

  @override
  String get loginTitle => '登录';

  @override
  String get loginSubtitle => '使用账号或可信身份服务登录。';

  @override
  String get emailLogin => '邮箱登录';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get accountLogin => '登录';

  @override
  String get loggingIn => '登录中...';

  @override
  String get requiredField => '必填';

  @override
  String get logout => '退出登录';

  @override
  String get googleLogin => '使用 Google 继续';

  @override
  String get appleLogin => '使用 Apple 继续';

  @override
  String get homeTitle => '今日';

  @override
  String get homeGreeting => '你的支持空间已准备好。';

  @override
  String get onboardingTitle => '引导页';

  @override
  String get onboardingLoading => '正在加载引导页内容...';

  @override
  String get onboardingEmpty => '暂无可用引导页内容。';

  @override
  String get retry => '重试';

  @override
  String get localModelTitle => '本地模型';

  @override
  String get localModelSubtitle => '下载已校验模型，用于设备端隐私对话。';

  @override
  String get downloadModel => '下载';

  @override
  String get deleteModel => '删除';

  @override
  String get modelNotDownloaded => '未下载';

  @override
  String get modelReady => '已校验，可使用';

  @override
  String get modelDownloading => '下载中';

  @override
  String get modelVerifying => '正在校验 SHA256';

  @override
  String get modelDownloadFailed => '下载失败';

  @override
  String get localChat => '本地对话';

  @override
  String get clearLocalChat => '清空对话';

  @override
  String get localModelMessageHint => '本地提问';

  @override
  String get localModelNotReady => '请先下载并校验模型。';

  @override
  String get modelUnavailable => '本地模型不可用。';

  @override
  String get localModelRuntimeChecking => '正在检查本地推理运行时...';

  @override
  String get localModelRuntimeReady => '本地推理运行时已就绪：';

  @override
  String get localModelRuntimeUnavailable => '本地推理运行时不可用：';

  @override
  String get chatTitle => 'AI 聊天';

  @override
  String get doctorChatMode => '医生模式';

  @override
  String get doctorChatDescription => '整理问题和照护建议。';

  @override
  String get companionChatMode => '陪伴模式';

  @override
  String get companionChatDescription => '用于支持和情绪整理的安静空间。';

  @override
  String get patientChatMode => '患者模式';

  @override
  String get patientChatDescription => '收集症状、感受和复诊记录。';

  @override
  String get recentConversations => '最近会话';

  @override
  String get noConversations => '暂无会话。';

  @override
  String get noMessages => '暂无消息。';

  @override
  String get chatMessageHint => '输入消息';

  @override
  String get sendMessage => '发送';

  @override
  String get networkUnavailable => '暂时无法连接 HelpSupport API。';

  @override
  String get apiBaseUrlLabel => 'API 基础地址';

  @override
  String get notifications => '通知';

  @override
  String get permissions => '权限';

  @override
  String get doctor => '医生';

  @override
  String get patient => '患者';

  @override
  String get community => '社区';

  @override
  String get communityFeedEmpty => '暂无社区帖子。';

  @override
  String get communityNewPost => '发布帖子';

  @override
  String get communityPostHint => '写下你想获得支持的内容...';

  @override
  String get communityPublish => '发布';

  @override
  String get communityAnonymous => '匿名发布';

  @override
  String get communityPendingReview => '待审核';

  @override
  String get communityComments => '评论';

  @override
  String get communityCommentHint => '写一条支持性的回复';

  @override
  String get communitySendComment => '发送评论';

  @override
  String get communityLike => '点赞';

  @override
  String get communityUnlike => '取消点赞';

  @override
  String get communityCollect => '收藏';

  @override
  String get communityUncollect => '取消收藏';

  @override
  String get plan => '计划';

  @override
  String get planCurrent => '当前计划';

  @override
  String get planEmpty => '暂无进行中的治疗计划。';

  @override
  String get planTodayTasks => '今日任务';

  @override
  String get planTaskEmpty => '今天暂无任务。';

  @override
  String get planAssessments => '评估记录';

  @override
  String get planAssessmentEmpty => '暂无评估记录。';

  @override
  String get planNoDate => '暂无日期';

  @override
  String get planStatusDraft => '草稿';

  @override
  String get planStatusActive => '进行中';

  @override
  String get planStatusPaused => '已暂停';

  @override
  String get planStatusFinished => '已完成';

  @override
  String get planTaskTodo => '待办';

  @override
  String get planTaskDone => '已完成';

  @override
  String get planTaskSkipped => '已跳过';

  @override
  String get planTaskDelayed => '已延期';

  @override
  String get planTaskComplete => '完成';

  @override
  String get planTaskSkip => '跳过';

  @override
  String get planTaskUpdated => '任务状态已更新。';

  @override
  String get me => '我的';
}
