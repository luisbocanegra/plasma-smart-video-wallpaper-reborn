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
{
    provider = new KDarkLightScheduleProvider();
    QObject::connect(provider, &KDarkLightScheduleProvider::scheduleChanged, this, &DayNight::schedule);
    m_systemClockMonitor->setActive(true);
    connect(m_systemClockMonitor, &KSystemClockSkewNotifier::skewed, this, &DayNight::schedule);
    m_rescheduleTimer->setSingleShot(true);
    connect(m_rescheduleTimer, &QTimer::timeout, this, &DayNight::schedule);
    schedule();
}

DayNight::~DayNight() = default;

bool DayNight::isDay() const
{
    return m_isDay;
}

void DayNight::schedule()
{
    qDebug() << "Updating day/night status...";
    const QDateTime now = QDateTime::currentDateTime();
    const KDarkLightSchedule schedule = provider->schedule();
    const KDarkLightTransition previousTransition = *schedule.previousTransition(now);
    const KDarkLightTransition nextTransition = *schedule.nextTransition(now);
    qDebug() << "Previous transition:" << previousTransition.type() << previousTransition.endDateTime();
    qDebug() << "Next transition:" << nextTransition.type() << nextTransition.startDateTime();
    const DayNightPhase phase = DayNightPhase::from(now, previousTransition, nextTransition);
    qDebug() << "Current phase:" << int(phase);
    const bool isDay = phase == DayNightPhase::Day || phase == DayNightPhase::Sunrise;
    qDebug() << "Is it day?" << isDay;
    if (m_isDay != isDay) {
        m_isDay = isDay;
        emit isDayChanged(isDay);
    }
    m_rescheduleTimer->start(now.msecsTo(nextTransition.startDateTime()));
}
