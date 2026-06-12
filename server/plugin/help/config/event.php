<?php

return [
    'member.login' => [
        [plugin\help\app\event\MemberLogin::class, 'deactivatePushDevices'],
    ],
];
