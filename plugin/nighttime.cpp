/*
    SPDX-FileCopyrightText: 2025 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
    SPDX-FileCopyrightText: 2026 Luis Bocanegra <luisbocanegra17b@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "nighttime.h"

DayNightPhase::DayNightPhase()
    : m_kind(Night)
{
}

DayNightPhase::DayNightPhase(Kind kind)
    : m_kind(kind)
{
}

static int positiveMod(int m, int n)
{
    return (n + (m % n)) % n;
}

DayNightPhase DayNightPhase::previous() const
{
    return {Kind(positiveMod(int(m_kind) - 1, 4))};
}

DayNightPhase DayNightPhase::next() const
{
    return {Kind(positiveMod(int(m_kind) + 1, 4))};
}

DayNightPhase DayNightPhase::from(KDarkLightTransition::Type type)
{
    switch (type) {
    case KDarkLightTransition::Morning:
        return Kind::Sunrise;
    case KDarkLightTransition::Evening:
        return Kind::Sunset;
    }

    Q_UNREACHABLE();
}

DayNightPhase DayNightPhase::from(const QDateTime &dateTime, const KDarkLightTransition &previousTransition, const KDarkLightTransition &nextTransition)
{
    const DayNightPhase previousPhase = from(previousTransition.type());
    switch (previousTransition.test(dateTime)) {
    case KDarkLightTransition::Upcoming:
        return previousPhase.previous();
    case KDarkLightTransition::InProgress:
        return previousPhase;
    case KDarkLightTransition::Passed:
        break;
    }

    const DayNightPhase nextPhase = from(nextTransition.type());
    switch (nextTransition.test(dateTime)) {
    case KDarkLightTransition::Upcoming:
        return nextPhase.previous();
    case KDarkLightTransition::InProgress:
        return nextPhase;
    case KDarkLightTransition::Passed:
        return nextPhase.next();
    }

    Q_UNREACHABLE();
}

DayNight::DayNight(QObject *parent)
    : QObject(parent)
    , m_systemClockMonitor(new KSystemClockSkewNotifier(this))
    , m_rescheduleTimer(new QTimer(this))
    , m_transitionUpdateTimer(new QTimer(this))
{
    m_transitionUpdateTimer->setSingleShot(true);
    connect(m_transitionUpdateTimer, &QTimer::timeout, this, &DayNight::update);

    m_systemClockMonitor->setActive(true);
    connect(m_systemClockMonitor, &KSystemClockSkewNotifier::skewed, this, &DayNight::schedule);

    m_rescheduleTimer->setSingleShot(true);
    connect(m_rescheduleTimer, &QTimer::timeout, this, &DayNight::schedule);
}

void DayNight::classBegin()
{
}

void DayNight::componentComplete()
{
    m_darkLightScheduleProvider = new KDarkLightScheduleProvider(m_initialState, this);
    connect(m_darkLightScheduleProvider, &KDarkLightScheduleProvider::scheduleChanged, this, [this]() {
        setState(m_darkLightScheduleProvider->state());
        schedule();
    });

    schedule();
}

void DayNight::schedule()
{
    const QDateTime now = QDateTime::currentDateTime();
    const KDarkLightSchedule schedule = m_darkLightScheduleProvider->schedule();

    m_previousTransition = *schedule.previousTransition(now);
    m_nextTransition = *schedule.nextTransition(now);

    m_rescheduleTimer->start(now.msecsTo(m_nextTransition.startDateTime()));
    update();
}

void DayNight::update()
{
    const QDateTime now = QDateTime::currentDateTime();

    const DayNightPhase currentPhase = DayNightPhase::from(now, m_previousTransition, m_nextTransition);

    if (m_phase != currentPhase) {
        m_phase = currentPhase;
        emit phaseChanged();
    }

    const int blendInterval = 60000;
    switch (currentPhase) {
    case DayNightPhase::Night:
    case DayNightPhase::Day:
    case DayNightPhase::Unknown:
        m_transitionUpdateTimer->stop();
        break;
    case DayNightPhase::Sunrise:
    case DayNightPhase::Sunset:
        m_transitionUpdateTimer->start(blendInterval);
        break;
    }
}

void DayNight::setInitialState(const QString &state)
{
    if (m_initialState != state) {
        m_initialState = state;
        Q_EMIT initialStateChanged();
    }
}

void DayNight::setState(const QString &state)
{
    if (m_state != state) {
        m_state = state;
        Q_EMIT stateChanged();
    }
}

int DayNight::phase() const
{
    return m_phase;
}

QString DayNight::initialState() const
{
    return m_initialState;
}

QString DayNight::state() const
{
    return m_state;
}
