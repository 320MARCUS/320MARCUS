#Requires -Version 5.1
<#
.SYNOPSIS
    设置本仓库提交身份，并把已有提交的作者一并改成新身份。
.DESCRIPTION
    只改本仓库的本地配置（git config --local），不动系统全局设置。
    会重写所有已有提交的作者信息，因此**必须在推送到远程之前执行**。
    执行前会列出将被改写的提交，要你确认。
.PARAMETER Name
    提交显示的姓名。想公开真名就填真名，否则填昵称。
.PARAMETER Email
    提交邮箱。强烈建议用 GitHub 的 noreply 地址，
    格式形如 12345678+username@users.noreply.github.com
.PARAMETER Yes
    跳过确认提示（用于脚本自动化）。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\set-identity.ps1 -Name "张三" -Email "12345+zhangsan@users.noreply.github.com"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Email,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

# ---------------------------------------------------------------- 参数校验
if ([string]::IsNullOrWhiteSpace($Name)) {
    Write-Host '× 姓名不能为空。' -ForegroundColor Red
    exit 1
}
if ($Email -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
    Write-Host ('× 邮箱格式不对: {0}' -f $Email) -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    Write-Host '× 当前目录不是 git 仓库。' -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------- 安全检查
$dirty = git status --porcelain
if ($dirty) {
    Write-Host '× 工作区有未提交的改动，重写历史前请先提交或撤销。' -ForegroundColor Red
    Write-Host '  当前改动:' -ForegroundColor DarkGray
    $dirty | ForEach-Object { Write-Host ('    ' + $_) -ForegroundColor DarkGray }
    exit 1
}

$remotes = @(git remote)
if ($remotes.Count -gt 0) {
    Write-Host ('! 本仓库已配置远程: {0}' -f ($remotes -join ', ')) -ForegroundColor Yellow
    Write-Host '  重写历史会让本地与远程不一致，需要强制推送才能同步。' -ForegroundColor Yellow
    Write-Host '  如果这些提交已经推送过，请先停下来，改成只改配置、不重写历史。' -ForegroundColor Yellow
    Write-Host ''
}

$commitCount = [int](git rev-list --count HEAD 2>$null)
if ($LASTEXITCODE -ne 0 -or $commitCount -eq 0) {
    Write-Host '仓库还没有任何提交，只设置配置即可。' -ForegroundColor Yellow
    git config user.name $Name
    git config user.email $Email
    Write-Host ('√ 已设置: {0} <{1}>' -f $Name, $Email) -ForegroundColor Green
    exit 0
}

# ---------------------------------------------------------------- 列出目标
Write-Host ''
Write-Host ('即将把以下 {0} 个提交的作者改写成: {1} <{2}>' -f $commitCount, $Name, $Email) -ForegroundColor Cyan
Write-Host ''
git log --format='  %h  %an <%ae>  %s'
Write-Host ''

if (-not $Yes) {
    $answer = Read-Host '确认继续? (y/N)'
    if ($answer -notin @('y', 'Y', 'yes', 'YES')) {
        Write-Host '已取消，未做任何改动。' -ForegroundColor Yellow
        exit 1
    }
}

# ---------------------------------------------------------------- 执行
git config user.name $Name
git config user.email $Email

$env:GIT_EDITOR = 'true'
git rebase --root --exec 'git commit --amend --reset-author --no-edit'
$rebaseCode = $LASTEXITCODE

if ($rebaseCode -ne 0) {
    Write-Host ''
    Write-Host '× 重写失败。可用 git rebase --abort 回到操作前的状态。' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '√ 完成。改写后的历史:' -ForegroundColor Green
git log --format='  %h  %an <%ae>  %s'
Write-Host ''
exit 0
