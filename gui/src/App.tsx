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
  Settings,
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
}

interface ScrcpyProcessStatus {
  running: boolean;
  error?: string;
}

const tabs = ["画面", "控制", "音频", "录制"];
const isTauri = "__TAURI_INTERNALS__" in window;

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
  const [dark, setDark] = useState(false);
  const [notice, setNotice] = useState("正在检查 ADB 设备…");
  const [wirelessOpen, setWirelessOpen] = useState(false);
  const [wirelessAddress, setWirelessAddress] = useState("");
  const [settings, setSettings] = useState<Omit<LaunchSettings, "serial">>({
    maxSize: 1920,
    maxFps: 60,
    videoCodec: "h264",
    bitrateMbps: 8,
    turnScreenOff: true,
    stayAwake: true,
  });

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

  async function toggleScrcpy() {
    if (!selected || selected.state !== "device") return;
    try {
      if (running) {
        await invoke("stop_scrcpy");
        setRunning(false);
        setNotice("投屏已停止");
      } else {
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
          <IconButton label="设置" onClick={() => setNotice("应用设置将在下一阶段接入")}>
            <Settings size={18} />
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
          ) : (
            <section className="placeholder-pane">
              <div className="placeholder-icon"><Settings size={24} /></div>
              <h3>{activeTab}设置</h3>
              <p>这个配置页将在下一阶段接入对应的 scrcpy 参数。</p>
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
        <span>ADB</span><span>scrcpy 4.1</span>
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

function Toggle({ label, description, checked, onChange }: { label: string; description: string; checked: boolean; onChange: (value: boolean) => void }) {
  return <div className="toggle-row"><div><strong>{label}</strong><span>{description}</span></div><button className={`switch ${checked ? "on" : ""}`} role="switch" aria-checked={checked} aria-label={label} onClick={() => onChange(!checked)}><i /></button></div>;
}

export default App;
