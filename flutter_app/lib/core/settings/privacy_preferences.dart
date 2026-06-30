import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

final privacyPreferencesProvider =
    NotifierProvider<PrivacyPreferencesController, PrivacyPreferences>(
      PrivacyPreferencesController.new,
    );

enum CommunityVisibility {
  private('private'),
  mutual('mutual'),
  public('public');

  const CommunityVisibility(this.storageValue);

  final String storageValue;

  static CommunityVisibility fromStorage(String? value) {
    return switch (value) {
      'private' => private,
      'public' => public,
      _ => mutual,
    };
  }

  String label(BuildContext context) {
    return switch (this) {
      private => _t(context, '仅自己', 'Private'),
      mutual => _t(context, '互相关注', 'Mutual'),
      public => _t(context, '公开', 'Public'),
    };
  }
}

class PrivacyPreferences {
  const PrivacyPreferences({
    this.communityVisibility = CommunityVisibility.mutual,
    this.anonymousPosting = true,
    this.hideRecoveryStage = false,
    this.showFollowingList = false,
    this.showSignature = true,
    this.syncDiarySummary = true,
    this.autoClearAttachments = false,
    this.confirmBeforeExport = true,
  });

  final CommunityVisibility communityVisibility;
  final bool anonymousPosting;
  final bool hideRecoveryStage;
  final bool showFollowingList;
  final bool showSignature;
  final bool syncDiarySummary;
  final bool autoClearAttachments;
  final bool confirmBeforeExport;

  PrivacyPreferences copyWith({
    CommunityVisibility? communityVisibility,
    bool? anonymousPosting,
    bool? hideRecoveryStage,
    bool? showFollowingList,
    bool? showSignature,
    bool? syncDiarySummary,
    bool? autoClearAttachments,
    bool? confirmBeforeExport,
  }) {
    return PrivacyPreferences(
      communityVisibility: communityVisibility ?? this.communityVisibility,
      anonymousPosting: anonymousPosting ?? this.anonymousPosting,
      hideRecoveryStage: hideRecoveryStage ?? this.hideRecoveryStage,
      showFollowingList: showFollowingList ?? this.showFollowingList,
      showSignature: showSignature ?? this.showSignature,
      syncDiarySummary: syncDiarySummary ?? this.syncDiarySummary,
      autoClearAttachments: autoClearAttachments ?? this.autoClearAttachments,
      confirmBeforeExport: confirmBeforeExport ?? this.confirmBeforeExport,
    );
  }

  factory PrivacyPreferences.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const PrivacyPreferences();
    }

    return PrivacyPreferences(
      communityVisibility: CommunityVisibility.fromStorage(
        (value['community_visibility'] ?? '').toString(),
      ),
      anonymousPosting: _boolValue(value['anonymous_posting'], fallback: true),
      hideRecoveryStage: _boolValue(
        value['hide_recovery_stage'],
        fallback: false,
      ),
      showFollowingList: _boolValue(
        value['show_following_list'],
        fallback: false,
      ),
      showSignature: _boolValue(value['show_signature'], fallback: true),
      syncDiarySummary: _boolValue(value['sync_diary_summary'], fallback: true),
      autoClearAttachments: _boolValue(
        value['auto_clear_attachments'],
        fallback: false,
      ),
      confirmBeforeExport: _boolValue(
        value['confirm_before_export'],
        fallback: true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'community_visibility': communityVisibility.storageValue,
      'anonymous_posting': anonymousPosting,
      'hide_recovery_stage': hideRecoveryStage,
      'show_following_list': showFollowingList,
      'show_signature': showSignature,
      'sync_diary_summary': syncDiarySummary,
      'auto_clear_attachments': autoClearAttachments,
      'confirm_before_export': confirmBeforeExport,
    };
  }
}

class PrivacyPreferencesController extends Notifier<PrivacyPreferences> {
  static const _prefix = 'settings.privacy.';

  @override
  PrivacyPreferences build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return PrivacyPreferences(
      communityVisibility: CommunityVisibility.fromStorage(
        prefs.getString('${_prefix}community_visibility'),
      ),
      anonymousPosting: prefs.getBool('${_prefix}anonymous_posting') ?? true,
      hideRecoveryStage:
          prefs.getBool('${_prefix}hide_recovery_stage') ?? false,
      showFollowingList:
          prefs.getBool('${_prefix}show_following_list') ?? false,
      showSignature: prefs.getBool('${_prefix}show_signature') ?? true,
      syncDiarySummary: prefs.getBool('${_prefix}sync_diary_summary') ?? true,
      autoClearAttachments:
          prefs.getBool('${_prefix}auto_clear_attachments') ?? false,
      confirmBeforeExport:
          prefs.getBool('${_prefix}confirm_before_export') ?? true,
    );
  }

  Future<void> save(PrivacyPreferences preferences) async {
    state = preferences;
    final prefs = ref.read(sharedPreferencesProvider);
    await Future.wait([
      prefs.setString(
        '${_prefix}community_visibility',
        preferences.communityVisibility.storageValue,
      ),
      prefs.setBool(
        '${_prefix}anonymous_posting',
        preferences.anonymousPosting,
      ),
      prefs.setBool(
        '${_prefix}hide_recovery_stage',
        preferences.hideRecoveryStage,
      ),
      prefs.setBool(
        '${_prefix}show_following_list',
        preferences.showFollowingList,
      ),
      prefs.setBool('${_prefix}show_signature', preferences.showSignature),
      prefs.setBool(
        '${_prefix}sync_diary_summary',
        preferences.syncDiarySummary,
      ),
      prefs.setBool(
        '${_prefix}auto_clear_attachments',
        preferences.autoClearAttachments,
      ),
      prefs.setBool(
        '${_prefix}confirm_before_export',
        preferences.confirmBeforeExport,
      ),
    ]);
  }

  Future<void> setCommunityVisibility(CommunityVisibility value) {
    return save(state.copyWith(communityVisibility: value));
  }

  Future<void> setAnonymousPosting(bool value) {
    return save(state.copyWith(anonymousPosting: value));
  }

  Future<void> setHideRecoveryStage(bool value) {
    return save(state.copyWith(hideRecoveryStage: value));
  }

  Future<void> setShowFollowingList(bool value) {
    return save(state.copyWith(showFollowingList: value));
  }

  Future<void> setShowSignature(bool value) {
    return save(state.copyWith(showSignature: value));
  }

  Future<void> setSyncDiarySummary(bool value) {
    return save(state.copyWith(syncDiarySummary: value));
  }

  Future<void> setAutoClearAttachments(bool value) {
    return save(state.copyWith(autoClearAttachments: value));
  }

  Future<void> setConfirmBeforeExport(bool value) {
    return save(state.copyWith(confirmBeforeExport: value));
  }
}

String _t(BuildContext context, String zh, String en) {
  return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
}

bool _boolValue(Object? value, {required bool fallback}) {
  if (value == null) {
    return fallback;
  }
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value.toInt() == 1;
  }
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
    return true;
  }
  if (normalized == '2' ||
      normalized == '0' ||
      normalized == 'false' ||
      normalized == 'no') {
    return false;
  }
  return fallback;
}
