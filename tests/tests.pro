# The test tree is intentionally opt-in.  The application and package builds
# do not enter it unless their qmake invocation explicitly adds CONFIG+=tests.
TEMPLATE = subdirs
CONFIG += ordered

contains(CONFIG, tests) {
    linux {
        connectionPolicy.file = $$PWD/connection/connection.pro
        SUBDIRS += connectionPolicy
        handheldUi.file = $$PWD/qml/handheld-ui.pro
        SUBDIRS += handheldUi
    }
    SUBDIRS += updates
    SUBDIRS += vrr
    SUBDIRS += haptics
    SUBDIRS += pyrowave
    macx {
        controllerNavigation.file = $$PWD/qml/controller-navigation.pro
        SUBDIRS += controllerNavigation
    } else:unix:packagesExist(sdl2) {
        controllerNavigation.file = $$PWD/qml/controller-navigation.pro
        SUBDIRS += controllerNavigation
    }
} else {
    message(VRR tests are disabled; rerun qmake with CONFIG+=tests)
}
