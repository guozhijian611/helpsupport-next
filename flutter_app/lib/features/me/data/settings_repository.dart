import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/data/auth_models.dart';
import 'settings_models.dart';

final meSettingsRepositoryProvider = Provider<MeSettingsRepository>((ref) {
  return MeSettingsRepository(ref.watch(apiClientProvider));
});

class MeSettingsRepository {
  const MeSettingsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<MeProfileBundle> fetchProfile() async {
    final result = await _apiClient.getApi<MeProfileBundle>(
      '/app/help/me/profile',
      decode: MeProfileBundle.fromJson,
    );
    final data = result.data;
    if (data == null) {
      throw const FormatException('个人资料响应缺少 data');
    }
    return data;
  }

  Future<MeProfileBundle> saveProfile(Map<String, dynamic> data) async {
    final result = await _apiClient.postApi<MeProfileBundle>(
      '/app/help/me/profile/save',
      data: data,
      decode: MeProfileBundle.fromJson,
    );
    final profile = result.data;
    if (profile == null) {
      throw const FormatException('保存个人资料响应缺少 data');
    }
    return profile;
  }

  Future<MeProfileBundle> uploadAvatar({required XFile file}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: file.name),
    });
    final result = await _apiClient.postApi<MeProfileBundle>(
      '/app/help/me/profile/avatar',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      decode: MeProfileBundle.fromJson,
    );
    final data = result.data;
    if (data == null) {
      throw const FormatException('头像上传响应缺少 data');
    }
    return data;
  }

  Future<SecurityOverview> fetchSecurityOverview() async {
    final result = await _apiClient.getApi<SecurityOverview>(
      '/app/help/me/security',
      decode: SecurityOverview.fromJson,
    );
    final data = result.data;
    if (data == null) {
      throw const FormatException('账号安全响应缺少 data');
    }
    return data;
  }

  Future<void> changePassword({
    String? oldPassword,
    required String newPassword,
  }) async {
    await _apiClient.postApi<bool>(
      '/app/help/me/security/password',
      data: {
        if (oldPassword != null && oldPassword.trim().isNotEmpty)
          'old_password': oldPassword,
        'new_password': newPassword,
      },
      decode: (_) => true,
    );
  }

  Future<VerificationCodeDelivery> sendMobileCode({
    required String mobile,
  }) async {
    final result = await _apiClient.postApi<VerificationCodeDelivery>(
      '/app/help/me/security/mobile-code',
      data: {'mobile': mobile.trim()},
      decode: VerificationCodeDelivery.fromJson,
    );
    final delivery = result.data;
    if (delivery == null) {
      throw const FormatException('绑定手机号验证码响应缺少 data');
    }
    return delivery;
  }

  Future<VerificationCodeDelivery> sendEmailCode({
    required String email,
  }) async {
    final result = await _apiClient.postApi<VerificationCodeDelivery>(
      '/app/help/me/security/email-code',
      data: {'email': email.trim()},
      decode: VerificationCodeDelivery.fromJson,
    );
    final delivery = result.data;
    if (delivery == null) {
      throw const FormatException('绑定邮箱验证码响应缺少 data');
    }
    return delivery;
  }

  Future<void> bindEmail({required String email, required String code}) async {
    await _apiClient.postApi<bool>(
      '/app/help/me/security/email',
      data: {'email': email.trim(), 'email_code': code.trim()},
      decode: (_) => true,
    );
  }

  Future<void> bindMobile({
    required String mobile,
    required String code,
  }) async {
    await _apiClient.postApi<bool>(
      '/app/help/me/security/mobile',
      data: {'mobile': mobile.trim(), 'mobile_code': code.trim()},
      decode: (_) => true,
    );
  }

  Future<int> logoutOtherDevices({
    String? currentDeviceId,
    String? platform,
  }) async {
    final result = await _apiClient.postApi<int>(
      '/app/help/me/security/logout-other-devices',
      data: {
        if (currentDeviceId != null && currentDeviceId.trim().isNotEmpty)
          'current_device_id': currentDeviceId.trim(),
        if (platform != null && platform.trim().isNotEmpty)
          'platform': platform.trim(),
      },
      decode: (value) {
        if (value is Map<String, dynamic>) {
          final raw = value['logged_out_devices'];
          if (raw is num) {
            return raw.toInt();
          }
          return int.tryParse((raw ?? '').toString()) ?? 0;
        }
        return 0;
      },
    );
    return result.data ?? 0;
  }
}
