#Requires -Version 5.1
<#
.SYNOPSIS
    从模板创建一个新项目目录。
.DESCRIPTION
    复制 projects/_TEMPLATE/ 为 projects/<名称>/，并把 README 里的占位符
    替换成项目名。只在本仓库内操作。
.PARAMETER Name
    项目目录名。建议用 ASCII，例如 stm32-audio-spectrum。
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File tools\new-project.ps1 stm32-audio-spectrum
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Name
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

$root = Split-Path -Parent $PSScriptRoot

# ---------------------------------------------------------------- 名称校验
if ($Name -match '[\\/:*?"<>|]') {
    Write-Host '× 项目名不能包含 \ / : * ? " < > | 这些字符。' -ForegroundColor Red
    exit 1
}
if ($Name.StartsWith('.')) {
    Write-Host '× 项目名不能以点开头。' -ForegroundColor Red
    exit 1
}
if ($Name -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') {
    Write-Host '× 这是 Windows 保留名，换一个。' -ForegroundColor Red
    exit 1
}

$template = Join-Path $root 'projects/_TEMPLATE'
$target = Join-Path $root ('projects/' + $Name)

if (-not (Test-Path -LiteralPath $template)) {
    Write-Host '× 找不到模板 projects/_TEMPLATE/' -ForegroundColor Red
    exit 1
}
if (Test-Path -LiteralPath $target) {
    Write-Host ('× {0} 已存在，未做任何改动。' -f $target) -ForegroundColor Red
    exit 1
}

# ---------------------------------------------------------------- 复制模板
Copy-Item -LiteralPath $template -Destination $target -Recurse

$readme = Join-Path $target 'README.md'
if (Test-Path -LiteralPath $readme) {
    $text = [System.IO.File]::ReadAllText($readme)
    $text = $text.Replace('<项目名称>', $Name)
    [System.IO.File]::WriteAllText($readme, $text, (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host ''
Write-Host ('已创建 projects/{0}/' -f $Name) -ForegroundColor Green
Write-Host ''
Write-Host '接下来:' -ForegroundColor Cyan
Write-Host ('  1. 把项目文件复制进 projects/{0}/' -f $Name)
Write-Host ('  2. 按 projects/{0}/README.md 的结构填写说明' -f $Name)
Write-Host '  3. 在 projects/README.md 的表格里登记一行'
Write-Host '  4. 提交前跑一遍扫描：'
Write-Host '     powershell -ExecutionPolicy Bypass -File tools\leak-scan.ps1 -IncludeUntracked'
Write-Host ''

if ($Name -match '[^\x00-\x7F]') {
    Write-Host '提示: 项目名含非 ASCII 字符，开源仓库建议改用英文名，兼容性更好。' -ForegroundColor Yellow
    Write-Host ''
}

exit 0
