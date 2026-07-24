# scrcpy GUI

A Tauri 2 desktop interface for the scrcpy client in this repository.

## Development

Requirements:

- Node.js 20 or newer
- pnpm
- Rust stable with the MSVC target
- A built scrcpy client in `../x/app/scrcpy.exe`
- A matching server in `../x/server/scrcpy-server`
- ADB, either on `PATH` or at `C:/msys64/mingw64/bin/adb.exe`

Install dependencies and start the desktop app:

```powershell
cd gui
pnpm install
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"
pnpm tauri dev
```

Build the frontend only:

```powershell
pnpm build
```

Build a Windows executable without an installer:

```powershell
pnpm tauri build --debug --no-bundle
```

The executable is generated at `src-tauri/target/debug/scrcpy-gui.exe`.

## Runtime overrides

The backend accepts these optional environment variables:

- `SCRCPY_GUI_ADB`: path to `adb.exe`
- `SCRCPY_GUI_SCRCPY`: path to `scrcpy.exe`
- `SCRCPY_GUI_SERVER`: path to the matching scrcpy server
