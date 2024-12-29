import Foundation
import SwiftUI
import UIKit

enum WeightUnit: String, CaseIterable, Codable {
    case kg = "kg"
    case lbs = "lbs"
    case stone = "stone"
}

struct Entry: Identifiable, Codable {
    let id: UUID
    var date: Date
    var weight: Double
    var bodyFat: Double
    var muscleMass: Double
    var visceralFat: Int
    var weightUnit: WeightUnit
    var imageFilePath: String?
    
    // MARK: - Codable Conformance
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case weight
        case bodyFat
        case muscleMass
        case visceralFat
        case weightUnit
        case imageFilePath
    }
}

class DataManager: ObservableObject {
    @Published var entries: [Entry] = []
    
    private let entriesKey = "Entries"
    private let fileManager = FileManager.default
    private let imagesDirectory: URL

    init() {
        // Set up directory for storing images
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            imagesDirectory = documentsURL.appendingPathComponent("EntryImages")
            if !fileManager.fileExists(atPath: imagesDirectory.path) {
                try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            }
        } else {
            fatalError("Unable to locate documents directory.")
        }
        
        loadEntries()
    }
    
    func addEntry(entry: Entry, image: UIImage?) {
        var newEntry = entry
        if let image = image {
            let imageFilePath = saveImage(image: image, for: entry.id)
            newEntry.imageFilePath = imageFilePath
        }
        entries.append(newEntry)
        saveEntries()
    }
    
    func getEntry(for date: Date) -> Entry? {
        let calendar = Calendar.current
        return entries.first(where: {
            calendar.isDate($0.date, inSameDayAs: date)
        })
    }
    
    func updateEntry(entry: Entry, updatedEntry: Entry, newImage: UIImage?) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            var entryToUpdate = updatedEntry
            if let newImage = newImage {
                if let oldFilePath = entry.imageFilePath {
                    deleteImage(at: oldFilePath)
                }
                let imageFilePath = saveImage(image: newImage, for: updatedEntry.id)
                entryToUpdate.imageFilePath = imageFilePath
            }
            entries[index] = entryToUpdate
            saveEntries()
        }
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: entriesKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([Entry].self, from: data) {
            entries = decoded
        }
    }
    
    private func saveImage(image: UIImage, for id: UUID) -> String? {
        let imageFileName = "\(id.uuidString).jpg"
        let filePath = imagesDirectory.appendingPathComponent(imageFileName)
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: filePath)
            return filePath.path
        }
        return nil
    }
    
    private func deleteImage(at filePath: String) {
        try? fileManager.removeItem(atPath: filePath)
    }
    
    func loadImage(for entry: Entry) -> UIImage? {
        guard let filePath = entry.imageFilePath else { return nil }
        return UIImage(contentsOfFile: filePath)
    }
}

