TEMPLATE = app
TARGET = tst_handheldui
QT += core gui quick quickcontrols2 qml svg testlib
CONFIG += console c++17
SOURCES += tst_handheldui.cpp
RESOURCES += ../../app/qml.qrc ../../app/resources.qrc
