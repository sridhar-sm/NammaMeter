# NammaMeter iOS App - Architectural Review

**Date:** 2026-02-05
**Branch:** sridhar-sm/arch-review (synced with main)

---

## 1. High-Level Architecture

### Overview
NammaMeter is a taxi fare meter iOS app built with SwiftUI using modern Swift 5.9+ patterns. The app calculates real-time fares based on distance, time, and waiting charges, with support for multiple city fare profiles.

### Architecture Pattern: MVVM + Observation Framework

```
┌─────────────────────────────────────────────────────────────────┐
│                         View Layer (SwiftUI)                     │
│   ContentView → MeterView / HistoryView / SettingsView          │
│   (Purely presentational, no business logic)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │ @Environment injection
┌────────────────────────────▼────────────────────────────────────┐
│                     ViewModel Layer (@Observable)                │
│   ┌─────────────┐  ┌──────────────┐  ┌────────────┐             │
│   │ MeterStore  │  │ SettingsStore│  │ TripStore  │             │
│   │ (active     │  │ (fare        │  │ (historical│             │
│   │  trip mgmt) │  │  profiles)   │  │  trips)    │             │
│   └──────┬──────┘  └──────┬───────┘  └─────┬──────┘             │
└──────────┼────────────────┼────────────────┼────────────────────┘
           │                │                │
┌──────────▼────────────────▼────────────────▼────────────────────┐
│                         Model Layer                              │
│   Trip, TripPoint, MeterSettings, RateSnapshot, CityFareProfile │
│   TripStateMachine (forHire → inProgress → complete)            │
│   TripMetrics (distance, elapsed time, waiting time)            │
└────────────────────────────┬────────────────────────────────────┘
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                     Services / Business Logic                    │
│   FareCalculator (pure calculation)                             │
│   LocationPermissionCoordinator (permission handling)           │
│   FareProfilePersistence / TripPersistence (actor-based I/O)    │
└─────────────────────────────────────────────────────────────────┘
```

### Project Structure

```
NammaMeter/
├── NammaMeterApp.swift          # App entry point
├── ContentView.swift            # Tab-based main navigation
├── Models.swift                 # Core data models
├── Theme.swift                  # Color scheme and styling
├── MeterTypes.swift             # Meter enums and dimensions
│
├── State/                       # State management
│   ├── TripStateMachine.swift   # Trip state (forHire/inProgress/complete)
│   └── TripMetrics.swift        # Distance, time tracking
│
├── MeterStore.swift             # Active trip state management
├── SettingsStore.swift          # Fare profiles management
├── TripStore.swift              # Historical trip storage
│
├── Calculation/
│   └── FareCalculator.swift     # Pure fare calculation logic
│
├── Location/                    # Location services
│   ├── LocationPermissionCoordinator.swift
│   └── LocationPermissionAlerts.swift
│
├── Forms/                       # Form validation
│   ├── FormValidator.swift
│   ├── FormState.swift
│   ├── CityFormValidator.swift
│   └── FareProfileFormValidator.swift
│
├── Components/
│   └── DigitWheel/              # Mechanical digit wheel component
│       ├── MechanicalDigitWheel.swift
│       ├── DigitWheelRenderer.swift
│       └── DigitWheelAnimationState.swift
│
├── Styles/
│   ├── FontPresets.swift
│   ├── StyleGuide.swift
│   └── ThemeColors.swift
│
├── Views/                       # Modular view components
│   ├── Meter/                   # Meter-related views
│   ├── History/                 # Trip history views
│   └── Settings/                # Settings views
│
└── [Meter Style Views]          # 5 different meter face styles
    ├── SuperMechanicalMeterView.swift
    ├── SuperElectronicMeterView.swift
    ├── GoldenEagleMeterView.swift
    ├── BrightDigitalMeterView.swift
    └── DigitalMeterView.swift
```

**Total:** ~62 Swift source files, ~6,400+ lines of code

---

## 2. Key Components

### Core Stores

| Store | Responsibility | Persistence |
|-------|---------------|-------------|
| **MeterStore** | Active trip lifecycle, location tracking, fare calculation | None (in-memory) |
| **SettingsStore** | City fare profiles, app settings | Documents/fare-profiles.json |
| **TripStore** | Historical trip storage, search, bulk operations | Documents/trips.json |

### Core Models

| Model | Purpose |
|-------|---------|
| **Trip** | Complete trip record (ID, dates, distance, fare, GPS points) |
| **TripPoint** | GPS location with speed, accuracy, timestamp |
| **MeterSettings** | Fare parameters (base fare, per-km rate, night multiplier) |
| **CityFareProfile** | City-specific fare configuration |
| **RateSnapshot** | Rates captured at trip start time |
| **TripStateMachine** | Three-state enum (forHire → inProgress → complete) |

### Fare Calculation Logic

```
Fare = Max(
  minFare,
  (baseFare + distanceFare + timeFare + waitFare) × multiplier
)

Where:
- distanceFare = (distance - includedKm) × perKmRate (if > includedKm)
- waitFare = ceil((waitMinutes - freeWait) / interval) × intervalCharge
- multiplier = nightMultiplier (if during configured night hours)
```

### Tab Navigation Structure

```
TabView
├── Tab 1: MeterView
│   ├── MeterLayoutContainer
│   │   ├── MeterPanelWithNotch (swipeable meter styles)
│   │   ├── MeterControlBar (start/stop/settings)
│   │   └── MeterPagerView (map display)
│   └── MeterSettingsSheetView
│
├── Tab 2: HistoryView
│   ├── HistorySearchBar
│   ├── HistoryListContent
│   ├── TripRow → TripDetailView
│   └── HistoryActionBar
│
└── Tab 3: SettingsView
    ├── SettingsCitySection
    ├── SettingsRatesSection
    ├── SettingsWaitingChargesSection
    ├── SettingsModifiersSection
    └── SettingsResetSection
```

---

## 3. Test Coverage Analysis

### Test Files Summary

| Category | Files | Description |
|----------|-------|-------------|
| **Unit Tests** | 12 | Core business logic and model tests |
| **Snapshot Tests** | 1 | Visual regression tests (50+ cases) |
| **Helpers** | 2 | Test utilities and mock implementations |
| **Total** | 15 | |

### Tested Components

| Component | Test File | Coverage |
|-----------|-----------|----------|
| Fare Calculation | FareCalculatorTests.swift | Comprehensive |
| Trip State Machine | TripStateMachineTests.swift | Comprehensive |
| Meter Store | MeterStoreTests.swift | Comprehensive (150+ assertions) |
| Trip Store | TripStoreTests.swift | Comprehensive (persistence, CRUD) |
| Settings Store | FareProfileTests.swift | Profile management, migration |
| Form Validation | FormValidationTests.swift | City and fare profile validation |
| Digit Wheel Rendering | DigitWheelRendererTests.swift | Animation calculations |
| Layout Metrics | MeterLayoutMetricsTests.swift | Container sizing |
| Accessibility | ThemeAccessibilityTests.swift | WCAG contrast compliance |
| Backward Compatibility | BackwardCompatibilityTests.swift | Legacy data migration |
| Location Permission | LocationPermissionCoordinatorTests.swift | Permission state transitions |
| Trip Metrics | TripMetricsTests.swift | Distance/time accumulation |
| Waiting Charges | WaitingChargeTests.swift | Interval billing logic |
| Meter Snapshots | MeterSnapshotTests.swift | All 5 meter styles, 5 devices |

### Test Coverage Gaps

| Area | Status | Notes |
|------|--------|-------|
| UI Integration Tests | Missing | No behavioral UI tests |
| View Layer Unit Tests | Missing | Views rely on snapshot tests only |
| Navigation Flow Tests | Missing | Tab switching, sheet presentation |
| Network/API Tests | Missing | Reverse geocoding error scenarios |
| End-to-End Tests | Missing | Full user journey tests |

---

## 4. Architectural Strengths

1. **Clean Separation of Concerns**
   - Views are purely presentational
   - State management isolated in @Observable classes
   - Calculation logic in pure FareCalculator
   - Persistence abstracted in actor-based classes

2. **Modern Swift Practices**
   - @Observable macro (Swift 5.9+) instead of Combine
   - Async/await for concurrency
   - @MainActor for UI thread safety
   - Sendable protocol for thread safety

3. **Type Safety & Concurrency**
   - Actor-based persistence (thread-safe)
   - Strong typing throughout
   - No force unwraps in business logic

4. **Testability**
   - FareCalculator is pure (no side effects)
   - LocationProviding protocol allows mocking
   - Protocol-oriented design for validators

5. **Zero External Dependencies**
   - Pure native iOS frameworks only
   - No CocoaPods, SPM dependencies (except SnapshotTesting for tests)

---

## 5. Suggested Architectural Improvements

### High Priority

#### 1. Add UI Integration Tests
**Issue:** UI behavior is only validated via snapshot tests, not interaction tests.

**Recommendation:**
- Add XCUITest target for critical user flows
- Test trip start/stop lifecycle
- Test navigation between tabs
- Test form submission and validation

#### 2. Address Open Technical Debt (Tracked Issues)
**Currently Open:**
- [#78](https://github.com/sridhar-sm/NammaMeter/issues/78): appintentsmetadataprocessor warning in tests
- [#71](https://github.com/sridhar-sm/NammaMeter/issues/71): IOSurfaceClientSetSurfaceNotify warning
- [#68](https://github.com/sridhar-sm/NammaMeter/issues/68): AttributeGraph cycle warnings in tests

#### 3. Clarify Settings/Profile Sync Logic
**Issue:** [#48](https://github.com/sridhar-sm/NammaMeter/issues/48) - Migration and sync logic between SettingsStore and profiles needs documentation.

**Recommendation:**
- Document the migration path for fare profile updates
- Add inline comments explaining sync behavior
- Consider a dedicated MigrationService

### Medium Priority

#### 4. Complete Meter Display Composition System
**Issue:** [#53](https://github.com/sridhar-sm/NammaMeter/issues/53) - Meter display row composition could be more declarative.

**Recommendation:**
- Extract meter rows into composable building blocks
- Create a MeterConfiguration protocol for meter styles
- Reduce duplication across 5 meter view files

#### 5. Extend MeterShell Decorations
**Issue:** [#55](https://github.com/sridhar-sm/NammaMeter/issues/55) - Support canopy and base decorations.

**Recommendation:**
- Implement slot-based decoration system
- Allow meter styles to define custom decorations
- Keep backward compatibility with existing styles

#### 6. Add Dependency Injection Container
**Current:** Stores are injected via @Environment at app root.

**Recommendation:**
- Consider a lightweight DI container for complex dependencies
- Would improve testability of nested view hierarchies
- Not urgent - current approach works well for this app size

### Low Priority

#### 7. Extract Geocoding Service
**Current:** Reverse geocoding is embedded in TripStore.

**Recommendation:**
- Extract into dedicated GeocodingService
- Add retry logic and error handling
- Cache results more aggressively

#### 8. Add Analytics/Logging Framework
**Current:** No structured logging or analytics.

**Recommendation:**
- Add OSLog-based structured logging
- Consider privacy-respecting analytics for trip patterns
- Would help debugging production issues

#### 9. Consider Modularization
**Current:** Single app target.

**Recommendation (future):**
- Extract FareCalculator into separate module (testable in isolation)
- Create MeterUI module for meter rendering
- Only worthwhile if team grows or app complexity increases significantly

---

## 6. Summary

### Architecture Quality: **Good**

The NammaMeter codebase demonstrates solid iOS architecture practices:
- Clean MVVM pattern with modern Swift Observation
- Strong separation between views, state, and business logic
- Comprehensive unit test coverage for core logic
- Visual regression protection via snapshot tests
- Thread-safe persistence with actors

### Main Improvement Areas:
1. UI integration test coverage
2. Resolve open test warnings (#78, #71, #68)
3. Document migration/sync logic (#48)
4. Complete refactoring items (#53, #55)

The architecture is well-suited for the current app complexity and follows iOS best practices.
