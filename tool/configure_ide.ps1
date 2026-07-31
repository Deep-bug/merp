$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ToolDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ToolDir
$LocalRunFile = Join-Path $RootDir ".run\MERP_QAS_Android_Local.run.xml"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom)
}

function Ensure-LocalJson {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Write-Utf8NoBom -Path $Path -Content ("{}" + [Environment]::NewLine)
        $relativePath = $Path -replace "^$([Regex]::Escape($RootDir))[\\/]*", ""
        Write-Host "  [已生成] $relativePath"
    }
}

New-Item -ItemType Directory -Force -Path (Join-Path $RootDir ".run") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $RootDir "config") | Out-Null

Ensure-LocalJson -Path (Join-Path $RootDir "config\qas.local.json")
Ensure-LocalJson -Path (Join-Path $RootDir "config\baidu_map.local.json")
Ensure-LocalJson -Path (Join-Path $RootDir "config\webview.local.json")

$AdditionalArguments = @(
    "--dart-define-from-file=config/qas.json"
    "--dart-define-from-file=config/qas.local.json"
    "--dart-define-from-file=config/baidu_map.local.json"
    "--dart-define-from-file=config/webview.local.json"
) -join " "
$EscapedArguments = [System.Security.SecurityElement]::Escape($AdditionalArguments)

$Xml = @"
<component name="ProjectRunConfigurationManager">
  <configuration default="false" name="MERP QAS Android (Local)" type="FlutterRunConfigurationType" factoryName="Flutter">
    <option name="additionalArgs" value="$EscapedArguments" />
    <option name="buildFlavor" value="qas" />
    <option name="filePath" value="`$PROJECT_DIR`$/lib/main.dart" />
    <method v="2" />
  </configuration>
</component>
"@

Write-Utf8NoBom -Path $LocalRunFile -Content ($Xml + [Environment]::NewLine)
Write-Host "  [已生成] .run\MERP_QAS_Android_Local.run.xml"
Write-Host "IDE 本地配置完成。共享配置不依赖密钥，本地配置会加载本机覆盖文件。"
