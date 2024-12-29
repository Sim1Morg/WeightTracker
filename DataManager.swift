import Foundation
import SwiftUI

enum WeightUnit: String, CaseIterable, Codable {
    case kg = "kg"
    case lbs = "lbs"
    case stone = "stone"
}

struct Entry: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var weight: Double
    var bodyFat: Double
    var muscleMass: Double
    var visceralFat: Int
    var weightUnit: WeightUnit
    var image: UIImage?
}

class DataManager: ObservableObject {
    @Published var entries: [Entry] = []
    
    init() {
       loadEntries()
    }
    
    func addEntry(entry: Entry) {
        entries.append(entry)
        saveEntries()
    }
    
    func getEntry(for date: Date) -> Entry? {
        let calendar = Calendar.current
        return entries.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        })
    }
    
    func updateEntry(entry: Entry, updatedEntry: Entry) {
        if let index = entries.firstIndex(where: {$0.id == entry.id}) {
            entries[index] = updatedEntry
           saveEntries()
        }
    }
    
    private func saveEntries() {
       if let encoded = try? JSONEncoder().encode(entries) {
           UserDefaults.standard.set(encoded, forKey: "Entries")
       }
   }

   private func loadEntries() {
       if let data = UserDefaults.standard.data(forKey: "Entries"),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
           entries = decoded
       }
    }
}
