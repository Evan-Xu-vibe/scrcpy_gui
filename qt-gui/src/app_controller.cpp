#include "app_controller.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QTimer>

namespace {

QVariantMap defaultSettings() {
    return {
        {"maxSize", 1920},
        {"maxFps", 60},
        {"videoCodec", "h264"},
        {"bitrateMbps", 8},
        {"turnScreenOff", true},
        {"stayAwake", true},
        {"keyboardMode", "sdk"},
        {"mouseMode", "sdk"},
        {"gamepadMode", "disabled"},
        {"showTouches", false},
        {"fullscreen", false},
        {"alwaysOnTop", false},
        {"borderless", false},
        {"toolbar", true},
        {"audioEnabled", true},
        {"audioSource", "output"},
        {"audioCodec", "opus"},
        {"audioBitrateKbps", 128},
        {"audioDup", false},
        {"recordEnabled", false},
        {"recordPath", "scrcpy-recording.mp4"},
        {"recordFormat", "mp4"},
        {"noPlayback", false},
        {"darkTheme", false},
    };
}

QString attribute(const QStringList &tokens, const QString &name) {
    for (const QString &token : tokens) {
        if (token.startsWith(name)) {
            return token.mid(name.size());
        }
    }
    return {};
}

} // namespace

AppController::AppController(QObject *parent)
    : QObject(parent), devices_(this), store_("Evan-Xu", "scrcpy-qt-gui") {
    settings_ = defaultSettings();
    for (auto it = settings_.begin(); it != settings_.end(); ++it) {
        settings_[it.key()] = store_.value(it.key(), it.value());
    }

    connect(&scrcpy_, &QProcess::readyReadStandardOutput, this, [this] {
        appendLog(QString::fromLocal8Bit(scrcpy_.readAllStandardOutput()));
    });
    connect(&scrcpy_, &QProcess::readyReadStandardError, this, [this] {
        appendLog(QString::fromLocal8Bit(scrcpy_.readAllStandardError()));
    });
    connect(&scrcpy_, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error != QProcess::Crashed) {
            setNotice(QString("scrcpy 启动失败：%1").arg(scrcpy_.errorString()));
        }
    });
    connect(&scrcpy_, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, [this](int exitCode, QProcess::ExitStatus status) {
        if (running_) {
            running_ = false;
            emit runningChanged();
        }
        if (status == QProcess::CrashExit) {
            setNotice("scrcpy 异常退出");
        } else if (exitCode == 0) {
            setNotice("投屏已停止");
        } else {
            setNotice(QString("scrcpy 已退出（exit code: %1）").arg(exitCode));
        }
    });

    setNotice("正在检查 ADB 设备…");
    QTimer::singleShot(0, this, &AppController::refreshDevices);
}

DeviceModel *AppController::devices() { return &devices_; }
bool AppController::running() const { return running_; }
QString AppController::notice() const { return notice_; }
QVariantMap AppController::settings() const { return settings_; }
QStringList AppController::logs() const { return logs_; }

void AppController::setNotice(const QString &notice) {
    if (notice_ == notice) {
        return;
    }
    notice_ = notice;
    emit noticeChanged();
}

void AppController::appendLog(const QString &line) {
    for (const QString &entry : line.split('\n', Qt::SkipEmptyParts)) {
        logs_.append(entry.trimmed());
    }
    while (logs_.size() > 500) {
        logs_.removeFirst();
    }
    emit logsChanged();
}

QString AppController::projectRoot() const {
    return QString::fromUtf8(SCRCPY_GUI_SOURCE_ROOT);
}

QString AppController::commandPath(const QString &environmentKey,
                                   const QString &developmentPath,
                                   const QString &executable) const {
    const QString override = qEnvironmentVariable(environmentKey.toUtf8().constData());
    if (!override.isEmpty()) {
        return override;
    }

    const QString bundled = QDir(QCoreApplication::applicationDirPath()).filePath(executable);
    if (QFileInfo::exists(bundled)) {
        return bundled;
    }

    const QString development = QDir(projectRoot()).filePath(developmentPath);
    if (QFileInfo::exists(development)) {
        return development;
    }
    return executable;
}

QString AppController::adbPath() const {
    return commandPath("SCRCPY_GUI_ADB", "C:/msys64/mingw64/bin/adb.exe", "adb.exe");
}

QString AppController::scrcpyPath() const {
    return commandPath("SCRCPY_GUI_SCRCPY", "x/app/scrcpy.exe", "scrcpy.exe");
}

QString AppController::serverPath() const {
    const QString override = qEnvironmentVariable("SCRCPY_GUI_SERVER");
    if (!override.isEmpty()) {
        return override;
    }
    const QString bundled = QDir(QCoreApplication::applicationDirPath()).filePath("scrcpy-server");
    if (QFileInfo::exists(bundled)) {
        return bundled;
    }
    const QString development = QDir(projectRoot()).filePath("x/server/scrcpy-server");
    return QFileInfo::exists(development) ? development : QString();
}

QString AppController::iconDirectory() const {
    const QString bundled = QDir(QCoreApplication::applicationDirPath()).filePath("app/data");
    if (QFileInfo::exists(bundled)) {
        return bundled;
    }
    const QString development = QDir(projectRoot()).filePath("app/data");
    return QFileInfo::exists(development) ? development : QString();
}

void AppController::refreshDevices() {
    auto *process = new QProcess(this);
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, [this, process](int exitCode, QProcess::ExitStatus) {
        const QString output = QString::fromLocal8Bit(process->readAllStandardOutput());
        const QString error = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
        if (exitCode == 0) {
            parseDevices(output);
            setNotice(devices_.rowCount() ? QString("发现 %1 台设备").arg(devices_.rowCount())
                                          : "未发现设备，请连接手机并开启 USB 调试");
        } else {
            setNotice(error.isEmpty() ? "无法读取 ADB 设备" : error);
        }
        process->deleteLater();
    });
    process->start(adbPath(), {"devices", "-l"});
}

void AppController::parseDevices(const QString &output) {
    QList<DeviceModel::Device> devices;
    const QStringList lines = output.split('\n', Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        if (line.startsWith("List of devices attached")) {
            continue;
        }
        const QStringList tokens = line.simplified().split(' ', Qt::SkipEmptyParts);
        if (tokens.size() < 2) {
            continue;
        }
        const QString serial = tokens.at(0);
        if (serial.startsWith('*')) {
            continue;
        }
        devices.append({
            serial,
            tokens.at(1),
            attribute(tokens, "model:"),
            attribute(tokens, "product:"),
            attribute(tokens, "android:"),
            serial.contains(':') ? "wireless" : "usb",
        });
    }
    devices_.setDevices(std::move(devices));
}

void AppController::connectWireless(const QString &address) {
    if (address.trimmed().isEmpty() || address.contains(QRegularExpression("\\s"))) {
        setNotice("请输入有效的 IP 地址和端口");
        return;
    }
    auto *process = new QProcess(this);
    connect(process, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, [this, process](int exitCode, QProcess::ExitStatus) {
        const QString output = QString::fromLocal8Bit(process->readAllStandardOutput()).trimmed();
        const QString error = QString::fromLocal8Bit(process->readAllStandardError()).trimmed();
        setNotice(exitCode == 0 ? output : (error.isEmpty() ? output : error));
        process->deleteLater();
        refreshDevices();
    });
    process->start(adbPath(), {"connect", address.trimmed()});
}

void AppController::configureScrcpyEnvironment() {
    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    const QString adb = adbPath();
    const QString scrcpy = scrcpyPath();
    QStringList searchPaths = {
        QFileInfo(scrcpy).absolutePath(),
        QFileInfo(adb).absolutePath(),
    };
    searchPaths.append(environment.value("PATH").split(QDir::listSeparator()));
    environment.insert("PATH", searchPaths.join(QDir::listSeparator()));
    environment.insert("ADB", adb);
    const QString server = serverPath();
    if (!server.isEmpty()) {
        environment.insert("SCRCPY_SERVER_PATH", server);
    }
    const QString icons = iconDirectory();
    if (!icons.isEmpty()) {
        environment.insert("SCRCPY_ICON_DIR", icons);
    }
    scrcpy_.setProcessEnvironment(environment);
}

QStringList AppController::scrcpyArguments(const QString &serial) const {
    QStringList arguments = {
        "--serial", serial,
        QString("--max-fps=%1").arg(settings_.value("maxFps").toInt()),
        QString("--video-codec=%1").arg(settings_.value("videoCodec").toString()),
        QString("--video-bit-rate=%1M").arg(settings_.value("bitrateMbps").toInt()),
        QString("--keyboard=%1").arg(settings_.value("keyboardMode").toString()),
        QString("--mouse=%1").arg(settings_.value("mouseMode").toString()),
        QString("--gamepad=%1").arg(settings_.value("gamepadMode").toString()),
    };
    const int maxSize = settings_.value("maxSize").toInt();
    if (maxSize > 0) arguments << QString("--max-size=%1").arg(maxSize);
    if (settings_.value("turnScreenOff").toBool()) arguments << "--turn-screen-off";
    if (settings_.value("stayAwake").toBool()) arguments << "--stay-awake";
    if (settings_.value("showTouches").toBool()) arguments << "--show-touches";
    if (settings_.value("fullscreen").toBool()) arguments << "--fullscreen";
    if (settings_.value("alwaysOnTop").toBool()) arguments << "--always-on-top";
    if (settings_.value("borderless").toBool()) arguments << "--window-borderless";
    if (settings_.value("toolbar").toBool()) arguments << "--toolbar";

    if (settings_.value("audioEnabled").toBool()) {
        arguments << QString("--audio-source=%1").arg(settings_.value("audioSource").toString())
                  << QString("--audio-codec=%1").arg(settings_.value("audioCodec").toString());
        if (settings_.value("audioCodec").toString() != "flac") {
            arguments << QString("--audio-bit-rate=%1K").arg(settings_.value("audioBitrateKbps").toInt());
        }
        if (settings_.value("audioDup").toBool()
                && settings_.value("audioSource").toString() == "playback") {
            arguments << "--audio-dup";
        }
    } else {
        arguments << "--no-audio";
    }

    if (settings_.value("recordEnabled").toBool()) {
        arguments << QString("--record=%1").arg(settings_.value("recordPath").toString().trimmed())
                  << QString("--record-format=%1").arg(settings_.value("recordFormat").toString());
        if (settings_.value("noPlayback").toBool()) arguments << "--no-playback";
    }
    return arguments;
}

void AppController::startScrcpy(const QString &serial) {
    if (running_) {
        setNotice("投屏已经在运行");
        return;
    }
    if (!devices_.findBySerial(serial) || devices_.findBySerial(serial)->state != "device") {
        setNotice("请选择一台已授权设备");
        return;
    }
    if (settings_.value("recordEnabled").toBool()
            && settings_.value("recordPath").toString().trimmed().isEmpty()) {
        setNotice("录制文件路径不能为空");
        return;
    }
    const QString executable = scrcpyPath();
    if (QFileInfo(executable).isAbsolute() && !QFileInfo::exists(executable)) {
        setNotice(QString("未找到 scrcpy：%1").arg(executable));
        return;
    }

    configureScrcpyEnvironment();
    activeSerial_ = serial;
    scrcpy_.setProgram(executable);
    scrcpy_.setArguments(scrcpyArguments(serial));
    scrcpy_.setWorkingDirectory(projectRoot());
    scrcpy_.start();
    if (!scrcpy_.waitForStarted(3000)) {
        setNotice(QString("无法启动 scrcpy：%1").arg(scrcpy_.errorString()));
        return;
    }
    running_ = true;
    emit runningChanged();
    setNotice("投屏已启动");
}

void AppController::stopScrcpy() {
    if (!running_) {
        return;
    }
    scrcpy_.terminate();
    QTimer::singleShot(3000, this, [this] {
        if (scrcpy_.state() != QProcess::NotRunning) {
            scrcpy_.kill();
        }
    });
}

QVariant AppController::setting(const QString &key) const {
    return settings_.value(key);
}

void AppController::setSetting(const QString &key, const QVariant &value) {
    if (!settings_.contains(key) || settings_.value(key) == value) {
        return;
    }
    settings_[key] = value;
    store_.setValue(key, value);
    emit settingsChanged();
}

void AppController::clearLogs() {
    if (logs_.isEmpty()) {
        return;
    }
    logs_.clear();
    emit logsChanged();
}
