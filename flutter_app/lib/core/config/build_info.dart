class BuildInfo {
  BuildInfo._();

  static const appName = 'HelpSupport';
  static const appVersion = String.fromEnvironment(
    'HELP_SUPPORT_APP_VERSION',
    defaultValue: '1.0.0+1',
  );

  static String get shortVersion => appVersion.split('+').first;
}
