/*
    SPDX-FileCopyrightText: 2025 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
    SPDX-FileCopyrightText: 2026 Luis Bocanegra <luisbocanegra17b@gmail.com>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#ifndef NIGHTTIME_H
#define NIGHTTIME_H

#pragma once
#include <KDarkLightScheduleProvider>
#include <KSystemClockSkewNotifier>
#include <QObject>
#include <QTimer>

class DayNightPhase
{
public:
    enum Kind {
        Night,
        Sunrise,
        Day,
        Sunset,
    };

    DayNightPhase();
    DayNightPhase(Kind kind);

    operator Kind() const;

    DayNightPhase previous() const;
    DayNightPhase next() const;

    static DayNightPhase from(KDarkLightTransition::Type type);
    static DayNightPhase from(const QDateTime &dateTime, const KDarkLightTransition &previousTransition, const KDarkLightTransition &nextTransition);

private:
    Kind m_kind;
};

inline DayNightPhase::operator DayNightPhase::Kind() const
{
    return m_kind;
}

class DayNight : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isDay READ isDay NOTIFY isDayChanged)

public:
    explicit DayNight(QObject *parent = nullptr);

    bool isDay() const;

    ~DayNight() override;

signals:

    void isDayChanged(bool isDay);

private:
    void schedule();

    KDarkLightScheduleProvider *provider = nullptr;
    KSystemClockSkewNotifier *m_systemClockMonitor;
    QTimer *m_rescheduleTimer;
    bool m_isDay = false;
};

#endif
