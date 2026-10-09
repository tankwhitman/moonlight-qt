TEMPLATE = app
TARGET = tst_connectionpolicy
QT += core network testlib
CONFIG += console testcase c++17
CONFIG -= app_bundle
# Link only the model paths used here; HTTP and wake-on-LAN aren't exercised.
unix:!macx {
    QMAKE_CXXFLAGS += -ffunction-sections -fdata-sections
    QMAKE_LFLAGS += -Wl,--gc-sections
}
INCLUDEPATH += ../../app ../../moonlight-common-c/moonlight-common-c/src
SOURCES += tst_connectionpolicy.cpp ../../app/backend/nvcomputer.cpp ../../app/backend/nvaddress.cpp ../../app/backend/nvapp.cpp
