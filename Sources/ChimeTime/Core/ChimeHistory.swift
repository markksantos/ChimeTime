import Foundation

struct ChimeRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let chimeType: String  // "hour" or "halfHour"
    let soundPlayed: String

    init(date: Date, chimeType: ChimeType, soundPlayed: String) {
        self.id = UUID()
        self.date = date
        self.chimeType = chimeType == .hour ? "hour" : "halfHour"
        self.soundPlayed = soundPlayed
    }
}

final class ChimeHistory: ObservableObject {
    @Published private(set) var records: [ChimeRecord] = []

    private let defaults = UserDefaults.standard
    private let storageKey = "chimetime.historyRecords"

    init() {
        loadRecords()
    }

    func addRecord(_ record: ChimeRecord, maxEntries: Int) {
        records.insert(record, at: 0)
        if records.count > maxEntries {
            records = Array(records.prefix(maxEntries))
        }
        saveRecords()
    }

    func clearHistory() {
        records = []
        saveRecords()
    }

    var recentEntries: [ChimeRecord] {
        Array(records.prefix(5))
    }

    private func loadRecords() {
        guard let data = defaults.data(forKey: storageKey) else { return }
        do {
            records = try JSONDecoder().decode([ChimeRecord].self, from: data)
        } catch {
            records = []
        }
    }

    private func saveRecords() {
        do {
            let data = try JSONEncoder().encode(records)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Save failed silently
        }
    }
}
