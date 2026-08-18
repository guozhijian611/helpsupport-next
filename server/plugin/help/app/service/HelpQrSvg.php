<?php

declare(strict_types=1);

namespace plugin\help\app\service;

/**
 * 轻量二维码 SVG 生成，仅用于公开下载页展示当前地址。
 */
final class HelpQrSvg
{
    /** @var array<int, array{0:int,1:int,2:int,3:int,4:int}> [eccPerBlock, g1Blocks, g1Data, g2Blocks, g2Data] */
    private const ECC_M = [
        1 => [10, 1, 16, 0, 0],
        2 => [16, 1, 28, 0, 0],
        3 => [26, 1, 44, 0, 0],
        4 => [18, 2, 32, 0, 0],
        5 => [24, 2, 43, 0, 0],
        6 => [16, 4, 27, 0, 0],
    ];

    /** @var array<int, list<int>> */
    private const ALIGNMENT = [
        1 => [],
        2 => [6, 18],
        3 => [6, 22],
        4 => [6, 26],
        5 => [6, 30],
        6 => [6, 34],
    ];

    /** @var array<int, int> */
    private const FORMAT_M = [
        0 => 0x5412,
        1 => 0x5125,
        2 => 0x5E7C,
        3 => 0x5B4B,
        4 => 0x45F9,
        5 => 0x40CE,
        6 => 0x4F97,
        7 => 0x4A80,
    ];

    public static function svg(string $text, int $module = 4, int $margin = 3): string
    {
        $matrix = self::matrix($text);
        if ($matrix === []) {
            return '';
        }

        $size = count($matrix);
        $dim = ($size + 2 * $margin) * $module;
        $rects = [];
        for ($r = 0; $r < $size; $r++) {
            for ($c = 0; $c < $size; $c++) {
                if ($matrix[$r][$c] !== 1) {
                    continue;
                }
                $x = ($c + $margin) * $module;
                $y = ($r + $margin) * $module;
                $rects[] = sprintf('<rect x="%d" y="%d" width="%d" height="%d"/>', $x, $y, $module, $module);
            }
        }

        return sprintf(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d" shape-rendering="crispEdges"><rect width="100%%" height="100%%" fill="#ffffff"/><g fill="#303236">%s</g></svg>',
            $dim,
            $dim,
            $dim,
            $dim,
            implode('', $rects)
        );
    }

    /**
     * @return list<list<int>>
     */
    public static function matrix(string $text): array
    {
        $bytes = array_values(unpack('C*', $text) ?: []);
        $version = self::pickVersion(count($bytes));
        if ($version === 0) {
            return [];
        }

        $bits = self::encodeBits($bytes, $version);
        $data = self::bitsToBytes($bits, self::dataCodewords($version));
        $codewords = self::interleave($data, $version);
        $size = $version * 4 + 17;
        $grid = array_fill(0, $size, array_fill(0, $size, null));
        $reserved = array_fill(0, $size, array_fill(0, $size, false));
        self::drawFunctionPatterns($grid, $reserved, $version, $size);
        self::placeData($grid, $reserved, $codewords, $size);

        $best = null;
        $bestScore = PHP_INT_MAX;
        for ($mask = 0; $mask < 8; $mask++) {
            $candidate = $grid;
            self::applyMask($candidate, $reserved, $mask, $size);
            self::drawFormat($candidate, $mask, $size);
            $score = self::penalty($candidate, $size);
            if ($score < $bestScore) {
                $bestScore = $score;
                $best = $candidate;
            }
        }

        if (!is_array($best)) {
            return [];
        }

        $matrix = [];
        for ($r = 0; $r < $size; $r++) {
            $row = [];
            for ($c = 0; $c < $size; $c++) {
                $row[] = ((int) $best[$r][$c]) === 1 ? 1 : 0;
            }
            $matrix[] = $row;
        }

        return $matrix;
    }

    private static function pickVersion(int $length): int
    {
        for ($version = 1; $version <= 6; $version++) {
            $countBits = $version >= 10 ? 16 : 8;
            $needBits = 4 + $countBits + $length * 8 + 4;
            if ((int) ceil($needBits / 8) <= self::dataCodewords($version)) {
                return $version;
            }
        }

        return 0;
    }

    private static function dataCodewords(int $version): int
    {
        [$ecc, $g1, $d1, $g2, $d2] = self::ECC_M[$version];
        unset($ecc);

        return $g1 * $d1 + $g2 * $d2;
    }

    /**
     * @param list<int> $bytes
     * @return list<int>
     */
    private static function encodeBits(array $bytes, int $version): array
    {
        $bits = [];
        self::pushBits($bits, 0b0100, 4);
        self::pushBits($bits, count($bytes), $version >= 10 ? 16 : 8);
        foreach ($bytes as $byte) {
            self::pushBits($bits, $byte, 8);
        }
        $capacity = self::dataCodewords($version) * 8;
        $remain = $capacity - count($bits);
        self::pushBits($bits, 0, min(4, max(0, $remain)));
        while (count($bits) % 8 !== 0) {
            $bits[] = 0;
        }
        $pad = true;
        while (count($bits) < $capacity) {
            self::pushBits($bits, $pad ? 0xEC : 0x11, 8);
            $pad = !$pad;
        }

        return array_slice($bits, 0, $capacity);
    }

    /**
     * @param list<int> $bits
     * @return list<int>
     */
    private static function bitsToBytes(array $bits, int $count): array
    {
        $bytes = [];
        for ($i = 0; $i < $count; $i++) {
            $value = 0;
            for ($b = 0; $b < 8; $b++) {
                $value = ($value << 1) | ($bits[$i * 8 + $b] ?? 0);
            }
            $bytes[] = $value;
        }

        return $bytes;
    }

    /**
     * @param list<int> $data
     * @return list<int>
     */
    private static function interleave(array $data, int $version): array
    {
        [$eccPerBlock, $g1, $d1, $g2, $d2] = self::ECC_M[$version];
        $blocks = [];
        $offset = 0;
        for ($i = 0; $i < $g1; $i++) {
            $block = array_slice($data, $offset, $d1);
            $offset += $d1;
            $blocks[] = [...$block, ...self::reedSolomon($block, $eccPerBlock)];
        }
        for ($i = 0; $i < $g2; $i++) {
            $block = array_slice($data, $offset, $d2);
            $offset += $d2;
            $blocks[] = [...$block, ...self::reedSolomon($block, $eccPerBlock)];
        }

        $maxData = max($d1, $d2);
        $result = [];
        for ($i = 0; $i < $maxData; $i++) {
            foreach ($blocks as $index => $block) {
                $dataLen = $index < $g1 ? $d1 : $d2;
                if ($i < $dataLen) {
                    $result[] = $block[$i];
                }
            }
        }
        for ($i = 0; $i < $eccPerBlock; $i++) {
            foreach ($blocks as $block) {
                $dataLen = count($block) - $eccPerBlock;
                $result[] = $block[$dataLen + $i];
            }
        }

        return $result;
    }

    /**
     * @param list<int> $data
     * @return list<int>
     */
    private static function reedSolomon(array $data, int $degree): array
    {
        $gf = self::gf();
        $gen = [1];
        for ($i = 0; $i < $degree; $i++) {
            $next = array_fill(0, count($gen) + 1, 0);
            $factor = $gf['exp'][$i];
            for ($j = 0; $j < count($gen); $j++) {
                $next[$j] ^= $gen[$j];
                $next[$j + 1] ^= self::gfMul($gen[$j], $factor, $gf);
            }
            $gen = $next;
        }

        $ecc = array_fill(0, $degree, 0);
        foreach ($data as $byte) {
            $factor = $byte ^ $ecc[0];
            array_shift($ecc);
            $ecc[] = 0;
            if ($factor === 0) {
                continue;
            }
            for ($i = 0; $i < $degree; $i++) {
                $ecc[$i] ^= self::gfMul($gen[$i + 1], $factor, $gf);
            }
        }

        return $ecc;
    }

    /**
     * @return array{exp: list<int>, log: list<int>}
     */
    private static function gf(): array
    {
        static $tables = null;
        if ($tables !== null) {
            return $tables;
        }

        $exp = array_fill(0, 512, 0);
        $log = array_fill(0, 256, 0);
        $value = 1;
        for ($i = 0; $i < 255; $i++) {
            $exp[$i] = $value;
            $log[$value] = $i;
            $value <<= 1;
            if ($value & 0x100) {
                $value ^= 0x11d;
            }
        }
        for ($i = 255; $i < 512; $i++) {
            $exp[$i] = $exp[$i - 255];
        }
        $tables = ['exp' => $exp, 'log' => $log];

        return $tables;
    }

    /**
     * @param array{exp: list<int>, log: list<int>} $gf
     */
    private static function gfMul(int $a, int $b, array $gf): int
    {
        if ($a === 0 || $b === 0) {
            return 0;
        }

        return $gf['exp'][$gf['log'][$a] + $gf['log'][$b]];
    }

    /**
     * @param list<list<int|null>> $grid
     * @param list<list<bool>> $reserved
     */
    private static function drawFunctionPatterns(array &$grid, array &$reserved, int $version, int $size): void
    {
        self::drawFinder($grid, $reserved, 0, 0);
        self::drawFinder($grid, $reserved, $size - 7, 0);
        self::drawFinder($grid, $reserved, 0, $size - 7);
        for ($i = 0; $i < $size; $i++) {
            if (!$reserved[6][$i]) {
                self::setReserved($grid, $reserved, 6, $i, $i % 2 === 0 ? 1 : 0);
            }
            if (!$reserved[$i][6]) {
                self::setReserved($grid, $reserved, $i, 6, $i % 2 === 0 ? 1 : 0);
            }
        }
        foreach (self::ALIGNMENT[$version] as $y) {
            foreach (self::ALIGNMENT[$version] as $x) {
                if (($x === 6 && $y === 6) || ($x === 6 && $y === $size - 7) || ($x === $size - 7 && $y === 6)) {
                    continue;
                }
                self::drawAlignment($grid, $reserved, $x, $y);
            }
        }
        for ($i = 0; $i < 9; $i++) {
            self::reserve($reserved, 8, $i);
            self::reserve($reserved, $i, 8);
        }
        for ($i = 0; $i < 8; $i++) {
            self::reserve($reserved, 8, $size - 1 - $i);
            self::reserve($reserved, $size - 1 - $i, 8);
        }
        self::setReserved($grid, $reserved, $size - 8, 8, 1);
    }

    /**
     * @param list<list<int|null>> $grid
     * @param list<list<bool>> $reserved
     */
    private static function drawFinder(array &$grid, array &$reserved, int $x, int $y): void
    {
        for ($r = -1; $r <= 7; $r++) {
            for ($c = -1; $c <= 7; $c++) {
                $rr = $y + $r;
                $cc = $x + $c;
                if ($rr < 0 || $cc < 0 || $rr >= count($grid) || $cc >= count($grid)) {
                    continue;
                }
                $on = ($r >= 0 && $r <= 6 && $c >= 0 && $c <= 6)
                    && ($r === 0 || $r === 6 || $c === 0 || $c === 6 || ($r >= 2 && $r <= 4 && $c >= 2 && $c <= 4));
                self::setReserved($grid, $reserved, $rr, $cc, $on ? 1 : 0);
            }
        }
    }

    /**
     * @param list<list<int|null>> $grid
     * @param list<list<bool>> $reserved
     */
    private static function drawAlignment(array &$grid, array &$reserved, int $cx, int $cy): void
    {
        for ($r = -2; $r <= 2; $r++) {
            for ($c = -2; $c <= 2; $c++) {
                $on = max(abs($r), abs($c)) !== 1;
                self::setReserved($grid, $reserved, $cy + $r, $cx + $c, $on ? 1 : 0);
            }
        }
    }

    /**
     * @param list<list<int|null>> $grid
     * @param list<list<bool>> $reserved
     * @param list<int> $codewords
     */
    private static function placeData(array &$grid, array $reserved, array $codewords, int $size): void
    {
        $bits = [];
        foreach ($codewords as $byte) {
            for ($i = 7; $i >= 0; $i--) {
                $bits[] = ($byte >> $i) & 1;
            }
        }
        $index = 0;
        $up = true;
        for ($col = $size - 1; $col > 0; $col -= 2) {
            if ($col === 6) {
                $col--;
            }
            for ($n = 0; $n < $size; $n++) {
                $row = $up ? $size - 1 - $n : $n;
                for ($offset = 0; $offset < 2; $offset++) {
                    $c = $col - $offset;
                    if ($reserved[$row][$c] || $grid[$row][$c] !== null) {
                        continue;
                    }
                    $grid[$row][$c] = $bits[$index] ?? 0;
                    $index++;
                }
            }
            $up = !$up;
        }
        for ($r = 0; $r < $size; $r++) {
            for ($c = 0; $c < $size; $c++) {
                if ($grid[$r][$c] === null) {
                    $grid[$r][$c] = 0;
                }
            }
        }
    }

    /**
     * @param list<list<int|null>> $grid
     * @param list<list<bool>> $reserved
     */
    private static function applyMask(array &$grid, array $reserved, int $mask, int $size): void
    {
        for ($r = 0; $r < $size; $r++) {
            for ($c = 0; $c < $size; $c++) {
                if ($reserved[$r][$c]) {
                    continue;
                }
                if (self::maskBit($mask, $r, $c)) {
                    $grid[$r][$c] = ((int) $grid[$r][$c]) ^ 1;
                }
            }
        }
    }

    private static function maskBit(int $mask, int $r, int $c): bool
    {
        return match ($mask) {
            0 => ($r + $c) % 2 === 0,
            1 => $r % 2 === 0,
            2 => $c % 3 === 0,
            3 => ($r + $c) % 3 === 0,
            4 => (intdiv($r, 2) + intdiv($c, 3)) % 2 === 0,
            5 => ($r * $c) % 2 + ($r * $c) % 3 === 0,
            6 => (($r * $c) % 2 + ($r * $c) % 3) % 2 === 0,
            default => (($r + $c) % 2 + ($r * $c) % 3) % 2 === 0,
        };
    }

    /**
     * @param list<list<int|null>> $grid
     */
    private static function drawFormat(array &$grid, int $mask, int $size): void
    {
        $bits = self::FORMAT_M[$mask];
        for ($i = 0; $i <= 5; $i++) {
            $grid[$i][8] = ($bits >> $i) & 1;
        }
        $grid[7][8] = ($bits >> 6) & 1;
        $grid[8][8] = ($bits >> 7) & 1;
        $grid[8][7] = ($bits >> 8) & 1;
        for ($i = 9; $i < 15; $i++) {
            $grid[8][14 - $i] = ($bits >> $i) & 1;
        }
        for ($i = 0; $i < 8; $i++) {
            $grid[8][$size - 1 - $i] = ($bits >> $i) & 1;
        }
        for ($i = 8; $i < 15; $i++) {
            $grid[$size - 15 + $i][8] = ($bits >> $i) & 1;
        }
    }

    /**
     * @param list<list<int|null>> $grid
     */
    private static function penalty(array $grid, int $size): int
    {
        $score = 0;
        for ($r = 0; $r < $size; $r++) {
            $score += self::runPenalty(array_map(static fn ($v) => (int) $v, $grid[$r]));
        }
        for ($c = 0; $c < $size; $c++) {
            $col = [];
            for ($r = 0; $r < $size; $r++) {
                $col[] = (int) $grid[$r][$c];
            }
            $score += self::runPenalty($col);
        }
        for ($r = 0; $r < $size - 1; $r++) {
            for ($c = 0; $c < $size - 1; $c++) {
                $v = (int) $grid[$r][$c];
                if ($v === (int) $grid[$r][$c + 1] && $v === (int) $grid[$r + 1][$c] && $v === (int) $grid[$r + 1][$c + 1]) {
                    $score += 3;
                }
            }
        }

        return $score;
    }

    /**
     * @param list<int> $line
     */
    private static function runPenalty(array $line): int
    {
        $score = 0;
        $count = 1;
        for ($i = 1, $n = count($line); $i <= $n; $i++) {
            if ($i < $n && $line[$i] === $line[$i - 1]) {
                $count++;
                continue;
            }
            if ($count >= 5) {
                $score += 3 + ($count - 5);
            }
            $count = 1;
        }

        return $score;
    }

    /**
     * @param list<list<int|null>> $grid
     * @param list<list<bool>> $reserved
     */
    private static function setReserved(array &$grid, array &$reserved, int $r, int $c, int $value): void
    {
        $grid[$r][$c] = $value;
        $reserved[$r][$c] = true;
    }

    /**
     * @param list<list<bool>> $reserved
     */
    private static function reserve(array &$reserved, int $r, int $c): void
    {
        if ($r >= 0 && $c >= 0 && $r < count($reserved) && $c < count($reserved)) {
            $reserved[$r][$c] = true;
        }
    }

    /**
     * @param list<int> $bits
     */
    private static function pushBits(array &$bits, int $value, int $length): void
    {
        for ($i = $length - 1; $i >= 0; $i--) {
            $bits[] = ($value >> $i) & 1;
        }
    }
}
