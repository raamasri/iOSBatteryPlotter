import Foundation
import UIKit
import CoreData
import Combine

@MainActor
class BatteryManager: ObservableObject {
    @Published var batteryLevel: Float = 0.0
    @Published var batteryState: UIDevice.BatteryState = .unknown
    @Published var isCharging: Bool = false
    @Published var currentSession: Session?
    @Published var estimatedWatts: Double = 0.0
    @Published var peakWatts: Double = 0.0
    @Published var averageWatts: Double = 0.0
    @Published var sessionDuration: TimeInterval = 0
    @Published var etaToFull: TimeInterval = 0
    
    private var batteryLevelSamples: [(Date, Float)] = []
    private var samplingTimer: Timer?
    private let samplingInterval: TimeInterval = 5.0
    private let windowDuration: TimeInterval = 90.0
    private let emaAlpha: Double = 0.1
    private var emaValue: Double?
    private let nominalVoltage: Double = 3.82
    
    private let persistenceController: PersistenceController
    private let deviceCatalog: DeviceCatalog
    private var cancellables = Set<AnyCancellable>()
    
    init(persistenceController: PersistenceController = .shared, deviceCatalog: DeviceCatalog = .shared) {
        self.persistenceController = persistenceController
        self.deviceCatalog = deviceCatalog
        
        setupBatteryMonitoring()
        setupNotifications()
    }
    
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        updateBatteryInfo()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateBatteryInfo()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updateBatteryInfo()
                    self?.handleBatteryStateChange()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.stopCurrentSession()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.resumeSessionIfCharging()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateBatteryInfo() {
        let device = UIDevice.current
        batteryLevel = device.batteryLevel
        batteryState = device.batteryState
        isCharging = batteryState == .charging
    }
    
    private func handleBatteryStateChange() {
        if batteryState == .charging {
            startSession()
        } else {
            stopCurrentSession()
        }
    }
    
    func startSession() {
        guard currentSession == nil, batteryState == .charging else { return }
        
        let context = persistenceController.container.viewContext
        let session = Session(context: context)
        session.id = UUID()
        session.startDate = Date()
        
        currentSession = session
        batteryLevelSamples.removeAll()
        emaValue = nil
        peakWatts = 0.0
        sessionDuration = 0
        
        startSampling()
        
        do {
            try context.save()
        } catch {
            print("Failed to create session: \(error)")
        }
    }
    
    func stopCurrentSession() {
        samplingTimer?.invalidate()
        samplingTimer = nil
        
        guard let session = currentSession else { return }
        
        session.endDate = Date()
        session.avgWatts = averageWatts
        session.peakWatts = peakWatts
        
        if let startDate = session.startDate,
           let endDate = session.endDate {
            let startLevel = batteryLevelSamples.first?.1 ?? batteryLevel
            let endLevel = batteryLevel
            session.deltaPct = Double(endLevel - startLevel) * 100
        }
        
        let context = persistenceController.container.viewContext
        do {
            try context.save()
        } catch {
            print("Failed to save session: \(error)")
        }
        
        currentSession = nil
        batteryLevelSamples.removeAll()
        estimatedWatts = 0.0
        averageWatts = 0.0
        sessionDuration = 0
        etaToFull = 0
    }
    
    private func resumeSessionIfCharging() {
        if batteryState == .charging && currentSession == nil {
            startSession()
        }
    }
    
    private func startSampling() {
        samplingTimer = Timer.scheduledTimer(withTimeInterval: samplingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.takeSample()
            }
        }
    }
    
    private func takeSample() {
        let now = Date()
        let level = batteryLevel
        
        batteryLevelSamples.append((now, level))
        
        batteryLevelSamples = batteryLevelSamples.filter { sample in
            now.timeIntervalSince(sample.0) <= windowDuration
        }
        
        updateSessionDuration()
        calculatePowerEstimate()
        calculateETA()
    }
    
    private func updateSessionDuration() {
        guard let session = currentSession,
              let startDate = session.startDate else { return }
        
        sessionDuration = Date().timeIntervalSince(startDate)
    }
    
    private func calculatePowerEstimate() {
        guard batteryLevelSamples.count >= 2 else { return }
        
        let oldest = batteryLevelSamples.first!
        let newest = batteryLevelSamples.last!
        
        let deltaPercent = Double(newest.1 - oldest.1) * 100
        let deltaHours = newest.0.timeIntervalSince(oldest.0) / 3600.0
        
        guard deltaHours > 0 && deltaPercent > 0 else { return }
        
        let capacityMAh = deviceCatalog.getCapacity()
        let chargingCurrentMA = capacityMAh * (deltaPercent / 100.0) / deltaHours
        let instantWatts = (chargingCurrentMA / 1000.0) * nominalVoltage
        
        if let ema = emaValue {
            emaValue = emaAlpha * instantWatts + (1 - emaAlpha) * ema
        } else {
            emaValue = instantWatts
        }
        
        estimatedWatts = emaValue ?? 0.0
        peakWatts = max(peakWatts, estimatedWatts)
        
        let validSamples = batteryLevelSamples.compactMap { sample in
            return sample.1 > 0 ? estimatedWatts : nil
        }
        averageWatts = validSamples.isEmpty ? 0.0 : validSamples.reduce(0, +) / Double(validSamples.count)
    }
    
    private func calculateETA() {
        guard estimatedWatts > 0, batteryLevel < 1.0 else {
            etaToFull = 0
            return
        }
        
        let remainingPercent = Double(1.0 - batteryLevel) * 100
        let capacityMAh = deviceCatalog.getCapacity()
        let remainingMAh = capacityMAh * (remainingPercent / 100.0)
        let currentMA = (estimatedWatts / nominalVoltage) * 1000.0
        
        if currentMA > 0 {
            etaToFull = (remainingMAh / currentMA) * 3600.0
        }
    }
    
    func updateSessionChargerType(_ chargerType: String) {
        currentSession?.chargerType = chargerType
        
        let context = persistenceController.container.viewContext
        do {
            try context.save()
        } catch {
            print("Failed to update charger type: \(error)")
        }
    }
    
    func updateSessionNotes(_ notes: String) {
        currentSession?.notes = notes
        
        let context = persistenceController.container.viewContext
        do {
            try context.save()
        } catch {
            print("Failed to update session notes: \(error)")
        }
    }
}