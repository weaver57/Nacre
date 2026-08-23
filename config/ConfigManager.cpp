#include "ConfigManager.h"

#include <QFile>
#include <QJsonDocument>
#include <QDir>
#include <QDebug>

const QString ConfigManager::DEFAULT_BAR_POSITION = QStringLiteral("top");
const QString ConfigManager::DEFAULT_THEME = QStringLiteral("default");

ConfigManager::ConfigManager(QObject *parent)
    : QObject(parent)
{
    // Determine config path: ~/.config/nacre/shell.json
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
        + QStringLiteral("/nacre");
    const QString configPath = configDir + QStringLiteral("/shell.json");

    // Ensure the directory exists
    QDir().mkpath(configDir);

    // Watch the config file (and its parent dir for first creation)
    m_watcher.addPath(configDir);
    if (QFile::exists(configPath)) {
        m_watcher.addPath(configPath);
    }

    connect(&m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &ConfigManager::onFileChanged);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged,
            this, &ConfigManager::onFileChanged);

    loadConfig();
}

int ConfigManager::barHeight() const
{
    return resolve(QStringLiteral("bar.height"), DEFAULT_BAR_HEIGHT).toInt();
}

QString ConfigManager::barPosition() const
{
    return resolve(QStringLiteral("bar.position"), DEFAULT_BAR_POSITION).toString();
}

bool ConfigManager::barVisible() const
{
    return resolve(QStringLiteral("bar.visible"), DEFAULT_BAR_VISIBLE).toBool();
}

QString ConfigManager::theme() const
{
    return resolve(QStringLiteral("theme"), DEFAULT_THEME).toString();
}

void ConfigManager::onFileChanged(const QString &path)
{
    Q_UNUSED(path)

    // Re-add the file watcher if the file was recreated
    const QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
        + QStringLiteral("/nacre/shell.json");

    if (QFile::exists(configPath) && !m_watcher.files().contains(configPath)) {
        m_watcher.addPath(configPath);
    }

    loadConfig();
}

void ConfigManager::loadConfig()
{
    const QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
        + QStringLiteral("/nacre/shell.json");

    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly)) {
        // File doesn't exist or can't be read — use all defaults
        if (!m_config.isEmpty()) {
            m_config = QJsonObject();
            emit configChanged();
        }
        return;
    }

    const QByteArray data = file.readAll();
    file.close();

    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "Nacre config: parse error at offset" << parseError.offset
                   << parseError.errorString();
        return;
    }

    if (!doc.isObject()) {
        qWarning() << "Nacre config: expected a JSON object at root";
        return;
    }

    QJsonObject newConfig = doc.object();

    if (newConfig != m_config) {
        m_config = newConfig;

        // Emit individual signals so bindings update granularly
        emit barHeightChanged();
        emit barPositionChanged();
        emit barVisibleChanged();
        emit themeChanged();
        emit configChanged();
    }
}

QJsonValue ConfigManager::resolve(const QString &key, const QJsonValue &fallback) const
{
    // Support dot-notation keys like "bar.height" → { "bar": { "height": ... } }
    const QStringList parts = key.split(QStringLiteral("."));
    QJsonValue current = m_config;

    for (const QString &part : parts) {
        if (!current.isObject()) {
            return fallback;
        }
        current = current.toObject().value(part);
    }

    return current.isUndefined() || current.isNull() ? fallback : current;
}
