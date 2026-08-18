<?php

declare(strict_types=1);

namespace plugin\help\app\api\controller;

use hg\apidoc\annotation as Apidoc;
use plugin\help\app\service\HelpDownloadPageService;
use plugin\saiadmin\basic\OpenController;
use support\Request;
use support\Response;

#[Apidoc\Group('公共配置')]
#[Apidoc\Title('HelpSupport App 下载页')]
class DownloadController extends OpenController
{
    public function __construct(private readonly HelpDownloadPageService $service = new HelpDownloadPageService())
    {
        parent::__construct();
    }

    #[Apidoc\Title('公开 App 下载页')]
    #[Apidoc\Url('/download')]
    #[Apidoc\Method('GET')]
    #[Apidoc\NotHeaders]
    public function page(Request $request): Response
    {
        $html = $this->service->renderPage($this->service->pageData($request));

        return response($html, 200, [
            'Content-Type' => 'text/html; charset=utf-8',
            'Cache-Control' => 'no-store, no-cache, must-revalidate',
        ]);
    }

    #[Apidoc\Title('iOS 开发版安装清单')]
    #[Apidoc\Url('/download/manifest.plist')]
    #[Apidoc\Method('GET')]
    #[Apidoc\NotHeaders]
    public function manifest(Request $request): Response
    {
        $xml = $this->service->manifestXml($request);
        if ($xml === null) {
            return response('manifest not available', 404, [
                'Content-Type' => 'text/plain; charset=utf-8',
            ]);
        }

        return response($xml, 200, [
            'Content-Type' => 'application/xml; charset=utf-8',
            'Cache-Control' => 'no-store, no-cache, must-revalidate',
        ]);
    }
}
