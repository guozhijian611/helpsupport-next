// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HelpSupport';

  @override
  String get splashTitle => 'HelpSupport';

  @override
  String get splashSubtitle =>
      'Private mental health support for patients and doctors.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle =>
      'Use your account or a trusted identity provider.';

  @override
  String get emailLogin => 'Email sign in';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get accountLogin => 'Sign in';

  @override
  String get loggingIn => 'Signing in...';

  @override
  String get requiredField => 'Required';

  @override
  String get logout => 'Sign out';

  @override
  String get googleLogin => 'Continue with Google';

  @override
  String get appleLogin => 'Continue with Apple';

  @override
  String get homeTitle => 'Today';

  @override
  String get homeGreeting => 'Your support space is ready.';

  @override
  String get onboardingTitle => 'Onboarding';

  @override
  String get onboardingLoading => 'Loading onboarding content...';

  @override
  String get onboardingEmpty => 'No onboarding content is available yet.';

  @override
  String get retry => 'Retry';

  @override
  String get localModelTitle => 'Local models';

  @override
  String get localModelSubtitle =>
      'Download verified models for private on-device chat.';

  @override
  String get downloadModel => 'Download';

  @override
  String get deleteModel => 'Delete';

  @override
  String get modelNotDownloaded => 'Not downloaded';

  @override
  String get modelReady => 'Verified and ready';

  @override
  String get modelDownloading => 'Downloading';

  @override
  String get modelVerifying => 'Verifying SHA256';

  @override
  String get modelDownloadFailed => 'Download failed';

  @override
  String get chatTitle => 'AI chat';

  @override
  String get doctorChatMode => 'Doctor mode';

  @override
  String get doctorChatDescription =>
      'Prepare questions and organize care advice.';

  @override
  String get companionChatMode => 'Companion mode';

  @override
  String get companionChatDescription =>
      'A calm space for support and reflection.';

  @override
  String get patientChatMode => 'Patient mode';

  @override
  String get patientChatDescription =>
      'Collect symptoms, feelings, and follow-up notes.';

  @override
  String get recentConversations => 'Recent conversations';

  @override
  String get noConversations => 'No conversations yet.';

  @override
  String get noMessages => 'No messages yet.';

  @override
  String get chatMessageHint => 'Write a message';

  @override
  String get sendMessage => 'Send';

  @override
  String get networkUnavailable => 'Unable to reach the HelpSupport API.';

  @override
  String get apiBaseUrlLabel => 'API base URL';

  @override
  String get notifications => 'Notifications';

  @override
  String get permissions => 'Permissions';

  @override
  String get doctor => 'Doctor';

  @override
  String get patient => 'Patient';

  @override
  String get community => 'Community';

  @override
  String get plan => 'Plan';

  @override
  String get me => 'Me';
}
