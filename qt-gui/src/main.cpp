#include <QGuiApplication>
#include <QFont>
#include <QFontInfo>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#include "app_controller.h"

int main(int argc, char *argv[]) {
    QQuickStyle::setStyle("Material");
    QQuickStyle::setFallbackStyle("Basic");

    QGuiApplication app(argc, argv);
    QFont appFont("Microsoft YaHei UI");
    app.setFont(appFont);
    qInfo().noquote() << "UI font:" << QFontInfo(app.font()).family();
    app.setOrganizationName("Evan-Xu");
    app.setApplicationName("scrcpy Qt GUI");

    AppController controller;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("app", &controller);
    engine.loadFromModule("ScrcpyGui", "Main");
    if (engine.rootObjects().isEmpty()) {
        return 1;
    }
    return app.exec();
}
