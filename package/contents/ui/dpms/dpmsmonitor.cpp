#include "dpmsmonitor.h"

#include <KWayland/Client/connection_thread.h>
#include <KWayland/Client/dpms.h>
#include <KWayland/Client/output.h>
#include <KWayland/Client/registry.h>

using namespace KWayland::Client;

DpmsMonitor::DpmsMonitor(QObject *parent)
    : QObject(parent)
{
    // Reuses the QGuiApplication's existing Wayland connection (plasmashell is
    // already a Wayland client) instead of opening a second socket connection.
    // Returns null on non-Wayland platforms (e.g. X11).
    auto connection = ConnectionThread::fromApplication(this);
    if (!connection) {
        return;
    }

    m_registry = new Registry(this);
    m_registry->create(connection);
    connect(m_registry, &Registry::interfacesAnnounced, this, &DpmsMonitor::handleInterfacesAnnounced);
    m_registry->setup();
}

DpmsMonitor::~DpmsMonitor() = default;

bool DpmsMonitor::isAvailable() const
{
    return m_available;
}

bool DpmsMonitor::screenIsOff() const
{
    return m_screenIsOff;
}

QRect DpmsMonitor::screenGeometry() const
{
    return m_screenGeometry;
}

void DpmsMonitor::setScreenGeometry(const QRect &geometry)
{
    if (m_screenGeometry == geometry) {
        return;
    }
    m_screenGeometry = geometry;
    Q_EMIT screenGeometryChanged();
    updateActiveOutput();
}

void DpmsMonitor::handleInterfacesAnnounced()
{
    const auto dpmsInterfaces = m_registry->interfaces(Registry::Interface::Dpms);
    const auto outputInterfaces = m_registry->interfaces(Registry::Interface::Output);

    if (dpmsInterfaces.isEmpty() || outputInterfaces.isEmpty()) {
        // Compositor isn't KWin, or doesn't advertise org_kde_kwin_dpms_manager.
        return;
    }

    m_dpmsManager = m_registry->createDpmsManager(dpmsInterfaces.first().name, dpmsInterfaces.first().version, this);

    for (const auto &outputInterface : outputInterfaces) {
        auto output = m_registry->createOutput(outputInterface.name, outputInterface.version, this);
        auto dpms = m_dpmsManager->getDpms(output, this);

        m_outputs.append(output);
        m_dpmsForOutput.insert(output, dpms);

        // Output geometry (and dpms support/mode) arrive asynchronously after
        // creation, so re-run matching whenever any of it changes.
        connect(output, &Output::changed, this, &DpmsMonitor::updateActiveOutput);
        connect(dpms, &Dpms::modeChanged, this, &DpmsMonitor::updateActiveOutput);
        connect(dpms, &Dpms::supportedChanged, this, &DpmsMonitor::updateActiveOutput);
    }

    updateActiveOutput();
}

void DpmsMonitor::updateActiveOutput()
{
    Output *matched = nullptr;

    if (m_outputs.size() == 1) {
        matched = m_outputs.first();
    } else if (!m_screenGeometry.isNull()) {
        // Output::geometry() combines globalPosition() with the native/physical
        // pixel size (from wl_output's mode event). On fractionally-scaled
        // outputs (e.g. 1.15x) that size never matches Plasma's logical
        // screenGeometry, since wl_output.scale is integer-only and can't
        // represent the real factor. Position, unlike size, is reported by
        // KWin in logical compositor space already, so it lines up with
        // screenGeometry - match on that alone.
        for (auto *output : std::as_const(m_outputs)) {
            if (output->globalPosition() == m_screenGeometry.topLeft()) {
                matched = output;
                break;
            }
        }
    }

    m_activeDpms = matched ? m_dpmsForOutput.value(matched) : nullptr;

    setAvailable(m_activeDpms && m_activeDpms->isSupported());
    setScreenIsOff(m_available && m_activeDpms->mode() != Dpms::Mode::On);
}

void DpmsMonitor::setAvailable(bool available)
{
    if (m_available == available) {
        return;
    }
    m_available = available;
    Q_EMIT availableChanged();
}

void DpmsMonitor::setScreenIsOff(bool off)
{
    if (m_screenIsOff == off) {
        return;
    }
    m_screenIsOff = off;
    Q_EMIT screenIsOffChanged();
}
