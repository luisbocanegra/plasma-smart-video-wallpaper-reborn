#include "mpvitem.h"
#include "mpvproperties.h"

#include <QQmlEngine>
#include <QQmlExtensionPlugin>

class MpvPlugin : public QQmlExtensionPlugin {
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

  public:
    void registerTypes(const char *uri) override {
        qmlRegisterType<MpvItem>(uri, 1, 0, "MpvItem");
        qmlRegisterSingletonType<MpvProperties>(uri, 1, 0, "MpvProperties",
[](QQmlEngine *engine, QJSEngine *) -> QObject * {
          Q_UNUSED(engine);
          return new MpvProperties();
        });
    }
};

#include "mpvplugin.moc"
