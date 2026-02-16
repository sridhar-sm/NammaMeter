# Snapshot Testing Guide

This project uses `swift-snapshot-testing` for visual regression tests in `NammaMeterTests/MeterSnapshotTests.swift`.

## Run Snapshot Tests

Run all tests:

```bash
xcodebuild test -scheme NammaMeter
```

Run only snapshot tests:

```bash
xcodebuild test -scheme NammaMeter \
  -only-testing:NammaMeterTests/MeterSnapshotTests
```

## Record Snapshot Baselines

Snapshot recording is controlled by `RECORD_SNAPSHOTS=1`, which must be visible inside the simulator runtime.

### 1) Pick a simulator and enable recording

```bash
DEVICE_ID="7FC6A507-C026-4B6E-B1EC-2D3FD528E6D0" # iPhone 17 Pro Max

xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
xcrun simctl spawn "$DEVICE_ID" launchctl setenv RECORD_SNAPSHOTS 1
```

### 2) Run the snapshot tests you want to update

```bash
xcodebuild test -scheme NammaMeter \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -only-testing:NammaMeterTests/MeterSnapshotTests/testDigitalForHire \
  -only-testing:NammaMeterTests/MeterSnapshotTests/testDigitalInProgress \
  -only-testing:NammaMeterTests/MeterSnapshotTests/testDigitalWaitingShowsRulesInBottomBar
```

Notes:

- `xcodebuild` exits with code `65` in record mode because snapshot assertions intentionally fail after writing new baselines.
- Look for `Record mode is on. Automatically recorded snapshot: …` in test output to confirm recording.

### 3) Turn recording off and verify

```bash
xcrun simctl spawn "$DEVICE_ID" launchctl unsetenv RECORD_SNAPSHOTS

xcodebuild test -scheme NammaMeter \
  -destination "platform=iOS Simulator,id=$DEVICE_ID" \
  -only-testing:NammaMeterTests/MeterSnapshotTests/testDigitalForHire \
  -only-testing:NammaMeterTests/MeterSnapshotTests/testDigitalInProgress \
  -only-testing:NammaMeterTests/MeterSnapshotTests/testDigitalWaitingShowsRulesInBottomBar
```

The verification run should pass with exit code `0`.

## Update Multiple Device Baselines

Repeat the record/verify flow per simulator device. Common devices used in this repo:

- `iPhone 17`
- `iPhone 17 Pro`
- `iPhone 17 Pro Max`
- `iPhone 16e`
- `iPhone 12`

## Known Warning

You may see this warning during test runs:

`Metadata extraction skipped. No AppIntents.framework dependency found.`

This is currently expected in this project.
