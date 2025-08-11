import Foundation
import CoreData
import SwiftUI

@MainActor
class ShortcutIngestor: ObservableObject {
    @Published var lastIngestDate: Date?
    @Published var lastIngestResult: IngestResult?
    @Published var isProcessing: Bool = false
    
    private let persistenceController: PersistenceController
    
    enum IngestResult {
        case success(cycles: Int?, health: Double?)
        case error(message: String)
    }
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    func processURL(_ url: URL) {
        guard url.scheme == "batterytrace" else {
            lastIngestResult = .error(message: "Invalid URL scheme")
            return
        }
        
        guard url.host == "ingest" else {
            lastIngestResult = .error(message: "Invalid URL host")
            return
        }
        
        isProcessing = true
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let queryItems = components?.queryItems else {
            lastIngestResult = .error(message: "No query parameters found")
            isProcessing = false
            return
        }
        
        var cycles: Int?
        var health: Double?
        var firstUseDate: Date?
        var manufactureDate: Date?
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for item in queryItems {
            switch item.name {
            case "cycles":
                if let value = item.value, let intValue = Int(value) {
                    cycles = intValue
                }
            case "health":
                if let value = item.value, let doubleValue = Double(value) {
                    health = min(max(doubleValue, 0.0), 1.0)
                }
            case "first_use":
                if let value = item.value {
                    firstUseDate = dateFormatter.date(from: value)
                }
            case "mfg":
                if let value = item.value {
                    manufactureDate = dateFormatter.date(from: value)
                }
            default:
                break
            }
        }
        
        if cycles == nil && health == nil {
            lastIngestResult = .error(message: "No valid data found in URL")
            isProcessing = false
            return
        }
        
        saveSnapshot(cycles: cycles, health: health, firstUse: firstUseDate, manufacture: manufactureDate)
        
        lastIngestResult = .success(cycles: cycles, health: health)
        lastIngestDate = Date()
        isProcessing = false
    }
    
    private func saveSnapshot(cycles: Int?, health: Double?, firstUse: Date?, manufacture: Date?) {
        let context = persistenceController.container.viewContext
        
        let snapshot = Snapshot(context: context)
        snapshot.id = UUID()
        snapshot.date = Date()
        snapshot.cycles = Int32(cycles ?? 0)
        snapshot.health = health ?? 0.0
        snapshot.firstUseDate = firstUse
        snapshot.manufactureDate = manufacture
        
        do {
            try context.save()
            print("Snapshot saved successfully: cycles=\(cycles ?? 0), health=\(String(format: "%.1f", (health ?? 0.0) * 100))%")
        } catch {
            lastIngestResult = .error(message: "Failed to save data: \(error.localizedDescription)")
        }
    }
    
    func triggerShortcut() {
        let shortcutName = "Battery%20Cycles"
        let callbackURL = "batterytrace://ingest"
        
        if let encodedCallback = callbackURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let urlString = "shortcuts://x-callback-url/run-shortcut?name=\(shortcutName)&x-success=\(encodedCallback)"
            
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url) { success in
                    if !success {
                        Task { @MainActor in
                            self.lastIngestResult = .error(message: "Failed to open Shortcuts app. Make sure the 'Battery Cycles' shortcut is installed.")
                        }
                    }
                }
            }
        }
    }
    
    func openShortcutInstallation() {
        if let url = URL(string: "https://www.icloud.com/shortcuts/53f0900518564258ad5b06867b032a1e") {
            UIApplication.shared.open(url)
        }
    }
    
    func clearLastResult() {
        lastIngestResult = nil
    }
    
    func getLatestSnapshot() -> Snapshot? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Snapshot> = Snapshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Snapshot.date, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let snapshots = try context.fetch(request)
            return snapshots.first
        } catch {
            print("Failed to fetch latest snapshot: \(error)")
            return nil
        }
    }
    
    func getAllSnapshots() -> [Snapshot] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Snapshot> = Snapshot.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Snapshot.date, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch snapshots: \(error)")
            return []
        }
    }
}