import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var batteryManager = BatteryManager()
    @StateObject private var shortcutIngestor = ShortcutIngestor()
    @StateObject private var deviceCatalog = DeviceCatalog.shared
    
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding, shortcutIngestor: shortcutIngestor)
            } else {
                mainTabView
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
                hasSeenOnboarding = true
            }
        }
        .onOpenURL { url in
            shortcutIngestor.processURL(url)
        }
    }
    
    private var mainTabView: some View {
        TabView {
            LiveChargingView(batteryManager: batteryManager)
                .tabItem {
                    Image(systemName: "bolt.fill")
                    Text("Live")
                }
            
            ChartsView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Charts")
                }
            
            HistoryView(shortcutIngestor: shortcutIngestor)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Image(systemName: "clock")
                    Text("History")
                }
            
            SettingsView(deviceCatalog: deviceCatalog)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}