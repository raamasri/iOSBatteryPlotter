import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @ObservedObject var shortcutIngestor: ShortcutIngestor
    @State private var currentPage = 0
    @State private var showingShortcutSetup = false
    
    private let pages = OnboardingPage.allPages
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page, isLastPage: index == pages.count - 1) {
                        if index == pages.count - 1 {
                            showingShortcutSetup = true
                        } else {
                            withAnimation {
                                currentPage = index + 1
                            }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            
            HStack {
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .foregroundColor(.blue)
                } else {
                    Button("Get Started") {
                        showingShortcutSetup = true
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingShortcutSetup) {
            ShortcutSetupView(showOnboarding: $showOnboarding, shortcutIngestor: shortcutIngestor)
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isLastPage: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .padding()
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }
            
            if !page.features.isEmpty {
                VStack(spacing: 12) {
                    ForEach(page.features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feature)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.horizontal, 48)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ShortcutSetupView: View {
    @Binding var showOnboarding: Bool
    @ObservedObject var shortcutIngestor: ShortcutIngestor
    @State private var currentStep = 0
    
    private let steps: [ShortcutSetupStep] = [
        ShortcutSetupStep(
            title: "Install the Shortcut",
            description: "First, you need to install the BatteryTrace Shortcut that will read your device's battery analytics.",
            action: "Install Shortcut",
            systemImage: "square.and.arrow.down"
        ),
        ShortcutSetupStep(
            title: "Enable Analytics",
            description: "Make sure analytics data is enabled in your device settings to allow the shortcut to read battery information.",
            action: "Open Settings",
            systemImage: "gear"
        ),
        ShortcutSetupStep(
            title: "Test the Connection",
            description: "Let's test if everything is working by running the shortcut and getting your first battery health reading.",
            action: "Test Shortcut",
            systemImage: "play.circle"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                ProgressView(value: Double(currentStep), total: Double(steps.count))
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal)
                
                VStack(spacing: 20) {
                    Image(systemName: steps[currentStep].systemImage)
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Step \(currentStep + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(steps[currentStep].title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text(steps[currentStep].description)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 32)
                }
                
                if currentStep == 0 {
                    shortcutInstallationView
                } else if currentStep == 1 {
                    analyticsSettingsView
                } else {
                    testShortcutView
                }
                
                Spacer()
                
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .foregroundColor(.blue)
                    } else {
                        Button("Finish Setup") {
                            showOnboarding = false
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                }
                .padding()
            }
            .navigationTitle("Setup BatteryTrace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        showOnboarding = false
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var shortcutInstallationView: some View {
        VStack(spacing: 20) {
            Button(action: {
                shortcutIngestor.openShortcutInstallation()
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Install BatteryTrace Shortcut")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("What happens next:")
                    .fontWeight(.semibold)
                
                Text("• Safari will open to the Shortcuts gallery")
                Text("• Tap 'Get Shortcut' to add it to your device")
                Text("• The shortcut will be named 'Battery Cycles'")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
        }
    }
    
    private var analyticsSettingsView: some View {
        VStack(spacing: 20) {
            Button(action: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal, 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Navigate to:")
                    .fontWeight(.semibold)
                
                Text("Settings → Privacy & Security → Analytics & Improvements → Analytics Data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Make sure 'Share Analytics' is enabled. This allows the shortcut to read your device's battery information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
        }
    }
    
    private var testShortcutView: some View {
        VStack(spacing: 20) {
            Button(action: {
                shortcutIngestor.triggerShortcut()
            }) {
                HStack {
                    Image(systemName: "play.circle")
                    Text("Test Shortcut")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal, 32)
            .disabled(shortcutIngestor.isProcessing)
            
            if let result = shortcutIngestor.lastIngestResult {
                VStack(spacing: 12) {
                    switch result {
                    case .success(let cycles, let health):
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Success!")
                                    .fontWeight(.semibold)
                                if let cycles = cycles, let health = health {
                                    Text("Found \(cycles) cycles, \(String(format: "%.1f", health * 100))% health")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                        
                    case .error(let message):
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("Error")
                                    .fontWeight(.semibold)
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 32)
            } else if shortcutIngestor.isProcessing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Running shortcut...")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("When you tap 'Test Shortcut':")
                        .fontWeight(.semibold)
                    
                    Text("• The Shortcuts app will open")
                    Text("• The shortcut will read your analytics data")
                    Text("• It will return to BatteryTrace with your battery info")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
    let features: [String]
    
    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to BatteryTrace",
            description: "Track your iPhone's battery health and charging performance over time.",
            imageName: "battery.100.bolt",
            color: .green,
            features: []
        ),
        OnboardingPage(
            title: "Monitor Battery Health",
            description: "See how your battery capacity degrades over time with detailed charts and analysis.",
            imageName: "chart.line.uptrend.xyaxis",
            color: .blue,
            features: [
                "Track health percentage over time",
                "Monitor cycle count progression",
                "View degradation curves",
                "Get health snapshots"
            ]
        ),
        OnboardingPage(
            title: "Analyze Charging Power",
            description: "Estimate charging wattage and compare different chargers and cables.",
            imageName: "bolt.horizontal.fill",
            color: .orange,
            features: [
                "Real-time power estimation",
                "Compare charging speeds",
                "Track session history",
                "Label charger types"
            ]
        ),
        OnboardingPage(
            title: "Your Data Stays Private",
            description: "All data is stored locally on your device. Nothing is sent to external servers.",
            imageName: "lock.shield",
            color: .purple,
            features: [
                "Local storage only",
                "No accounts required",
                "Export your data anytime",
                "Full data control"
            ]
        )
    ]
}

struct ShortcutSetupStep {
    let title: String
    let description: String
    let action: String
    let systemImage: String
}