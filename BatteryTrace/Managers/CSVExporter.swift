import Foundation
import UIKit

class CSVExporter {
    
    func exportSessions(_ sessions: [Session]) {
        let csvContent = generateSessionsCSV(sessions)
        let fileName = "BatteryTrace_Sessions_\(dateString()).csv"
        shareCSV(content: csvContent, fileName: fileName)
    }
    
    func exportSnapshots(_ snapshots: [Snapshot]) {
        let csvContent = generateSnapshotsCSV(snapshots)
        let fileName = "BatteryTrace_Snapshots_\(dateString()).csv"
        shareCSV(content: csvContent, fileName: fileName)
    }
    
    func exportAllData(sessions: [Session], snapshots: [Snapshot]) {
        let sessionContent = generateSessionsCSV(sessions)
        let snapshotContent = generateSnapshotsCSV(snapshots)
        
        let combinedContent = """
        BatteryTrace Export - \(dateString())
        
        CHARGING SESSIONS
        \(sessionContent)
        
        HEALTH SNAPSHOTS
        \(snapshotContent)
        """
        
        let fileName = "BatteryTrace_Complete_\(dateString()).csv"
        shareCSV(content: combinedContent, fileName: fileName)
    }
    
    private func generateSessionsCSV(_ sessions: [Session]) -> String {
        let headers = [
            "Date",
            "Start Time", 
            "End Time",
            "Duration (minutes)",
            "Average Watts",
            "Peak Watts", 
            "Battery Delta (%)",
            "Charger Type",
            "Notes"
        ]
        
        var csvContent = headers.joined(separator: ",") + "\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for session in sessions.filter({ $0.startDate != nil }).sorted(by: { $0.startDate! < $1.startDate! }) {
            let date = dateFormatter.string(from: session.startDate!)
            let startTime = timeFormatter.string(from: session.startDate!)
            let endTime = session.endDate != nil ? timeFormatter.string(from: session.endDate!) : ""
            
            let duration: String
            if let endDate = session.endDate {
                let durationMinutes = Int(endDate.timeIntervalSince(session.startDate!) / 60)
                duration = "\(durationMinutes)"
            } else {
                duration = ""
            }
            
            let avgWatts = session.avgWatts > 0 ? String(format: "%.2f", session.avgWatts) : ""
            let peakWatts = session.peakWatts > 0 ? String(format: "%.2f", session.peakWatts) : ""
            let deltaPct = session.deltaPct != 0 ? String(format: "%.1f", session.deltaPct) : ""
            let chargerType = escapeCSVField(session.chargerType ?? "")
            let notes = escapeCSVField(session.notes ?? "")
            
            let row = [
                date,
                startTime,
                endTime,
                duration,
                avgWatts,
                peakWatts,
                deltaPct,
                chargerType,
                notes
            ]
            
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    private func generateSnapshotsCSV(_ snapshots: [Snapshot]) -> String {
        let headers = [
            "Date",
            "Time",
            "Battery Health (%)",
            "Cycle Count",
            "First Use Date",
            "Manufacture Date"
        ]
        
        var csvContent = headers.joined(separator: ",") + "\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateStyle = .short
        
        for snapshot in snapshots.filter({ $0.date != nil }).sorted(by: { $0.date! < $1.date! }) {
            let date = dateFormatter.string(from: snapshot.date!)
            let time = timeFormatter.string(from: snapshot.date!)
            let health = snapshot.health > 0 ? String(format: "%.1f", snapshot.health * 100) : ""
            let cycles = snapshot.cycles > 0 ? "\(snapshot.cycles)" : ""
            let firstUse = snapshot.firstUseDate != nil ? shortDateFormatter.string(from: snapshot.firstUseDate!) : ""
            let manufacture = snapshot.manufactureDate != nil ? shortDateFormatter.string(from: snapshot.manufactureDate!) : ""
            
            let row = [
                date,
                time,
                health,
                cycles,
                firstUse,
                manufacture
            ]
            
            csvContent += row.joined(separator: ",") + "\n"
        }
        
        return csvContent
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func shareCSV(content: String, fileName: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("Could not find root view controller")
            return
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let activityViewController = UIActivityViewController(
                activityItems: [tempURL],
                applicationActivities: nil
            )
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                         y: rootViewController.view.bounds.midY,
                                         width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            var presenter = rootViewController
            while let presented = presenter.presentedViewController {
                presenter = presented
            }
            
            presenter.present(activityViewController, animated: true) {
                try? FileManager.default.removeItem(at: tempURL)
            }
            
        } catch {
            print("Failed to create CSV file: \(error)")
        }
    }
}