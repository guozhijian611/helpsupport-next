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
  String get loginNoAccount => '还没有账号？';

  @override
  String get loginAgreementNotice => '登录即表示你已阅读并同意隐私政策';

  @override
  String get loginAgreementPrefix => '我已阅读并同意';

  @override
  String get loginAgreementJoin => '与';

  @override
  String get termsOfUse => '《使用协议》';

  @override
  String get privacyPolicy => '《隐私协议》';

  @override
  String get backAction => '返回上一步';

  @override
  String get loginAction => '去登录';

  @override
  String get registerAccountAction => '注册账号';

  @override
  String get forgotPassword => '忘记密码';

  @override
  String get forgotPasswordTitle => '找回密码';

  @override
  String get forgotPasswordSubtitle => '用邮箱或手机号验证码重置你的登录密码。';

  @override
  String get forgotPasswordHasAccount => '想起密码了？';

  @override
  String get phoneLogin => '手机号登录';

  @override
  String get phoneNumber => '手机号';

  @override
  String get loginEmailPlaceholder => '电子邮件';

  @override
  String get invalidPhone => '请输入正确格式的手机号码';

  @override
  String get featureComingSoon => '该功能暂未开放';

  @override
  String get registerAction => '立即注册';

  @override
  String get registerTitle => '注册';

  @override
  String get registerSubtitle => '使用邮箱或手机号验证码创建你的 HelpSupport 支持空间。';

  @override
  String get registerSubmit => '注册';

  @override
  String get registering => '注册中...';

  @override
  String get registerHasAccount => '已有账号？';

  @override
  String get emailRegister => '邮箱注册';

  @override
  String get phoneRegister => '手机号注册';

  @override
  String get email => '邮箱';

  @override
  String get emailCode => '邮箱验证码';

  @override
  String get verificationCode => '验证码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get newPassword => '设置密码';

  @override
  String get sendEmailCode => '发送验证码';

  @override
  String get sendVerificationCode => '获取验证码';

  @override
  String get resendEmailCodeIn => '重新发送';

  @override
  String get resendVerificationCodeIn => '重新发送';

  @override
  String get registerEmailCodeSent => '验证码已发送至';

  @override
  String get verificationCodeSentTo => '验证码已发送至';

  @override
  String get authOtherMethods => '其他登录方式';

  @override
  String get authAgreementText => '我已阅读并同意隐私政策';

  @override
  String get agreementRequired => '请先同意隐私政策';

  @override
  String get invalidEmail => '请输入正确的邮箱格式';

  @override
  String get usernameLengthRule => '账号长度需为 3-32 个字符';

  @override
  String get passwordLengthRule => '密码长度不能少于 6 位';

  @override
  String get passwordMismatch => '两次输入密码不一致';

  @override
  String get resetPasswordAction => '重置密码';

  @override
  String get resettingPassword => '重置中...';

  @override
  String get passwordResetSuccess => '密码已重置，请重新登录';

  @override
  String get memberRoleLabel => '身份';

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
  String get profileCompleteTitle => '填写个人信息';

  @override
  String get profileCompleteSubtitle => '补全昵称、性别和生日后进入 HelpSupport。';

  @override
  String get profileDisplayName => '账号名称';

  @override
  String get profileGender => '性别';

  @override
  String get profileBirthday => '出生日期';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderPrivate => '保密';

  @override
  String get profileSaving => '保存中...';

  @override
  String get enterAppAction => '进入';

  @override
  String get logout => '退出登录';

  @override
  String get googleLogin => '使用 Google 账号登录';

  @override
  String get appleLogin => '使用 Apple 账号登录';

  @override
  String get homeTab => '首页';

  @override
  String get homeTitle => '今日';

  @override
  String get homeGreeting => '你的支持空间已准备好。';

  @override
  String get greetingMorning => '早上好！';

  @override
  String get greetingNoon => '中午好！';

  @override
  String get greetingAfternoon => '下午好！';

  @override
  String get greetingEvening => '晚上好！';

  @override
  String get onboardingTitle => '引导页';

  @override
  String get onboardingLoading => '正在加载引导页内容...';

  @override
  String get onboardingEmpty => '暂无可用引导页内容。';

  @override
  String get onboardingSkip => '跳过';

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

  @override
  String get meAgeLabel => '年龄';

  @override
  String get meGenderLabel => '性别';

  @override
  String get meMonthPlan => '本月计划';

  @override
  String get meNoTask => '暂无任务';

  @override
  String get meKeyTrigger => '重点触发';

  @override
  String get mePendingSupplement => '待补充';

  @override
  String get meRecoveryGoal => '康复目标';

  @override
  String get meCurrentLevel => '当前等级';

  @override
  String get meLevelTitle => 'Lv.1 普通会员';

  @override
  String get meScoreText => '积分 0 / 300';

  @override
  String get meNextLevelHint => '距离下一等级还差300积分';

  @override
  String get meMemoirBenefitTitle => '专属回忆录';

  @override
  String get meMemoirBenefitDesc => '每升一级可生成回忆录';

  @override
  String get meFreeDoctorTitle => '免费预约医生';

  @override
  String get meFreeDoctorDesc => '6000积分可免费预约';

  @override
  String get meHonorBadgesTitle => '荣誉徽章';

  @override
  String get meHonorLevelApprentice => '见习者';

  @override
  String get meHonorLevelPersistent => '坚持者';

  @override
  String get meHonorLevelInspired => '启迪者';

  @override
  String get meHonorLevelReborn => '重生者';

  @override
  String get meHonorUnlocked => '已解锁';

  @override
  String get meHonorLocked => '待解锁';

  @override
  String meHonorPointsProgress(Object current, Object target) {
    return '积分 $current / $target';
  }

  @override
  String meHonorPointsProgressOpen(Object current) {
    return '积分 $current / -';
  }

  @override
  String meHonorNextHint(Object points) {
    return '距离下一等级还差$points积分';
  }

  @override
  String get meHonorFinalHint => '恭喜你已经到达了最终阶段，祝你在新的阶段一帆风顺！';

  @override
  String get meHonorRecentBadges => '最近获得';

  @override
  String get meHonorNoBadges => '暂未获得徽章';

  @override
  String meHonorBadgeCount(Object count) {
    return '已获得 $count 枚徽章';
  }

  @override
  String meHonorPointsBalance(Object points) {
    return '当前积分 $points';
  }

  @override
  String get meCommonFunctions => '常用功能';

  @override
  String get meFollowing => '我的关注';

  @override
  String get meCollection => '我的收藏';

  @override
  String get meHistory => '历史记录';

  @override
  String get mePrivacy => '隐私设置';

  @override
  String get meMemoir => '回忆录';

  @override
  String get meJournal => '日记';

  @override
  String get aiCapabilityTestEntryTitle => 'AI 运行测试';

  @override
  String get aiCapabilityTestEntrySubtitle => '检查本设备能否运行本地 AI';

  @override
  String get aiCapabilityTestTitle => 'AI 运行测试';

  @override
  String get aiCapabilityTestCheckingHeadline => '正在检查设备 AI 运行能力';

  @override
  String get aiCapabilityTestCheckingBody => '应用正在检测本地推理运行时和模型状态，请稍候片刻。';

  @override
  String get aiCapabilityTestReadyHeadline => '本设备具备运行 AI 的基础能力';

  @override
  String get aiCapabilityTestReadyWithModelBody =>
      '本地推理运行时已就绪，且已经检测到可直接使用的本地模型，现在就可以开始试聊。';

  @override
  String get aiCapabilityTestReadyWithoutModelBody =>
      '本地推理运行时已就绪，但当前还没有已下载模型。下载并校验一个本地模型后，就能完成完整实测。';

  @override
  String get aiCapabilityTestUnavailableHeadline => '当前设备还不能运行应用内本地 AI';

  @override
  String get aiCapabilityTestUnavailableBody =>
      '本地推理运行时没有通过检测。你仍然可以查看模型列表，但需要先解决运行时问题。';

  @override
  String get aiCapabilityTestOpenLocalModels => '打开本地模型';

  @override
  String get aiCapabilityTestStartChat => '开始 AI 试聊';

  @override
  String get aiCapabilityTestOverviewTitle => '检测结果';

  @override
  String get aiCapabilityTestRuntimeLabel => '运行时状态';

  @override
  String get aiCapabilityTestRuntimeReadyValue => '已就绪';

  @override
  String get aiCapabilityTestRuntimeUnavailableValue => '不可用';

  @override
  String get aiCapabilityTestLibraryPathLabel => '运行库路径';

  @override
  String get aiCapabilityTestCpuLabel => 'CPU 核心数';

  @override
  String get aiCapabilityTestCatalogLabel => '可选模型';

  @override
  String get aiCapabilityTestDownloadedLabel => '已下载模型';

  @override
  String get aiCapabilityTestMinMemoryLabel => '最轻模型内存要求';

  @override
  String aiCapabilityTestCountCores(Object count) {
    return '$count 核';
  }

  @override
  String aiCapabilityTestCountModels(Object count) {
    return '$count 个模型';
  }

  @override
  String aiCapabilityTestCountDownloaded(Object count) {
    return '$count 个已下载';
  }

  @override
  String aiCapabilityTestMemoryRequirement(Object count) {
    return '至少 $count MB';
  }

  @override
  String get diagnosticsTitle => '诊断信息';

  @override
  String get diagnosticsSubtitle => '查看本地运行日志，并在排查问题时手动上传到服务器。';

  @override
  String get diagnosticsUpload => '上传';

  @override
  String get diagnosticsUploadSuccess => '诊断日志上传成功';

  @override
  String get diagnosticsUploadEmpty => '当前还没有可上传的本地诊断日志。';

  @override
  String get diagnosticsRefresh => '刷新';

  @override
  String get diagnosticsEntriesTitle => '本地日志';

  @override
  String get diagnosticsDetailsTitle => '详细信息';

  @override
  String get diagnosticsNoDetails => '这条日志没有额外详情。';

  @override
  String get diagnosticsEmptyTitle => '暂无诊断日志';

  @override
  String get diagnosticsEmptyBody => '当出现网络错误、已处理异常或执行诊断上传后，对应日志会展示在这里，方便排查。';

  @override
  String get diagnosticsMetaVersion => '版本';

  @override
  String get diagnosticsMetaEntries => '条目数';

  @override
  String get diagnosticsMetaPlatform => '平台';

  @override
  String get diagnosticsMetaLocale => '语言';

  @override
  String get diagnosticsMetaTimezone => '时区';

  @override
  String get diagnosticsMetaDeviceId => '设备 ID';

  @override
  String get diagnosticsLevelInfo => '信息';

  @override
  String get diagnosticsLevelWarning => '警告';

  @override
  String get diagnosticsLevelError => '错误';
}
