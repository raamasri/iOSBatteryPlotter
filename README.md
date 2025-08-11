# BatteryTrace

> **Know your battery. Over time.**

A comprehensive iOS application for tracking battery health degradation and analyzing charging performance. BatteryTrace provides detailed insights into your iPhone's battery health trends, cycle count progression, and real-time charging power estimation.

## 🔋 Features

### Battery Health Tracking
- **Long-term Health Monitoring**: Track battery capacity degradation over time
- **Cycle Count Progression**: Monitor charge cycles and their impact on health
- **Degradation Analysis**: Visualize health vs. cycle count relationships
- **Historical Data**: Complete timeline of your battery's performance

### Charging Analysis
- **Real-time Power Estimation**: Live wattage calculation during charging sessions
- **Session History**: Detailed charging session records with metrics
- **Charger Comparison**: Compare different chargers and cables
- **Session Notes**: Label sessions with charger types and custom notes

### Data Visualization
- **Interactive Charts**: Built with Swift Charts for smooth, native performance
- **Health Over Time**: Line charts showing capacity trends
- **Cycle Progression**: Track the relationship between usage and degradation
- **Session Analytics**: Compare charging speeds across different setups

### Data Export & Privacy
- **CSV Export**: Export all data for analysis in Numbers, Excel, or Google Sheets
- **Local Storage**: All data stays on your device - no external servers
- **Complete Control**: Export or delete your data anytime

## 📱 Requirements

- **iOS 18.0** or later
- **iPhone** (battery monitoring not available on iPad)
- **iOS Shortcuts** app for battery health data integration

## 🚀 Installation

1. **Download the App**
   - Clone this repository
   - Open `BatteryTrace.xcodeproj` in Xcode 16.0+
   - Build and install on your iPhone

2. **Install the Battery Shortcuts**
   - Install the required iOS Shortcut: [Battery Cycles Shortcut](https://www.icloud.com/shortcuts/53f0900518564258ad5b06867b032a1e)
   - Modify the shortcut to include the callback URL (instructions in-app)

3. **Enable Analytics** (if not already enabled)
   - Go to Settings → Privacy & Security → Analytics & Improvements
   - Enable "Share Analytics" to allow the shortcut to read battery data

## 🔧 How It Works

### Power Estimation
BatteryTrace estimates charging power using a percent-change-over-time algorithm:

1. **Sampling**: Monitors battery percentage every 5 seconds while charging
2. **Calculation**: Uses the formula: `Power = (Capacity × ΔPercent) / ΔTime × Voltage`
3. **Smoothing**: Applies exponential moving average for stable readings
4. **Device-Specific**: Uses actual device capacity for accurate calculations

### Health Data Integration
Battery health and cycle count data comes from iOS Analytics logs via Shortcuts:

1. **Shortcut Execution**: Tap "Refresh Cycles" to run the configured shortcut
2. **Analytics Parsing**: Shortcut reads device analytics for battery metrics
3. **Data Return**: Information returns to BatteryTrace via custom URL scheme
4. **Storage**: Data is stored locally in Core Data for historical tracking

## 📊 Understanding the Data

### Power Estimates
- **Accuracy**: Estimates are approximate, affected by device usage during charging
- **Variables**: Screen brightness, background apps, and temperature impact readings  
- **Comparison**: Best used for relative comparison between chargers/cables
- **Real-time**: Values update continuously during charging sessions

### Health Metrics
- **Battery Health**: Maximum capacity as percentage of original capacity
- **Cycle Count**: Number of complete charge/discharge cycles
- **Degradation Rate**: Health loss per cycle over time
- **First Use Date**: When the battery was first activated (when available)

## 🎯 Use Cases

### Personal Battery Health Management
- Monitor long-term battery degradation trends
- Identify when battery replacement might be needed
- Track the impact of charging habits on battery health

### Charger and Cable Testing
- Compare charging speeds between different power adapters
- Identify the fastest charging setup for your device
- Verify charger specifications with real-world measurements

### Data Analysis and Research
- Export detailed charging and health data
- Analyze patterns in battery degradation
- Track correlation between usage patterns and battery health

## 🏗 Technical Architecture

### Built With
- **SwiftUI** - Modern iOS user interface framework
- **Swift Charts** - Native chart rendering with smooth animations
- **Core Data** - Local data persistence and management
- **Combine** - Reactive programming for real-time updates

### Supported Devices
Complete device database including:
- iPhone 6s through iPhone 16 series
- Automatic capacity detection for accurate power calculations
- Custom capacity override for modified devices

### Privacy & Security
- **Local Storage**: All data remains on your device
- **No Tracking**: No analytics, ads, or user tracking
- **Open Source**: Complete source code available for review
- **User Control**: Full control over data export and deletion

## 🔍 Troubleshooting

### Shortcut Integration Issues
- Ensure the iOS Shortcuts app is installed and updated
- Verify analytics data sharing is enabled in Settings
- Check that the shortcut includes the proper callback URL
- Try running the shortcut manually to test functionality

### Power Estimation Concerns
- Keep the app in the foreground while charging for accurate readings
- Minimize device usage during measurement sessions
- Remember that estimates are approximate, not precise measurements
- Temperature and charging condition affect accuracy

### Data Export Problems
- Ensure you have sufficient storage for export files
- Try exporting smaller date ranges if experiencing issues
- Verify the receiving app supports CSV format

## 🤝 Contributing

This project welcomes contributions! Areas where help is appreciated:

- **Device Database**: Adding capacity data for new iPhone models
- **Algorithm Improvements**: Enhancing power estimation accuracy
- **UI/UX**: Improving user interface and experience
- **Testing**: Validating functionality across different devices and iOS versions

## 📄 License

This project is open source. See the LICENSE file for details.

## ⚠️ Disclaimer

BatteryTrace provides estimated power values based on battery percentage changes over time. These values are approximate and may vary based on device usage, temperature, and charging conditions. The app is designed for informational purposes and relative comparison between charging setups.

Battery health and cycle count data comes from iOS Analytics logs and may not be available on all devices or iOS versions. The accuracy of this data depends on iOS system reporting.

## 🔗 Links

- **Repository**: [https://github.com/raamasri/iOSBatteryPlotter](https://github.com/raamasri/iOSBatteryPlotter)
- **Required Shortcut**: [Battery Cycles Shortcut](https://www.icloud.com/shortcuts/53f0900518564258ad5b06867b032a1e)
- **Issues & Support**: [GitHub Issues](https://github.com/raamasri/iOSBatteryPlotter/issues)

---

**Built with ❤️ for iPhone users who want to understand their battery better.**