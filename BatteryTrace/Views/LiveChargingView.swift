import SwiftUI
import Charts

struct LiveChargingView: View {
    @ObservedObject var batteryManager: BatteryManager
    @State private var chargerType: String = ""
    @State private var sessionNotes: String = ""
    @State private var showChargerPicker = false
    
    private let chargerTypes = [
        "5W USB-A", "12W USB-A", "18W USB-C", "20W USB-C", 
        "30W USB-C", "MagSafe 15W", "Qi 7.5W", "Other"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    batteryStatusCard
                    
                    if batteryManager.isCharging && batteryManager.currentSession != nil {
                        chargingMetricsCard
                        powerEstimationCard
                        sessionControlsCard
                    } else {
                        notChargingCard
                    }
                    
                    disclaimerCard
                }
                .padding()
            }
            .navigationTitle("Live Charging")
            .sheet(isPresented: $showChargerPicker) {
                chargerPickerSheet
            }
        }
    }
    
    private var batteryStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: batteryIconName)
                    .font(.title)
                    .foregroundColor(batteryColor)
                
                VStack(alignment: .leading) {
                    Text("Battery Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.0f", batteryManager.batteryLevel * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(batteryStatusText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(batteryManager.isCharging ? .green : .primary)
                }
            }
            
            ProgressView(value: Double(batteryManager.batteryLevel))
                .progressViewStyle(LinearProgressViewStyle(tint: batteryColor))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var chargingMetricsCard: some View {
        VStack(spacing: 16) {
            Text("Charging Metrics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                metricView(
                    title: "Estimated Power",
                    value: "\(String(format: "%.1f", batteryManager.estimatedWatts))W",
                    icon: "bolt.fill",
                    color: .yellow
                )
                
                metricView(
                    title: "Peak Power",
                    value: "\(String(format: "%.1f", batteryManager.peakWatts))W",
                    icon: "bolt.horizontal.fill",
                    color: .orange
                )
                
                metricView(
                    title: "Session Time",
                    value: formatDuration(batteryManager.sessionDuration),
                    icon: "clock.fill",
                    color: .blue
                )
                
                metricView(
                    title: "ETA to Full",
                    value: formatDuration(batteryManager.etaToFull),
                    icon: "hourglass",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var powerEstimationCard: some View {
        VStack(spacing: 12) {
            Text("Power Estimation")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                VStack {
                    Text("\(String(format: "%.1f", batteryManager.estimatedWatts))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                    Text("Current Watts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(String(format: "%.1f", batteryManager.averageWatts))")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("Session Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            if batteryManager.estimatedWatts > 0 {
                powerGauge
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var powerGauge: some View {
        VStack {
            Text("Power Range")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("0W")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("30W")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: min(batteryManager.estimatedWatts / 30.0, 1.0))
                .progressViewStyle(LinearProgressViewStyle(tint: .yellow))
                .scaleEffect(y: 3)
        }
    }
    
    private var sessionControlsCard: some View {
        VStack(spacing: 16) {
            Text("Session Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("Charger Type:")
                    .foregroundColor(.secondary)
                Spacer()
                Button(chargerType.isEmpty ? "Set Charger" : chargerType) {
                    showChargerPicker = true
                }
                .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Notes:")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextField("Add notes about this charging session...", text: $sessionNotes, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                    .onChange(of: sessionNotes) { _, newValue in
                        batteryManager.updateSessionNotes(newValue)
                    }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var notChargingCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "battery")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("Not Charging")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Connect your charger and keep the app open to monitor live charging metrics.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var disclaimerCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Estimation Disclaimer")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text("Power estimates are calculated from battery percentage changes over time. Values are approximate and may vary based on device usage, temperature, and charging conditions.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(12)
    }
    
    private var chargerPickerSheet: some View {
        NavigationView {
            List(chargerTypes, id: \.self) { type in
                Button(action: {
                    chargerType = type
                    batteryManager.updateSessionChargerType(type)
                    showChargerPicker = false
                }) {
                    HStack {
                        Text(type)
                            .foregroundColor(.primary)
                        Spacer()
                        if chargerType == type {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Charger Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showChargerPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func metricView(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var batteryIconName: String {
        let level = Int(batteryManager.batteryLevel * 100)
        let charging = batteryManager.isCharging
        
        if charging {
            return "battery.100.bolt"
        }
        
        switch level {
        case 0...10:
            return "battery.0"
        case 11...25:
            return "battery.25"
        case 26...50:
            return "battery.50"
        case 51...75:
            return "battery.75"
        default:
            return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        let level = batteryManager.batteryLevel
        
        if batteryManager.isCharging {
            return .green
        }
        
        switch level {
        case 0...0.2:
            return .red
        case 0.2...0.5:
            return .orange
        default:
            return .green
        }
    }
    
    private var batteryStatusText: String {
        switch batteryManager.batteryState {
        case .charging:
            return "Charging"
        case .full:
            return "Full"
        case .unplugged:
            return "Unplugged"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
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