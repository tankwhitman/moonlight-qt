#include "backend/nvcomputer.h"
#include <QtTest>
#include <QTemporaryDir>

class ConnectionPolicyTest : public QObject {
    Q_OBJECT
private slots:
    void selectedRouteDoesNotFallBack() {
        QTemporaryDir dir;
        QSettings settings(dir.filePath("host.ini"), QSettings::IniFormat);
        NvComputer host(settings);
        host.activeAddress = NvAddress("192.168.1.5", 47989);
        host.localAddress = host.activeAddress;
        host.lanConnectionAddress = host.localAddress;
        host.tailscaleConnectionAddress = NvAddress("100.100.1.5", 48000);
        host.connectionMode = 2;
        QCOMPARE(host.uniqueAddresses(), QVector<NvAddress>{host.tailscaleConnectionAddress});
        host.connectionMode = 1;
        QCOMPARE(host.uniqueAddresses(), QVector<NvAddress>{host.lanConnectionAddress});
        host.connectionMode = 0;
        QCOMPARE(host.uniqueAddresses(), QVector<NvAddress>{host.activeAddress});
    }
    void settingsSurviveRestart() {
        QTemporaryDir dir;
        QSettings settings(dir.filePath("host.ini"), QSettings::IniFormat);
        NvComputer host(settings);
        host.connectionMode = 2;
        host.lanConnectionAddress = NvAddress("192.168.1.5", 47990);
        host.tailscaleConnectionAddress = NvAddress("100.100.1.5", 48000);
        host.serialize(settings, false);
        NvComputer restored(settings);
        QCOMPARE(restored.connectionMode, 2);
        QCOMPARE(restored.lanConnectionAddress, host.lanConnectionAddress);
        QCOMPARE(restored.tailscaleConnectionAddress, host.tailscaleConnectionAddress);
        QVERIFY(host.isEqualSerialized(restored));
        restored.connectionMode = 1;
        QVERIFY(!host.isEqualSerialized(restored));
    }
    void stalePollCannotUndoRouteSwitch() {
        QTemporaryDir dir;
        QSettings settings(dir.filePath("host.ini"), QSettings::IniFormat);
        settings.setValue("uuid", "test-host");
        NvComputer host(settings), response(settings);
        host.connectionMode = 2;
        host.connectionRevision = 3;
        host.tailscaleConnectionAddress = NvAddress("100.100.1.5", 47989);
        response.activeAddress = host.tailscaleConnectionAddress;
        response.state = NvComputer::CS_ONLINE;
        bool accepted = true;
        QVERIFY(!host.update(response, 2, &accepted));
        QVERIFY(!accepted);
        QCOMPARE(host.state, NvComputer::CS_UNKNOWN);
        response.activeAddress = NvAddress("192.168.1.5", 47989);
        QVERIFY(!host.update(response, 3, &accepted));
        QVERIFY(!accepted);
        response.activeAddress = host.tailscaleConnectionAddress;
        QVERIFY(host.update(response, 3, &accepted));
        QVERIFY(accepted);
        QCOMPARE(host.state, NvComputer::CS_ONLINE);
        QCOMPARE(host.connectionMode, 2);
    }
    void oldSettingsRemainAutomatic() {
        QTemporaryDir dir;
        QSettings settings(dir.filePath("host.ini"), QSettings::IniFormat);
        settings.setValue("localaddress", "192.168.1.5");
        NvComputer host(settings);
        QCOMPARE(host.connectionMode, 0);
        QCOMPARE(host.uniqueAddresses(), QVector<NvAddress>{host.localAddress});
    }
};
QTEST_GUILESS_MAIN(ConnectionPolicyTest)
#include "tst_connectionpolicy.moc"
