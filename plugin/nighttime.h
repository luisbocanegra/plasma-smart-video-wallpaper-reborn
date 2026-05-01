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
#include <QQmlParserStatus>
#include <QTimer>
#include <qqmlintegration.h>

class DayNightPhase
{
public:
    enum Kind {
        Night,
        Sunrise,
        Day,
        Sunset,
        Unknown,
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

class DayNight : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT

    Q_PROPERTY(int phase READ phase NOTIFY phaseChanged)
    Q_PROPERTY(QString initialState READ initialState WRITE setInitialState NOTIFY initialStateChanged)
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)

public:
    explicit DayNight(QObject *parent = nullptr);

    void classBegin() override;
    void componentComplete() override;

    int phase() const;

    QString initialState() const;
    void setInitialState(const QString &state);

    QString state() const;
    void setState(const QString &state);

signals:

    void phaseChanged();
    void initialStateChanged();
    void stateChanged();

private:
    void schedule();
    void update();

    KDarkLightScheduleProvider *m_darkLightScheduleProvider = nullptr;
    KSystemClockSkewNotifier *m_systemClockMonitor;
    KDarkLightTransition m_previousTransition;
    KDarkLightTransition m_nextTransition;
    QTimer *m_rescheduleTimer;
    QTimer *m_transitionUpdateTimer;
    QString m_initialState;
    QString m_state;

    int m_phase = DayNightPhase::Unknown;
};

#endif
