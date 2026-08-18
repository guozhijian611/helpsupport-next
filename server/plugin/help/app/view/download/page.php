<?php
/** @var array<string, mixed> $data */
$e = static fn (mixed $value): string => htmlspecialchars((string) $value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
$name = $e($data['name'] ?? 'HelpSupport');
$logo = $e($data['logo'] ?? '');
$description = $e($data['description'] ?? '');
$pageUrl = $e($data['page_url'] ?? '');
$qrSvg = (string) ($data['qr_svg'] ?? '');
$appStoreUrl = $e($data['store']['app_store_url'] ?? '');
$googlePlayUrl = $e($data['store']['google_play_url'] ?? '');
$testflightPublicUrl = $e($data['testflight']['public_url'] ?? '');
$testflightInternalUrl = $e($data['testflight']['internal_url'] ?? '');
$apkUrl = $e($data['dev']['apk_url'] ?? '');
$ipaUrl = $e($data['dev']['ipa_url'] ?? '');
$otaUrl = $e($data['ota_url'] ?? '');
$hasStore = !empty($data['has_store']);
$hasTestflight = !empty($data['has_testflight']);
$hasDev = !empty($data['has_dev']);
$hasAny = $hasStore || $hasTestflight || $hasDev;
$initial = $e(mb_substr((string) ($data['name'] ?? 'H'), 0, 1));
?>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#FF9585">
  <title><?= $name ?> 下载</title>
  <meta name="description" content="<?= $description ?>">
  <style>
    :root {
      --brand: #FF9585;
      --brand-deep: #FF8D7F;
      --brand-soft: #FFB4A8;
      --bg: #F3F5FA;
      --card: #ffffff;
      --text: #303236;
      --muted: #96999F;
      --line: #ECE7E4;
      --shadow: 0 18px 40px rgba(48, 50, 54, 0.08);
    }
    * { box-sizing: border-box; }
    html, body {
      margin: 0;
      min-height: 100%;
      background:
        radial-gradient(1200px 420px at 50% -80px, rgba(255, 149, 133, 0.28), transparent 70%),
        var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
    }
    .wrap {
      width: min(920px, calc(100% - 32px));
      margin: 0 auto;
      padding: 32px 0 48px;
    }
    .hero {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      gap: 12px;
      margin-bottom: 24px;
    }
    .logo, .logo-fallback {
      width: 88px;
      height: 88px;
      border-radius: 22px;
      box-shadow: var(--shadow);
      object-fit: cover;
      background: linear-gradient(135deg, #FF9585, #FCB08E);
    }
    .logo-fallback {
      display: grid;
      place-items: center;
      color: #fff;
      font-size: 36px;
      font-weight: 700;
    }
    h1 {
      margin: 8px 0 0;
      font-size: 28px;
      font-weight: 700;
    }
    .desc {
      max-width: 520px;
      margin: 0;
      color: var(--muted);
      line-height: 1.7;
      font-size: 15px;
    }
    .layout {
      display: grid;
      grid-template-columns: minmax(0, 1.15fr) 280px;
      gap: 20px;
      align-items: start;
    }
    .card {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 20px;
      padding: 22px;
      box-shadow: var(--shadow);
    }
    .section-title {
      margin: 0 0 14px;
      font-size: 15px;
      font-weight: 700;
    }
    .actions { display: grid; gap: 12px; }
    .btn {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 10px;
      min-height: 52px;
      padding: 12px 16px;
      border-radius: 14px;
      text-decoration: none;
      font-weight: 600;
      font-size: 15px;
      color: #fff;
      background: linear-gradient(135deg, var(--brand), #FCB08E);
    }
    .btn.secondary {
      color: var(--text);
      background: #F7F7FA;
      border: 1px solid var(--line);
    }
    .btn.ios { background: #303236; }
    .btn.android { background: linear-gradient(135deg, #5A81DA, #7AA0E8); }
    .btn svg { width: 18px; height: 18px; fill: currentColor; }
    .empty {
      padding: 18px 8px;
      color: var(--muted);
      text-align: center;
      line-height: 1.7;
    }
    .qr {
      text-align: center;
    }
    .qr-box {
      display: grid;
      place-items: center;
      width: 196px;
      height: 196px;
      margin: 0 auto 12px;
      padding: 10px;
      border: 1px solid var(--line);
      border-radius: 16px;
      background: #fff;
    }
    .qr-box svg { width: 100%; height: 100%; }
    .qr p {
      margin: 0;
      color: var(--muted);
      font-size: 13px;
      line-height: 1.6;
    }
    .url {
      margin-top: 10px;
      word-break: break-all;
      color: #7D828A;
      font-size: 12px;
    }
    .wechat-mask {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0, 0, 0, 0.72);
      color: #fff;
      z-index: 20;
      padding: 24px;
    }
    .wechat-mask.show { display: grid; align-content: start; justify-items: end; }
    .wechat-mask p {
      width: min(280px, 100%);
      margin-top: 8px;
      line-height: 1.7;
      text-align: right;
    }
    @media (max-width: 760px) {
      .layout { grid-template-columns: 1fr; }
      .qr { order: -1; }
      .wrap { padding-top: 20px; }
    }
  </style>
</head>
<body>
  <div class="wrap">
    <header class="hero">
      <?php if ($logo !== ''): ?>
        <img class="logo" src="<?= $logo ?>" alt="<?= $name ?>">
      <?php else: ?>
        <div class="logo-fallback" aria-hidden="true"><?= $initial ?></div>
      <?php endif; ?>
      <h1><?= $name ?></h1>
      <p class="desc"><?= $description ?></p>
    </header>

    <div class="layout">
      <main class="card">
        <?php if ($hasStore): ?>
          <h2 class="section-title">商店下载</h2>
          <div class="actions" style="margin-bottom: 22px;">
            <?php if ($appStoreUrl !== ''): ?>
              <a class="btn ios" data-platform="ios" href="<?= $appStoreUrl ?>">
                <svg viewBox="0 0 24 24"><path d="M16.2 12.4c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.5.9s-1.8-.8-3-.8c-1.5 0-3 .9-3.8 2.3-1.6 2.8-.4 7 1.2 9.3.8 1.1 1.7 2.3 2.9 2.3 1.2 0 1.6-.7 3-.7s1.8.7 3 .7 2.1-1.1 2.8-2.2c.9-1.2 1.2-2.4 1.2-2.5 0 0-2.1-.8-2.1-3zM14.3 6.8c.6-.8 1.1-1.9.9-3-1 .1-2.1.7-2.8 1.5-.6.7-1.2 1.8-1 2.9 1.1.1 2.2-.6 2.9-1.4z"/></svg>
                App Store
              </a>
            <?php endif; ?>
            <?php if ($googlePlayUrl !== ''): ?>
              <a class="btn android" data-platform="android" href="<?= $googlePlayUrl ?>">
                <svg viewBox="0 0 24 24"><path d="M4.2 2.8 14.7 12 4.2 21.2c-.5-.3-.8-.8-.8-1.4V4.2c0-.6.3-1.1.8-1.4zm12.1 10.6 2.4 2.4c.8-.5 2.3-1.4 2.3-3.8s-1.5-3.3-2.3-3.8l-2.4 2.4 1.2 1.4-1.2 1.4zm-1.6-1.4L5.6 3.4l9.6 9.6-2.5 2.4z"/></svg>
                Google Play
              </a>
            <?php endif; ?>
          </div>
        <?php endif; ?>

        <?php if ($hasTestflight): ?>
          <h2 class="section-title">TestFlight</h2>
          <div class="actions" style="margin-bottom: 22px;">
            <?php if ($testflightPublicUrl !== ''): ?>
              <a class="btn ios" data-platform="ios" href="<?= $testflightPublicUrl ?>">TestFlight 公共测试</a>
            <?php endif; ?>
            <?php if ($testflightInternalUrl !== ''): ?>
              <a class="btn secondary" data-platform="ios" href="<?= $testflightInternalUrl ?>">TestFlight 内部测试</a>
            <?php endif; ?>
          </div>
        <?php endif; ?>

        <?php if ($hasDev): ?>
          <h2 class="section-title">内测 / 开发版</h2>
          <div class="actions">
            <?php if ($apkUrl !== ''): ?>
              <a class="btn" data-platform="android" href="<?= $apkUrl ?>">下载 Android APK</a>
            <?php endif; ?>
            <?php if ($otaUrl !== ''): ?>
              <a class="btn ios" data-platform="ios" href="<?= $otaUrl ?>">安装 iOS 内测版</a>
            <?php endif; ?>
            <?php if ($ipaUrl !== ''): ?>
              <a class="btn secondary" data-platform="ios" href="<?= $ipaUrl ?>">下载 iOS IPA</a>
            <?php endif; ?>
          </div>
        <?php endif; ?>

        <?php if (!$hasAny): ?>
          <div class="empty">暂未配置下载地址，请先在后台填写商店链接或安装包。</div>
        <?php endif; ?>
      </main>

      <aside class="card qr">
        <h2 class="section-title">手机扫码下载</h2>
        <div class="qr-box"><?= $qrSvg !== '' ? $qrSvg : '<span style="color:#96999F">二维码暂不可用</span>' ?></div>
        <p>使用手机相机或浏览器扫描</p>
        <div class="url"><?= $pageUrl ?></div>
      </aside>
    </div>
  </div>

  <div class="wechat-mask" id="wechatMask">
    <p>请点击右上角菜单，选择「在浏览器中打开」后再下载安装。</p>
  </div>

  <script>
    (function () {
      var ua = navigator.userAgent || '';
      var isWeChat = /MicroMessenger/i.test(ua);
      var isIOS = /iPad|iPhone|iPod/i.test(ua);
      var isAndroid = /Android/i.test(ua);
      var mask = document.getElementById('wechatMask');
      if (isWeChat && mask) {
        mask.classList.add('show');
        mask.addEventListener('click', function () { mask.classList.remove('show'); });
      }
      document.querySelectorAll('[data-platform]').forEach(function (el) {
        var platform = el.getAttribute('data-platform');
        if ((isIOS && platform === 'android') || (isAndroid && platform === 'ios')) {
          el.style.opacity = '0.72';
        }
      });
    })();
  </script>
</body>
</html>
