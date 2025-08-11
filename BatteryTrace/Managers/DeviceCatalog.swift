import Foundation
import UIKit

class DeviceCatalog: ObservableObject {
    static let shared = DeviceCatalog()
    
    @Published var customCapacity: Double?
    
    private var deviceCapacities: [String: Double] = [:]
    private let userDefaultsKey = "CustomBatteryCapacity"
    
    init() {
        loadDeviceCapacities()
        loadCustomCapacity()
    }
    
    private func loadDeviceCapacities() {
        guard let path = Bundle.main.path(forResource: "device_capacities", ofType: "json"),
              let data = NSData(contentsOfFile: path) as Data? else {
            print("Failed to load device_capacities.json")
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let dictionary = json as? [String: Int] {
                deviceCapacities = dictionary.mapValues { Double($0) }
            }
        } catch {
            print("Failed to parse device_capacities.json: \(error)")
        }
    }
    
    private func loadCustomCapacity() {
        let capacity = UserDefaults.standard.double(forKey: userDefaultsKey)
        if capacity > 0 {
            customCapacity = capacity
        }
    }
    
    func setCustomCapacity(_ capacity: Double?) {
        customCapacity = capacity
        
        if let capacity = capacity, capacity > 0 {
            UserDefaults.standard.set(capacity, forKey: userDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    func getCapacity() -> Double {
        if let custom = customCapacity, custom > 0 {
            return custom
        }
        
        let modelIdentifier = getModelIdentifier()
        return deviceCapacities[modelIdentifier] ?? getDefaultCapacity()
    }
    
    private func getModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(Character(UnicodeScalar(UInt8(value))))
        }
        return identifier
    }
    
    private func getDefaultCapacity() -> Double {
        return 3000.0
    }
    
    func getModelName() -> String {
        let identifier = getModelIdentifier()
        return getDeviceNameFromIdentifier(identifier) ?? identifier
    }
    
    func getKnownCapacityForModel(_ identifier: String) -> Double? {
        return deviceCapacities[identifier]
    }
    
    func getAllKnownDevices() -> [(String, Double)] {
        return deviceCapacities.map { (key, value) in
            let displayName = getDeviceNameFromIdentifier(key) ?? key
            return (displayName, value)
        }.sorted { $0.0 < $1.0 }
    }
    
    private func getDeviceNameFromIdentifier(_ identifier: String) -> String? {
        let deviceMap: [String: String] = [
            "iPhone8,1": "iPhone 6s",
            "iPhone8,2": "iPhone 6s Plus",
            "iPhone8,4": "iPhone SE (1st gen)",
            "iPhone9,1": "iPhone 7",
            "iPhone9,2": "iPhone 7 Plus",
            "iPhone9,3": "iPhone 7",
            "iPhone9,4": "iPhone 7 Plus",
            "iPhone10,1": "iPhone 8",
            "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,3": "iPhone X",
            "iPhone10,4": "iPhone 8",
            "iPhone10,5": "iPhone 8 Plus",
            "iPhone10,6": "iPhone X",
            "iPhone11,2": "iPhone XS",
            "iPhone11,4": "iPhone XS Max",
            "iPhone11,6": "iPhone XS Max",
            "iPhone11,8": "iPhone XR",
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            "iPhone12,8": "iPhone SE (2nd gen)",
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            "iPhone14,2": "iPhone 13 mini",
            "iPhone14,3": "iPhone 13",
            "iPhone14,4": "iPhone 13 Pro",
            "iPhone14,5": "iPhone 13 Pro Max",
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus"
        ]
        
        return deviceMap[identifier]
    }
    
    func calibrateCapacity(fromChargeSession session: Session) -> Double? {
        guard let startDate = session.startDate,
              let endDate = session.endDate,
              session.avgWatts > 0 else {
            return nil
        }
        
        let duration = endDate.timeIntervalSince(startDate) / 3600.0
        let energyWh = session.avgWatts * duration
        let deltaPct = abs(session.deltaPct) / 100.0
        
        if deltaPct > 0.1 {
            let nominalVoltage = 3.82
            let estimatedCapacityMAh = (energyWh / nominalVoltage) / deltaPct
            return estimatedCapacityMAh
        }
        
        return nil
    }
}