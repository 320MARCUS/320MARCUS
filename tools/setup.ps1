#Requires -Version 5.1
<#
.SYNOPSIS
    一键启用本仓库的红线防护（本地配置，不改全局设置）。
.DESCRIPTION
    1. 确认当前目录是 git 仓库
    2. 启用 hooks/pre-commit 提交前扫描
    3. 统一换行符处理，交给 .gitattributes 负责
    4. 检查提交身份是否已配置
    5. 跑一次全量泄漏扫描自检
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\setup.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

Write-Host ''
Write-Host '=== My_GitHub 红线防护自检 ===' -ForegroundColor Cyan
Write-Host ('仓库: {0}' -f $root)
Write-Host ''

# ---------------------------------------------------------------- 1. 仓库检查
if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    Write-Host '× 当前目录不是 git 仓库。请先执行: git init' -ForegroundColor Red
    exit 1
}
Write-Host '√ git 仓库' -ForegroundColor Green

# ---------------------------------------------------------------- 编码自检
# Windows PowerShell 5.1 对无 BOM 的 UTF-8 脚本按 GBK 解析，中文会直接语法报错
$toolsDir = Join-Path $root 'tools'
$psScripts = @()
if (Test-Path -LiteralPath $toolsDir) {
    $psScripts = @(Get-ChildItem -LiteralPath $toolsDir -Filter '*.ps1' -File -Force |
        Sort-Object Name | ForEach-Object { 'tools/' + $_.Name })
}
$bomIssues = @()
foreach ($script in $psScripts) {
    $full = Join-Path $root $script
    if (Test-Path -LiteralPath $full) {
        $bytes = [System.IO.File]::ReadAllBytes($full)
        $hasBom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
        if (-not $hasBom) { $bomIssues += $script }
    }
}
if ($bomIssues.Count -gt 0) {
    Write-Host '! 以下脚本缺少 UTF-8 BOM，PowerShell 5.1 会解析出错:' -ForegroundColor Yellow
    foreach ($item in $bomIssues) { Write-Host ('    ' + $item) -ForegroundColor Yellow }
    Write-Host '  用编辑器「另存为 UTF-8 带 BOM」，或执行:' -ForegroundColor DarkGray
    Write-Host '    $p="tools\leak-scan.ps1"; $t=[IO.File]::ReadAllText($p); [IO.File]::WriteAllText((Resolve-Path $p),$t,(New-Object Text.UTF8Encoding($true)))' -ForegroundColor DarkGray
} else {
    Write-Host '√ 脚本编码正常 (UTF-8 with BOM)' -ForegroundColor Green
}

# ---------------------------------------------------------------- 2. 启用钩子
git config core.hooksPath hooks
if ($LASTEXITCODE -eq 0) {
    Write-Host '√ 提交前扫描已启用 (core.hooksPath = hooks)' -ForegroundColor Green
} else {
    Write-Host '× 启用钩子失败' -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------- 3. 换行符
git config core.autocrlf false
Write-Host '√ 换行符交给 .gitattributes 统一处理' -ForegroundColor Green

# ---------------------------------------------------------------- 4. 提交身份
$name = (git config user.name)
$email = (git config user.email)
$identityOk = $true

if ([string]::IsNullOrWhiteSpace($name) -or [string]::IsNullOrWhiteSpace($email)) {
    $identityOk = $false
    Write-Host '! 提交身份未配置' -ForegroundColor Yellow
} elseif ($email -like '*users.noreply.github.com' -and $name -eq 'Your Name') {
    $identityOk = $false
    Write-Host '! 提交身份仍是占位符，正式提交前请替换' -ForegroundColor Yellow
} else {
    Write-Host ('√ 提交身份: {0} <{1}>' -f $name, $email) -ForegroundColor Green
}

if (-not $identityOk) {
    Write-Host ''
    Write-Host '  设置方式（会同时改写已有提交的作者，务必在 push 之前执行）:' -ForegroundColor DarkGray
    Write-Host '    powershell -ExecutionPolicy Bypass -File tools\set-identity.ps1 `' -ForegroundColor DarkGray
    Write-Host '      -Name "你的名字" -Email "你的ID@users.noreply.github.com"' -ForegroundColor DarkGray
}

# ---------------------------------------------------------------- 5. 全量自检
Write-Host ''
$scanner = Join-Path $root 'tools\leak-scan.ps1'
if (Test-Path -LiteralPath $scanner) {
    # 加上 -IncludeUntracked：首次提交前还没有已跟踪文件，否则自检会空跑
    & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $scanner -IncludeUntracked
    if ($LASTEXITCODE -ne 0) {
        Write-Host '自检未通过，请先处理上面的拦截项。' -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host '! 未找到 tools\leak-scan.ps1' -ForegroundColor Yellow
}

Write-Host '防护就绪。' -ForegroundColor Green
Write-Host ''
exit 0
