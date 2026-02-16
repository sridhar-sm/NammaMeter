# NammaMeter iOS App - Architectural Review

**Date:** 2026-02-16
**Branch:** `main` (reviewed from `sridhar-sm/readme-issue-135`)

---

## 1. High-Level Architecture

### Overview
NammaMeter is a SwiftUI fare meter app built around `@Observable` stores, pure fare-calculation services, and actor-backed persistence. Recent WhatIf phases (0-6) added cross-city comparison, favorites, currency conversion, and expanded fare catalog modeling.

### Architecture Pattern: Store-Centric MVVM + Service Layer

```text
┌──────────────────────────────────────────────────────────────────────┐
│                          View Layer (SwiftUI)                       │
│ ContentView -> MeterView / HistoryView / SettingsView               │
│ Meter: WhatIfComparisonPage   History: TripComparisonView           │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ @Environment injection via AppContainer
┌───────────────────────────────▼──────────────────────────────────────┐
│                       Store Layer (@Observable)                      │
│ MeterStore     SettingsStore     TripStore     ExchangeRateProvider  │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│                  Domain Model + Calculation Layer                    │
│ Trip, RateSnapshot, CityFareProfile, FareSurcharge, WhatIfFavorite  │
│ TripStateMachine, TripMetrics, FareCalculator, WhatIfCalculator     │
│ FareCalculationStrategy, SurchargeCalculator, FareRuleEvaluator       │
└───────────────────────────────┬──────────────────────────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────────┐
│                    Persistence + Integration Layer                   │
│ Actor-backed JSON persistence (trips, profiles, exchange rates)     │
│ LocationPermissionCoordinator + CLGeocoder + ECB rate fetch          │
└──────────────────────────────────────────────────────────────────────┘
```

### Current Project Structure (Key Areas)

```text
NammaMeter/
├── AppContainer.swift
├── ContentView.swift
├── MeterStore.swift
├── SettingsStore.swift
├── TripStore.swift
├── Models.swift
├── FareProfiles.swift
├── VehicleType.swift
├── Surcharge.swift
├── Currency/
│   ├── ExchangeRate.swift
│   ├── ExchangeRateProvider.swift
│   ├── ECBExchangeRateService.swift
│   └── BundledExchangeRates.swift
├── Calculation/
│   ├── FareCalculator.swift
│   ├── FareCalculationStrategy.swift
│   ├── FareRule.swift
│   ├── FareRuleEvaluator.swift
│   ├── SurchargeCalculator.swift
│   └── WhatIfCalculator.swift
├── Views/
│   ├── Meter/WhatIfComparisonPage.swift
│   └── History/TripComparisonView.swift
└── ... (remaining meter styles, forms, settings, location, state)
```

**Code footprint at review time:**
- App Swift files: `78`
- Unit/snapshot test Swift files: `39`
- UI test Swift files: `5`
- App Swift LOC: `11,908`

---

## 2. WhatIf & Currency Architecture

### Newly Material Components

| Component | Purpose |
|---|---|
| `WhatIfFavorite` | Stores a `(cityId, vehicleType)` comparison target |
| `WhatIfResult` | Computed fare/breakdown result for one WhatIf target |
| `CityGroup` | Grouped city presentation model with available vehicle types |
| `FareSurcharge` | Typed surcharge rules used in fare evaluation |
| `ExchangeRateTable` | Fetched/cached exchange-rate dataset |
| `VehicleTypeInfo` | Metadata for display/behavior by vehicle type |
| `CityKey` | Canonical city identity + country/currency metadata |

### Runtime Flow

1. `SettingsStore` maintains selected city/vehicle, fare profiles, and up to 3 WhatIf favorites.
2. `MeterStore.startTrip(...)` captures a `RateSnapshot` and loads WhatIf profile mappings.
3. `FareCalculator` computes primary fare via strategy + surcharge logic.
4. `WhatIfCalculator.calculateAll(...)` evaluates the same trip metrics against each favorite profile.
5. `ExchangeRateProvider` converts foreign-currency WhatIf totals for side-by-side UI comparison.
6. `WhatIfComparisonPage` (active trip) and `TripComparisonView` (history) render comparison cards.

### Exchange Rate Design Notes

- `ExchangeRateProvider` is a `@MainActor @Observable` store.
- Uses bundled fallback data first, then actor-backed cache load.
- Refreshes via `ECBExchangeRateService` when cached table is stale (`7` day threshold).
- Conversion falls back to original amount if a rate path is unavailable.

---

## 3. Test Coverage Status

### Test Suite Inventory

| Suite | Status |
|---|---|
| WhatIf | `Phase4WhatIfTests`, `Phase5ComparisonTests`, `Phase6FavoritesUITests`, `WhatIfCalculatorTests`, `WhatIfFavoriteTests` |
| Exchange Rates | `ExchangeRateTests`, `ExchangeRateProviderTests`, `ECBXMLParserTests` |
| Fare Engine | `FareCalculatorTests`, `FareCalculationStrategyTests`, `FareRuleEvaluatorTests`, `SurchargeTests`, `WaitingChargeTests` |
| Store/State | `MeterStoreTests`, `SettingsStoreTests`, `TripStoreTests`, `TripStateMachineTests`, `TripMetricsTests` |
| UI/Visual | `MeterSnapshotTests` + UITest suites (`Meter`, `History`, `Settings`, `Navigation`) |

### Overall Assessment

- WhatIf and currency additions are covered by dedicated unit tests.
- Fare rules engine (`FareRuleEvaluatorTests`) covers rule generation, evaluation, and amount accuracy.
- Snapshot testing coverage remains strong across multiple devices/styles.
- UI test scaffolding now exists (previously listed as a gap).

---

## 4. Core Strengths

1. Clear separation between state stores, pure calculation logic, and views.
2. Backward-compatible model decoding for older persisted schema variants.
3. Good concurrency discipline: actor-backed persistence + `@MainActor` stores.
4. WhatIf extension is additive and avoids destabilizing base trip lifecycle.
5. Currency conversion integration is optional at call sites (safe fallback behavior).

---

## 5. Risks and Follow-Ups

### Active Technical Risks (from open issues)

- `#103` Swift 6 actor-isolation warnings in test targets.
- `#102` CA event launch measurement warnings in tests.
- `#78` appintentsmetadataprocessor warning in tests.
- `#104`/`#105`/`#106` meter UI architecture and layout hardening concerns.

### Recommended Near-Term Improvements

1. Add targeted tests around exchange-rate stale-refresh boundaries and conversion fallback semantics in comparison views.
2. Continue de-risking meter paging/layout architecture called out in `#104`, `#105`, `#106`.
3. Keep architectural docs updated when new fare catalog versions and migration behavior are introduced.

---

## 6. Summary

### Architecture Quality: **Good and Improving**

The architecture remains coherent after the WhatIf expansion. The app now includes first-class support for multi-city/multi-vehicle comparison and currency normalization without collapsing store boundaries. The biggest remaining concerns are test-warning cleanup and ongoing meter-layout technical debt, both already tracked in open issues.
