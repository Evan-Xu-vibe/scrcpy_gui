#include <QtTest>

#include "device_model.h"

class DeviceModelTest final : public QObject {
    Q_OBJECT

private slots:
    void exposesDeviceRoles();
};

void DeviceModelTest::exposesDeviceRoles() {
    DeviceModel model;
    model.setDevices({
        {
            .serial = "emulator-5554",
            .state = "device",
            .model = "Pixel_8",
            .product = "husky",
            .androidVersion = "15",
            .connection = "usb",
        },
    });

    QCOMPARE(model.count(), 1);
    QCOMPARE(model.firstSerial(), "emulator-5554");
    const QModelIndex index = model.index(0, 0);
    QCOMPARE(model.data(index, DeviceModel::SerialRole).toString(), "emulator-5554");
    QCOMPARE(model.data(index, DeviceModel::ModelRole).toString(), "Pixel_8");
    QCOMPARE(model.data(index, DeviceModel::ConnectionRole).toString(), "usb");
}

QTEST_MAIN(DeviceModelTest)

#include "test_device_model.moc"
