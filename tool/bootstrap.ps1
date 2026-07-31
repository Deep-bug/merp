$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ToolDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ToolDir
$VersionsFile = Join-Path $ToolDir "versions"

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    throw $Message
}

function Get-VersionValue {
    param([Parameter(Mandatory = $true)][string]$Name)

    $Pattern = "^\s*$([Regex]::Escape($Name))=`"([^`"]+)`""
    foreach ($Line in Get-Content -LiteralPath $VersionsFile) {
        if ($Line -match $Pattern) {
            return $Matches[1]
        }
    }
    Fail "tool\versions 中缺少 $Name。"
}

function Require-Command {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Fail $Message
    }
}

function Invoke-Fvm {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    & $script:FvmBin @Arguments
    if ($LASTEXITCODE -ne 0) {
        Fail "FVM 命令执行失败：$($Arguments -join ' ')"
    }
}

Require-Command -Name "git" -Message "请先安装 Git for Windows。"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$FvmVersion = Get-VersionValue -Name "FVM_VERSION"
$FlutterVersion = Get-VersionValue -Name "FLUTTER_VERSION"
$Architecture = if ($env:PROCESSOR_ARCHITEW6432) {
    $env:PROCESSOR_ARCHITEW6432
} else {
    $env:PROCESSOR_ARCHITECTURE
}

if ($Architecture -eq "ARM64") {
    $PlatformKey = "windows-arm64"
    $FvmUrl = Get-VersionValue -Name "FVM_WINDOWS_ARM64_URL"
    $FvmSha256 = Get-VersionValue -Name "FVM_WINDOWS_ARM64_SHA256"
} elseif ($Architecture -eq "AMD64") {
    $PlatformKey = "windows-x64"
    $FvmUrl = Get-VersionValue -Name "FVM_WINDOWS_X64_URL"
    $FvmSha256 = Get-VersionValue -Name "FVM_WINDOWS_X64_SHA256"
} else {
    Fail "不支持的 Windows CPU 架构：$Architecture"
}

$FvmHome = Join-Path $RootDir ".tool-cache\fvm\$FvmVersion\$PlatformKey"
$script:FvmBin = Join-Path $FvmHome "fvm.exe"
$DownloadDir = Join-Path $RootDir ".tool-cache\downloads"
$Archive = Join-Path $DownloadDir "fvm-$FvmVersion-$PlatformKey.zip"

New-Item -ItemType Directory -Force -Path $FvmHome, $DownloadDir | Out-Null

if (-not (Test-Path -LiteralPath $script:FvmBin -PathType Leaf)) {
    if (-not (Test-Path -LiteralPath $Archive -PathType Leaf)) {
        Write-Host "下载项目固定版本 FVM $FvmVersion（$PlatformKey）..."
        Invoke-WebRequest -UseBasicParsing -Uri $FvmUrl -OutFile $Archive
    } else {
        Write-Host "复用已下载的 FVM 压缩包：$Archive"
    }

    $ActualSha256 = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ActualSha256 -ne $FvmSha256.ToLowerInvariant()) {
        Remove-Item -LiteralPath $Archive -Force
        Fail "FVM 文件校验失败，已删除缓存，请重新执行。"
    }

    $ExtractDir = Join-Path $FvmHome "extracted"
    if (Test-Path -LiteralPath $ExtractDir) {
        Remove-Item -LiteralPath $ExtractDir -Recurse -Force
    }
    Expand-Archive -LiteralPath $Archive -DestinationPath $ExtractDir -Force
    $ExtractedFvm = Get-ChildItem -LiteralPath $ExtractDir -Recurse -File -Filter "fvm.exe" |
        Select-Object -First 1
    if (-not $ExtractedFvm) {
        Fail "FVM 压缩包内未找到 fvm.exe。"
    }
    Copy-Item -LiteralPath $ExtractedFvm.FullName -Destination $script:FvmBin -Force
}

$FvmRc = Get-Content -LiteralPath (Join-Path $RootDir ".fvmrc") -Raw | ConvertFrom-Json
if ($FvmRc.flutter -ne $FlutterVersion) {
    Fail ".fvmrc ($($FvmRc.flutter)) 与 tool\versions ($FlutterVersion) 不一致。"
}

Write-Host "FVM：$FvmVersion"
Write-Host "Flutter：$FlutterVersion"

Push-Location $RootDir
$PreviousAnalytics = $env:FVM_NO_ANALYTICS
$env:FVM_NO_ANALYTICS = "1"
try {
    Invoke-Fvm "install" $FlutterVersion
    Invoke-Fvm "use" $FlutterVersion "--force"
    Invoke-Fvm "flutter" "pub" "get"
    & (Join-Path $ToolDir "configure_ide.ps1")
} finally {
    $env:FVM_NO_ANALYTICS = $PreviousAnalytics
    Pop-Location
}

Write-Host ""
Write-Host "系统工具检查："

$JavaCandidates = @()
if ($env:JAVA_HOME) {
    $JavaCandidates += (Join-Path $env:JAVA_HOME "bin\java.exe")
}
if ($env:ProgramFiles) {
    $JavaCandidates += (Join-Path $env:ProgramFiles "Android\Android Studio\jbr\bin\java.exe")
}
$JavaBin = $JavaCandidates |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1
if ($JavaBin) {
    $JavaVersionLine = (& $JavaBin -version 2>&1 | Select-Object -First 1).ToString()
    $JavaMajor = 0
    if ($JavaVersionLine -match 'version "1\.(\d+)') {
        $JavaMajor = [int]$Matches[1]
    } elseif ($JavaVersionLine -match 'version "(\d+)') {
        $JavaMajor = [int]$Matches[1]
    }
    if ($JavaMajor -ge 17) {
        Write-Host "  [OK] Android Java：$JavaVersionLine"
    } else {
        Write-Host "  [需修复] Java：$JavaVersionLine；Android 构建需要 JDK 17。"
    }
} else {
    Write-Host "  [缺失] Java：请安装 Android Studio，或配置 JAVA_HOME。"
}

$AndroidSdkCandidates = @(
    $env:ANDROID_SDK_ROOT
    $env:ANDROID_HOME
    $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA "Android\Sdk" })
) | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) }
$AndroidSdk = $AndroidSdkCandidates | Select-Object -First 1
if ($AndroidSdk) {
    Write-Host "  [OK] Android SDK：$AndroidSdk"
} else {
    Write-Host "  [提示] 未找到 Android SDK；请通过 Android Studio SDK Manager 安装。"
}

Write-Host ""
Write-Host "初始化完成。后续统一使用 .\tool\app.cmd；VS Code 可直接选择 MERP QAS 配置。"
