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
  String get plan => '计划';

  @override
  String get me => '我的';
}
