<?php

namespace app\controller;

use hg\apidoc\export\ExportSwagger;
use hg\apidoc\middleware\WebmanMiddleware;
use hg\apidoc\utils\ApiShare;
use hg\apidoc\utils\ConfigProvider;
use hg\apidoc\utils\Helper;
use support\Request;
use support\Response;

class ApidocOpenapiController
{
    public function show(Request $request, string $appKey): Response
    {
        $config = WebmanMiddleware::getApidocConfig();
        ConfigProvider::set($config);

        $apps = Helper::handleAppsConfig($config['apps'], false, $config);
        $apiData = ApiShare::getAppShareApis($config, $apps, '', [$appKey], true);

        if (empty($apiData)) {
            return json([
                'code' => 404,
                'message' => "APIDOC app key [{$appKey}] 不存在",
            ], 404);
        }

        $openapi = (new ExportSwagger($config['export_config']))->exportJson($config, [
            'shareData' => [
                'type' => 'app',
                'appKeys' => [$appKey],
            ],
            'apiData' => $apiData,
        ]);
        $openapi = $this->mergeSamePathMethods($openapi, $config, $apiData, $appKey);

        return json($openapi);
    }

    /**
     * hg/apidoc-export 0.x 在同一 path 同时存在 GET/POST 时只保留第一个接口。
     * 这里用原始 APIDOC 数据逐个导出缺失 method，再合并回总 OpenAPI。
     */
    private function mergeSamePathMethods(array $openapi, array $config, array $apiData, string $appKey): array
    {
        foreach ($this->collectApiItems($apiData) as $item) {
            $api = $item['api'];
            $url = (string) ($api['url'] ?? '');
            if ($url === '' || empty($api['method'])) {
                continue;
            }

            $methods = is_array($api['method']) ? $api['method'] : [$api['method']];
            foreach ($methods as $method) {
                $methodKey = strtolower((string) $method);
                if ($methodKey === '' || isset($openapi['paths'][$url][$methodKey])) {
                    continue;
                }

                $singleOpenapi = (new ExportSwagger($config['export_config']))->exportJson($config, [
                    'shareData' => [
                        'type' => 'app',
                        'appKeys' => [$appKey],
                    ],
                    'apiData' => [$this->singleApiData($item['app'], $item['controller'], $api)],
                ]);
                if (!empty($singleOpenapi['paths'][$url][$methodKey])) {
                    $openapi['paths'][$url][$methodKey] = $singleOpenapi['paths'][$url][$methodKey];
                    $openapi = $this->mergeOpenapiComponents($openapi, $singleOpenapi);
                }
            }
        }

        return $openapi;
    }

    private function collectApiItems(array $apiData): array
    {
        $items = [];
        foreach ($apiData as $app) {
            foreach (($app['children'] ?? []) as $controller) {
                foreach (($controller['children'] ?? []) as $api) {
                    if (!empty($api['url'])) {
                        $items[] = [
                            'app' => $app,
                            'controller' => $controller,
                            'api' => $api,
                        ];
                    }
                }
            }
        }

        return $items;
    }

    private function singleApiData(array $app, array $controller, array $api): array
    {
        $controller['children'] = [$api];
        $app['children'] = [$controller];

        return $app;
    }

    private function mergeOpenapiComponents(array $openapi, array $singleOpenapi): array
    {
        foreach (($singleOpenapi['tags'] ?? []) as $tag) {
            $tagName = $tag['name'] ?? null;
            if (!$tagName) {
                continue;
            }
            $exists = false;
            foreach (($openapi['tags'] ?? []) as $existingTag) {
                if (($existingTag['name'] ?? null) === $tagName) {
                    $exists = true;
                    break;
                }
            }
            if (!$exists) {
                $openapi['tags'][] = $tag;
            }
        }

        foreach (($singleOpenapi['components']['schemas'] ?? []) as $name => $schema) {
            $openapi['components']['schemas'][$name] = $openapi['components']['schemas'][$name] ?? $schema;
        }

        return $openapi;
    }
}
