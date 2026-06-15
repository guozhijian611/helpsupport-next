import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HelpSupport'**
  String get appTitle;

  /// No description provided for @splashTitle.
  ///
  /// In en, this message translates to:
  /// **'HelpSupport'**
  String get splashTitle;

  /// No description provided for @splashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Private mental health support for patients and doctors.'**
  String get splashSubtitle;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use your account or a trusted identity provider.'**
  String get loginSubtitle;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account yet?'**
  String get loginNoAccount;

  /// No description provided for @loginAgreementNotice.
  ///
  /// In en, this message translates to:
  /// **'By signing in, you confirm that you have read and agree to the privacy policy.'**
  String get loginAgreementNotice;

  /// No description provided for @loginAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to'**
  String get loginAgreementPrefix;

  /// No description provided for @loginAgreementJoin.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get loginAgreementJoin;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @backAction.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAction;

  /// No description provided for @loginAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginAction;

  /// No description provided for @registerAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerAccountAction;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use an email or phone verification code to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Remembered your password?'**
  String get forgotPasswordHasAccount;

  /// No description provided for @phoneLogin.
  ///
  /// In en, this message translates to:
  /// **'Phone sign in'**
  String get phoneLogin;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @loginEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginEmailPlaceholder;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mainland China phone number'**
  String get invalidPhone;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This feature is not available yet'**
  String get featureComingSoon;

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get registerAction;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use an email or phone verification code to create your HelpSupport space.'**
  String get registerSubtitle;

  /// No description provided for @registerSubmit.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerSubmit;

  /// No description provided for @registering.
  ///
  /// In en, this message translates to:
  /// **'Registering...'**
  String get registering;

  /// No description provided for @registerHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get registerHasAccount;

  /// No description provided for @emailRegister.
  ///
  /// In en, this message translates to:
  /// **'Email sign up'**
  String get emailRegister;

  /// No description provided for @phoneRegister.
  ///
  /// In en, this message translates to:
  /// **'Phone sign up'**
  String get phoneRegister;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailCode.
  ///
  /// In en, this message translates to:
  /// **'Email code'**
  String get emailCode;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCode;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @sendEmailCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendEmailCode;

  /// No description provided for @sendVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendVerificationCode;

  /// No description provided for @resendEmailCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in'**
  String get resendEmailCodeIn;

  /// No description provided for @resendVerificationCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in'**
  String get resendVerificationCodeIn;

  /// No description provided for @registerEmailCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get registerEmailCodeSent;

  /// No description provided for @verificationCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent to'**
  String get verificationCodeSentTo;

  /// No description provided for @authOtherMethods.
  ///
  /// In en, this message translates to:
  /// **'Other sign-in methods'**
  String get authOtherMethods;

  /// No description provided for @authAgreementText.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the privacy policy'**
  String get authAgreementText;

  /// No description provided for @agreementRequired.
  ///
  /// In en, this message translates to:
  /// **'Please agree to the privacy policy first'**
  String get agreementRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @usernameLengthRule.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3-32 characters'**
  String get usernameLengthRule;

  /// No description provided for @passwordLengthRule.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthRule;

  /// No description provided for @passwordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordMismatch;

  /// No description provided for @resetPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordAction;

  /// No description provided for @resettingPassword.
  ///
  /// In en, this message translates to:
  /// **'Resetting...'**
  String get resettingPassword;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset. Please sign in again.'**
  String get passwordResetSuccess;

  /// No description provided for @memberRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get memberRoleLabel;

  /// No description provided for @emailLogin.
  ///
  /// In en, this message translates to:
  /// **'Email sign in'**
  String get emailLogin;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @accountLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountLogin;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loggingIn;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your display name, gender, and birthday before entering HelpSupport.'**
  String get profileCompleteSubtitle;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayName;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get profileBirthday;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderPrivate.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderPrivate;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get profileSaving;

  /// No description provided for @enterAppAction.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get enterAppAction;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @googleLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get googleLogin;

  /// No description provided for @appleLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get appleLogin;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Your support space is ready.'**
  String get homeGreeting;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning!'**
  String get greetingMorning;

  /// No description provided for @greetingNoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get greetingNoon;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon!'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening!'**
  String get greetingEvening;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Onboarding'**
  String get onboardingTitle;

  /// No description provided for @onboardingLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading onboarding content...'**
  String get onboardingLoading;

  /// No description provided for @onboardingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No onboarding content is available yet.'**
  String get onboardingEmpty;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @localModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Local models'**
  String get localModelTitle;

  /// No description provided for @localModelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download verified models for private on-device chat.'**
  String get localModelSubtitle;

  /// No description provided for @downloadModel.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadModel;

  /// No description provided for @deleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteModel;

  /// No description provided for @modelNotDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get modelNotDownloaded;

  /// No description provided for @modelReady.
  ///
  /// In en, this message translates to:
  /// **'Verified and ready'**
  String get modelReady;

  /// No description provided for @modelDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get modelDownloading;

  /// No description provided for @modelVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying SHA256'**
  String get modelVerifying;

  /// No description provided for @modelDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get modelDownloadFailed;

  /// No description provided for @localChat.
  ///
  /// In en, this message translates to:
  /// **'Local chat'**
  String get localChat;

  /// No description provided for @clearLocalChat.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get clearLocalChat;

  /// No description provided for @localModelMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Ask locally'**
  String get localModelMessageHint;

  /// No description provided for @localModelNotReady.
  ///
  /// In en, this message translates to:
  /// **'Download and verify the model first.'**
  String get localModelNotReady;

  /// No description provided for @modelUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The local model is unavailable.'**
  String get modelUnavailable;

  /// No description provided for @localModelRuntimeChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking local inference runtime...'**
  String get localModelRuntimeChecking;

  /// No description provided for @localModelRuntimeReady.
  ///
  /// In en, this message translates to:
  /// **'Local inference runtime ready:'**
  String get localModelRuntimeReady;

  /// No description provided for @localModelRuntimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Local inference runtime unavailable:'**
  String get localModelRuntimeUnavailable;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI chat'**
  String get chatTitle;

  /// No description provided for @doctorChatMode.
  ///
  /// In en, this message translates to:
  /// **'Doctor mode'**
  String get doctorChatMode;

  /// No description provided for @doctorChatDescription.
  ///
  /// In en, this message translates to:
  /// **'Prepare questions and organize care advice.'**
  String get doctorChatDescription;

  /// No description provided for @companionChatMode.
  ///
  /// In en, this message translates to:
  /// **'Companion mode'**
  String get companionChatMode;

  /// No description provided for @companionChatDescription.
  ///
  /// In en, this message translates to:
  /// **'A calm space for support and reflection.'**
  String get companionChatDescription;

  /// No description provided for @patientChatMode.
  ///
  /// In en, this message translates to:
  /// **'Patient mode'**
  String get patientChatMode;

  /// No description provided for @patientChatDescription.
  ///
  /// In en, this message translates to:
  /// **'Collect symptoms, feelings, and follow-up notes.'**
  String get patientChatDescription;

  /// No description provided for @recentConversations.
  ///
  /// In en, this message translates to:
  /// **'Recent conversations'**
  String get recentConversations;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.'**
  String get noConversations;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessages;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get chatMessageHint;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @networkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to reach the HelpSupport API.'**
  String get networkUnavailable;

  /// No description provided for @apiBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'API base URL'**
  String get apiBaseUrlLabel;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @patient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patient;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @communityFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No community posts yet.'**
  String get communityFeedEmpty;

  /// No description provided for @communityNewPost.
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get communityNewPost;

  /// No description provided for @communityPostHint.
  ///
  /// In en, this message translates to:
  /// **'Share what you want support with...'**
  String get communityPostHint;

  /// No description provided for @communityPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get communityPublish;

  /// No description provided for @communityAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Post anonymously'**
  String get communityAnonymous;

  /// No description provided for @communityPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get communityPendingReview;

  /// No description provided for @communityComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get communityComments;

  /// No description provided for @communityCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a supportive reply'**
  String get communityCommentHint;

  /// No description provided for @communitySendComment.
  ///
  /// In en, this message translates to:
  /// **'Send comment'**
  String get communitySendComment;

  /// No description provided for @communityLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get communityLike;

  /// No description provided for @communityUnlike.
  ///
  /// In en, this message translates to:
  /// **'Unlike'**
  String get communityUnlike;

  /// No description provided for @communityCollect.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get communityCollect;

  /// No description provided for @communityUncollect.
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get communityUncollect;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @planCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get planCurrent;

  /// No description provided for @planEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active treatment plan yet.'**
  String get planEmpty;

  /// No description provided for @planTodayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s tasks'**
  String get planTodayTasks;

  /// No description provided for @planTaskEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks scheduled for today.'**
  String get planTaskEmpty;

  /// No description provided for @planAssessments.
  ///
  /// In en, this message translates to:
  /// **'Assessments'**
  String get planAssessments;

  /// No description provided for @planAssessmentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assessment records yet.'**
  String get planAssessmentEmpty;

  /// No description provided for @planNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get planNoDate;

  /// No description provided for @planStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get planStatusDraft;

  /// No description provided for @planStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get planStatusActive;

  /// No description provided for @planStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get planStatusPaused;

  /// No description provided for @planStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get planStatusFinished;

  /// No description provided for @planTaskTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get planTaskTodo;

  /// No description provided for @planTaskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get planTaskDone;

  /// No description provided for @planTaskSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get planTaskSkipped;

  /// No description provided for @planTaskDelayed.
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get planTaskDelayed;

  /// No description provided for @planTaskComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get planTaskComplete;

  /// No description provided for @planTaskSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get planTaskSkip;

  /// No description provided for @planTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Task updated.'**
  String get planTaskUpdated;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @meAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get meAgeLabel;

  /// No description provided for @meGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get meGenderLabel;

  /// No description provided for @meMonthPlan.
  ///
  /// In en, this message translates to:
  /// **'Monthly plan'**
  String get meMonthPlan;

  /// No description provided for @meNoTask.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get meNoTask;

  /// No description provided for @meKeyTrigger.
  ///
  /// In en, this message translates to:
  /// **'Key triggers'**
  String get meKeyTrigger;

  /// No description provided for @mePendingSupplement.
  ///
  /// In en, this message translates to:
  /// **'To complete'**
  String get mePendingSupplement;

  /// No description provided for @meRecoveryGoal.
  ///
  /// In en, this message translates to:
  /// **'Recovery goal'**
  String get meRecoveryGoal;

  /// No description provided for @meCurrentLevel.
  ///
  /// In en, this message translates to:
  /// **'Current level'**
  String get meCurrentLevel;

  /// No description provided for @meLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Lv.1 Basic member'**
  String get meLevelTitle;

  /// No description provided for @meScoreText.
  ///
  /// In en, this message translates to:
  /// **'Points 0 / 300'**
  String get meScoreText;

  /// No description provided for @meNextLevelHint.
  ///
  /// In en, this message translates to:
  /// **'300 points to the next level'**
  String get meNextLevelHint;

  /// No description provided for @meMemoirBenefitTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal memoir'**
  String get meMemoirBenefitTitle;

  /// No description provided for @meMemoirBenefitDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate a memoir at each level'**
  String get meMemoirBenefitDesc;

  /// No description provided for @meFreeDoctorTitle.
  ///
  /// In en, this message translates to:
  /// **'Free doctor booking'**
  String get meFreeDoctorTitle;

  /// No description provided for @meFreeDoctorDesc.
  ///
  /// In en, this message translates to:
  /// **'6000 points for a free booking'**
  String get meFreeDoctorDesc;

  /// No description provided for @meHonorBadgesTitle.
  ///
  /// In en, this message translates to:
  /// **'Honor badges'**
  String get meHonorBadgesTitle;

  /// No description provided for @meHonorLevelApprentice.
  ///
  /// In en, this message translates to:
  /// **'Apprentice'**
  String get meHonorLevelApprentice;

  /// No description provided for @meHonorLevelPersistent.
  ///
  /// In en, this message translates to:
  /// **'Persistent'**
  String get meHonorLevelPersistent;

  /// No description provided for @meHonorLevelInspired.
  ///
  /// In en, this message translates to:
  /// **'Inspired'**
  String get meHonorLevelInspired;

  /// No description provided for @meHonorLevelReborn.
  ///
  /// In en, this message translates to:
  /// **'Reborn'**
  String get meHonorLevelReborn;

  /// No description provided for @meHonorUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get meHonorUnlocked;

  /// No description provided for @meHonorLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get meHonorLocked;

  /// No description provided for @meHonorPointsProgress.
  ///
  /// In en, this message translates to:
  /// **'Points {current} / {target}'**
  String meHonorPointsProgress(Object current, Object target);

  /// No description provided for @meHonorPointsProgressOpen.
  ///
  /// In en, this message translates to:
  /// **'Points {current} / -'**
  String meHonorPointsProgressOpen(Object current);

  /// No description provided for @meHonorNextHint.
  ///
  /// In en, this message translates to:
  /// **'{points} points to the next level'**
  String meHonorNextHint(Object points);

  /// No description provided for @meHonorFinalHint.
  ///
  /// In en, this message translates to:
  /// **'You have reached the final level. Wishing you steady progress in the next chapter.'**
  String get meHonorFinalHint;

  /// No description provided for @meHonorRecentBadges.
  ///
  /// In en, this message translates to:
  /// **'Recent badges'**
  String get meHonorRecentBadges;

  /// No description provided for @meHonorNoBadges.
  ///
  /// In en, this message translates to:
  /// **'No badges yet'**
  String get meHonorNoBadges;

  /// No description provided for @meHonorBadgeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} badges earned'**
  String meHonorBadgeCount(Object count);

  /// No description provided for @meHonorPointsBalance.
  ///
  /// In en, this message translates to:
  /// **'Current points {points}'**
  String meHonorPointsBalance(Object points);

  /// No description provided for @meCommonFunctions.
  ///
  /// In en, this message translates to:
  /// **'Common actions'**
  String get meCommonFunctions;

  /// No description provided for @meFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get meFollowing;

  /// No description provided for @meCollection.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get meCollection;

  /// No description provided for @meHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get meHistory;

  /// No description provided for @mePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get mePrivacy;

  /// No description provided for @meMemoir.
  ///
  /// In en, this message translates to:
  /// **'Memoir'**
  String get meMemoir;

  /// No description provided for @meJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get meJournal;

  /// No description provided for @diagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnosticsTitle;

  /// No description provided for @diagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View local runtime logs and upload them to the server when support asks for troubleshooting data.'**
  String get diagnosticsSubtitle;

  /// No description provided for @diagnosticsUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get diagnosticsUpload;

  /// No description provided for @diagnosticsUploadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic logs uploaded'**
  String get diagnosticsUploadSuccess;

  /// No description provided for @diagnosticsUploadEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no local diagnostic logs to upload yet.'**
  String get diagnosticsUploadEmpty;

  /// No description provided for @diagnosticsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get diagnosticsRefresh;

  /// No description provided for @diagnosticsEntriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Local logs'**
  String get diagnosticsEntriesTitle;

  /// No description provided for @diagnosticsDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get diagnosticsDetailsTitle;

  /// No description provided for @diagnosticsNoDetails.
  ///
  /// In en, this message translates to:
  /// **'No extra details were recorded for this entry.'**
  String get diagnosticsNoDetails;

  /// No description provided for @diagnosticsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No diagnostic logs yet'**
  String get diagnosticsEmptyTitle;

  /// No description provided for @diagnosticsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'When network errors, handled exceptions, or diagnostic uploads happen, they will appear here for review.'**
  String get diagnosticsEmptyBody;

  /// No description provided for @diagnosticsMetaVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get diagnosticsMetaVersion;

  /// No description provided for @diagnosticsMetaEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get diagnosticsMetaEntries;

  /// No description provided for @diagnosticsMetaPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get diagnosticsMetaPlatform;

  /// No description provided for @diagnosticsMetaLocale.
  ///
  /// In en, this message translates to:
  /// **'Locale'**
  String get diagnosticsMetaLocale;

  /// No description provided for @diagnosticsMetaTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get diagnosticsMetaTimezone;

  /// No description provided for @diagnosticsMetaDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get diagnosticsMetaDeviceId;

  /// No description provided for @diagnosticsLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get diagnosticsLevelInfo;

  /// No description provided for @diagnosticsLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get diagnosticsLevelWarning;

  /// No description provided for @diagnosticsLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get diagnosticsLevelError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
