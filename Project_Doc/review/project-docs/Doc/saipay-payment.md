# SaiPay 支付插件接入说明

本文档说明 `saipay` 支付插件的配置分组、支付方式、订单字段、接口流程和人工扫码确认规则。插件源码位于 `server/plugin/saipay`，后台页面位于 `saiadmin-artd/src/views/plugin/saipay`。

## 支付方式

| 支付方式 | 内部值 | 当前能力 | 配置开关 |
| --- | --- | --- | --- |
| 支付宝支付 | `alipay` | 支持扫码、网页、H5、App、小程序等 `PayService` 已接入类型 | `saipay_config.alipay_enabled` |
| 微信支付 | `wechat` | 支持扫码、H5、App、小程序、公众号等 `PayService` 已接入类型 | `saipay_config.wechat_enabled` |
| 扫码支付 | `manual_scan` | 展示管理员配置的收款码，用户确认付款后由管理员人工确认到账 | `saipay_config.manual_scan_enabled` |
| 银联支付 | `unipay` | 目前仅保留配置和回调入口，暂未接入统一发起支付 | `saipay_config.unipay_enabled` |

`PayService::paymentMethods()` 只按支付方式开关决定是否返回该方式。某个方式返回后，不代表它一定能完成下单；例如银联支付目前会展示，但发起支付时会返回“不支持的支付渠道”。扫码支付会展示，但实际发起时要求至少配置一个收款码。

## 配置分组

### 支付插件配置

配置标识：`saipay_config`

用于控制支付方式是否在前台展示，并在后端发起支付前做启停校验。

| 配置项 | 说明 |
| --- | --- |
| `alipay_enabled` | 支付宝支付开关 |
| `wechat_enabled` | 微信支付开关 |
| `manual_scan_enabled` | 扫码支付开关 |
| `unipay_enabled` | 银联支付开关 |

### 扫码支付配置

配置标识：`qrpay_config`

用于人工扫码支付的收款码和通知邮箱。

| 配置项 | 说明 |
| --- | --- |
| `manual_scan_alipay_qrcode` | 支付宝收款二维码 |
| `manual_scan_wechat_qrcode` | 微信收款二维码 |
| `manual_scan_notice_emails` | 管理员通知邮箱，多个邮箱可用逗号、分号或换行分隔 |

扫码支付开关打开后会出现在支付方式列表中。用户真正进入扫码支付时，后端会要求至少配置一个收款码；用户点击“我已付款”时，后端会要求已配置管理员通知邮箱。

项目内置了两张扫码支付演示收款码，资源文件位于 `server/public/storage/20260606/`，迁移 `20260606000300_seed_qrpay_demo_assets.php` 会在收款码配置为空或仍是本地上传地址时写入这些演示资源。正式上线前可以在后台替换为真实收款码。

### 渠道配置

| 配置标识 | 说明 |
| --- | --- |
| `alipay_config` | 支付宝应用、密钥、证书和回调配置 |
| `wxpay_config` | 微信商户、证书和回调配置 |
| `unipay_config` | 银联配置；当前仅用于保留配置和回调能力 |

## 订单字段

支付订单表：`saipay_order`

| 字段 | 说明 |
| --- | --- |
| `order_no` | 插件支付订单号 |
| `order_name` | 订单名称 |
| `order_price` | 应付金额，单位元 |
| `pay_price` | 实付金额，单位元 |
| `pay_method` | 支付方式：`alipay`、`wechat`、`manual_scan`、`unipay` |
| `pay_type` | 支付类型：`scan`、`web`、`h5`、`app`、`mini`、`mp` |
| `pay_channel` | 实际收款渠道。人工扫码支付时记录 `alipay` 或 `wechat` |
| `pay_status` | 支付状态：`1` 已支付，`2` 未支付，`3` 待管理员确认 |
| `trade_no` | 第三方交易号或人工确认标识 |
| `pay_url` | 自动扫码支付二维码链接 |
| `pay_url_expire` | 自动扫码支付二维码过期时间 |
| `plugin` | 发起支付的业务插件 |
| `order_id` | 业务订单 ID |
| `member_id` | 会员 ID |

`pay_method` 表示用户选择的支付方式，`pay_channel` 表示资金实际付到哪里。人工扫码支付必须记录 `pay_channel`，否则管理员无法判断用户扫的是支付宝收款码还是微信收款码。

## 接口

### 可用支付方式

`GET /app/saipay/api/demo/paymentMethods`

返回已开启的支付方式列表。

关键返回字段：

| 字段 | 说明 |
| --- | --- |
| `label` | 前端展示名称 |
| `value` | 支付方式内部值 |
| `enabled` | 开关是否启用 |
| `manual` | 是否人工扫码支付 |
| `configured` | 人工扫码支付是否已配置至少一个收款码 |
| `qrcodes` | 人工扫码支付可选收款码列表 |
| `supported` | 当前是否已接入统一发起支付能力 |

### 创建扫码支付测试单

`GET /app/saipay/api/demo/manualScan`

创建测试订单并返回可选收款码。返回的 `qrcodes` 中每一项都有 `method`，前端必须让用户选择其中一个。

```json
{
  "pay_method": "manual_scan",
  "pay_type": "scan",
  "manual": true,
  "qrcodes": [
    {
      "label": "支付宝收款码",
      "method": "alipay",
      "image": "/storage/..."
    },
    {
      "label": "微信收款码",
      "method": "wechat",
      "image": "/storage/..."
    }
  ]
}
```

### 继续支付

`POST /app/saipay/api/demo/payOrder`

常用参数：

| 参数 | 说明 |
| --- | --- |
| `order_no` | 订单号 |
| `pay_method` | 可选，重新选择支付方式 |
| `pay_type` | 可选，支付类型 |

如果订单选择的是人工扫码支付，接口返回 `manual = true` 和 `qrcodes`，前端进入收款码选择界面。

### 用户确认扫码支付已付款

`POST /app/saipay/api/demo/confirmManualPaid`

参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `order_no` | 是 | 订单号 |
| `pay_channel` | 是 | 用户实际选择并付款的收款渠道：`alipay` 或 `wechat` |

后端会校验：

1. `pay_channel` 必须对应已配置的收款码。
2. 订单必须是 `manual_scan`。
3. 订单状态必须是未支付。
4. 管理员通知邮箱必须已配置。

校验通过后：

1. 订单 `pay_status` 更新为 `3`。
2. 订单 `pay_channel` 保存为用户选择的收款渠道。
3. 订单 `trade_no` 保存为 `manual_pending_<order_no>`。
4. 系统向管理员邮箱发送待确认通知。

### 管理员确认到账

`POST /app/saipay/admin/Order/confirmManualPaid`

参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `order_no` | 是 | 订单号 |

管理员确认后：

1. 订单 `pay_status` 更新为 `1`。
2. 订单 `pay_price` 更新为订单金额。
3. 订单 `pay_time` 写入确认时间。
4. 订单 `trade_no` 写入 `manual_scan_<pay_channel>_<order_no>`。
5. 触发 `saipay.order.paid` 事件。

## 人工扫码支付前端规则

人工扫码支付必须让用户二选一，不允许一次性展示多个收款码让用户自行决定。

推荐流程：

1. 用户选择“扫码支付”。
2. 前端展示“支付宝收款码”和“微信收款码”两个选项。
3. 用户选择一个选项后，只显示该渠道二维码。
4. 订单信息区显示：
   - 支付方式：扫码支付
   - 收款渠道：支付宝收款码或微信收款码
5. 用户点击“我已付款”时提交 `pay_channel`。
6. 管理员后台列表和详情展示 `pay_channel` 的中文名称。

这样后台可以明确知道用户声称付款到哪个渠道，管理员核账时不需要猜。

## 字典值

字典类型：`saipay_method`

| 展示名 | 字典值 |
| --- | --- |
| 支付宝 | `alipay` |
| 微信支付 | `wechat` |
| 扫码支付 | `manual_scan` |
| 银联支付 | `unipay` |

注意：`manual_scan` 是内部值，前端展示时必须兜底为“扫码支付”，不能直接把内部值展示给用户。

## 事件

支付成功后触发：

```php
Event::emit('saipay.order.paid', [
    'order' => $order,
    'context' => $context,
]);
```

人工扫码支付只有管理员确认到账后才触发该事件。用户点击“我已付款”只表示进入待确认状态，不代表支付成功。

### 管理员驳回付款确认

`POST /app/saipay/admin/Order/rejectManualPaid`

参数：

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `order_no` | 是 | 订单号 |
| `remark` | 是 | 驳回备注，例如未查到账、金额不一致、收款渠道不匹配 |

管理员驳回后：

1. 订单 `pay_status` 回到 `2` 未支付。
2. 清空 `pay_channel`，避免继续展示上一次用户声称付款的渠道。
3. `trade_no` 写入 `manual_rejected_<order_no>`。
4. 驳回原因写入订单 `remark`，格式为 `扫码支付驳回：<remark>`。
5. 不触发 `saipay.order.paid` 事件，用户可以重新发起或重新提交扫码支付确认。

## 验证命令

后端语法：

```bash
php -l server/plugin/saipay/service/PayService.php
php -l server/plugin/saipay/service/ManualScanPaymentService.php
php -l server/plugin/saipay/app/api/controller/DemoController.php
php -l server/plugin/saipay/app/api/logic/OrderLogic.php
```

迁移：

```bash
cd server
php webman b8:migrate --dry-run
php webman b8:migrate
php webman b8:migrate:status
```

路由：

```bash
cd server
php webman route:list | rg "paymentMethods|manualScan|confirmManualPaid|saipay/api/notify"
```

前端：

```bash
cd saiadmin-artd
pnpm build
```
