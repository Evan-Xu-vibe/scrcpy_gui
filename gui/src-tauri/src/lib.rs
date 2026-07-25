use serde::{Deserialize, Serialize};
use std::{
    env,
    fs::{self, File},
    path::{Path, PathBuf},
    process::{Child, Command, Stdio},
    sync::Mutex,
    thread,
    time::Duration,
};

struct ScrcpyProcess {
    child: Child,
    log_path: PathBuf,
    serial: String,
}

#[derive(Default)]
struct AppState {
    scrcpy: Mutex<Option<ScrcpyProcess>>,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct DeviceInfo {
    serial: String,
    state: String,
    model: String,
    product: Option<String>,
    android_version: Option<String>,
    connection: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct LaunchSettings {
    serial: String,
    max_size: u32,
    max_fps: u32,
    video_codec: String,
    bitrate_mbps: u32,
    turn_screen_off: bool,
    stay_awake: bool,
    keyboard_mode: String,
    mouse_mode: String,
    gamepad_mode: String,
    show_touches: bool,
    fullscreen: bool,
    always_on_top: bool,
    borderless: bool,
    toolbar: bool,
    audio_enabled: bool,
    audio_source: String,
    audio_codec: String,
    audio_bitrate_kbps: u32,
    audio_dup: bool,
    record_enabled: bool,
    record_path: String,
    record_format: String,
    no_playback: bool,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct ScrcpyStatus {
    running: bool,
    error: Option<String>,
}

fn command_path(environment_key: &str, development_path: &str, executable: &str) -> PathBuf {
    if let Some(path) = env::var_os(environment_key) {
        return PathBuf::from(path);
    }

    if let Ok(current_exe) = env::current_exe() {
        if let Some(directory) = current_exe.parent() {
            let bundled = directory.join(executable);
            if bundled.exists() {
                return bundled;
            }
        }
    }

    let development = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join(development_path);
    if development.exists() {
        return development;
    }

    PathBuf::from(executable)
}

fn adb_path() -> PathBuf {
    command_path("SCRCPY_GUI_ADB", "C:/msys64/mingw64/bin/adb.exe", "adb.exe")
}

fn scrcpy_path() -> PathBuf {
    command_path("SCRCPY_GUI_SCRCPY", "../../x/app/scrcpy.exe", "scrcpy.exe")
}

fn server_path() -> Option<PathBuf> {
    if let Some(path) = env::var_os("SCRCPY_GUI_SERVER") {
        return Some(PathBuf::from(path));
    }
    if let Ok(executable) = env::current_exe() {
        if let Some(directory) = executable.parent() {
            let bundled = directory.join("scrcpy-server");
            if bundled.exists() {
                return Some(bundled);
            }
        }
    }
    let development =
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../x/server/scrcpy-server");
    development.exists().then_some(development)
}

fn icon_directory() -> Option<PathBuf> {
    let development = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../app/data");
    development.exists().then_some(development)
}

fn configure_scrcpy_environment(command: &mut Command) -> Result<(), String> {
    let adb = adb_path();
    command.env("ADB", &adb);

    let mut search_paths = Vec::new();
    if let Some(directory) = scrcpy_path()
        .parent()
        .filter(|path| !path.as_os_str().is_empty())
    {
        search_paths.push(directory.to_path_buf());
    }
    if let Some(directory) = adb.parent().filter(|path| !path.as_os_str().is_empty()) {
        search_paths.push(directory.to_path_buf());
    }
    if let Some(existing) = env::var_os("PATH") {
        search_paths.extend(env::split_paths(&existing));
    }
    let search_path = env::join_paths(search_paths)
        .map_err(|error| format!("无法配置 scrcpy 运行库路径：{error}"))?;
    command.env("PATH", search_path);

    if let Some(server) = server_path() {
        command.env("SCRCPY_SERVER_PATH", server);
    }
    if let Some(icons) = icon_directory() {
        command.env("SCRCPY_ICON_DIR", icons);
    }
    Ok(())
}

fn exit_message(status: std::process::ExitStatus, log_path: &Path) -> String {
    let detail = fs::read_to_string(log_path).ok().and_then(|log| {
        log.lines()
            .rev()
            .find(|line| line.contains("ERROR") || line.contains("FATAL"))
            .or_else(|| log.lines().rev().find(|line| !line.trim().is_empty()))
            .map(|line| line.trim().to_string())
    });
    match detail {
        Some(detail) => format!("scrcpy 已退出（{status}）：{detail}"),
        None => format!("scrcpy 已退出（{status}）"),
    }
}

fn run_adb(arguments: &[&str]) -> Result<String, String> {
    let output = Command::new(adb_path())
        .args(arguments)
        .output()
        .map_err(|error| format!("无法启动 ADB：{error}"))?;

    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_string();
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
    if output.status.success() {
        Ok(stdout)
    } else {
        Err(if stderr.is_empty() { stdout } else { stderr })
    }
}

fn attribute<'a>(tokens: &'a [&str], name: &str) -> Option<&'a str> {
    tokens.iter().find_map(|token| token.strip_prefix(name))
}

fn validate_choice(label: &str, value: &str, choices: &[&str]) -> Result<(), String> {
    if choices.contains(&value) {
        Ok(())
    } else {
        Err(format!("不支持的{label}：{value}"))
    }
}

#[cfg(windows)]
fn request_window_close(process_id: u32) -> bool {
    use windows::core::BOOL;
    use windows::Win32::{
        Foundation::{HWND, LPARAM, WPARAM},
        UI::WindowsAndMessaging::{EnumWindows, GetWindowThreadProcessId, PostMessageW, WM_CLOSE},
    };

    struct CloseContext {
        process_id: u32,
        posted: bool,
    }

    unsafe extern "system" fn callback(window: HWND, parameter: LPARAM) -> BOOL {
        let context = unsafe { &mut *(parameter.0 as *mut CloseContext) };
        let mut window_process_id = 0;
        unsafe { GetWindowThreadProcessId(window, Some(&mut window_process_id)) };
        if window_process_id == context.process_id
            && unsafe { PostMessageW(Some(window), WM_CLOSE, WPARAM(0), LPARAM(0)) }.is_ok()
        {
            context.posted = true;
            return BOOL(0);
        }
        BOOL(1)
    }

    let mut context = CloseContext {
        process_id,
        posted: false,
    };
    let _ = unsafe {
        EnumWindows(
            Some(callback),
            LPARAM((&mut context as *mut CloseContext) as isize),
        )
    };
    context.posted
}

#[cfg(not(windows))]
fn request_window_close(_process_id: u32) -> bool {
    false
}

fn wait_for_exit(child: &mut Child, timeout: Duration) -> Result<bool, String> {
    let deadline = std::time::Instant::now() + timeout;
    while std::time::Instant::now() < deadline {
        if child
            .try_wait()
            .map_err(|error| error.to_string())?
            .is_some()
        {
            return Ok(true);
        }
        thread::sleep(Duration::from_millis(50));
    }
    Ok(false)
}

fn stop_device_server(serial: &str) {
    let _ = Command::new(adb_path())
        .args([
            "-s",
            serial,
            "shell",
            "pkill",
            "-f",
            "com.genymobile.scrcpy.Server",
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
}

#[tauri::command]
fn list_devices() -> Result<Vec<DeviceInfo>, String> {
    let output = run_adb(&["devices", "-l"])?;
    let mut devices = Vec::new();

    for line in output
        .lines()
        .skip(1)
        .filter(|line| !line.trim().is_empty())
    {
        let tokens: Vec<&str> = line.split_whitespace().collect();
        if tokens.len() < 2 {
            continue;
        }
        let serial = tokens[0].to_string();
        let state = tokens[1].to_string();
        let model = attribute(&tokens[2..], "model:")
            .unwrap_or("Android 设备")
            .replace('_', " ");
        let product = attribute(&tokens[2..], "product:").map(ToOwned::to_owned);
        let android_version = if state == "device" {
            run_adb(&[
                "-s",
                &serial,
                "shell",
                "getprop",
                "ro.build.version.release",
            ])
            .ok()
        } else {
            None
        };
        let connection = if serial.contains(':') {
            "wireless"
        } else {
            "usb"
        };

        devices.push(DeviceInfo {
            serial,
            state,
            model,
            product,
            android_version,
            connection: connection.to_string(),
        });
    }
    Ok(devices)
}

#[tauri::command]
fn connect_wireless(address: String) -> Result<String, String> {
    let address = address.trim();
    if address.is_empty() || address.chars().any(char::is_whitespace) {
        return Err("请输入有效的 IP 地址和端口".to_string());
    }
    run_adb(&["connect", address])
}

#[tauri::command]
fn start_scrcpy(settings: LaunchSettings, state: tauri::State<'_, AppState>) -> Result<(), String> {
    let mut process = state.scrcpy.lock().map_err(|_| "无法访问投屏进程状态")?;
    if let Some(managed) = process.as_mut() {
        if managed
            .child
            .try_wait()
            .map_err(|error| error.to_string())?
            .is_none()
        {
            return Err("投屏已经在运行".to_string());
        }
    }

    validate_choice("视频编码", &settings.video_codec, &["h264", "h265", "av1"])?;
    validate_choice(
        "键盘模式",
        &settings.keyboard_mode,
        &["disabled", "sdk", "uhid", "aoa"],
    )?;
    validate_choice(
        "鼠标模式",
        &settings.mouse_mode,
        &["disabled", "sdk", "uhid", "aoa"],
    )?;
    validate_choice(
        "手柄模式",
        &settings.gamepad_mode,
        &["disabled", "uhid", "aoa"],
    )?;
    validate_choice(
        "音频源",
        &settings.audio_source,
        &["output", "playback", "mic"],
    )?;
    validate_choice("音频编码", &settings.audio_codec, &["opus", "aac", "flac"])?;
    validate_choice("录制格式", &settings.record_format, &["mp4", "mkv"])?;
    if settings.record_enabled && settings.record_path.trim().is_empty() {
        return Err("录制文件路径不能为空".to_string());
    }

    let executable = scrcpy_path();
    if executable.components().count() > 1 && !Path::new(&executable).exists() {
        return Err(format!("未找到 scrcpy：{}", executable.display()));
    }

    let log_path = env::temp_dir().join("scrcpy-gui.log");
    let stdout = File::create(&log_path).map_err(|error| format!("无法创建启动日志：{error}"))?;
    let stderr = stdout
        .try_clone()
        .map_err(|error| format!("无法创建启动日志：{error}"))?;

    let mut command = Command::new(executable);
    command
        .arg("--serial")
        .arg(&settings.serial)
        .arg(format!("--max-fps={}", settings.max_fps))
        .arg(format!("--video-codec={}", settings.video_codec))
        .arg(format!("--video-bit-rate={}M", settings.bitrate_mbps))
        .arg(format!("--keyboard={}", settings.keyboard_mode))
        .arg(format!("--mouse={}", settings.mouse_mode))
        .arg(format!("--gamepad={}", settings.gamepad_mode))
        .stdin(Stdio::null())
        .stdout(Stdio::from(stdout))
        .stderr(Stdio::from(stderr));

    if settings.max_size > 0 {
        command.arg(format!("--max-size={}", settings.max_size));
    }
    if settings.turn_screen_off {
        command.arg("--turn-screen-off");
    }
    if settings.stay_awake {
        command.arg("--stay-awake");
    }
    if settings.show_touches {
        command.arg("--show-touches");
    }
    if settings.fullscreen {
        command.arg("--fullscreen");
    }
    if settings.always_on_top {
        command.arg("--always-on-top");
    }
    if settings.borderless {
        command.arg("--window-borderless");
    }
    if settings.toolbar {
        command.arg("--toolbar");
    }
    if settings.audio_enabled {
        command
            .arg(format!("--audio-source={}", settings.audio_source))
            .arg(format!("--audio-codec={}", settings.audio_codec));
        if settings.audio_codec != "flac" {
            command.arg(format!("--audio-bit-rate={}K", settings.audio_bitrate_kbps));
        }
        if settings.audio_dup && settings.audio_source == "playback" {
            command.arg("--audio-dup");
        }
    } else {
        command.arg("--no-audio");
    }
    if settings.record_enabled {
        command
            .arg(format!("--record={}", settings.record_path.trim()))
            .arg(format!("--record-format={}", settings.record_format));
        if settings.no_playback {
            command.arg("--no-playback");
        }
    }
    configure_scrcpy_environment(&mut command)?;

    let mut child = command
        .spawn()
        .map_err(|error| format!("无法启动 scrcpy：{error}"))?;
    thread::sleep(Duration::from_millis(350));
    if let Some(status) = child.try_wait().map_err(|error| error.to_string())? {
        return Err(exit_message(status, &log_path));
    }

    *process = Some(ScrcpyProcess {
        child,
        log_path,
        serial: settings.serial,
    });
    Ok(())
}

#[tauri::command]
fn stop_scrcpy(state: tauri::State<'_, AppState>) -> Result<(), String> {
    let mut process = state.scrcpy.lock().map_err(|_| "无法访问投屏进程状态")?;
    if let Some(mut managed) = process.take() {
        let window_close_requested = request_window_close(managed.child.id());
        if !window_close_requested || !wait_for_exit(&mut managed.child, Duration::from_secs(1))? {
            stop_device_server(&managed.serial);
        }
        if !wait_for_exit(&mut managed.child, Duration::from_secs(3))? {
            managed
                .child
                .kill()
                .map_err(|error| format!("无法停止 scrcpy：{error}"))?;
            let _ = managed.child.wait();
        }
    }
    Ok(())
}

#[tauri::command]
fn scrcpy_status(state: tauri::State<'_, AppState>) -> Result<ScrcpyStatus, String> {
    let mut process = state.scrcpy.lock().map_err(|_| "无法访问投屏进程状态")?;
    if let Some(managed) = process.as_mut() {
        match managed
            .child
            .try_wait()
            .map_err(|error| error.to_string())?
        {
            None => Ok(ScrcpyStatus {
                running: true,
                error: None,
            }),
            Some(status) => {
                let error = exit_message(status, &managed.log_path);
                *process = None;
                Ok(ScrcpyStatus {
                    running: false,
                    error: Some(error),
                })
            }
        }
    } else {
        Ok(ScrcpyStatus {
            running: false,
            error: None,
        })
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .manage(AppState::default())
        .invoke_handler(tauri::generate_handler![
            list_devices,
            connect_wireless,
            start_scrcpy,
            stop_scrcpy,
            scrcpy_status
        ])
        .run(tauri::generate_context!())
        .expect("error while running scrcpy GUI");
}
