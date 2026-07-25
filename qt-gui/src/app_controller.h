#pragma once

#include <QObject>
#include <QProcess>
#include <QSettings>
#include <QStringList>
#include <QVariantMap>

#include "device_model.h"

class AppController final : public QObject {
    Q_OBJECT
    Q_PROPERTY(DeviceModel *devices READ devices CONSTANT)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QString notice READ notice NOTIFY noticeChanged)
    Q_PROPERTY(QVariantMap settings READ settings NOTIFY settingsChanged)
    Q_PROPERTY(QStringList logs READ logs NOTIFY logsChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    DeviceModel *devices();
    bool running() const;
    QString notice() const;
    QVariantMap settings() const;
    QStringList logs() const;

    Q_INVOKABLE void refreshDevices();
    Q_INVOKABLE void connectWireless(const QString &address);
    Q_INVOKABLE void startScrcpy(const QString &serial);
    Q_INVOKABLE void stopScrcpy();
    Q_INVOKABLE QVariant setting(const QString &key) const;
    Q_INVOKABLE void setSetting(const QString &key, const QVariant &value);
    Q_INVOKABLE void clearLogs();

signals:
    void runningChanged();
    void noticeChanged();
    void settingsChanged();
    void logsChanged();

private:
    void appendLog(const QString &line);
    void setNotice(const QString &notice);
    void parseDevices(const QString &output);
    void configureScrcpyEnvironment();
    QString commandPath(const QString &environmentKey,
                        const QString &developmentPath,
                        const QString &executable) const;
    QString adbPath() const;
    QString scrcpyPath() const;
    QString serverPath() const;
    QString iconDirectory() const;
    QString projectRoot() const;
    QStringList scrcpyArguments(const QString &serial) const;

    DeviceModel devices_;
    QProcess scrcpy_;
    QSettings store_;
    QVariantMap settings_;
    QStringList logs_;
    QString notice_;
    QString activeSerial_;
    bool running_ = false;
};
