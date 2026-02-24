# NammaMeter - Professional Auto Rickshaw Meter App

A professional-grade auto rickshaw meter application for iOS that provides accurate fare calculations, trip tracking, and multiple meter display styles.

## 🚕 Features

- **Five Professional Meter Styles**
  - Super Mechanical (classic mechanical design)
  - Super Electronic (advanced with night mode)
  - Golden Eagle (premium aesthetic)
  - Neo Digital (minimalist glowing display)
  - Bright Digital (modern LCD display)

- **Real-Time Fare Calculation**
  - GPS-based distance measurement
  - Configurable city-specific rates
  - Automatic night mode surcharges
  - Waiting time charge tracking
  - Multiple vehicle types per city (auto, taxi, cab)

- **WhatIf City Comparison**
  - Compare fares across cities and vehicle types in real time
  - Set up to 3 favorite city+vehicle combinations
  - Live WhatIf pages during active trips
  - Historical trip comparisons from trip history
  - Automatic currency conversion via ECB exchange rates

- **Multi-City Fare Catalog**
  - 22 pre-configured fare profiles across 15 cities
  - Karnataka, Indian, and US cities included
  - Easy to add custom city profiles

- **Trip Management**
  - Complete trip history with timestamps
  - Trip statistics and analytics
  - Offline functionality (no internet required)
  - Light and dark mode themes

- **Privacy First**
  - All data stored locally on device
  - No cloud transmission
  - No analytics tracking
  - No account required

## 📋 Documentation

### Quick Links

- **[Privacy Policy](docs/app-store/PRIVACY_POLICY.md)** - Complete GDPR/CCPA compliant privacy policy
- **[Privacy Policy (Short Version)](docs/app-store/PRIVACY_POLICY_SHORT.txt)** - Quick reference summary
- **[Legal Terms & Rights](docs/app-store/LEGAL_AND_RIGHTS.md)** - Terms of service and liability disclaimers
- **[App Store Submission Materials](docs/app-store/)** - Marketing copy, screenshots, and submission guides

### Developer Documentation

- **[Architecture Review](docs/architectural-review.md)** - System design and architecture
- **[Migrations](docs/migrations.md)** - Database and schema migrations
- **[Snapshot Testing](docs/snapshot-testing.md)** - Run and record snapshot baselines

## 🔐 Privacy & Legal

NammaMeter is designed with privacy as a core principle:

- ✅ **Offline First** - No network communication required
- ✅ **Local Storage Only** - All data stays on your device
- ✅ **User Control** - You decide what data is stored
- ✅ **Transparent** - No hidden tracking or collection
- ✅ **Open Source** - Code available for review on GitHub

### Key Privacy Points

- Location data is used only for distance calculation during trips
- Trip data is stored locally and never transmitted
- No personal information is collected
- Users have complete control over their data
- Data can be deleted at any time

For detailed information, see [Privacy Policy](docs/app-store/PRIVACY_POLICY.md) or [Short Summary](docs/app-store/PRIVACY_POLICY_SHORT.txt).

## 📱 System Requirements

- **iOS:** 17.6 or later
- **Devices:** iPhone and iPad
- **Storage:** Minimal (data stored locally)
- **Permissions:** Location access (only during trips)

## 🏗️ Project Structure

```
NammaMeter/
├── NammaMeter/              # Main app source code
├── NammaMeterTests/         # Unit and snapshot tests
├── NammaMeterUITests/       # UI integration tests
├── docs/
│   ├── app-store/          # App Store submission materials
│   ├── architectural-review.md
│   ├── migrations.md
│   └── snapshot-testing.md
├── NammaMeter.xcodeproj/   # Xcode project
└── README.md               # This file
```

## 🚀 Getting Started

### For Users

Download NammaMeter from the App Store:
- Search for "NammaMeter" on the App Store
- Tap "Get" to download
- Launch and configure your city's fare rates

### For Developers

1. **Clone the repository**
   ```bash
   git clone https://github.com/sridhar-sm/NammaMeter.git
   cd NammaMeter
   ```

2. **Open in Xcode**
   ```bash
   open NammaMeter.xcodeproj
   ```

3. **Build and Run**
   - Select your device or simulator
   - Press Cmd+R to build and run

4. **Run Tests**
   ```bash
   xcodebuild test -scheme NammaMeter
   ```
   For cleaner simulator logs (while preserving real warnings/errors), you can run:
   ```bash
   scripts/run-xcodebuild-filtered.sh xcodebuild test -scheme NammaMeter
   ```

## 📦 App Store Submission

All materials needed for App Store submission are in `docs/app-store/`:

- **[APPSTORE_QUICK_COPY.txt](docs/app-store/APPSTORE_QUICK_COPY.txt)** - Copy-paste ready content for submission
- **[APP_STORE_SUBMISSION_TEXT.md](docs/app-store/APP_STORE_SUBMISSION_TEXT.md)** - Comprehensive submission guide
- **[APPSTORE_MARKETING_VARIATIONS.md](docs/app-store/APPSTORE_MARKETING_VARIATIONS.md)** - Marketing alternatives and strategy
- **[Legal & Rights](docs/app-store/LEGAL_AND_RIGHTS.md)** - Complete legal documentation
- **[README](docs/app-store/README.md)** - App Store materials guide

## 🔗 Links

- **GitHub Repository:** https://github.com/sridhar-sm/NammaMeter
- **Privacy Policy:**
  - [Full Version (Local)](docs/app-store/PRIVACY_POLICY.md) | [Short Summary](docs/app-store/PRIVACY_POLICY_SHORT.txt)
  - [Full Version (Raw GitHub URL)](https://raw.githubusercontent.com/sridhar-sm/NammaMeter/main/docs/app-store/PRIVACY_POLICY.md)
- **Legal Terms:**
  - [Legal & Rights (Local)](docs/app-store/LEGAL_AND_RIGHTS.md)
  - [Legal & Rights (Raw GitHub URL)](https://raw.githubusercontent.com/sridhar-sm/NammaMeter/main/docs/app-store/LEGAL_AND_RIGHTS.md)

## 📄 License

© 2026 Sridhar SM. All rights reserved.

This is proprietary software. See [Legal & Rights](docs/app-store/LEGAL_AND_RIGHTS.md) for complete license information.

## 🤝 Support

For issues, questions, or feature requests:

- **GitHub Issues:** https://github.com/sridhar-sm/NammaMeter/issues
- **GitHub Discussions:** https://github.com/sridhar-sm/NammaMeter/discussions

## 📞 Contact

**Developer:** Sridhar SM
**GitHub:** https://github.com/sridhar-sm/NammaMeter

---

**Last Updated:** February 16, 2026
**App Version:** 1.0
**Status:** Ready for App Store Submission
