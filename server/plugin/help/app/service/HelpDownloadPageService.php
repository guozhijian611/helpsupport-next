<?php

declare(strict_types=1);

namespace plugin\help\app\service;

use support\Request;

class HelpDownloadPageService
{
    private const DEFAULT_BUNDLE_ID = 'com.openb8.helpsupportApp';
    private const DEFAULT_VERSION = '1.0.0';

    public function __construct(private readonly HelpApiService $api = new HelpApiService())
    {
    }

    public function pageData(Request $request): array
    {
        $config = $this->api->appConfig();
        $baseUrl = $this->publicBaseUrl($request);
        $pageUrl = $baseUrl . '/download';
        $app = is_array($config['app'] ?? null) ? $config['app'] : [];
        $download = is_array($config['download'] ?? null) ? $config['download'] : [];
        $oauth = is_array($config['oauth']['apple'] ?? null) ? $config['oauth']['apple'] : [];

        $name = $this->filled($app['name'] ?? null, 'HelpSupport');
        $logo = $this->absoluteUrl((string) ($app['logo'] ?? ''), $baseUrl);
        $description = $this->filled(
            $app['description'] ?? null,
            '治疗支持 App，帮助你更好地完成日常恢复与陪伴。'
        );
        $store = [
            'app_store_url' => $this->absoluteUrl((string) ($download['app_store_url'] ?? ''), $baseUrl),
            'google_play_url' => $this->absoluteUrl((string) ($download['google_play_url'] ?? ''), $baseUrl),
        ];
        $testflight = [
            'public_url' => $this->absoluteUrl((string) ($download['testflight_public_url'] ?? ''), $baseUrl),
            'internal_url' => $this->absoluteUrl((string) ($download['testflight_internal_url'] ?? ''), $baseUrl),
        ];
        $dev = [
            'apk_url' => $this->absoluteUrl((string) ($download['dev_apk_url'] ?? ''), $baseUrl),
            'ipa_url' => $this->absoluteUrl((string) ($download['dev_ipa_url'] ?? ''), $baseUrl),
        ];
        $ipaUrl = $dev['ipa_url'];
        $canOta = $ipaUrl !== '' && str_starts_with(strtolower($ipaUrl), 'https://');
        $plistUrl = $canOta ? $baseUrl . '/download/manifest.plist' : '';
        $otaUrl = $plistUrl !== ''
            ? 'itms-services://?action=download-manifest&url=' . rawurlencode($plistUrl)
            : '';

        return [
            'name' => $name,
            'logo' => $logo,
            'description' => $description,
            'page_url' => $pageUrl,
            'qr_svg' => HelpQrSvg::svg($pageUrl),
            'store' => $store,
            'testflight' => $testflight,
            'dev' => $dev,
            'ota_url' => $otaUrl,
            'has_store' => $store['app_store_url'] !== '' || $store['google_play_url'] !== '',
            'has_testflight' => $testflight['public_url'] !== '' || $testflight['internal_url'] !== '',
            'has_dev' => $dev['apk_url'] !== '' || $dev['ipa_url'] !== '',
            'bundle_id' => $this->filled($oauth['bundle_id'] ?? null, self::DEFAULT_BUNDLE_ID),
        ];
    }

    public function manifestXml(Request $request): ?string
    {
        $data = $this->pageData($request);
        $ipaUrl = (string) ($data['dev']['ipa_url'] ?? '');
        if ($ipaUrl === '' || !str_starts_with(strtolower($ipaUrl), 'https://')) {
            return null;
        }

        $name = $this->xml($data['name']);
        $bundleId = $this->xml($data['bundle_id']);
        $ipa = $this->xml($ipaUrl);
        $logo = $this->xml((string) $data['logo']);
        $iconAsset = $logo !== ''
            ? <<<XML
				<dict>
					<key>kind</key>
					<string>display-image</string>
					<key>need-shine</key>
					<false/>
					<key>url</key>
					<string>{$logo}</string>
				</dict>
XML
            : '';

        return <<<XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>items</key>
	<array>
		<dict>
			<key>assets</key>
			<array>
				<dict>
					<key>kind</key>
					<string>software-package</string>
					<key>url</key>
					<string>{$ipa}</string>
				</dict>
{$iconAsset}
			</array>
			<key>metadata</key>
			<dict>
				<key>bundle-identifier</key>
				<string>{$bundleId}</string>
				<key>bundle-version</key>
				<string>{$this->xml(self::DEFAULT_VERSION)}</string>
				<key>kind</key>
				<string>software</string>
				<key>title</key>
				<string>{$name}</string>
			</dict>
		</dict>
	</array>
</dict>
</plist>
XML;
    }

    public function renderPage(array $data): string
    {
        $view = base_path() . '/plugin/help/app/view/download/page.php';
        ob_start();
        include $view;

        return (string) ob_get_clean();
    }

    public function publicBaseUrl(Request $request): string
    {
        $forwarded = strtolower(trim(explode(',', (string) (
            $request->header('x-forwarded-proto')
            ?: $request->header('x-forwarded-scheme')
            ?: ''
        ))[0]));
        $host = trim(explode(',', (string) ($request->header('x-forwarded-host') ?: $request->host()))[0]);
        if (in_array($forwarded, ['http', 'https'], true)) {
            $proto = $forwarded;
        } else {
            $https = strtolower((string) $request->header('https', ''));
            $proto = in_array($https, ['on', '1'], true) || str_contains($host, 'openb8.org')
                ? 'https'
                : 'http';
        }
        if ($host === '') {
            $host = '127.0.0.1:8787';
        }

        return $proto . '://' . $host;
    }

    private function absoluteUrl(string $url, string $baseUrl): string
    {
        $url = trim($url);
        if ($url === '') {
            return '';
        }
        if (preg_match('#^https?://#i', $url) === 1) {
            return $url;
        }
        if (str_starts_with($url, '//')) {
            $proto = str_starts_with($baseUrl, 'https://') ? 'https:' : 'http:';
            return $proto . $url;
        }
        if (str_starts_with($url, '/')) {
            return $baseUrl . $url;
        }

        return $baseUrl . '/' . ltrim($url, '/');
    }

    private function filled(?string $value, string $fallback = ''): string
    {
        $value = trim((string) $value);

        return $value !== '' ? $value : $fallback;
    }

    private function xml(string $value): string
    {
        return htmlspecialchars($value, ENT_QUOTES | ENT_XML1, 'UTF-8');
    }
}
