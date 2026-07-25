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
Copy-Item (Join-Path $projectRoot "app\data") (Join-Path $OutputDirectory "app\data") -Recurse -Force

Write-Output "Qt Quick package created at $OutputDirectory"
