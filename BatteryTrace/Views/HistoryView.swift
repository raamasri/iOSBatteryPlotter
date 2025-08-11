import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var shortcutIngestor: ShortcutIngestor
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.startDate, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Snapshot.date, ascending: false)],
        animation: .default)
    private var snapshots: FetchedResults<Snapshot>
    
    @State private var selectedTab: HistoryTab = .sessions
    @State private var showingExportSheet = false
    
    enum HistoryTab: String, CaseIterable {
        case sessions = "Charging Sessions"
        case snapshots = "Health Snapshots"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("History Type", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedTab {
                case .sessions:
                    sessionsView
                case .snapshots:
                    snapshotsView
                }
                
                Spacer()
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        showingExportSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                exportSheet
            }
        }
    }
    
    private var sessionsView: some View {
        Group {
            if sessions.isEmpty {
                emptySessionsView
            } else {
                List {
                    ForEach(sessions, id: \.id) { session in
                        SessionRowView(session: session)
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
        }
    }
    
    private var snapshotsView: some View {
        VStack {
            refreshButton
            
            if snapshots.isEmpty {
                emptySnapshotsView
            } else {
                List {
                    ForEach(snapshots, id: \.id) { snapshot in
                        SnapshotRowView(snapshot: snapshot)
                    }
                    .onDelete(perform: deleteSnapshots)
                }
            }
        }
    }
    
    private var refreshButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                shortcutIngestor.triggerShortcut()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh Cycles & Health")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(shortcutIngestor.isProcessing)
            
            if let result = shortcutIngestor.lastIngestResult {
                resultView(result)
            }
            
            if let lastDate = shortcutIngestor.lastIngestDate {
                Text("Last updated: \(lastDate, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var emptySessionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Charging Sessions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start charging your device with the app open to record charging sessions and power estimates.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySnapshotsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Health Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap 'Refresh Cycles & Health' to get battery health data from your device analytics.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
            
            Button("Install Shortcut") {
                shortcutIngestor.openShortcutInstallation()
            }
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var exportSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Data")
                    .font(.title)
                    .padding()
                
                VStack(spacing: 16) {
                    Button("Export Charging Sessions") {
                        exportSessions()
                    }
                    .buttonStyle(ExportButtonStyle())
                    
                    Button("Export Health Snapshots") {
                        exportSnapshots()
                    }
                    .buttonStyle(ExportButtonStyle())
                    
                    Button("Export All Data") {
                        exportAllData()
                    }
                    .buttonStyle(ExportButtonStyle(isPrimary: true))
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    private func resultView(_ result: ShortcutIngestor.IngestResult) -> some View {
        Group {
            switch result {
            case .success(let cycles, let health):
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading) {
                        Text("Data updated successfully")
                            .fontWeight(.semibold)
                        if let cycles = cycles, let health = health {
                            Text("Cycles: \(cycles), Health: \(String(format: "%.1f", health * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(message)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .onTapGesture {
            shortcutIngestor.clearLastResult()
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            offsets.map { sessions[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting sessions: \(error)")
            }
        }
    }
    
    private func deleteSnapshots(offsets: IndexSet) {
        withAnimation {
            offsets.map { snapshots[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting snapshots: \(error)")
            }
        }
    }
    
    private func exportSessions() {
        let exporter = CSVExporter()
        exporter.exportSessions(Array(sessions))
        showingExportSheet = false
    }
    
    private func exportSnapshots() {
        let exporter = CSVExporter()
        exporter.exportSnapshots(Array(snapshots))
        showingExportSheet = false
    }
    
    private func exportAllData() {
        let exporter = CSVExporter()
        exporter.exportAllData(sessions: Array(sessions), snapshots: Array(snapshots))
        showingExportSheet = false
    }
}

struct SessionRowView: View {
    let session: Session
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let startDate = session.startDate {
                    Text(startDate, style: .date)
                } else {
                    Text("Unknown Date")
                }
                    .font(.headline)
                Spacer()
                if session.avgWatts > 0 {
                    Text("\(String(format: "%.1f", session.avgWatts))W avg")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            HStack {
                if let startDate = session.startDate {
                    Text(startDate, style: .time)
                        .foregroundColor(.secondary)
                }
                
                if let endDate = session.endDate {
                    Text("- \(endDate, style: .time)")
                        .foregroundColor(.secondary)
                    
                    if let startDate = session.startDate {
                        let duration = endDate.timeIntervalSince(startDate)
                        Text("(\(formatDuration(duration)))")
                            .foregroundColor(.secondary)
                    }
            }
            .font(.caption)
            
            if let chargerType = session.chargerType, !chargerType.isEmpty {
                Text("Charger: \(chargerType)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if session.peakWatts > 0 {
                    Label("\(String(format: "%.1f", session.peakWatts))W peak", systemImage: "bolt")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if session.deltaPct != 0 {
                    Label("\(String(format: "%.0f", abs(session.deltaPct)))% charged", systemImage: "battery.100")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if let notes = session.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct SnapshotRowView: View {
    let snapshot: Snapshot
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let date = snapshot.date {
                    Text(date, style: .date)
                        .font(.headline)
                    Text(date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Unknown Date")
                        .font(.headline)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if snapshot.health > 0 {
                    Text("\(String(format: "%.1f", snapshot.health * 100))%")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(healthColor(snapshot.health))
                    Text("Health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if snapshot.cycles > 0 {
                    Text("\(snapshot.cycles) cycles")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func healthColor(_ health: Double) -> Color {
        switch health {
        case 0.9...1.0:
            return .green
        case 0.8..<0.9:
            return .yellow
        default:
            return .red
        }
    }
}

struct ExportButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    init(isPrimary: Bool = false) {
        self.isPrimary = isPrimary
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isPrimary ? .white : .blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPrimary ? Color.blue : Color.blue.opacity(0.1))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}