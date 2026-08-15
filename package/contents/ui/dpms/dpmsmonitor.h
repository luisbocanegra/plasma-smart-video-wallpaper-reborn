#pragma once

#include <QHash>
#include <QList>
#include <QObject>
#include <QRect>
#include <qqmlintegration.h>

namespace KWayland
{
namespace Client
{
class Registry;
class DpmsManager;
class Dpms;
class Output;
}
}

// Event-driven DPMS (monitor power) state via the KWin-only org_kde_kwin_dpms
// Wayland protocol - the same source kscreen-doctor reads, but pushed instead
// of polled. Only available under Plasma Wayland; `available` stays false
// everywhere else (X11, other compositors, or if KWin doesn't advertise the
// protocol), so callers must keep a fallback for those cases.
class DpmsMonitor : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool available READ isAvailable NOTIFY availableChanged)
    Q_PROPERTY(bool screenIsOff READ screenIsOff NOTIFY screenIsOffChanged)
    Q_PROPERTY(QRect screenGeometry READ screenGeometry WRITE setScreenGeometry NOTIFY screenGeometryChanged)

public:
    explicit DpmsMonitor(QObject *parent = nullptr);
    ~DpmsMonitor() override;

    bool isAvailable() const;
    bool screenIsOff() const;
    QRect screenGeometry() const;
    void setScreenGeometry(const QRect &geometry);

Q_SIGNALS:
    void availableChanged();
    void screenIsOffChanged();
    void screenGeometryChanged();

private:
    void handleInterfacesAnnounced();
    void updateActiveOutput();
    void setAvailable(bool available);
    void setScreenIsOff(bool off);

    KWayland::Client::Registry *m_registry = nullptr;
    KWayland::Client::DpmsManager *m_dpmsManager = nullptr;
    QList<KWayland::Client::Output *> m_outputs;
    QHash<KWayland::Client::Output *, KWayland::Client::Dpms *> m_dpmsForOutput;
    KWayland::Client::Dpms *m_activeDpms = nullptr;
    QRect m_screenGeometry;
    bool m_available = false;
    bool m_screenIsOff = false;
};
