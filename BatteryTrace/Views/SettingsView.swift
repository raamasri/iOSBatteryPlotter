import SwiftUI

struct SettingsView: View {
    @ObservedObject var deviceCatalog: DeviceCatalog
    @State private var customCapacityText: String = ""
    @State private var showingCustomCapacityAlert = false
    @State private var showingDeleteAlert = false
    @State private var showingDeviceInfo = false
    
    private let persistenceController = PersistenceController.shared
    
    var body: some View {
        NavigationView {
            List {
                deviceSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
        .alert("Custom Battery Capacity", isPresented: $showingCustomCapacityAlert) {
            TextField("Capacity (mAh)", text: $customCapacityText)
                .keyboardType(.numberPad)
            Button("Save") {
                saveCustomCapacity()
            }
            Button("Cancel", role: .cancel) { }
            Button("Reset to Default") {
                deviceCatalog.setCustomCapacity(nil)
                customCapacityText = ""
            }
        } message: {
            Text("Enter the battery capacity in mAh for more accurate power estimates. Leave empty to use the default value for your device model.")
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all charging sessions and health snapshots. This action cannot be undone.")
        }
        .sheet(isPresented: $showingDeviceInfo) {
            deviceInfoSheet
        }
    }
    
    private var deviceSection: some View {
        Section("Device & Battery") {
            HStack {
                Text("Device Model")
                Spacer()
                Text(deviceCatalog.getModelName())
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Battery Capacity")
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(String(format: "%.0f", deviceCatalog.getCapacity())) mAh")
                        .foregroundColor(.secondary)
                    if deviceCatalog.customCapacity != nil {
                        Text("Custom")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onTapGesture {
                customCapacityText = deviceCatalog.customCapacity != nil ? String(format: "%.0f", deviceCatalog.customCapacity!) : ""
                showingCustomCapacityAlert = true
            }
            
            Button("Device Information") {
                showingDeviceInfo = true
            }
            .foregroundColor(.blue)
        }
    }
    
    private var dataSection: some View {
        Section("Data Management") {
            NavigationLink("Export Data") {
                ExportSettingsView()
            }
            
            Button("Delete All Data") {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Disclaimer")
                    .fontWeight(.semibold)
                Text("BatteryTrace provides estimated power values based on battery percentage changes over time. These values are approximate and may vary based on device usage, temperature, and charging conditions.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            Button("Privacy Policy") {
                if let url = URL(string: "https://batterytrace.app/privacy") {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(.blue)
            
            Button("Support") {
                if let url = URL(string: "mailto:support@batterytrace.app") {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(.blue)
        }
    }
    
    private var deviceInfoSheet: some View {
        NavigationView {
            List {
                Section("Current Device") {
                    HStack {
                        Text("Model Name")
                        Spacer()
                        Text(deviceCatalog.getModelName())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Model Identifier")
                        Spacer()
                        Text(getModelIdentifier())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Default Capacity")
                        Spacer()
                        Text("\(String(format: "%.0f", deviceCatalog.getKnownCapacityForModel(getModelIdentifier()) ?? 3000)) mAh")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Current Setting")
                        Spacer()
                        Text("\(String(format: "%.0f", deviceCatalog.getCapacity())) mAh")
                            .foregroundColor(deviceCatalog.customCapacity != nil ? .blue : .secondary)
                    }
                }
                
                Section("All Supported Devices") {
                    ForEach(deviceCatalog.getAllKnownDevices(), id: \.0) { device in
                        HStack {
                            Text(device.0)
                            Spacer()
                            Text("\(String(format: "%.0f", device.1)) mAh")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Device Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDeviceInfo = false
                    }
                }
            }
        }
    }
    
    private func saveCustomCapacity() {
        guard !customCapacityText.isEmpty,
              let capacity = Double(customCapacityText),
              capacity > 0 else {
            deviceCatalog.setCustomCapacity(nil)
            return
        }
        
        deviceCatalog.setCustomCapacity(capacity)
    }
    
    private func deleteAllData() {
        persistenceController.deleteAllData()
    }
    
    private func getModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value))!)
        }
        return identifier
    }
}

struct ExportSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.startDate, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Snapshot.date, ascending: false)],
        animation: .default)
    private var snapshots: FetchedResults<Snapshot>
    
    var body: some View {
        List {
            Section("Data Overview") {
                HStack {
                    Text("Charging Sessions")
                    Spacer()
                    Text("\(sessions.count)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Health Snapshots")
                    Spacer()
                    Text("\(snapshots.count)")
                        .foregroundColor(.secondary)
                }
                
                if let oldestSession = sessions.last {
                    HStack {
                        Text("Oldest Session")
                        Spacer()
                        Text(oldestSession.startDate, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let oldestSnapshot = snapshots.last {
                    HStack {
                        Text("Oldest Health Data")
                        Spacer()
                        Text(oldestSnapshot.date, style: .date)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Export Options") {
                Button("Export Charging Sessions") {
                    exportSessions()
                }
                
                Button("Export Health Snapshots") {
                    exportSnapshots()
                }
                
                Button("Export All Data") {
                    exportAllData()
                }
                .fontWeight(.semibold)
            }
            
            Section("Export Format") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CSV Format")
                        .fontWeight(.semibold)
                    Text("Data is exported in CSV (Comma-Separated Values) format, compatible with Numbers, Excel, Google Sheets, and other spreadsheet applications.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exportSessions() {
        let exporter = CSVExporter()
        exporter.exportSessions(Array(sessions))
    }
    
    private func exportSnapshots() {
        let exporter = CSVExporter()
        exporter.exportSnapshots(Array(snapshots))
    }
    
    private func exportAllData() {
        let exporter = CSVExporter()
        exporter.exportAllData(sessions: Array(sessions), snapshots: Array(snapshots))
    }
}