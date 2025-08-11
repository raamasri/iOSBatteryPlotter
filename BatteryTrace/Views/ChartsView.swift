import SwiftUI
import Charts
import CoreData

struct ChartsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Snapshot.date, ascending: true)],
        animation: .default)
    private var snapshots: FetchedResults<Snapshot>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Session.startDate, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<Session>
    
    @State private var selectedChart: ChartType = .healthOverTime
    
    enum ChartType: String, CaseIterable {
        case healthOverTime = "Health Over Time"
        case cyclesOverTime = "Cycles Over Time" 
        case degradationCurve = "Degradation Curve"
        case chargingSessions = "Charging Sessions"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Chart Type", selection: $selectedChart) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    switch selectedChart {
                    case .healthOverTime:
                        healthOverTimeChart
                    case .cyclesOverTime:
                        cyclesOverTimeChart
                    case .degradationCurve:
                        degradationCurveChart
                    case .chargingSessions:
                        chargingSessionsChart
                    }
                }
            }
            .navigationTitle("Battery Analysis")
        }
    }
    
    private var healthOverTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Battery Health Over Time")
                .font(.headline)
                .padding(.horizontal)
            
            if snapshots.isEmpty {
                emptyStateView(message: "No health data available. Tap 'Refresh Cycles' to get battery health data.")
            } else {
                Chart(snapshots.filter { $0.health > 0 }, id: \.id) { snapshot in
                    LineMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Health", snapshot.health * 100)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Health", snapshot.health * 100)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYScale(domain: 70...100)
                .padding(.horizontal)
                
                healthSummary
            }
        }
    }
    
    private var cyclesOverTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Battery Cycles Over Time")
                .font(.headline)
                .padding(.horizontal)
            
            if snapshots.isEmpty {
                emptyStateView(message: "No cycle data available. Tap 'Refresh Cycles' to get battery cycle data.")
            } else {
                Chart(snapshots.filter { $0.cycles > 0 }, id: \.id) { snapshot in
                    LineMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Cycles", snapshot.cycles)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", snapshot.date),
                        y: .value("Cycles", snapshot.cycles)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .padding(.horizontal)
                
                cyclesSummary
            }
        }
    }
    
    private var degradationCurveChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health vs Cycles (Degradation)")
                .font(.headline)
                .padding(.horizontal)
            
            let validSnapshots = snapshots.filter { $0.health > 0 && $0.cycles > 0 }
            
            if validSnapshots.isEmpty {
                emptyStateView(message: "No degradation data available. Both health and cycle data are needed.")
            } else {
                Chart(validSnapshots, id: \.id) { snapshot in
                    PointMark(
                        x: .value("Cycles", snapshot.cycles),
                        y: .value("Health", snapshot.health * 100)
                    )
                    .foregroundStyle(.orange)
                    .symbolSize(60)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYScale(domain: 70...100)
                .padding(.horizontal)
                
                degradationSummary
            }
        }
    }
    
    private var chargingSessionsChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Charging Sessions")
                .font(.headline)
                .padding(.horizontal)
            
            let recentSessions = Array(sessions.prefix(10))
            
            if recentSessions.isEmpty {
                emptyStateView(message: "No charging sessions recorded. Start charging your device with the app open to record sessions.")
            } else {
                Chart(recentSessions, id: \.id) { session in
                    BarMark(
                        x: .value("Session", session.startDate, unit: .day),
                        y: .value("Average Watts", session.avgWatts)
                    )
                    .foregroundStyle(.purple)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .padding(.horizontal)
                
                sessionsSummary
            }
        }
    }
    
    private var healthSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Summary")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if let latestSnapshot = snapshots.filter({ $0.health > 0 }).last {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Health")
                        Text("\(String(format: "%.1f", latestSnapshot.health * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(healthColor(latestSnapshot.health))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Last Updated")
                        Text(latestSnapshot.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                if snapshots.count > 1 {
                    let firstSnapshot = snapshots.first { $0.health > 0 }
                    if let first = firstSnapshot {
                        let healthChange = (latestSnapshot.health - first.health) * 100
                        HStack {
                            Text("Total Change")
                            Spacer()
                            Text("\(healthChange >= 0 ? "+" : "")\(String(format: "%.1f", healthChange))%")
                                .foregroundColor(healthChange >= 0 ? .green : .red)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.bottom)
    }
    
    private var cyclesSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cycles Summary")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if let latestSnapshot = snapshots.filter({ $0.cycles > 0 }).last {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Cycles")
                        Text("\(latestSnapshot.cycles)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Last Updated")
                        Text(latestSnapshot.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
    }
    
    private var degradationSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Degradation Analysis")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            let validSnapshots = snapshots.filter { $0.health > 0 && $0.cycles > 0 }
            
            if validSnapshots.count >= 2 {
                let sortedSnapshots = validSnapshots.sorted { $0.cycles < $1.cycles }
                let first = sortedSnapshots.first!
                let last = sortedSnapshots.last!
                
                let cyclesDiff = Double(last.cycles - first.cycles)
                let healthDiff = (last.health - first.health) * 100
                
                if cyclesDiff > 0 {
                    let degradationRate = abs(healthDiff) / cyclesDiff
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Degradation Rate")
                            Spacer()
                            Text("\(String(format: "%.3f", degradationRate))% per cycle")
                                .foregroundColor(.orange)
                        }
                        
                        HStack {
                            Text("Cycles Range")
                            Spacer()
                            Text("\(first.cycles) - \(last.cycles)")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom)
    }
    
    private var sessionsSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sessions Summary")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if !sessions.isEmpty {
                let validSessions = sessions.filter { $0.avgWatts > 0 }
                
                if !validSessions.isEmpty {
                    let avgWatts = validSessions.reduce(0) { $0 + $1.avgWatts } / Double(validSessions.count)
                    let maxWatts = validSessions.map { $0.peakWatts }.max() ?? 0
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Avg Power")
                            Text("\(String(format: "%.1f", avgWatts))W")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Peak Power")
                            Text("\(String(format: "%.1f", maxWatts))W")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Total Sessions")
                        Spacer()
                        Text("\(sessions.count)")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
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