#include "device_model.h"

DeviceModel::DeviceModel(QObject *parent) : QAbstractListModel(parent) {}

int DeviceModel::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : devices_.size();
}

QVariant DeviceModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= devices_.size()) {
        return {};
    }

    const Device &device = devices_.at(index.row());
    switch (role) {
        case SerialRole: return device.serial;
        case StateRole: return device.state;
        case ModelRole: return device.model;
        case ProductRole: return device.product;
        case AndroidVersionRole: return device.androidVersion;
        case ConnectionRole: return device.connection;
        default: return {};
    }
}

QHash<int, QByteArray> DeviceModel::roleNames() const {
    return {
        {SerialRole, "serial"},
        {StateRole, "state"},
        {ModelRole, "modelName"},
        {ProductRole, "product"},
        {AndroidVersionRole, "androidVersion"},
        {ConnectionRole, "connection"},
    };
}

int DeviceModel::count() const {
    return devices_.size();
}

QString DeviceModel::firstSerial() const {
    return devices_.isEmpty() ? QString() : devices_.constFirst().serial;
}

void DeviceModel::setDevices(QList<Device> devices) {
    const int previousCount = devices_.size();
    beginResetModel();
    devices_ = std::move(devices);
    endResetModel();
    if (devices_.size() != previousCount) {
        emit countChanged();
    }
}

const DeviceModel::Device *DeviceModel::findBySerial(const QString &serial) const {
    for (const Device &device : devices_) {
        if (device.serial == serial) {
            return &device;
        }
    }
    return nullptr;
}
