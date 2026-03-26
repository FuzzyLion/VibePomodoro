import Foundation

extension PomodoroStore {
    func persist() {
        Self.saveValue(settings, for: StorageKey.settings, using: defaults, encoder: encoder)
        Self.saveValue(activeSession, for: StorageKey.activeSession, using: defaults, encoder: encoder)
        Self.saveValue(completedSessions, for: StorageKey.completedSessions, using: defaults, encoder: encoder)
        Self.saveValue(productivityCache, for: StorageKey.productivityCache, using: defaults, encoder: encoder)
    }

    func repairProductivityCacheIfNeeded() {
        let completedSessionIDs = Set(completedSessions.map(\.id))
        let needsRebuild = productivityCache.schemaVersion != ProductivityAggregateCache.currentSchemaVersion
            || productivityCache.accountedSessionIDs != completedSessionIDs

        guard needsRebuild else { return }

        productivityCache = ProductivityAggregateCache.rebuild(from: completedSessions)
        persist()
    }

    static func saveValue<T: Encodable>(
        _ value: T?,
        for key: String,
        using defaults: UserDefaults,
        encoder: JSONEncoder
    ) {
        guard let value else {
            defaults.removeObject(forKey: key)
            return
        }

        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    static func loadValue<T: Decodable>(for key: String, using defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
