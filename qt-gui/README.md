# scrcpy Qt Quick GUI

This is the native Qt Quick replacement for the Tauri GUI. It launches the
custom scrcpy client and passes `--toolbar` when the toolbar setting is enabled.

## Build

```powershell
$cmake = "C:\Qt\Tools\CMake_64\bin\cmake.exe"
& $cmake -S qt-gui -B build\qt-quick -G Ninja `
  -DCMAKE_PREFIX_PATH=C:\Qt\6.9.1\mingw_64 `
  -DCMAKE_CXX_COMPILER=C:\Qt\Tools\mingw1310_64\bin\g++.exe
& $cmake --build build\qt-quick --parallel
ctest --test-dir build\qt-quick --output-on-failure
```

The development process locates `x/app/scrcpy.exe`, `x/server/scrcpy-server`,
and `app/data` from the repository root. Override paths with
`SCRCPY_GUI_ADB`, `SCRCPY_GUI_SCRCPY`, and `SCRCPY_GUI_SERVER`.

## Package for Windows

```powershell
.\qt-gui\scripts\deploy-windows.ps1 `
  -BuildDirectory .\build\qt-quick `
  -OutputDirectory .\release\qt-gui
```

The deployment script runs `windeployqt` and copies scrcpy, its server, ADB,
and the icon assets into a self-contained Windows directory.
