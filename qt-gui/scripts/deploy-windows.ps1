param(
    [Parameter(Mandatory = $true)]
    [string]$BuildDirectory,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    [string]$QtRoot = "C:\Qt\6.9.1\mingw_64",
    [string]$AdbPath = "C:\msys64\mingw64\bin\adb.exe"
)

$ErrorActionPreference = "Stop"
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$binary = Join-Path (Resolve-Path $BuildDirectory) "scrcpy-qt-gui.exe"

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Copy-Item $binary $OutputDirectory -Force
& (Join-Path $QtRoot "bin\windeployqt.exe") --qmldir (Join-Path $projectRoot "qt-gui\qml") (Join-Path $OutputDirectory "scrcpy-qt-gui.exe")

Copy-Item (Join-Path $projectRoot "x\app\scrcpy.exe") $OutputDirectory -Force
Copy-Item (Join-Path $projectRoot "x\server\scrcpy-server") $OutputDirectory -Force
Copy-Item $AdbPath $OutputDirectory -Force

$adbDirectory = Split-Path -Parent $AdbPath
$adbRuntimeDlls = @(
    "AdbWinApi.dll",
    "AdbWinUsbApi.dll",
    "libgcc_s_seh-1.dll",
    "libstdc++-6.dll",
    "libwinpthread-1.dll",
    "zlib1.dll",
    "libbrotlicommon.dll",
    "libbrotlidec.dll",
    "libbrotlienc.dll",
    "liblz4.dll",
    "libprotobuf.dll",
    "libzstd.dll",
    "libutf8_validity.dll",
    "libutf8_range.dll"
)
$adbRuntimeDlls += (Get-ChildItem -LiteralPath $adbDirectory -Filter "libabsl_*.dll" -File).Name
foreach ($dll in $adbRuntimeDlls) {
    $source = Join-Path $adbDirectory $dll
    if (-not (Test-Path -LiteralPath $source)) {
        throw "ADB runtime dependency not found: $source"
    }
    Copy-Item $source $OutputDirectory -Force
}

$msysRoot = (Get-Item -LiteralPath $adbDirectory).Parent.Parent.FullName
$ldd = Join-Path $msysRoot "usr\bin\ldd.exe"
if (-not (Test-Path -LiteralPath $ldd)) {
    throw "MSYS2 ldd not found: $ldd"
}

$scrcpyBinary = Join-Path $OutputDirectory "scrcpy.exe"
$originalPath = $env:PATH
try {
    $env:PATH = "$adbDirectory;$env:PATH"
    $lddOutput = & $ldd $scrcpyBinary 2>&1
} finally {
    $env:PATH = $originalPath
}

$missingScrcpyDlls = $lddOutput | Where-Object {
    $_ -match '^\s*\S+\.dll\s*=>\s*not found\s*$'
}
if ($missingScrcpyDlls) {
    throw "scrcpy runtime dependencies not found: $($missingScrcpyDlls -join '; ')"
}

$scrcpyRuntimeDlls = $lddOutput | ForEach-Object {
    if ($_ -match '^\s*(?<name>\S+\.dll)\s*=>\s*/mingw64/bin/') {
        $Matches['name']
    }
} | Sort-Object -Unique
foreach ($dll in $scrcpyRuntimeDlls) {
    $source = Join-Path $adbDirectory $dll
    if (-not (Test-Path -LiteralPath $source)) {
        throw "scrcpy runtime dependency not found: $source"
    }
    Copy-Item $source $OutputDirectory -Force
}

Copy-Item (Join-Path $projectRoot "app\data") (Join-Path $OutputDirectory "app\data") -Recurse -Force

Write-Output "Qt Quick package created at $OutputDirectory"
