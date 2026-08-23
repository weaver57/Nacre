#pragma once

#include <QObject>
#include <QJsonObject>
#include <QFileSystemWatcher>
#include <QStandardPaths>

class ConfigManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int barHeight READ barHeight NOTIFY barHeightChanged)
    Q_PROPERTY(QString barPosition READ barPosition NOTIFY barPositionChanged)
    Q_PROPERTY(bool barVisible READ barVisible NOTIFY barVisibleChanged)
    Q_PROPERTY(QString theme READ theme NOTIFY themeChanged)

public:
    explicit ConfigManager(QObject *parent = nullptr);

    int barHeight() const;
    QString barPosition() const;
    bool barVisible() const;
    QString theme() const;

signals:
    void configChanged();
    void barHeightChanged();
    void barPositionChanged();
    void barVisibleChanged();
    void themeChanged();

private slots:
    void onFileChanged(const QString &path);

private:
    void loadConfig();
    QJsonValue resolve(const QString &key, const QJsonValue &fallback) const;

    QFileSystemWatcher m_watcher;
    QJsonObject m_config;

    // Defaults
    static constexpr int DEFAULT_BAR_HEIGHT = 32;
    static const QString DEFAULT_BAR_POSITION;
    static constexpr bool DEFAULT_BAR_VISIBLE = true;
    static const QString DEFAULT_THEME;
};
