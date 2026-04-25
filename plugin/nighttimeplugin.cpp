#include "nighttime.h"

#include <QGuiApplication>
#include <QQmlEngine>
#include <QQmlExtensionPlugin>

class DayNightPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri) override
    {
        qmlRegisterType<DayNight>(uri, 1, 0, "DayNight");
    }
};

#include "nighttimeplugin.moc"
