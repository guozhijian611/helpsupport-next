<?php

declare(strict_types=1);

namespace plugin\saiai\app\admin\controller\speech;

use hg\apidoc\annotation as Apidoc;
use plugin\saiadmin\basic\BaseController;
use plugin\saiadmin\exception\ApiException;
use plugin\saiadmin\service\Permission;
use plugin\saiai\app\service\SpeechService;
use support\Request;
use support\Response;

/**
 * SAIAI ASR / TTS 后台测试
 */
class SpeechTestController extends BaseController
{
    #[Apidoc\Title('语音测试配置列表')]
    #[Apidoc\Url('/app/saiai/admin/speech/SpeechTest/configs')]
    #[Apidoc\Method('GET')]
    #[Apidoc\Query('type', type: 'string', require: true, desc: 'asr 或 tts')]
    #[Permission('语音测试配置', 'saiai:speech:test')]
    public function configs(Request $request): Response
    {
        $type = (string) $request->get('type', '');
        return $this->success((new SpeechService())->listConfigs($type));
    }

    #[Apidoc\Title('ASR 转写测试')]
    #[Apidoc\Url('/app/saiai/admin/speech/SpeechTest/asr')]
    #[Apidoc\Method('POST')]
    #[Apidoc\ContentType('multipart/form-data')]
    #[Apidoc\Param('config_id', type: 'int', require: true, desc: 'ASR 配置 ID')]
    #[Apidoc\Param('file', type: 'file', require: true, desc: '音频文件')]
    #[Permission('ASR测试', 'saiai:speech:asr')]
    public function asr(Request $request): Response
    {
        $configId = (int) $request->post('config_id', 0);
        if ($configId <= 0) {
            throw new ApiException('请选择 ASR 配置', 400);
        }
        $file = $request->file('file') ?: current($request->file() ?: []);
        $text = (new SpeechService())->transcribeUploadedFile($configId, $file);

        return $this->success([
            'text' => $text,
            'config_id' => $configId,
        ]);
    }

    #[Apidoc\Title('TTS 合成测试')]
    #[Apidoc\Url('/app/saiai/admin/speech/SpeechTest/tts')]
    #[Apidoc\Method('POST')]
    #[Apidoc\Param('config_id', type: 'int', require: true, desc: 'TTS 配置 ID')]
    #[Apidoc\Param('text', type: 'string', require: true, desc: '要合成的文本')]
    #[Apidoc\Param('voice', type: 'string', require: false, desc: '音色，可空')]
    #[Permission('TTS测试', 'saiai:speech:tts')]
    public function tts(Request $request): Response
    {
        $configId = (int) $request->post('config_id', 0);
        if ($configId <= 0) {
            throw new ApiException('请选择 TTS 配置', 400);
        }
        $text = (string) $request->post('text', '');
        $voice = (string) $request->post('voice', '');
        $result = (new SpeechService())->synthesize($text, $configId, $voice, SpeechService::TYPE_TTS, false);

        return $this->success($result);
    }
}
