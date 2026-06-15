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
  String get loginNoAccount => 'No account yet?';

  @override
  String get loginAction => 'Sign in';

  @override
  String get registerAction => 'Create one';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle =>
      'Use an email verification code to create your HelpSupport space.';

  @override
  String get registerSubmit => 'Register';

  @override
  String get registering => 'Registering...';

  @override
  String get registerHasAccount => 'Already have an account?';

  @override
  String get email => 'Email';

  @override
  String get emailCode => 'Email code';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get sendEmailCode => 'Send code';

  @override
  String get resendEmailCodeIn => 'Resend in';

  @override
  String get registerEmailCodeSent => 'Code sent to';

  @override
  String get authOtherMethods => 'Other sign-in methods';

  @override
  String get authAgreementText => 'I have read and agree to the privacy policy';

  @override
  String get agreementRequired => 'Please agree to the privacy policy first';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get usernameLengthRule => 'Username must be 3-32 characters';

  @override
  String get passwordLengthRule => 'Password must be at least 6 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get memberRoleLabel => 'Role';

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
  String get localChat => 'Local chat';

  @override
  String get clearLocalChat => 'Clear chat';

  @override
  String get localModelMessageHint => 'Ask locally';

  @override
  String get localModelNotReady => 'Download and verify the model first.';

  @override
  String get modelUnavailable => 'The local model is unavailable.';

  @override
  String get localModelRuntimeChecking => 'Checking local inference runtime...';

  @override
  String get localModelRuntimeReady => 'Local inference runtime ready:';

  @override
  String get localModelRuntimeUnavailable =>
      'Local inference runtime unavailable:';

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
  String get communityFeedEmpty => 'No community posts yet.';

  @override
  String get communityNewPost => 'New post';

  @override
  String get communityPostHint => 'Share what you want support with...';

  @override
  String get communityPublish => 'Publish';

  @override
  String get communityAnonymous => 'Post anonymously';

  @override
  String get communityPendingReview => 'Pending review';

  @override
  String get communityComments => 'Comments';

  @override
  String get communityCommentHint => 'Write a supportive reply';

  @override
  String get communitySendComment => 'Send comment';

  @override
  String get communityLike => 'Like';

  @override
  String get communityUnlike => 'Unlike';

  @override
  String get communityCollect => 'Save';

  @override
  String get communityUncollect => 'Unsave';

  @override
  String get plan => 'Plan';

  @override
  String get planCurrent => 'Current plan';

  @override
  String get planEmpty => 'No active treatment plan yet.';

  @override
  String get planTodayTasks => 'Today\'s tasks';

  @override
  String get planTaskEmpty => 'No tasks scheduled for today.';

  @override
  String get planAssessments => 'Assessments';

  @override
  String get planAssessmentEmpty => 'No assessment records yet.';

  @override
  String get planNoDate => 'No date';

  @override
  String get planStatusDraft => 'Draft';

  @override
  String get planStatusActive => 'Active';

  @override
  String get planStatusPaused => 'Paused';

  @override
  String get planStatusFinished => 'Finished';

  @override
  String get planTaskTodo => 'To do';

  @override
  String get planTaskDone => 'Done';

  @override
  String get planTaskSkipped => 'Skipped';

  @override
  String get planTaskDelayed => 'Delayed';

  @override
  String get planTaskComplete => 'Complete';

  @override
  String get planTaskSkip => 'Skip';

  @override
  String get planTaskUpdated => 'Task updated.';

  @override
  String get me => 'Me';
}
