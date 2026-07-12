param(
    [switch]$Apply,
    [switch]$CleanResidual
)

$ErrorActionPreference = 'Stop'

$AndroidSdk = 'E:\android'
$AndroidAvd = 'E:\android-avd'
$AndroidUserHome = 'E:\android-user'
$GradleHome = 'E:\.gradle'
$PubCache = 'E:\pub-cache'
$FlutterSdk = 'E:\flutter_windows_3.44.5-stable\flutter'

function Get-DirSizeGB([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return 'missing'
    }
    $sum = (Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue |
        Measure-Object Length -Sum).Sum
    if ($null -eq $sum) {
        $sum = 0
    }
    return [math]::Round($sum / 1GB, 2)
}

function Set-UserEnv([string]$Name, [string]$Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    Set-Item -Path "Env:$Name" -Value $Value
}

Write-Host 'MERP Android/Flutter E drive setup'
Write-Host "Apply mode: $Apply"
Write-Host "Clean residual: $CleanResidual"
Write-Host ''

$targetDirs = @($AndroidSdk, $AndroidAvd, $AndroidUserHome, $GradleHome, $PubCache)
if ($Apply) {
    foreach ($dir in $targetDirs) {
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
        }
    }

    Set-UserEnv 'ANDROID_HOME' $AndroidSdk
    Set-UserEnv 'ANDROID_SDK_ROOT' $AndroidSdk
    Set-UserEnv 'ANDROID_AVD_HOME' $AndroidAvd
    Set-UserEnv 'ANDROID_USER_HOME' $AndroidUserHome
    Set-UserEnv 'GRADLE_USER_HOME' $GradleHome
    Set-UserEnv 'PUB_CACHE' $PubCache

    & "$FlutterSdk\bin\flutter.bat" config --android-sdk $AndroidSdk
}

$cAndroidAvd = Join-Path $env:USERPROFILE '.android\avd'
$cAndroidCache = Join-Path $env:USERPROFILE '.android\cache'
$cGradle = Join-Path $env:USERPROFILE '.gradle'
$cPubCache = Join-Path $env:LOCALAPPDATA 'Pub\Cache'

if ($Apply -and $CleanResidual) {
    # Keep .android identity files such as adbkey and debug.keystore.
    # Only empty Android cache/AVD folders and old Gradle/Pub caches are candidates.
    foreach ($dir in @($cAndroidAvd, $cAndroidCache)) {
        if ((Test-Path -LiteralPath $dir) -and ((Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue).Count -eq 0)) {
            Remove-Item -LiteralPath $dir -Force
        }
    }

    if ((Test-Path -LiteralPath $cGradle) -and ($cGradle -ne $GradleHome)) {
        Remove-Item -LiteralPath $cGradle -Recurse -Force
    }

    if ((Test-Path -LiteralPath $cPubCache) -and ($cPubCache -ne $PubCache)) {
        Remove-Item -LiteralPath $cPubCache -Recurse -Force
    }
}

$paths = @(
    $AndroidSdk,
    $AndroidAvd,
    $AndroidUserHome,
    $GradleHome,
    $PubCache,
    $cAndroidAvd,
    $cAndroidCache,
    $cGradle,
    $cPubCache
)

Write-Host ''
Write-Host 'Directory sizes:'
foreach ($path in $paths) {
    $size = Get-DirSizeGB $path
    Write-Host ("{0}  {1} GB" -f $path, $size)
}

Write-Host ''
Write-Host 'User environment after setup:'
foreach ($name in @('ANDROID_HOME', 'ANDROID_SDK_ROOT', 'ANDROID_AVD_HOME', 'ANDROID_USER_HOME', 'GRADLE_USER_HOME', 'PUB_CACHE')) {
    $value = [Environment]::GetEnvironmentVariable($name, 'User')
    Write-Host ("{0}={1}" -f $name, $value)
}

Write-Host ''
Write-Host 'Restart VSCode and terminals after applying user environment changes.'
