$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ToolDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ToolDir
$VersionsFile = Join-Path $ToolDir "versions"

function Show-Usage {
    Write-Host @"
用法：
  .\tool\app.cmd doctor
  .\tool\app.cmd ide
  .\tool\app.cmd analyze
  .\tool\app.cmd test
  .\tool\app.cmd run qas android [Flutter 额外参数]
  .\tool\app.cmd run mock android [Flutter 额外参数]
  .\tool\app.cmd build qas android [Flutter 额外参数]
  .\tool\app.cmd build prd android [Flutter 额外参数]

版本覆盖：
  `$env:BUILD_NAME="1.2.0"
  `$env:BUILD_NUMBER="10001"
  .\tool\app.cmd build qas android
"@
}

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "错误：$Message" -ForegroundColor Red
    Show-Usage
    exit 1
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

$FvmVersion = Get-VersionValue -Name "FVM_VERSION"
$Architecture = if ($env:PROCESSOR_ARCHITEW6432) {
    $env:PROCESSOR_ARCHITEW6432
} else {
    $env:PROCESSOR_ARCHITECTURE
}
$FvmPlatform = if ($Architecture -eq "ARM64") {
    "windows-arm64"
} elseif ($Architecture -eq "AMD64") {
    "windows-x64"
} else {
    Fail "不支持的 Windows CPU 架构：$Architecture"
}
$script:FvmBin = Join-Path $RootDir ".tool-cache\fvm\$FvmVersion\$FvmPlatform\fvm.exe"

function Ensure-Fvm {
    if (-not (Test-Path -LiteralPath $script:FvmBin -PathType Leaf)) {
        Write-Host "尚未初始化项目工具链，正在执行 bootstrap.ps1..."
        & (Join-Path $ToolDir "bootstrap.ps1")
        if ($LASTEXITCODE -ne 0) {
            Fail "Windows 项目工具链初始化失败。"
        }
    }
}

function Invoke-Flutter {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)

    $PreviousAnalytics = $env:FVM_NO_ANALYTICS
    $env:FVM_NO_ANALYTICS = "1"
    try {
        & $script:FvmBin flutter @Arguments
        if ($LASTEXITCODE -ne 0) {
            Fail "Flutter 命令执行失败：$($Arguments -join ' ')"
        }
    } finally {
        $env:FVM_NO_ANALYTICS = $PreviousAnalytics
    }
}

function Get-JavaMajor {
    param([Parameter(Mandatory = $true)][string]$JavaBin)

    $VersionLine = (& $JavaBin -version 2>&1 | Select-Object -First 1).ToString()
    if ($VersionLine -match 'version "1\.(\d+)') {
        return [int]$Matches[1]
    }
    if ($VersionLine -match 'version "(\d+)') {
        return [int]$Matches[1]
    }
    return 0
}

function Ensure-AndroidJava {
    $JavaBin = $null
    if ($env:JAVA_HOME) {
        $Candidate = Join-Path $env:JAVA_HOME "bin\java.exe"
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
            $JavaBin = $Candidate
        }
    }
    if (-not $JavaBin) {
        $JavaCommand = Get-Command "java.exe" -ErrorAction SilentlyContinue
        if ($JavaCommand) {
            $JavaBin = $JavaCommand.Source
        }
    }
    if ($JavaBin -and (Get-JavaMajor -JavaBin $JavaBin) -ge 17) {
        return
    }

    $AndroidStudioJavaHome = if ($env:ProgramFiles) {
        Join-Path $env:ProgramFiles "Android\Android Studio\jbr"
    } else {
        $null
    }
    if ($AndroidStudioJavaHome -and
        (Test-Path -LiteralPath (Join-Path $AndroidStudioJavaHome "bin\java.exe") -PathType Leaf)) {
        $env:JAVA_HOME = $AndroidStudioJavaHome
        $env:Path = "$(Join-Path $env:JAVA_HOME 'bin');$env:Path"
        Write-Host "当前 Java 版本不满足 Android 构建要求，已使用 Android Studio 内置 JDK。"
        return
    }

    Fail "Android 构建需要 JDK 17 以上；请安装 Android Studio，或配置 JAVA_HOME。"
}

function Get-ConfigArguments {
    param([Parameter(Mandatory = $true)][string]$Name)

    $BaseEnvironment = if ($Name -eq "mock") { "qas" } else { $Name }
    $BaseFile = Join-Path $RootDir "config\$BaseEnvironment.json"
    if (-not (Test-Path -LiteralPath $BaseFile -PathType Leaf)) {
        Fail "缺少环境配置：$BaseFile"
    }
    $Result = @("--dart-define-from-file=$BaseFile")
    $RelativePaths = @("config\$BaseEnvironment.local.json")
    if ($Name -eq "mock") {
        # mock 覆盖 QAS 的 APP_ENV 与 Mock 开关，同时继续复用 QAS 本机地址配置。
        $RelativePaths += @("config\mock.json", "config\mock.local.json")
    }
    $RelativePaths += @("config\baidu_map.local.json", "config\webview.local.json")
    foreach ($RelativePath in $RelativePaths) {
        $Candidate = Join-Path $RootDir $RelativePath
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) {
            $Result += "--dart-define-from-file=$Candidate"
        }
    }
    return $Result
}

function Get-ProjectVersion {
    $Pubspec = Get-Content -LiteralPath (Join-Path $RootDir "pubspec.yaml")
    foreach ($Line in $Pubspec) {
        if ($Line -match '^version:\s*([^+\s]+)(?:\+(\d+))?') {
            return @($Matches[1], $Matches[2])
        }
    }
    Fail "无法从 pubspec.yaml 读取版本号或构建编号。"
}

function Test-HasDeviceArgument {
    param([string[]]$Arguments)

    foreach ($Argument in $Arguments) {
        if ($Argument -eq "-d" -or
            $Argument -eq "--device-id" -or
            $Argument -match '^--device-id=') {
            return $true
        }
    }
    return $false
}

function Select-AndroidDevice {
    $PreviousAnalytics = $env:FVM_NO_ANALYTICS
    $env:FVM_NO_ANALYTICS = "1"
    try {
        $DevicesJson = (& $script:FvmBin flutter devices --machine | Out-String)
        if ($LASTEXITCODE -ne 0) {
            Fail "读取 Flutter 设备列表失败。"
        }
    } finally {
        $env:FVM_NO_ANALYTICS = $PreviousAnalytics
    }
    $Devices = $DevicesJson | ConvertFrom-Json
    $Device = $Devices |
        Where-Object { $_.targetPlatform -like "android*" } |
        Select-Object -First 1
    if (-not $Device) {
        Fail "没有发现 Android 设备；请启动模拟器、连接手机，或传入 -d <device-id>。"
    }
    return $Device.id
}

function Confirm-Prd {
    $ConfigFile = Join-Path $RootDir "config\prd.local.json"
    if (-not (Test-Path -LiteralPath $ConfigFile -PathType Leaf)) {
        $ConfigFile = Join-Path $RootDir "config\prd.json"
    }
    $Config = Get-Content -LiteralPath $ConfigFile -Raw | ConvertFrom-Json
    $ApiUrl = [string]$Config.API_BASE_URL
    if (-not $ApiUrl -or $ApiUrl -match '替换|placeholder') {
        Fail "PRD API_BASE_URL 尚未配置。请创建 config\prd.local.json，或由 CI 安全生成。"
    }

    if ($env:CI -eq "true" -or $env:CI -eq "1") {
        return
    }
    Write-Host ""
    Write-Host "警告：即将构建 PRD 正式包，不会自动上传应用商店。"
    if ((Read-Host "请输入 prd 继续") -ne "prd") {
        Write-Host "已取消 PRD 构建。"
        exit 1
    }
}

function Print-Artifact {
    param(
        [Parameter(Mandatory = $true)][string]$EnvironmentName,
        [Parameter(Mandatory = $true)][string]$Extension,
        [Parameter(Mandatory = $true)][datetime]$StartedAt,
        [Parameter(Mandatory = $true)][string]$VersionName,
        [Parameter(Mandatory = $true)][string]$BuildNumber
    )

    $Artifact = Get-ChildItem -LiteralPath (Join-Path $RootDir "build") -Recurse -File |
        Where-Object {
            $_.Extension -eq ".$Extension" -and
            $_.LastWriteTime -ge $StartedAt.AddSeconds(-1)
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if (-not $Artifact) {
        Fail "构建命令结束，但没有找到本次生成的 .$Extension 产物。"
    }
    $Commit = (& git -C $RootDir rev-parse --short HEAD 2>$null)
    Write-Host ""
    Write-Host "✓ 构建成功"
    Write-Host "环境：$EnvironmentName"
    Write-Host "平台：android"
    Write-Host "版本：$VersionName+$BuildNumber"
    Write-Host "提交：$Commit"
    Write-Host "产物：$($Artifact.FullName)"
}

$Command = if ($args.Count -ge 1) { [string]$args[0] } else { "" }

switch ($Command) {
    "ide" {
        if ($args.Count -ne 1) { Fail "ide 不接受额外的位置参数。" }
        & (Join-Path $ToolDir "configure_ide.ps1")
        exit 0
    }
    "doctor" {
        if ($args.Count -ne 1) { Fail "doctor 不接受额外的位置参数。" }
        & (Join-Path $ToolDir "bootstrap.ps1")
        Ensure-Fvm
        Invoke-Flutter "doctor" "-v"
        exit 0
    }
    "analyze" {
        if ($args.Count -ne 1) { Fail "analyze 不接受额外的位置参数。" }
        Ensure-Fvm
        Push-Location $RootDir
        try { Invoke-Flutter "analyze" } finally { Pop-Location }
        exit 0
    }
    "test" {
        if ($args.Count -ne 1) { Fail "test 不接受额外的位置参数。" }
        Ensure-Fvm
        Push-Location $RootDir
        try { Invoke-Flutter "test" } finally { Pop-Location }
        exit 0
    }
    { $_ -in @("run", "build") } { }
    default { Fail "未知命令：$Command" }
}

$EnvironmentName = if ($args.Count -ge 2) { [string]$args[1] } else { "" }
$Platform = if ($args.Count -ge 3) { [string]$args[2] } else { "" }
$ExtraArguments = if ($args.Count -gt 3) { @($args[3..($args.Count - 1)]) } else { @() }

if ($EnvironmentName -notin @("qas", "mock", "prd")) {
    Fail "环境只能是 qas、mock 或 prd。"
}
if ($Platform -ne "android") {
    Fail "Windows 脚本只支持 Android；iOS 运行和打包必须在 macOS 执行。"
}
if ($Command -eq "run" -and $EnvironmentName -eq "prd") {
  Fail "不提供 run prd；本地日常运行固定使用 QAS。"
}
if ($Command -eq "build" -and $EnvironmentName -eq "mock") {
    Fail "mock 仅用于 Debug 启动，不允许构建或发布。"
}

Ensure-Fvm
Ensure-AndroidJava
$ConfigArguments = Get-ConfigArguments -Name $EnvironmentName

Push-Location $RootDir
try {
    if ($Command -eq "run") {
        if (-not (Test-HasDeviceArgument -Arguments $ExtraArguments)) {
            $DeviceId = Select-AndroidDevice
            $ExtraArguments = @("-d", $DeviceId) + $ExtraArguments
            Write-Host "使用 android 设备：$DeviceId"
        }
        $RunArguments = @("run", "--flavor", "qas")
        $HasExplicitBuildMode = $ExtraArguments | Where-Object {
            $_ -in @("--debug", "--profile", "--jit-release", "--release")
        }
        if (-not $HasExplicitBuildMode) {
            $RunArguments += "--debug"
        }
        $RunArguments += @("--target", "lib/main.dart")
        $RunArguments += $ConfigArguments + $ExtraArguments
        Invoke-Flutter @RunArguments
        exit 0
    }

    $ProjectVersion = Get-ProjectVersion
    $VersionName = if ($env:BUILD_NAME) { $env:BUILD_NAME } else { $ProjectVersion[0] }
    $BuildNumber = if ($env:BUILD_NUMBER) { $env:BUILD_NUMBER } else { $ProjectVersion[1] }
    if (-not $VersionName -or -not $BuildNumber) {
        Fail "无法从 pubspec.yaml 读取版本号或构建编号。"
    }
    if ($BuildNumber -notmatch '^\d{5}$') {
        Fail "BUILD_NUMBER 必须是五位数字（例如 10000），当前值：$BuildNumber"
    }
    if ($EnvironmentName -eq "prd") {
        Confirm-Prd
    }

    $StartedAt = Get-Date
    if ($EnvironmentName -eq "qas") {
        $BuildArguments = @(
            "build", "apk"
            "--flavor", "qas"
            "--release"
            "--target", "lib/main.dart"
            "--target-platform", "android-arm64"
            "--split-per-abi"
        ) + $ConfigArguments + @(
            "--build-name", $VersionName
            "--build-number", $BuildNumber
        ) + $ExtraArguments
        Invoke-Flutter @BuildArguments
        Print-Artifact -EnvironmentName "qas" -Extension "apk" -StartedAt $StartedAt `
            -VersionName $VersionName -BuildNumber $BuildNumber
    } else {
        $BuildArguments = @(
            "build", "appbundle"
            "--flavor", "prd"
            "--release"
            "--target", "lib/main.dart"
            "--target-platform", "android-arm64"
        ) + $ConfigArguments + @(
            "--build-name", $VersionName
            "--build-number", $BuildNumber
        ) + $ExtraArguments
        Invoke-Flutter @BuildArguments
        Print-Artifact -EnvironmentName "prd" -Extension "aab" -StartedAt $StartedAt `
            -VersionName $VersionName -BuildNumber $BuildNumber
    }
} finally {
    Pop-Location
}
