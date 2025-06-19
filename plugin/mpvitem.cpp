/*
 * SPDX-FileCopyrightText: 2023 George Florea Bănuș <georgefb899@gmail.com>
 *
 * SPDX-License-Identifier: MIT
 */

#include "mpvitem.h"

#include <MpvController>

#include "mpvproperties.h"

MpvItem::MpvItem(QQuickItem *parent)
    : MpvAbstractItem(parent)
{
    observeProperty(MpvProperties::self()->MediaTitle, MPV_FORMAT_STRING);
    observeProperty(MpvProperties::self()->Position, MPV_FORMAT_DOUBLE);
    observeProperty(MpvProperties::self()->Duration, MPV_FORMAT_DOUBLE);
    observeProperty(MpvProperties::self()->Pause, MPV_FORMAT_FLAG);
    observeProperty(MpvProperties::self()->Volume, MPV_FORMAT_INT64);

    setupConnections();

    // since this is async the effects are not immediately visible
    // to do something after the property was set do it in onAsyncReply
    // use the id to identify the correct call
    setPropertyAsync(QStringLiteral("volume"), 99, static_cast<int>(MpvItem::AsyncIds::SetVolume));
    setProperty(QStringLiteral("mute"), true);

    // since this is async the effects are not immediately visible
    // to get the value do it in onGetPropertyReply
    // use the id to identify the correct call
    getPropertyAsync(MpvProperties::self()->Volume, static_cast<int>(MpvItem::AsyncIds::GetVolume));
}

void MpvItem::setupConnections()
{
    // clang-format off
    connect(mpvController(), &MpvController::propertyChanged,
            this, &MpvItem::onPropertyChanged, Qt::QueuedConnection);

    connect(mpvController(), &MpvController::fileStarted,
            this, &MpvItem::fileStarted, Qt::QueuedConnection);

    connect(mpvController(), &MpvController::fileLoaded,
            this, &MpvItem::fileLoaded, Qt::QueuedConnection);

    connect(mpvController(), &MpvController::endFile,
            this, &MpvItem::endFile, Qt::QueuedConnection);

    connect(mpvController(), &MpvController::videoReconfig,
            this, &MpvItem::videoReconfig, Qt::QueuedConnection);

    connect(mpvController(), &MpvController::asyncReply,
            this, &MpvItem::onAsyncReply, Qt::QueuedConnection);
    // clang-format on
}

void MpvItem::onPropertyChanged(const QString &property, const QVariant &value)
{
    if (property == MpvProperties::self()->MediaTitle) {
        Q_EMIT mediaTitleChanged();

    } else if (property == MpvProperties::self()->Position) {
        m_formattedPosition = formatTime(value.toDouble());
        Q_EMIT positionChanged();

    } else if (property == MpvProperties::self()->Duration) {
        m_formattedDuration = formatTime(value.toDouble());
        Q_EMIT durationChanged();

    } else if (property == MpvProperties::self()->Pause) {
        Q_EMIT pauseChanged();

    } else if (property == MpvProperties::self()->Volume) {
        Q_EMIT volumeChanged();
    }
}

void MpvItem::onAsyncReply(const QVariant &data, mpv_event event)
{
    switch (static_cast<AsyncIds>(event.reply_userdata)) {
    case AsyncIds::None: {
        break;
    }
    case AsyncIds::SetVolume: {
        qDebug() << "onSetPropertyReply" << event.reply_userdata;
        break;
    }
    case AsyncIds::GetVolume: {
        qDebug() << "onGetPropertyReply" << event.reply_userdata << data;
        break;
    }
    case AsyncIds::ExpandText: {
        qDebug() << "onGetPropertyReply" << event.reply_userdata << data;
        break;
    }
    }
}

QString MpvItem::formatTime(const double time)
{
    int totalNumberOfSeconds = static_cast<int>(time);
    int seconds = totalNumberOfSeconds % 60;
    int minutes = (totalNumberOfSeconds / 60) % 60;
    int hours = (totalNumberOfSeconds / 60 / 60);

    QString timeString =
        QStringLiteral("%1:%2:%3").arg(hours, 2, 10, QLatin1Char('0')).arg(minutes, 2, 10, QLatin1Char('0')).arg(seconds, 2, 10, QLatin1Char('0'));

    return timeString;
}

void MpvItem::loadFile(const QString &file)
{
    auto url = QUrl::fromUserInput(file);
    if (m_currentUrl != url) {
        m_currentUrl = url;
        Q_EMIT currentUrlChanged();
    }

    Q_EMIT command(QStringList() << QStringLiteral("loadfile") << m_currentUrl.toString(QUrl::PreferLocalFile));
}

QString MpvItem::mediaTitle()
{
    return getProperty(MpvProperties::self()->MediaTitle).toString();
}

double MpvItem::position()
{
    return getProperty(MpvProperties::self()->Position).toDouble();
}

void MpvItem::setPosition(double value)
{
    if (qFuzzyCompare(value, position())) {
        return;
    }
    Q_EMIT setPropertyAsync(MpvProperties::self()->Position, value);
}

double MpvItem::duration()
{
    return getProperty(MpvProperties::self()->Duration).toDouble();
}

bool MpvItem::pause()
{
    return getProperty(MpvProperties::self()->Pause).toBool();
}

void MpvItem::setPause(bool value)
{
    if (value == pause()) {
        return;
    }
    Q_EMIT setPropertyAsync(MpvProperties::self()->Pause, value);
}

int MpvItem::volume()
{
    return getProperty(MpvProperties::self()->Volume).toInt();
}

void MpvItem::setVolume(int value)
{
    if (value == volume()) {
        return;
    }
    Q_EMIT setPropertyAsync(MpvProperties::self()->Volume, value);
}

QString MpvItem::formattedDuration() const
{
    return m_formattedDuration;
}

QString MpvItem::formattedPosition() const
{
    return m_formattedPosition;
}

QUrl MpvItem::currentUrl() const
{
    return m_currentUrl;
}

#include "moc_mpvitem.cpp"
