#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "app_controller.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
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
