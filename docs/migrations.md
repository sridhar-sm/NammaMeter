# Fare Profile Settings Migration Guide

## Overview

NammaMeter uses a versioned migration system to safely evolve fare profile settings over time. This guide explains the migration philosophy, version management, and how to safely add new features requiring data migrations.

## Migration Philosophy

### Core Principles

1. **Graceful Backward Compatibility**
   - Old data files load successfully in new app versions
   - Missing fields get safe default values via `decodeIfPresent`
   - No data loss during upgrades

2. **Append-Only Catalog Updates**
   - Never remove cities from the catalog
   - Only add new catalog profiles
   - Respect user deletions (don't re-add deleted profiles)

3. **Fail-Safe Defaults**
   - Always fallback to Bengaluru (default city) if selection is invalid
   - Ensure at least one profile exists at all times
   - activeProfile() returns fallback if city not found

4. **Idempotent Migrations**
   - Migrations can run multiple times safely
   - Return `true` only if state was actually modified
   - Order dependencies are documented

5. **Profile Versioning**
   - User edits create NEW profile versions (don't mutate existing)
   - Profiles have `effectiveFrom` timestamps
   - `activeProfile()` selects most recent applicable version
   - Preserves history and enables future revert functionality

## Version Management

### Two-Version System

NammaMeter tracks two separate version numbers:

#### 1. Schema Version

**Purpose:** Tracks `FareProfileSettings` structure changes

**Current Version:** `3`

**Defined in:** `FareProfileSettings.currentSchemaVersion`

**When to bump:**
- Adding/removing fields to FareProfileSettings
- Changing field types or semantics
- Restructuring the data model

**Future use:**
```swift
// When schema version changes, add version-specific migrations:
if state.schemaVersion == 1 {
    migrateV1toV2(&state)
} else if state.schemaVersion == 2 {
    migrateV2toV3(&state)
}
state.schemaVersion = FareProfileSettings.currentSchemaVersion
```

**Current implementation:**
```swift
// Currently only bumps version, no version-specific logic yet
if state.schemaVersion != FareProfileSettings.currentSchemaVersion {
    state.schemaVersion = FareProfileSettings.currentSchemaVersion
    didMutate = true
}
```

#### 2. Catalog Version

**Purpose:** Tracks which catalog profiles user has seen

**Current Version:** `3`

**Defined in:** `FareCatalog.currentVersion`

**Stored in:** `FareProfileSettings.catalogVersionApplied`

**When to bump:**
- Adding new cities to the catalog
- Updating existing catalog profiles (creates new version)

**How it works:**
```swift
// Each catalog entry tracks when it was introduced
struct FareCatalogEntry {
    let introducedInVersion: Int  // Version when this profile was added
    let profile: CityFareProfile
}

// Migration only adds profiles introduced after catalogVersionApplied
let newEntries = FareCatalog.entries.filter {
    $0.introducedInVersion > state.catalogVersionApplied
}
```

**Why user deletions are respected:**

If a user deletes a catalog profile, `catalogVersionApplied` is already at or above the version where that profile was introduced, so it won't be re-added. The migration only adds profiles with `introducedInVersion > catalogVersionApplied`.

## Migration Orchestration

### Load Sequence

All migrations run during `SettingsStore.load()` in a specific order:

```swift
private func load() async {
    // 1. Load or seed
    if let decoded = await persistence.load() {
        state = decoded
    } else {
        // First run: seed with all catalog profiles
        state = seedWithCatalogDefaults()
    }

    // 2. Schema version bump
    if state.schemaVersion != FareProfileSettings.currentSchemaVersion {
        state.schemaVersion = FareProfileSettings.currentSchemaVersion
    }

    // 3. Catalog updates
    applyCatalogUpdatesIfNeeded()

    // 4. Minimum profile guarantee
    ensureMinimumProfile()

    // 5. Selection validation
    normalizeSelection()

    // 6. Sync settings from active profile
    syncSettingsFromActiveProfile()
}
```

### Why Order Matters

**Dependencies:**
- `ensureMinimumProfile()` must run before `normalizeSelection()`
  - Selection needs profiles to exist first
- `applyCatalogUpdatesIfNeeded()` should run early
  - Populates profiles before validation steps
- Schema version bump happens first
  - Enables future version-specific transformations

**Safety:**
All migrations are idempotent, so the order provides optimization but not correctness (both `ensureMinimumProfile` and `normalizeSelection` can add the default profile safely).

## Adding New Features

### Scenario 1: Adding a New Catalog City

**When:** Adding a new city to the default catalog (e.g., "Mumbai")

**Steps:**

1. **Define the profile in FareCatalog:**
```swift
// FareProfiles.swift
struct FareCatalog {
    static let currentVersion = 3  // Bump version

    static let entries: [FareCatalogEntry] = [
        // Existing entries at version 2...
        FareCatalogEntry(
            introducedInVersion: 2,
            profile: bengaluruProfile
        ),
        // New entry
        FareCatalogEntry(
            introducedInVersion: 3,  // New version
            profile: mumbaiProfile
        ),
    ]

    static let mumbaiProfile = CityFareProfile(
        cityId: "mumbai",
        name: "Mumbai",
        // ... rest of profile definition
    )
}
```

2. **No other code changes needed!**
   - `applyCatalogUpdatesIfNeeded()` automatically adds it
   - Users with `catalogVersionApplied < 3` get Mumbai added
   - Users who had `catalogVersionApplied = 2` get the update on next app launch

3. **Test the migration:**
```swift
func testCatalogUpdateAddsMumbai() async throws {
    // Simulate user with catalogVersionApplied = 2
    let oldSettings = FareProfileSettings(
        schemaVersion: 2,
        selectedCityId: "bengaluru",
        profiles: [bengaluruProfile, mandyaProfile],
        catalogVersionApplied: 2
    )

    // Save old settings
    await persistence.save(oldSettings)

    // Load with new catalog version
    let store = SettingsStore(fileURL: testURL)
    await waitForLoad(store)

    // Verify Mumbai was added
    XCTAssertTrue(store.profiles.contains { $0.cityId == "mumbai" })
    XCTAssertEqual(store.state.catalogVersionApplied, 3)
}
```

### Scenario 2: Adding a New Field to FareProfileSettings

**When:** Adding a new top-level field to the settings structure

**Example:** Adding `favoriteProfiles: [String]` to track user favorites

**Steps:**

1. **Add field with default value:**
```swift
// FareProfiles.swift
struct FareProfileSettings: Codable {
    var schemaVersion: Int
    var selectedCityId: String?
    var profiles: [CityFareProfile]
    var catalogVersionApplied: Int
    var favoriteProfiles: [String]  // New field

    static let currentSchemaVersion = 3  // Bump version
}
```

2. **Update decoding to handle missing field:**
```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion)
        ?? Self.currentSchemaVersion
    selectedCityId = try container.decodeIfPresent(String.self, forKey: .selectedCityId)
    profiles = try container.decodeIfPresent([CityFareProfile].self, forKey: .profiles) ?? []
    catalogVersionApplied = try container.decodeIfPresent(Int.self, forKey: .catalogVersionApplied) ?? 0

    // New field with default empty array
    favoriteProfiles = try container.decodeIfPresent([String].self, forKey: .favoriteProfiles) ?? []
}
```

3. **No migration logic needed** if default value is appropriate
   - Old data files load successfully
   - Missing field gets default value `[]`
   - Schema version bump happens automatically

4. **Add migration logic** if default isn't appropriate:
```swift
// SettingsStore.swift - in load() after schema version bump
if state.schemaVersion == 2 {
    // V2→V3 migration: Populate favoriteProfiles with catalog cities
    state.favoriteProfiles = state.profiles
        .filter { isCatalogCity($0.cityId) }
        .map { $0.id }
    state.schemaVersion = 3
}
```

### Scenario 3: Modifying an Existing Catalog Profile

**When:** Updating fare rates for an existing city (e.g., Bengaluru rates change)

**Important:** Current implementation does NOT update existing user profiles

**Option A: Create a new catalog version (Recommended)**
```swift
// FareProfiles.swift
static let entries: [FareCatalogEntry] = [
    // Keep old version for users who haven't updated
    FareCatalogEntry(
        introducedInVersion: 2,
        profile: bengaluruProfileV1
    ),
    // Add new version with updated rates
    FareCatalogEntry(
        introducedInVersion: 3,
        profile: bengaluruProfileV2  // Updated rates, effectiveFrom = futureDate
    ),
]

static let bengaluruProfileV2 = CityFareProfile(
    cityId: "bengaluru",
    name: "Bengaluru",
    effectiveFrom: Date(timeIntervalSince1970: 1735776000), // 2025-01-02
    // ... updated rates
)
```

**Option B: Implement catalog update migration (Future enhancement)**
```swift
// Not currently implemented - would require new migration logic
private func updateExistingCatalogProfiles() -> Bool {
    var didUpdate = false
    for catalogEntry in FareCatalog.entries {
        if let index = state.profiles.firstIndex(where: {
            $0.id == catalogEntry.profile.id
        }) {
            // Update only if catalog profile is newer
            if catalogEntry.profile.effectiveFrom > state.profiles[index].effectiveFrom {
                state.profiles[index] = catalogEntry.profile
                didUpdate = true
            }
        }
    }
    return didUpdate
}
```

### Scenario 4: Removing a Deprecated Field

**When:** Removing an old field that's no longer used

**Example:** Removing `rainMultiplier` and `trafficMultiplier` (already done)

**Steps:**

1. **Remove field from struct:**
```swift
// Models.swift
struct MeterSettings: Codable {
    var baseFare: Decimal
    var perKilometerRate: Decimal
    var nightMultiplier: Decimal
    // Removed: var rainMultiplier: Decimal
    // Removed: var trafficMultiplier: Decimal
}
```

2. **Update decoder to ignore old field:**
```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    baseFare = try container.decode(Decimal.self, forKey: .baseFare)
    perKilometerRate = try container.decode(Decimal.self, forKey: .perKilometerRate)
    nightMultiplier = try container.decode(Decimal.self, forKey: .nightMultiplier)

    // Ignore old fields - they're in JSON but not decoded
    // Old data: {"baseFare": 25, "rainMultiplier": 1.1}
    // Decoder silently ignores rainMultiplier
}
```

3. **No explicit migration needed** - decoder handles it automatically

4. **Add test to verify backward compatibility:**
```swift
func testDecodesLegacyDataWithRainMultiplier() throws {
    let json = """
    {
        "baseFare": 25,
        "rainMultiplier": 1.1,
        "trafficMultiplier": 1.05
    }
    """

    let settings = try JSONDecoder().decode(MeterSettings.self, from: json.data(using: .utf8)!)
    XCTAssertEqual(settings.baseFare, 25)
    // Old fields are silently ignored
}
```

## Bidirectional Settings Sync

### The Sync Mechanism

NammaMeter maintains a **bidirectional sync** between observable `MeterSettings` (UI state) and versioned `CityFareProfile` (persistence):

```
┌─────────────────┐         ┌──────────────────────┐
│  MeterSettings  │ ←────── │  CityFareProfile     │
│  (Observable)   │         │  (Persisted)         │
│                 │ ──────→ │                      │
└─────────────────┘         └──────────────────────┘
   Profile→Settings            Settings→Profile
   syncSettings...()           commitSettingsChange()
```

### Direction 1: Profile → Settings

**Function:** `syncSettingsFromActiveProfile()`

**When it runs:**
- App load (after migrations)
- User selects a different city
- User resets to defaults
- User deletes the currently selected city

**What it does:**
```swift
1. Get active profile for selected city
2. Convert profile → MeterSettings
3. Set isSyncingFromProfile = true
4. Update observable settings
5. Set isSyncingFromProfile = false
```

**Why the flag?**
Prevents infinite loops. Without `isSyncingFromProfile`:
1. syncSettings...() updates settings
2. settings.didSet triggers commit
3. commit creates new profile
4. New profile triggers sync again → ∞ loop

### Direction 2: Settings → Profile

**Function:** `commitSettingsChange()`

**When it runs:**
- User modifies any MeterSettings field (after 500ms debounce)
- settings.didSet when `isLoaded=true` and `isSyncingFromProfile=false`

**What it does:**
```swift
1. Check if settings actually changed
2. Create new CityFareProfile with current settings
3. Set effectiveFrom = now
4. Append to profiles array
5. Schedule save
```

**Why create new profiles instead of mutating?**
- Preserves catalog profiles unchanged
- Maintains history of settings changes
- Enables future features: revert, history viewer
- activeProfile() uses effectiveFrom to select current version

### Debouncing

**Purpose:** Prevent creating excessive profile versions during rapid edits

**Implementation:**
```swift
var settings: MeterSettings {
    didSet {
        guard isLoaded, !isSyncingFromProfile else { return }
        scheduleSettingsCommit()  // 500ms debounce
    }
}

private func scheduleSettingsCommit() {
    commitTask?.cancel()  // Cancel previous pending commit
    commitTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        commitSettingsChange()
    }
}
```

**Example:**
- User drags slider from ₹25 → ₹30 (fires ~10 didSet events)
- Each event cancels previous commit and restarts timer
- Only final value (₹30) creates a profile version after 500ms pause

## Testing Migrations

### Test Patterns

#### 1. First Run (Catalog Seeding)
```swift
func testSettingsStoreSeedsCatalogOnFirstLoad() async throws {
    let store = SettingsStore(fileURL: tempURL)
    await waitForLoad(store)

    XCTAssertEqual(store.profiles.count, FareCatalog.entries.count)
    XCTAssertEqual(store.selectedCityId, FareCatalog.defaultCityId)
}
```

#### 2. Catalog Updates
```swift
func testSettingsStoreAppendsCatalogUpdates() async throws {
    // Setup: User has old catalog version
    let oldSettings = FareProfileSettings(
        schemaVersion: 2,
        selectedCityId: "bengaluru",
        profiles: [bengaluruProfile],
        catalogVersionApplied: 1
    )
    await persistence.save(oldSettings)

    // Load with new catalog version
    let store = SettingsStore(fileURL: testURL)
    await waitForLoad(store)

    // Verify new profiles added
    XCTAssertGreaterThan(store.profiles.count, 1)
    XCTAssertEqual(store.state.catalogVersionApplied, FareCatalog.currentVersion)
}
```

#### 3. Invalid Selection Normalization
```swift
func testSettingsStoreFallbacksToBengaluru() async throws {
    let oldSettings = FareProfileSettings(
        schemaVersion: 2,
        selectedCityId: "non-existent-city",
        profiles: [bengaluruProfile],
        catalogVersionApplied: 2
    )
    await persistence.save(oldSettings)

    let store = SettingsStore(fileURL: testURL)
    await waitForLoad(store)

    XCTAssertEqual(store.selectedCityId, "bengaluru")
}
```

#### 4. Field Defaults
```swift
func testProfileDecodingDefaultsNightWindow() throws {
    // Old profile JSON without nightWindow field
    let json = """
    {
        "cityId": "test",
        "name": "Test",
        "rates": { ... }
    }
    """

    let profile = try JSONDecoder().decode(CityFareProfile.self, from: json.data(using: .utf8)!)
    XCTAssertNotNil(profile.nightWindow)  // Should have default
}
```

### Edge Cases to Test

1. **Empty profiles array** → ensureMinimumProfile adds default
2. **Invalid selection** → normalizeSelection falls back
3. **Catalog version rollback** → catalogVersionApplied > currentVersion
4. **Schema version bump idempotency** → can run multiple times
5. **Migration order** → verify dependencies

## Common Pitfalls

### ❌ Mutating Catalog Profiles

**Wrong:**
```swift
// DON'T: Mutating an existing profile loses history
if let index = state.profiles.firstIndex(where: { $0.id == profileId }) {
    state.profiles[index].baseFare = newValue
}
```

**Right:**
```swift
// DO: Create new profile version
let newProfile = CityFareProfile(
    id: UUID().uuidString,
    cityId: existingProfile.cityId,
    // ... copy existing fields with new values
    effectiveFrom: Date()
)
state.profiles.append(newProfile)
```

### ❌ Forgetting decodeIfPresent

**Wrong:**
```swift
// DON'T: Crashes if field missing in old data
init(from decoder: Decoder) throws {
    newField = try container.decode(String.self, forKey: .newField)
}
```

**Right:**
```swift
// DO: Provide default for missing field
init(from decoder: Decoder) throws {
    newField = try container.decodeIfPresent(String.self, forKey: .newField) ?? "default"
}
```

### ❌ Ignoring Migration Order

**Wrong:**
```swift
// DON'T: normalizeSelection before ensureMinimumProfile
normalizeSelection()  // May try to select from empty profiles
ensureMinimumProfile()
```

**Right:**
```swift
// DO: Ensure profiles exist before selection validation
ensureMinimumProfile()
normalizeSelection()
```

### ❌ Breaking Idempotency

**Wrong:**
```swift
// DON'T: Always mutates state
private func migration() -> Bool {
    state.profiles.append(defaultProfile)
    return true  // Adds duplicate on second run
}
```

**Right:**
```swift
// DO: Check before mutating
private func migration() -> Bool {
    guard state.profiles.isEmpty else { return false }
    state.profiles.append(defaultProfile)
    return true
}
```

## Future Enhancements

### Phase 2: Extract Migrations

When schema complexity increases, consider extracting to `SettingsMigrations.swift`:

```swift
struct SettingsMigrations {
    static func applyCatalogUpdates(to state: inout FareProfileSettings) -> Bool {
        // Move implementation from SettingsStore
    }

    static func ensureMinimumProfile(in state: inout FareProfileSettings) -> Bool {
        // Move implementation from SettingsStore
    }

    static func normalizeSelection(in state: inout FareProfileSettings) -> Bool {
        // Move implementation from SettingsStore
    }
}
```

**Trigger conditions:**
- Bumping to schema v3 with complex migrations
- Need for version-specific transformations
- Migration testability becomes an issue

### Phase 3: Protocol-Based System

Only implement if migration complexity significantly increases:

```swift
protocol SettingsMigration {
    var targetVersion: Int { get }
    func canApply(fromVersion: Int) -> Bool
    func apply(to settings: inout FareProfileSettings) throws
}

struct SettingsMigrationEngine {
    private let migrations: [SettingsMigration]

    func migrate(_ settings: inout FareProfileSettings) throws {
        // Apply migrations in sequence
    }
}
```

**Trigger conditions:**
- 3+ schema migrations in 6 months
- Complex migration dependencies
- Need for rollback capability

## Summary

**Current approach:** Simple, functional, well-documented
- Migration logic in SettingsStore.load()
- Graceful backward compatibility via decodeIfPresent
- Append-only catalog updates
- Profile versioning preserves history

**Migration checklist:**
- ✓ Migrations are idempotent
- ✓ Default values for new fields
- ✓ Catalog version bumped when adding cities
- ✓ Schema version bumped when changing structure
- ✓ Tests verify migration paths
- ✓ Order dependencies documented

**When in doubt:**
- Favor graceful defaults over complex migrations
- Test with old data files
- Document WHY, not just WHAT
- Keep it simple until complexity demands abstraction
