#Requires -Version 5.1
<#
.SYNOPSIS
    本地泄漏扫描器 —— 红线约定的自动执行部分。
.DESCRIPTION
    扫描仓库内容，拦截密钥、凭据、内网信息、可疑文件名与超大文件。
    规则来源：
        .leakscan/content/*.txt   内容正则（逐行扫描文件内容）
        .leakscan/names/*.txt     路径正则（匹配仓库内相对路径）
    规则语法为 POSIX 扩展正则，一行一条，# 开头为注释。
    安全设计：命中时只报告「文件 + 行号」，绝不打印匹配原文，
    避免把密钥本身写进终端日志、CI 日志或提交信息。
    全程只读写本仓库内部：临时文件写在 .git 目录下，用完即删，
    不向外写任何内容（红线第 1 条）。
.PARAMETER Staged
    只扫描已暂存的内容。pre-commit 钩子使用此模式。
.PARAMETER IncludeUntracked
    全量扫描时，额外扫描未被 .gitignore 忽略的未跟踪文件。
.PARAMETER MaxFileMB
    单文件体积上限，默认 5 MB。超过即拦截；1 MB 以上给出提醒。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\leak-scan.ps1
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\leak-scan.ps1 -Staged
.NOTES
    退出码：0 = 通过；1 = 存在拦截项；2 = 扫描器自身出错。
#>
[CmdletBinding()]
param(
    [switch]$Staged,
    [switch]$IncludeUntracked,
    [double]$MaxFileMB = 5
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

# 扫描器自身与规则库不参与内容扫描（规则文件里含有特征串本身）
$SelfExclude = @(
    ':(exclude).leakscan',
    ':(exclude).leakscan/**',
    ':(exclude)tools/leak-scan.ps1'
)

# 显式传入路径作为 pathspec 的上限，避免超出命令行长度限制
$MaxExplicitPaths = 400

$script:Findings = New-Object 'System.Collections.Generic.List[object]'

function Add-Finding {
    param(
        [ValidateSet('BLOCK', 'WARN')][string]$Level,
        [string]$Category,
        [string]$Where,
        [string]$Detail
    )
    $script:Findings.Add([pscustomobject]@{
        Level    = $Level
        Category = $Category
        Where    = $Where
        Detail   = $Detail
    })
}

function Read-RuleFile {
    param([string]$Directory)
    $patterns = New-Object 'System.Collections.Generic.List[string]'
    if (Test-Path -LiteralPath $Directory) {
        # -Force：Linux 上 PowerShell 把点开头的路径当隐藏项，不加会取不到
        $files = Get-ChildItem -LiteralPath $Directory -Filter '*.txt' -File -Recurse -Force | Sort-Object FullName
        foreach ($file in $files) {
            foreach ($line in [System.IO.File]::ReadAllLines($file.FullName)) {
                $text = $line.Trim()
                if ($text.Length -gt 0 -and -not $text.StartsWith('#')) {
                    $patterns.Add($text)
                }
            }
        }
    }
    return $patterns.ToArray()
}

function Invoke-Git {
    param([string[]]$Arguments)
    $output = & git @Arguments 2>$null
    return [pscustomobject]@{ Output = @($output); Code = $LASTEXITCODE }
}

# ------------------------------------------------------------------ 0. 定位仓库
$rootOutput = & git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($rootOutput)) {
    Write-Host 'leak-scan: 当前目录不在 git 仓库内，跳过扫描。' -ForegroundColor Yellow
    exit 0
}
$root = ($rootOutput | Select-Object -First 1).Trim()

# .git 目录（worktree 场景下不是 <root>\.git，交给 git 自己回答）
$gitDirOutput = & git rev-parse --absolute-git-dir 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitDirOutput)) {
    $gitDir = Join-Path $root '.git'
} else {
    $gitDir = ($gitDirOutput | Select-Object -First 1).Trim()
}

# ------------------------------------------------------------------ 1. 载入规则
$contentPatterns = @(Read-RuleFile (Join-Path $root '.leakscan/content'))
$namePatterns = @(Read-RuleFile (Join-Path $root '.leakscan/names'))

if ($contentPatterns.Count -eq 0 -and $namePatterns.Count -eq 0) {
    Write-Host 'leak-scan: 未找到任何规则（.leakscan 目录缺失？），跳过扫描。' -ForegroundColor Yellow
    exit 0
}

# ------------------------------------------------------------------ 2. 待扫描集合
$targets = @()
if ($Staged) {
    $diff = Invoke-Git @('diff', '--cached', '--name-only', '--diff-filter=ACM')
    if ($diff.Code -ne 0) {
        Write-Host 'leak-scan: 读取暂存区失败，跳过扫描。' -ForegroundColor Yellow
        exit 0
    }
    $targets = @($diff.Output | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_.Trim() })
} else {
    $ls = Invoke-Git @('ls-files')
    $targets = @($ls.Output | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_.Trim() })
    if ($IncludeUntracked) {
        $other = Invoke-Git @('ls-files', '--others', '--exclude-standard')
        $targets += @($other.Output | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_.Trim() })
    }
    $targets = @($targets | Sort-Object -Unique)
}

$modeLabel = if ($Staged) { '暂存区' } else { '全量' }
$scopeLabel = if ($Staged) { '本次提交' }
elseif ($IncludeUntracked) { '已跟踪文件 + 未跟踪文件' }
else { '已跟踪文件' }

Write-Host ''
Write-Host ('=== 泄漏扫描 [{0}] ===' -f $modeLabel) -ForegroundColor Cyan
Write-Host ('仓库    : {0}' -f $root)
Write-Host ('规则    : 内容 {0} 条 / 路径 {1} 条' -f $contentPatterns.Count, $namePatterns.Count)
Write-Host ('范围    : {0}（{1} 个文件）' -f $scopeLabel, $targets.Count)

if ($targets.Count -eq 0) {
    Write-Host '没有需要扫描的文件。' -ForegroundColor DarkGray
    Write-Host ''
    exit 0
}

# ------------------------------------------------------------------ 3. 路径规则
foreach ($path in $targets) {
    foreach ($pattern in $namePatterns) {
        if ($path -match $pattern) {
            Add-Finding 'BLOCK' '敏感文件名' $path '路径命中规则，请确认该文件不应入库'
            break
        }
    }
}

# ------------------------------------------------------------------ 4. 体积检查
$warnBytes = 1MB
$maxBytes = $MaxFileMB * 1MB
$sizeSkipped = New-Object 'System.Collections.Generic.List[string]'

foreach ($path in $targets) {
    $size = $null
    if ($Staged) {
        $blob = Invoke-Git @('cat-file', '-s', (':' + $path))
        if ($blob.Code -eq 0 -and $blob.Output.Count -gt 0) {
            $parsed = 0L
            if ([int64]::TryParse(($blob.Output[0]).Trim(), [ref]$parsed)) { $size = $parsed }
        }
    } else {
        $full = Join-Path $root $path
        try {
            # -Force 是必需的：PowerShell 在 Linux 上把点开头的文件当隐藏项，
            # 不加会抛 "Could not find item"，而 Test-Path 却返回 true。
            # 这个不一致会让整轮扫描在第一个点文件上直接崩掉。
            $item = Get-Item -LiteralPath $full -Force -ErrorAction Stop
            if (-not $item.PSIsContainer) { $size = [int64]$item.Length }
        } catch {
            # 读不到就跳过体积检查，绝不因为体积检查中断内容扫描
            $sizeSkipped.Add($path)
        }
    }
    if ($null -ne $size) {
        if ($size -gt $maxBytes) {
            Add-Finding 'BLOCK' '文件过大' $path ('{0:N2} MB，超过上限 {1} MB' -f ($size / 1MB), $MaxFileMB)
        } elseif ($size -gt $warnBytes) {
            Add-Finding 'WARN' '文件偏大' $path ('{0:N2} MB，建议改用 Release 附件' -f ($size / 1MB))
        }
    }
}

# ------------------------------------------------------------------ 5. 内容规则
if ($contentPatterns.Count -gt 0) {
    $patternFile = Join-Path $gitDir ('leakscan-patterns-' + [guid]::NewGuid().ToString('N') + '.txt')
    try {
        $patternText = ($contentPatterns -join "`n") + "`n"
        [System.IO.File]::WriteAllText($patternFile, $patternText, (New-Object System.Text.UTF8Encoding($false)))

        $grepArgs = @('grep', '-i', '-I', '-n', '-E', '--no-color', '-f', $patternFile)
        if ($Staged) { $grepArgs += '--cached' }
        elseif ($IncludeUntracked) { $grepArgs += '--untracked' }
        $grepArgs += '--'
        $grepArgs += $SelfExclude
        if ($targets.Count -le $MaxExplicitPaths) {
            $grepArgs += @($targets | ForEach-Object { ':(literal)' + $_ })
        }

        $result = Invoke-Git $grepArgs

        if ($result.Code -eq 0) {
            $seen = New-Object 'System.Collections.Generic.HashSet[string]'
            foreach ($line in $result.Output) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = $line -split ':', 3
                if ($parts.Count -lt 3) { continue }
                $key = $parts[0] + ':' + $parts[1]
                if ($seen.Add($key)) {
                    Add-Finding 'BLOCK' '敏感内容' $key '内容命中规则（原文已隐去）'
                }
            }
        } elseif ($result.Code -ne 1) {
            Write-Host ''
            Write-Host 'leak-scan: 内容扫描失败，多半是 .leakscan 里有无法解析的正则。' -ForegroundColor Red
            Write-Host ('           git grep 返回码: {0}' -f $result.Code)
            Write-Host '           为保证安全，本次按「未通过」处理。请修正规则后重试。'
            exit 2
        }
    } finally {
        Remove-Item -LiteralPath $patternFile -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------------ 6. 报告
$blocks = @($script:Findings | Where-Object { $_.Level -eq 'BLOCK' })
$warns = @($script:Findings | Where-Object { $_.Level -eq 'WARN' })

Write-Host ''
if ($sizeSkipped.Count -gt 0) {
    Write-Host ('[提醒] 体积检查跳过 {0} 个文件（内容扫描不受影响）' -f $sizeSkipped.Count) -ForegroundColor Yellow
    $sizeSkipped | Select-Object -First 3 | ForEach-Object { Write-Host ('        └─ ' + $_) -ForegroundColor DarkGray }
}
if ($script:Findings.Count -gt 0) {
    foreach ($finding in $script:Findings) {
        $tag = if ($finding.Level -eq 'BLOCK') { '[拦截]' } else { '[提醒]' }
        $color = if ($finding.Level -eq 'BLOCK') { 'Red' } else { 'Yellow' }
        Write-Host ('{0} {1}  {2}' -f $tag, $finding.Category.PadRight(6), $finding.Where) -ForegroundColor $color
        Write-Host ('        └─ {0}' -f $finding.Detail) -ForegroundColor DarkGray
    }
    Write-Host ''
}

if ($blocks.Count -gt 0) {
    Write-Host ('结果: 拦截 {0} 项，提醒 {1} 项 —— 未通过。' -f $blocks.Count, $warns.Count) -ForegroundColor Red
    Write-Host '处理方式: 从提交中移除相关内容；确需跳过请用 git commit --no-verify，并记录原因。' -ForegroundColor DarkGray
    Write-Host ''
    exit 1
}

if ($warns.Count -gt 0) {
    Write-Host ('结果: 通过（{0} 项提醒，不阻断提交）。' -f $warns.Count) -ForegroundColor Yellow
} else {
    Write-Host '结果: 通过，未发现可疑内容。' -ForegroundColor Green
}
Write-Host ''
exit 0
