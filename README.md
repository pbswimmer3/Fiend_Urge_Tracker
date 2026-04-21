# Fiend — Urge & Recovery Tracker

A privacy-first iOS app for tracking urges, sobriety time, and recovery patterns. Built with SwiftUI, SwiftData, Swift Charts, and MapKit. All data stays on-device.

## Status

Working v1. Ships with onboarding, one-tap urge logger, breathing/grounding interventions, slip logger with reflection, and a full analytics dashboard (time-of-day heatmap, weekday trends, urge wave, refocus success rate, on-device danger-zone map, sober dividend, contextual correlations).

## Requirements

- **Xcode 15** or newer (uses SwiftData and iOS 17 APIs)
- **iOS 17.0+** deployment target
- A free Apple ID will work for side-loading to your own iPhone (7-day signing), or an Apple Developer account ($99/yr) for 1-year signing and eventual App Store submission

## Quick start — put it on your iPhone

1. Clone the repo and open the project:
   ```sh
   git clone <repo-url>
   cd Fiend_Urge_Tracker
   open Fiend.xcodeproj
   ```
2. In Xcode, select the **Fiend** target → **Signing & Capabilities**.
3. Change `PRODUCT_BUNDLE_IDENTIFIER` to something unique to you (e.g. `com.yourname.fiend`).
4. Under **Team**, choose your Apple ID / developer team.
5. Plug in your iPhone. Trust the Mac if prompted.
6. In the Xcode run-destination selector at the top, pick your iPhone.
7. Hit **⌘R**.
8. On first launch, iOS will refuse to open the app until you trust the developer profile: **Settings → General → VPN & Device Management → [your Apple ID] → Trust**.

> Note on free Apple IDs: the app's provisioning profile expires after 7 days. Re-run from Xcode to renew, or upgrade to a paid developer account for 1-year signing.

## Architecture

The project is organized for scale so going from personal side-loaded build to App Store release is a configuration change, not a rewrite.

```
Fiend/
├── FiendApp.swift              // @main, ModelContainer, root routing
├── Models/                     // @Model SwiftData entities
│   ├── UrgeLog.swift
│   ├── Slip.swift
│   └── UserProfile.swift
├── Services/                   // pure logic, no views
│   ├── LocationService.swift   // CoreLocation wrapper, @MainActor, async/await
│   └── AnalyticsEngine.swift   // stateless analytics over fetched data
├── DesignSystem/               // design tokens + reusable components
│   └── Theme.swift
├── Features/                   // one folder per feature
│   ├── Onboarding/
│   ├── Home/
│   ├── Logger/
│   ├── Refocus/
│   ├── Slip/
│   ├── Dashboard/
│   └── Settings/
├── Assets.xcassets
└── Info.plist
```

### Why these choices

- **SwiftUI + SwiftData.** Modern Apple stack. SwiftData is migration-friendly and CloudKit-ready if we ever want sync.
- **Feature folders, not MVC stacks.** Each feature owns its views and local state. No cross-feature imports. Makes it easy to extract features into modules later.
- **AnalyticsEngine is a pure struct.** Input: arrays of models. Output: value types. No Swift-UI, no storage. Swap in a server backend later without touching UI.
- **LocationService is an `ObservableObject` singleton** with an `async/await` one-shot API. When we add background tracking or replace CoreLocation, only this file changes.
- **Theme is a namespace, not a Color asset set.** Faster to iterate during personal-use phase. For App Store we will move the palette to the asset catalog for free dark-mode compliance reviews.

## Path to App Store

Here is the upgrade checklist when you're ready to ship to customers. Nothing below requires a rewrite — each bullet maps to a narrow change.

1. **Apple Developer Program.** Sign up ($99/yr), create an App ID matching your bundle id, register the app on App Store Connect.
2. **App Icon + launch assets.** Drop a real 1024×1024 PNG into `Assets.xcassets/AppIcon.appiconset`. The empty set is already wired up.
3. **Privacy labels + policy URL.** App Store Connect → App Privacy. All data is on-device, so you'll declare "Data Not Collected" for every category. Host `PRIVACY_POLICY.md` at a public URL and paste it into App Store Connect.
4. **Medical disclaimer.** Already surfaced during onboarding and in Settings. Apple reviewers look for this — it's there.
5. **Location usage string.** Already in `Info.plist` under `NSLocationWhenInUseUsageDescription`. Reads exactly as recommended by the spec.
6. **Accessibility pass.** Run Xcode's Accessibility Inspector; tap-targets are already ≥44pt; verify VoiceOver labels on the intensity slider and tag chips.
7. **iCloud sync (optional).** SwiftData's `ModelConfiguration` accepts `cloudKitDatabase:`. Flip it on, add an iCloud entitlement, and you're syncing across the user's devices with zero server code. Opt-in only.
8. **Authentication (if/when needed).** If you ever add account-based features, the architecture assumes unauthenticated-by-default. A single `AuthService` beside `LocationService` is the insertion point.
9. **Analytics/telemetry.** Keep this minimal and transparent; if you add any first-party analytics, wire a feature flag and default it off.
10. **TestFlight.** Archive from Xcode → distribute to App Store Connect → invite beta testers. Same binary becomes your submission candidate.

## Feature map → spec

| Spec item | Implementation |
| --- | --- |
| One-tap urge logger | `HomeView` big button → `UrgeLoggerView` |
| 1-5 intensity slider | `UrgeLoggerView` with animated intensity ring |
| HALT / emotional tags | `EmotionalTag` enum + adaptive chip grid |
| Automatic timestamp + geolocation | `UrgeLog.init` + `LocationService.oneShotLocation()` |
| EMI refocus (intensity 4/5) | `RefocusView` (4-7-8 breathing pacer + 5-4-3-2-1 grounding) |
| Compassionate sobriety counter | `HomeView.sobrietyHero` with TimelineView |
| Slip log + clean-days-of-30 | `SlipLoggerView` + `AnalyticsEngine.cleanDaysInLast30` |
| Time-of-day heatmap | `HourHeatmapView` (Swift Charts) |
| Day-of-week trends | `WeekdayChartView` |
| Trigger location map / danger zones | `DangerZoneMapView` + `AnalyticsEngine.dangerZones` (on-device grid clustering) |
| Refocus success rate | `SuccessRateView` |
| Urge wave predictor | `UrgeWaveView` (7-day rolling avg) |
| Contextual correlation card | `CorrelationInsightCard` + `AnalyticsEngine.topCorrelation` |
| Sober dividend | `SoberDividendView` |
| Clinical-but-warm aesthetic | `Theme` (deep blues, soft greens, rounded cards) |
| Dark mode | `UIUserInterfaceStyle = Automatic` + semantic colors |
| Location permission copy | `NSLocationWhenInUseUsageDescription` in `Info.plist` |
| Medical disclaimer | Onboarding gate + Settings sheet |
| Privacy policy | Settings sheet + `PRIVACY_POLICY.md` |

## Reset / erase for personal testing

Settings → **Erase all data** removes every urge and slip on-device. Deleting the app also wipes the SwiftData store.

## License

Personal use. Add a LICENSE file before public distribution.
