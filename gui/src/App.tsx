import { useCallback, useEffect, useMemo, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import {
  ChevronDown,
  CircleStop,
  FileText,
  LoaderCircle,
  MonitorSmartphone,
  Moon,
  Play,
  RefreshCw,
  Smartphone,
  Sun,
  Wifi,
  X,
} from "lucide-react";
import "./App.css";

type DeviceState = "device" | "unauthorized" | "offline" | string;

interface DeviceInfo {
  serial: string;
  state: DeviceState;
  model: string;
  product?: string;
  androidVersion?: string;
  connection: "usb" | "wireless";
}

interface LaunchSettings {
  serial: string;
  maxSize: number;
  maxFps: number;
  videoCodec: string;
  bitrateMbps: number;
  turnScreenOff: boolean;
  stayAwake: boolean;
  keyboardMode: string;
  mouseMode: string;
  gamepadMode: string;
  showTouches: boolean;
  fullscreen: boolean;
  alwaysOnTop: boolean;
  borderless: boolean;
  audioEnabled: boolean;
  audioSource: string;
  audioCodec: string;
  audioBitrateKbps: number;
  audioDup: boolean;
  recordEnabled: boolean;
  recordPath: string;
  recordFormat: string;
  noPlayback: boolean;
}

interface ScrcpyProcessStatus {
  running: boolean;
  error?: string;
}

const tabs = ["画面", "控制", "音频", "录制"];
const isTauri = "__TAURI_INTERNALS__" in window;
const settingsStorageKey = "scrcpy-gui.settings.v1";
const defaultSettings: Omit<LaunchSettings, "serial"> = {
  maxSize: 1920,
  maxFps: 60,
  videoCodec: "h264",
  bitrateMbps: 8,
  turnScreenOff: true,
  stayAwake: true,
  keyboardMode: "sdk",
  mouseMode: "sdk",
  gamepadMode: "disabled",
  showTouches: false,
  fullscreen: false,
  alwaysOnTop: false,
  borderless: false,
  audioEnabled: true,
  audioSource: "output",
  audioCodec: "opus",
  audioBitrateKbps: 128,
  audioDup: false,
  recordEnabled: false,
  recordPath: "scrcpy-recording.mp4",
  recordFormat: "mp4",
  noPlayback: false,
};

function loadSettings() {
  try {
    const saved = localStorage.getItem(settingsStorageKey);
    return saved ? { ...defaultSettings, ...JSON.parse(saved) } : defaultSettings;
  } catch {
    return defaultSettings;
  }
}

function stateLabel(state: DeviceState) {
  if (state === "device") return "已连接";
  if (state === "unauthorized") return "等待授权";
  if (state === "offline") return "离线";
  return state;
}

function App() {
  const [devices, setDevices] = useState<DeviceInfo[]>([]);
  const [selectedSerial, setSelectedSerial] = useState("");
  const [activeTab, setActiveTab] = useState("画面");
  const [loading, setLoading] = useState(true);
  const [running, setRunning] = useState(false);
  const [dark, setDark] = useState(() => localStorage.getItem("scrcpy-gui.theme") === "dark");
  const [notice, setNotice] = useState("正在检查 ADB 设备…");
  const [wirelessOpen, setWirelessOpen] = useState(false);
  const [wirelessAddress, setWirelessAddress] = useState("");
  const [settings, setSettings] = useState<Omit<LaunchSettings, "serial">>(loadSettings);

  const selected = useMemo(
    () => devices.find((device) => device.serial === selectedSerial) ?? devices[0],
    [devices, selectedSerial],
  );

  const refreshDevices = useCallback(async () => {
    setLoading(true);
    if (!isTauri) {
      setNotice("浏览器预览模式 · 启动桌面应用以连接设备");
      setLoading(false);
      return;
    }
    try {
      const result = await invoke<DeviceInfo[]>("list_devices");
      setDevices(result);
      setSelectedSerial((current) =>
        result.some((device) => device.serial === current) ? current : (result[0]?.serial ?? ""),
      );
      setNotice(result.length ? `发现 ${result.length} 台设备` : "未发现设备，请连接手机并开启 USB 调试");
    } catch (error) {
      setNotice(String(error));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void refreshDevices();
    if (!isTauri) return;
    const statusTimer = window.setInterval(async () => {
      try {
        const status = await invoke<ScrcpyProcessStatus>("scrcpy_status");
        setRunning(status.running);
        if (status.error) setNotice(status.error);
      } catch {
        // Browser-only preview does not expose Tauri commands.
      }
    }, 1500);
    return () => window.clearInterval(statusTimer);
  }, [refreshDevices]);

  useEffect(() => {
    localStorage.setItem(settingsStorageKey, JSON.stringify(settings));
  }, [settings]);

  useEffect(() => {
    localStorage.setItem("scrcpy-gui.theme", dark ? "dark" : "light");
  }, [dark]);

  async function toggleScrcpy() {
    if (!selected || selected.state !== "device") return;
    try {
      if (running) {
        await invoke("stop_scrcpy");
        setRunning(false);
        setNotice("投屏已停止");
      } else {
        if (settings.recordEnabled && !settings.recordPath.trim()) {
          setActiveTab("录制");
          setNotice("请先填写录制文件路径");
          return;
        }
        await invoke("start_scrcpy", {
          settings: { ...settings, serial: selected.serial },
        });
        setRunning(true);
        setNotice(`正在投屏 ${selected.model}`);
      }
    } catch (error) {
      setNotice(String(error));
    }
  }

  async function connectWireless() {
    const address = wirelessAddress.trim();
    if (!address) return;
    if (!isTauri) {
      setNotice("无线连接需要在桌面应用中使用");
      setWirelessOpen(false);
      return;
    }
    setNotice(`正在连接 ${address}…`);
    try {
      const message = await invoke<string>("connect_wireless", { address });
      setNotice(message.trim());
      setWirelessOpen(false);
      setWirelessAddress("");
      await refreshDevices();
    } catch (error) {
      setNotice(String(error));
    }
  }

  return (
    <div className={dark ? "app theme-dark" : "app"}>
      <header className="titlebar">
        <div className="brand">
          <span className="brand-mark"><MonitorSmartphone size={18} /></span>
          <span>scrcpy GUI</span>
        </div>
        <div className="title-actions">
          <IconButton label="刷新设备" onClick={() => void refreshDevices()} disabled={loading}>
            <RefreshCw size={18} className={loading ? "spin" : ""} />
          </IconButton>
          <IconButton label="查看日志" onClick={() => setNotice("日志面板将在下一阶段接入")}>
            <FileText size={18} />
          </IconButton>
          <IconButton label={dark ? "切换浅色主题" : "切换深色主题"} onClick={() => setDark((value) => !value)}>
            {dark ? <Sun size={18} /> : <Moon size={18} />}
          </IconButton>
        </div>
      </header>

      <div className="workspace">
        <aside className="sidebar">
          <div className="sidebar-heading">
            <h2>设备</h2>
            <span className="device-count">{devices.length}</span>
          </div>

          <div className="device-list">
            {loading && devices.length === 0 ? (
              <div className="empty-state"><LoaderCircle className="spin" size={22} /><span>正在发现设备</span></div>
            ) : devices.length === 0 ? (
              <div className="empty-state"><Smartphone size={24} /><strong>未发现设备</strong><span>连接手机并开启 USB 调试</span></div>
            ) : (
              devices.map((device) => (
                <button
                  className={`device-item ${selected?.serial === device.serial ? "selected" : ""}`}
                  key={device.serial}
                  onClick={() => setSelectedSerial(device.serial)}
                >
                  <Smartphone size={22} />
                  <span className="device-copy">
                    <span className="device-name"><i className={`state-dot ${device.state}`} />{device.model}</span>
                    <span>{device.connection === "usb" ? "USB" : "无线"}{device.androidVersion ? ` · Android ${device.androidVersion}` : ""}</span>
                  </span>
                </button>
              ))
            )}
          </div>

          <button className="wireless-button" onClick={() => setWirelessOpen(true)}>
            <Wifi size={19} /><span>无线连接</span>
          </button>
        </aside>

        <main className="main-panel">
          <section className="device-header">
            <div className="device-avatar"><Smartphone size={28} /></div>
            <div>
              <div className="device-title-row">
                <h1>{selected?.model ?? "等待设备"}</h1>
                {selected && <span className={`status-badge ${selected.state}`}><i />{stateLabel(selected.state)}</span>}
              </div>
              <p>{selected ? `序列号：${selected.serial}` : "连接手机后即可配置并启动投屏"}</p>
            </div>
          </section>

          <nav className="tabs" aria-label="投屏配置">
            {tabs.map((tab) => (
              <button className={activeTab === tab ? "active" : ""} key={tab} onClick={() => setActiveTab(tab)}>{tab}</button>
            ))}
          </nav>

          {activeTab === "画面" ? (
            <section className="settings-pane">
              <SettingRow label="分辨率" description="限制视频较长边，降低可减少延迟">
                <div className="select-wrap">
                  <select value={settings.maxSize} onChange={(event) => setSettings({ ...settings, maxSize: Number(event.target.value) })}>
                    <option value={0}>设备原始分辨率</option>
                    <option value={2560}>2560</option>
                    <option value={1920}>1920</option>
                    <option value={1600}>1600</option>
                    <option value={1280}>1280</option>
                    <option value={1024}>1024</option>
                  </select>
                  <ChevronDown size={17} />
                </div>
              </SettingRow>

              <SettingRow label="帧率" description="设备性能不足时会自动降低">
                <div className="number-field">
                  <input type="number" min={1} max={240} value={settings.maxFps} onChange={(event) => setSettings({ ...settings, maxFps: Number(event.target.value) })} />
                  <span>FPS</span>
                </div>
              </SettingRow>

              <SettingRow label="视频编码" description="H.264 具有最佳兼容性">
                <div className="segmented">
                  {["h264", "h265", "av1"].map((codec) => (
                    <button className={settings.videoCodec === codec ? "active" : ""} key={codec} onClick={() => setSettings({ ...settings, videoCodec: codec })}>{codec.toUpperCase()}</button>
                  ))}
                </div>
              </SettingRow>

              <SettingRow label="码率" description="更高码率会提升画质和带宽占用">
                <div className="slider-control">
                  <input type="range" min={1} max={32} value={settings.bitrateMbps} onChange={(event) => setSettings({ ...settings, bitrateMbps: Number(event.target.value) })} />
                  <output>{settings.bitrateMbps} Mbps</output>
                </div>
              </SettingRow>

              <div className="toggle-section">
                <Toggle label="关闭手机屏幕" description="投屏启动后关闭设备物理屏幕" checked={settings.turnScreenOff} onChange={(value) => setSettings({ ...settings, turnScreenOff: value })} />
                <Toggle label="保持唤醒" description="连接期间防止设备自动休眠" checked={settings.stayAwake} onChange={(value) => setSettings({ ...settings, stayAwake: value })} />
              </div>
            </section>
          ) : activeTab === "控制" ? (
            <section className="settings-pane">
              <SettingRow label="键盘模式" description="SDK 兼容性最佳，UHID 模拟物理键盘">
                <SelectControl value={settings.keyboardMode} onChange={(value) => setSettings({ ...settings, keyboardMode: value })} options={[["sdk", "SDK"], ["uhid", "UHID"], ["disabled", "禁用"]]} />
              </SettingRow>
              <SettingRow label="鼠标模式" description="选择鼠标事件注入方式">
                <SelectControl value={settings.mouseMode} onChange={(value) => setSettings({ ...settings, mouseMode: value })} options={[["sdk", "SDK"], ["uhid", "UHID"], ["disabled", "禁用"]]} />
              </SettingRow>
              <SettingRow label="手柄模式" description="UHID 将电脑手柄模拟为 Android 物理手柄">
                <SelectControl value={settings.gamepadMode} onChange={(value) => setSettings({ ...settings, gamepadMode: value })} options={[["disabled", "禁用"], ["uhid", "UHID"]]} />
              </SettingRow>
              <div className="toggle-section">
                <Toggle label="显示手机物理触点" description="仅显示手指直接触摸手机屏幕的位置，不显示电脑鼠标点击" checked={settings.showTouches} onChange={(value) => setSettings({ ...settings, showTouches: value })} />
                <Toggle label="全屏启动" description="投屏窗口打开后立即进入全屏" checked={settings.fullscreen} onChange={(value) => setSettings({ ...settings, fullscreen: value })} />
                <Toggle label="窗口置顶" description="让投屏窗口保持在其他窗口上方" checked={settings.alwaysOnTop} onChange={(value) => setSettings({ ...settings, alwaysOnTop: value })} />
                <Toggle label="无边框窗口" description="隐藏投屏窗口的标题栏和边框" checked={settings.borderless} onChange={(value) => setSettings({ ...settings, borderless: value })} />
              </div>
            </section>
          ) : activeTab === "音频" ? (
            <section className="settings-pane">
              <div className="toggle-section top-toggle">
                <Toggle label="转发设备音频" description="Android 11 及以上系统支持音频转发" checked={settings.audioEnabled} onChange={(value) => setSettings({ ...settings, audioEnabled: value })} />
              </div>
              <fieldset className="settings-fieldset" disabled={!settings.audioEnabled}>
                <SettingRow label="音频源" description="输出捕获整个系统声音，播放仅捕获允许的应用">
                  <SelectControl value={settings.audioSource} onChange={(value) => setSettings({ ...settings, audioSource: value, audioDup: value === "playback" ? settings.audioDup : false })} options={[["output", "系统输出"], ["playback", "应用播放"], ["mic", "麦克风"]]} />
                </SettingRow>
                <SettingRow label="音频编码" description="Opus 延迟低，AAC 兼容性好，FLAC 无损">
                  <div className="segmented three">
                    {["opus", "aac", "flac"].map((codec) => <button type="button" className={settings.audioCodec === codec ? "active" : ""} key={codec} onClick={() => setSettings({ ...settings, audioCodec: codec })}>{codec.toUpperCase()}</button>)}
                  </div>
                </SettingRow>
                <SettingRow label="音频码率" description="仅对 Opus 和 AAC 编码生效">
                  <div className="slider-control">
                    <input type="range" min={64} max={320} step={32} disabled={settings.audioCodec === "flac"} value={settings.audioBitrateKbps} onChange={(event) => setSettings({ ...settings, audioBitrateKbps: Number(event.target.value) })} />
                    <output>{settings.audioBitrateKbps} Kbps</output>
                  </div>
                </SettingRow>
                <div className="toggle-section">
                  <Toggle label="设备同时播放" description="仅在音频源为“应用播放”时可用" disabled={settings.audioSource !== "playback"} checked={settings.audioDup} onChange={(value) => setSettings({ ...settings, audioDup: value })} />
                </div>
              </fieldset>
            </section>
          ) : (
            <section className="settings-pane">
              <div className="toggle-section top-toggle">
                <Toggle label="录制投屏内容" description="将视频与音频保存到本地文件" checked={settings.recordEnabled} onChange={(value) => setSettings({ ...settings, recordEnabled: value })} />
              </div>
              <fieldset className="settings-fieldset" disabled={!settings.recordEnabled}>
                <SettingRow label="保存路径" description="支持绝对路径或相对于 GUI 启动目录的路径">
                  <input className="text-field" value={settings.recordPath} placeholder="scrcpy-recording.mp4" onChange={(event) => setSettings({ ...settings, recordPath: event.target.value })} />
                </SettingRow>
                <SettingRow label="文件格式" description="MP4 通用性更好，MKV 对编码组合更宽容">
                  <div className="segmented two">
                    {["mp4", "mkv"].map((format) => <button type="button" className={settings.recordFormat === format ? "active" : ""} key={format} onClick={() => setSettings({ ...settings, recordFormat: format, recordPath: settings.recordPath.replace(/\.(mp4|mkv)$/i, `.${format}`) })}>{format.toUpperCase()}</button>)}
                  </div>
                </SettingRow>
                <div className="toggle-section">
                  <Toggle label="仅录制，不播放" description="不打开投屏播放窗口，仅在后台录制" checked={settings.noPlayback} onChange={(value) => setSettings({ ...settings, noPlayback: value })} />
                </div>
              </fieldset>
            </section>
          )}

          <footer className="action-bar">
            <div className="action-summary">
              <span className={`state-dot ${running ? "device" : ""}`} />
              <span>{running ? `正在投屏 ${selected?.model ?? ""}` : selected?.state === "device" ? "设备已就绪" : "等待可用设备"}</span>
            </div>
            <button className={`primary-button ${running ? "stop" : ""}`} disabled={!selected || selected.state !== "device"} onClick={() => void toggleScrcpy()}>
              {running ? <CircleStop size={19} /> : <Play size={19} fill="currentColor" />}
              <span>{running ? "停止投屏" : "开始投屏"}</span>
            </button>
          </footer>
        </main>
      </div>

      <footer className="statusbar">
        <span className="status-message"><i className={`state-dot ${notice.includes("失败") || notice.includes("error") ? "offline" : "device"}`} />{notice}</span>
        <span>ADB</span><span>scrcpy</span>
      </footer>

      {wirelessOpen && (
        <div className="modal-backdrop" onMouseDown={() => setWirelessOpen(false)}>
          <section className="modal" onMouseDown={(event) => event.stopPropagation()}>
            <div className="modal-header"><div><h3>无线连接</h3><p>输入已开启无线调试的设备地址</p></div><IconButton label="关闭" onClick={() => setWirelessOpen(false)}><X size={18} /></IconButton></div>
            <label htmlFor="wireless-address">IP 地址与端口</label>
            <input id="wireless-address" autoFocus placeholder="192.168.1.88:5555" value={wirelessAddress} onChange={(event) => setWirelessAddress(event.target.value)} onKeyDown={(event) => event.key === "Enter" && void connectWireless()} />
            <div className="modal-actions"><button className="secondary-button" onClick={() => setWirelessOpen(false)}>取消</button><button className="primary-button compact" disabled={!wirelessAddress.trim()} onClick={() => void connectWireless()}>连接</button></div>
          </section>
        </div>
      )}

    </div>
  );
}

function IconButton({ label, children, ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { label: string }) {
  return <button className="icon-button" title={label} aria-label={label} {...props}>{children}</button>;
}

function SettingRow({ label, description, children }: { label: string; description: string; children: React.ReactNode }) {
  return <div className="setting-row"><div className="setting-label"><strong>{label}</strong><span>{description}</span></div><div className="setting-control">{children}</div></div>;
}

function SelectControl({ value, onChange, options }: { value: string; onChange: (value: string) => void; options: [string, string][] }) {
  return <div className="select-wrap"><select value={value} onChange={(event) => onChange(event.target.value)}>{options.map(([optionValue, label]) => <option value={optionValue} key={optionValue}>{label}</option>)}</select><ChevronDown size={17} /></div>;
}

function Toggle({ label, description, checked, disabled = false, onChange }: { label: string; description: string; checked: boolean; disabled?: boolean; onChange: (value: boolean) => void }) {
  return <div className={`toggle-row ${disabled ? "disabled" : ""}`}><div><strong>{label}</strong><span>{description}</span></div><button disabled={disabled} className={`switch ${checked ? "on" : ""}`} role="switch" aria-checked={checked} aria-label={label} onClick={() => onChange(!checked)}><i /></button></div>;
}

export default App;
