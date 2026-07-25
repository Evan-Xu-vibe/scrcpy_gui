#pragma once

#include <QAbstractListModel>

class DeviceModel final : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        SerialRole = Qt::UserRole + 1,
        StateRole,
        ModelRole,
        ProductRole,
        AndroidVersionRole,
        ConnectionRole,
    };
    Q_ENUM(Role)

    struct Device {
        QString serial;
        QString state;
        QString model;
        QString product;
        QString androidVersion;
        QString connection;
    };

    explicit DeviceModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    int count() const;

    Q_INVOKABLE QString firstSerial() const;

    void setDevices(QList<Device> devices);
    const Device *findBySerial(const QString &serial) const;

signals:
    void countChanged();

private:
    QList<Device> devices_;
};
