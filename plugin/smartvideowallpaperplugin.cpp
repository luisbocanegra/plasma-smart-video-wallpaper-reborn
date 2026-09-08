#include <QQmlEngine>
#include <QQmlExtensionPlugin>
#include <qqmlextensionplugin.h>

class DayNightPlugin : public QQmlEngineExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
};

#include "smartvideowallpaperplugin.moc"
