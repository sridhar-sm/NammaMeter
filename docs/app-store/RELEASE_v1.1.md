# NammaMeter v1.1 — App Store Update Guide

**Date:** February 17, 2026
**App Version:** 1.1
**Previous Version:** 1.0

---

## Release Notes (paste into App Store Connect)

```
NammaMeter 1.1 - Fare Transparency & Refined Layouts

NEW FEATURES:
- Fare rules engine — see which fare rules apply during your trip in real time
- Fare breakdown on trip completion — view itemised charges when a trip ends
- Active rule highlighting — clearly shows base fare, distance, waiting, and surcharge components

UI IMPROVEMENTS:
- Simplified square meter layouts for a cleaner look
- Landscape orientation support
- Removed visual decorations for improved readability
```

---

## Description Updates

Two new bullet points added to the **ACCURATE FARE CALCULATION** section:
- "Fare rules engine with active rule highlighting"
- "Itemised fare breakdown on trip completion"

One new bullet added to **CUSTOMIZABLE EXPERIENCE**:
- "Portrait and landscape orientation support"

---

## Screenshots (action needed)

Screenshots need to be **recaptured** before submitting v1.1. The meter layouts changed significantly:

- Meters are now **square** proportions
- Visual **decorations removed** (cleaner look)
- **Landscape mode** is new and should be shown
- **Fare breakdown** at trip completion is a new state worth capturing

See `SCREENSHOTS_MANIFEST.md` for the full list of recommended new screenshots.

---

## Documents Updated (9 files)

| File | Changes |
|------|---------|
| `APP_STORE_SUBMISSION_TEXT.md` | v1.1 release notes, feature bullets, roadmap, testing notes, version ref |
| `APPSTORE_QUICK_COPY.txt` | v1.1 release notes, feature bullets, marketing copy |
| `APPSTORE_MARKETING_VARIATIONS.md` | v1.1 release notes, roadmap shifted, differentiators added |
| `INDEX.md` | v1.1 roadmap, version ref, date |
| `README.md` | Version history table, date |
| `PRIVACY_POLICY.md` | Version refs, version history table |
| `PRIVACY_POLICY_SHORT.txt` | Version ref |
| `LEGAL_AND_RIGHTS.md` | Version ref |
| `SCREENSHOTS_MANIFEST.md` | v1.1 update notice, new screenshots needed section |

---

## No Privacy/Legal Content Changes

The v1.1 features (fare rules, layout changes) don't change any data collection or processing practices, so the privacy policy and legal docs only needed version number bumps.

---

## Commits Included in v1.1

| Commit | Summary |
|--------|---------|
| `ab6d81b` | Bump application version from 1.0 to 1.1 |
| `e371974` | Simplify meter layout with square meters, landscape support, and remove decorations |
| `317d07f` | Show fare breakdown on Neo meter when trip completes |
| `eb285a1` | Add fare rules engine with active rule highlighting |
