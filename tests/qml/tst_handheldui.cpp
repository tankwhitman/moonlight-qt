#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickItem>
#include <QTimer>
#include <QtTest>
#include <QAbstractListModel>

class Nav : public QObject {
    Q_OBJECT
public:
    bool mode = false;
    Q_INVOKABLE void setUiNavMode(bool value) { mode = value; }
    Q_INVOKABLE bool getUiNavMode() { return mode; }
    Q_INVOKABLE int getConnectedGamepads() { return 1; }
};
class Model : public QAbstractListModel {
    Q_OBJECT
public:
    using QAbstractListModel::QAbstractListModel;
    Q_INVOKABLE void initialize(QObject*, int = 0, bool = false) {}
    Q_INVOKABLE int getDirectLaunchAppIndex() { return -1; }
    int rowCount(const QModelIndex& = QModelIndex()) const override { return 8; }
    QHash<int,QByteArray> roleNames() const override { return {{256,"name"},{257,"boxart"},{258,"hidden"},{259,"running"},{260,"isAppCollectorGame"},{261,"directLaunch"}}; }
    QVariant data(const QModelIndex& i, int role) const override {
        if(role==256) return QStringList{"Desktop", "Hades II", "Forza Horizon", "Stardew Valley", "Elden Ring", "Balatro", "Portal 2", "Cyberpunk 2077"}[i.row()];
        if(role==257) return "qrc:/res/no_app_image.png";
        return false;
    }
signals:
    void computerLost();
};
int main(int argc, char** argv) {
    qInstallMessageHandler([](QtMsgType, const QMessageLogContext&, const QString& message) { fprintf(stderr, "%s\n", qPrintable(message)); });
    QGuiApplication app(argc,argv);
    QDir outputDir(qEnvironmentVariable("MOONLIGHT_TEST_OUTPUT", QDir::tempPath() + "/moonlight-handheld-ui-test"));
    QDir().mkpath(outputDir.absolutePath());
    Nav nav;
    QObject prefs, manager;
    qmlRegisterSingletonInstance("SdlGamepadKeyNavigation",1,0,"SdlGamepadKeyNavigation",&nav);
    qmlRegisterSingletonInstance("StreamingPreferences",1,0,"StreamingPreferences",&prefs);
    qmlRegisterSingletonInstance("ComputerManager",1,0,"ComputerManager",&manager);
    qmlRegisterType<Model>("AppModel",1,0,"AppModel");
    QQmlApplicationEngine engine;
    const QByteArray qml=R"(
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Controls.Material 2.2
import "qrc:/gui" as UI
ApplicationWindow {
 id: window
 width: 1920; height: 1080; visible: true
 property real uiScale: Math.max(1, Math.min(width / 1280, height / 720))
 Material.theme: Material.Dark
 Material.accent: "#66d9ef"
 Material.background: "#101722"
 color: "#101722"
 header: ToolBar { height: 72 * window.uiScale; background: Rectangle { color: "#172232" } Label { anchors.centerIn: parent; text: "Gaming PC · Library"; font.pixelSize: 28 * window.uiScale; font.bold: true } }
 footer: ToolBar { height: 52 * window.uiScale; background: Rectangle { color: "#172232" } Label { anchors.centerIn: parent; text: "A  Select     B  Back     X  Options     Y / Start  Settings"; font.pixelSize: 18 * window.uiScale } }
 StackView { id: stackView; focus: true; anchors.fill: parent; initialItem: UI.AppView { objectName: "library"; computerIndex: 0; showGames: true } }
 UI.ConnectionDialog { id: connection; objectName: "connection" }
 UI.ControllerKeyboard { objectName: "keyboard" }
 TextField { objectName: "keyboardField"; text: "192."; width: 1; height: 1; maximumLength: 30 }
}
)";
    engine.loadData(qml);
    if(engine.rootObjects().isEmpty()) return 1;
    auto* window=qobject_cast<QQuickWindow*>(engine.rootObjects()[0]);
    window->requestActivate();
    auto* library = window->findChild<QQuickItem*>("library");
    library->setProperty("currentIndex",0);
    library->forceActiveFocus();
    QTimer::singleShot(800,[&] {
        window->grabWindow().save(outputDir.filePath("library-preview.png"));
        auto* dialog=window->findChild<QObject*>("connection");
        QMetaObject::invokeMethod(dialog,"open");
        QVariant config=QVariantMap{{"mode",2},{"lan","192.168.1.10:47989"},{"tailscale","100.100.1.10:47989"}};
        QMetaObject::invokeMethod(dialog,"loadSettings",Q_ARG(QVariant,config));
        QTimer::singleShot(500,[&] {
            window->grabWindow().save(outputDir.filePath("connection-preview.png"));
            QMetaObject::invokeMethod(window->findChild<QObject*>("connection"), "close");
            window->resize(1280,720);
            auto* field = window->findChild<QObject*>("keyboardField");
            auto* keyboard = window->findChild<QObject*>("keyboard");
            QMetaObject::invokeMethod(keyboard,"edit",Q_ARG(QVariant,QVariant::fromValue(field)),Q_ARG(QVariant,true));
            QTimer::singleShot(300,[&, keyboard] {
                QTest::keyClick(window, Qt::Key_Return);
                QTest::keyClick(window, Qt::Key_Right);
                QTest::keyClick(window, Qt::Key_Return);
                if (keyboard->property("draft").toString() != "192.12") {
                    fprintf(stderr,"FAIL: controller keyboard input: %s\n", qPrintable(keyboard->property("draft").toString()));
                    app.exit(2); return;
                }
                window->grabWindow().save(outputDir.filePath("keyboard-preview.png"));
                QMetaObject::invokeMethod(keyboard->findChild<QObject*>("keyboardDone"),"clicked");
                if (window->findChild<QObject*>("keyboardField")->property("text").toString() != "192.12" || nav.mode) {
                    fprintf(stderr,"FAIL: keyboard commit or navigation restoration\n");
                    app.exit(3); return;
                }
                fprintf(stderr,"PASS: controller keyboard input, commit, and navigation restoration\n");
                QTimer::singleShot(300,[&] {
                    auto* library = window->findChild<QQuickItem*>("library");
                    library->forceActiveFocus();
                    window->grabWindow().save(outputDir.filePath("library-preview-720p.png"));
                    app.quit();
                });
            });
        });
    });
    return app.exec();
}
#include "tst_handheldui.moc"
