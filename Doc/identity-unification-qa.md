# 身份统一 QA

## 背景

HelpSupport 的 Flutter 端同时承载患者端与医生端，登录、消息、个人资料和底部导航共用一套壳。

在本次修正前，代码里对“当前用户身份”存在三类混用：

- 登录返回里没有明确的顶层身份字段。
- 前端零散地从 `profile.member_role` 推断身份。
- 后端医生能力实际上又依赖 `sa_help_doctor_profile` 的审核结果，而不只是 `member_role=doctor`。

这会导致一个直接问题：

- “资料里选择了医生”不等于“当前已经是可用医生身份”。
- 前后端都可能各自做一套判断，最终出现展示身份、权限身份、导航身份不一致。

## Q1：这次修的核心问题是什么？

不是“后端完全没返回身份”，而是“身份返回契约不明确，也没有统一的生效规则”。

修正前，登录接口实际返回：

```json
{
  "token": {},
  "member": {},
  "profile": {},
  "doctor_profile": {}
}
```

其中身份信息只隐含在：

- `profile.member_role`
- `doctor_profile.audit_status`

前端如果只看 `member_role=doctor`，会把“申请医生但未审核通过”的用户也当成医生；但后端医生接口实际要求医生资质审核通过。

## Q2：现在统一后的规则是什么？

统一后把身份拆成两层：

1. `profile_role`
   含义：资料层保存的角色偏好，也就是用户在资料里选择的是 `patient` 还是 `doctor`。

2. `current_role`
   含义：当前真正生效的身份，用于 Flutter 端页面分流、能力开关、导航切换。

当前生效规则是：

```text
如果 profile_role == doctor 且 doctor_profile 已审核通过
=> current_role = doctor

否则
=> current_role = patient
```

也就是说：

- 用户可以“申请成为医生”
- 但只有审核通过后，系统才把他视为真正的医生身份

## Q3：现在登录/刷新/资料接口统一返回什么？

以下接口现在都统一返回相同的身份结构：

- `POST /app/help/auth/account-login`
- `POST /app/help/auth/account-register`
- `POST /app/help/auth/google`
- `POST /app/help/auth/apple`
- `POST /app/help/auth/refresh`
- `GET /app/help/me/profile`
- `POST /app/help/me/profile/save`

返回结构现在是：

```json
{
  "token": {
    "access_token": "xxx",
    "refresh_token": "xxx",
    "token_type": "Bearer",
    "expires_in": 86400
  },
  "member": {
    "id": 1,
    "username": "demo",
    "nickname": "Demo"
  },
  "profile": {
    "member_role": "doctor"
  },
  "doctor_profile": {
    "audit_status": 1,
    "status": 1
  },
  "current_role": "doctor",
  "role_flags": {
    "profile_role": "doctor",
    "is_patient": false,
    "is_doctor": true,
    "doctor_profile_submitted": true,
    "doctor_approved": true
  }
}
```

## Q4：`role_flags` 每个字段是什么意思？

- `profile_role`
  资料里记录的角色偏好，取值 `patient` / `doctor`

- `is_patient`
  当前是否按患者身份生效

- `is_doctor`
  当前是否按医生身份生效

- `doctor_profile_submitted`
  是否已经提交过医生资质资料

- `doctor_approved`
  医生资质是否审核通过

这几个字段的目的不是增加复杂度，而是避免 Flutter 端再去自己拼逻辑。

## Q5：为什么不能只返回 `member_role`？

因为 `member_role` 只能表达“用户想成为什么角色”，不能表达“系统现在允许他以什么角色工作”。

典型场景：

- 用户资料里把自己切到 `doctor`
- 但医生资质还在待审核或被拒绝

如果此时前端只看 `member_role=doctor`：

- 底部导航可能切成医生端
- 医生工作台入口可能提前开放
- 但真实医生接口会被后端拒绝

这就是典型的“展示层身份”和“权限层身份”不一致。

所以必须把：

- `profile_role`
- `doctor_approved`
- `current_role`

分开表达。

## Q6：Flutter 端现在应该怎么用？

Flutter 端不应再自己拼：

```dart
profile['member_role'] ?? member['member_role']
```

统一使用 `AuthSession` 上的新字段：

- `session.currentRole`
- `session.profileRole`
- `session.roleFlags`
- `session.isDoctor`
- `session.isPatient`
- `session.isDoctorApproved`

使用建议：

- 页面/导航/能力分流：看 `currentRole`
- 资料回填：看 `profileRole`
- 医生认证状态文案：看 `doctorApproved` / `doctorProfileSubmitted`

## Q7：这次后端改了哪些地方？

主要改动点：

- `server/plugin/help/app/service/HelpAuthService.php`
  统一登录、注册、第三方登录、刷新 token 的返回契约

- `server/plugin/help/app/service/HelpApiService.php`
  统一 `GET /me/profile` 和 `POST /me/profile/save` 的返回契约

- `server/plugin/help/app/api/controller/AuthController.php`
  更新 APIDOC 注解，补充 `current_role` 与 `role_flags`

- `server/plugin/help/app/api/controller/MeController.php`
  更新 APIDOC 注解，补充 `current_role` 与 `role_flags`

## Q8：这次 Flutter 端改了哪些地方？

主要改动点：

- `flutter_app/lib/features/auth/data/auth_models.dart`
  为 `AuthSession` 增加：
  - `currentRole`
  - `profileRole`
  - `roleFlags`
  - `isDoctor`
  - `isPatient`
  - `isDoctorApproved`

- `flutter_app/lib/features/auth/application/auth_controller.dart`
  增加 `refreshCurrentSession()`，用于资料保存后刷新当前会话

- `flutter_app/lib/features/auth/presentation/complete_profile_screen.dart`
  不再手写读取 `profile['member_role']` 作为最终身份判断
  资料保存后主动刷新当前 session，避免角色切换后首页还是旧状态

## Q9：现在这套设计已经完全覆盖医生/患者分流了吗？

还没有。

这次统一解决的是“身份定义”和“身份返回契约”问题，不是一次性把医生端 Flutter 页面都补完。

目前已经具备的前提是：

- 后端明确告诉前端当前生效身份是什么
- 前端已经有稳定字段可以消费

接下来如果要继续做医生/患者差异页面，应该直接基于 `current_role` 做，而不要再重复设计身份判断。

## Q10：当前仍然保留了哪些边界？

当前刻意保留了两个边界：

1. `profile_role` 不等于 `current_role`
   这是有意设计，不是 bug。

2. 医生资格的最终真值仍以后端审核结果为准
   Flutter 端只消费结果，不应自己推导审核逻辑。

## 结论

这次“身份统一”不是简单新增一个字段，而是明确了三件事：

- 用户资料里保存的角色偏好是什么
- 用户当前真正生效的身份是什么
- 医生资质当前处于什么状态

后续所有 Flutter 端的角色分流、底部导航、医生能力展示、患者能力展示，都应基于这套统一契约继续开发。
