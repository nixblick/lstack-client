#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("LSTack OS Client");
    app.setOrganizationName("LSTack");
    app.setWindowIcon(QIcon(":/resources/icons/lstack-client.png"));

    QQmlApplicationEngine engine;
    const QUrl url(u"qrc:/ui/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, [](){ QCoreApplication::exit(-1); }, Qt::QueuedConnection);
    engine.load(url);
    return app.exec();
}
