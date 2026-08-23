import Foundation

struct PomodoroPersistenceScope: OptionSet {
    let rawValue: UInt8

    static let settings = PomodoroPersistenceScope(rawValue: 1 << 0)
    static let activeSession = PomodoroPersistenceScope(rawValue: 1 << 1)
    static let completedSessions = PomodoroPersistenceScope(rawValue: 1 << 2)
    static let productivityCache = PomodoroPersistenceScope(rawValue: 1 << 3)

    static let completedSessionTransaction: PomodoroPersistenceScope = [
        .activeSession,
        .completedSessions,
        .productivityCache
    ]
}

extension PomodoroStore {
    func persist(_ scope: PomodoroPersistenceScope) {
        if scope.contains(.settings) {
            Self.saveValue(settings, for: StorageKey.settings, using: defaults, encoder: encoder)
        }
        if scope.contains(.activeSession) {
            Self.saveValue(activeSession, for: StorageKey.activeSession, using: defaults, encoder: encoder)
        }
        if scope.contains(.completedSessions) {
            Self.saveValue(completedSessions, for: StorageKey.completedSessions, using: defaults, encoder: encoder)
        }
        if scope.contains(.productivityCache) {
            Self.saveValue(productivityCache, for: StorageKey.productivityCache, using: defaults, encoder: encoder)
        }
    }

    func repairProductivityCacheIfNeeded() {
        let completedSessionIDs = Set(completedSessions.map(\.id))
        let needsRebuild = productivityCache.schemaVersion != ProductivityAggregateCache.currentSchemaVersion
            || productivityCache.accountedSessionIDs != completedSessionIDs

        guard needsRebuild else { return }

        productivityCache = ProductivityAggregateCache.rebuild(from: completedSessions)
        persist(.productivityCache)
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
