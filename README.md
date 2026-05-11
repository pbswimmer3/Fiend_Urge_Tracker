# Fiend — Urge & Recovery Tracker

A privacy-first iOS app for tracking urges, sobriety time, and recovery patterns. Built with SwiftUI, SwiftData, Swift Charts, MapKit, WidgetKit, and Apple Speech. All data stays on-device; the only thing that leaves your phone is the LLM counselor request (and only if you turn it on and supply your own key).

## Requirements

- **Xcode 15** or newer (SwiftData + iOS 17 APIs)
- **iOS 17.0+** deployment target
- A free Apple ID works for side-loading the main app (7-day signing)
- A paid Apple Developer account ($99/yr) is required for the **widget extension** and **App Group** entitlement — those features can be skipped on a free account

## Quick start — put it on your iPhone

1. `open Fiend.xcodeproj`
2. Target → **Signing & Capabilities** → set your Team and a unique `PRODUCT_BUNDLE_IDENTIFIER` (e.g. `com.yourname.fiend`).
3. Plug in your iPhone, pick it as the destination, hit **⌘R**.
4. First launch: **Settings → General → VPN & Device Management → trust your Apple ID**.

The app and all features except home-screen widgets will work on a free Apple ID. The widget extension needs to be added manually — see "Enabling widgets" below.

## What's in v1.1

### Features
- **Onboarding** — medical disclaimer, habit name, your "why," clean start date, sober dividend, location permission, optional "mark current spot as Home."
- **Sleek home screen** — sober-days badge with start date, ring-style countdown with milestone progress, "Why I'm doing this" card, milestone tracker (last + next + time-to-go), one-tap urge button, today summary, recent activity with delete via context-menu, link to full history.
- **One-tap Urge logger** — animated 1–5 intensity, HALT/emotional tags, optional notes, automatic timestamp + coordinate.
- **Refocus** — auto-launches at intensity 4/5: 4-7-8 breathing pacer **or** 5-4-3-2-1 grounding. Grounding now requires **voice input** (must speak the required number of items before "Next" enables).
- **Slip logger** — 40-char minimum reflection, optional clean-date reset.
- **History view** — list all urges and slips, swipe-to-delete on each.
- **Dashboard** — time-of-day heatmap, weekday trends, urge wave (rolling avg), refocus success ring, on-device danger-zone map, sober dividend, contextual correlation card.
- **Milestone system** — 25 milestones from 12 hours to 5 years. Home page shows last + next; the first launch after crossing one triggers a fullscreen confetti celebration; opt-in local notifications fire on each milestone.
- **Notifications** — peak-time daily alert (30 min before your most-frequent hour) and peak-location alerts (CoreLocation region monitoring around your danger zones). Toggleable per-feature.
- **LLM Counselor (BYOK)** — Anthropic Claude via your own API key (stored in Keychain). Daily digest summarizes likely symptoms and what people on the same day report. Refreshes once a day, manual refresh available.
- **Home-screen widgets** — small/medium/large sobriety widget (days clean + next milestone) and a milestone-only widget. See setup below.
- **Settings** — edit clean date, why, home location, sober-dividend assumptions, notification toggles, API key, privacy policy, medical disclaimer, view/delete data, erase all.

### Bug fixes from v1.0
- "Clean days in last 30" now reads **0** on a fresh install (was incorrectly showing 30 due to slip-based counting only).
- Grounding "Next" button is now clearly visible (was using subtle SoftButtonStyle on a dark gradient) and is gated by voice input.

## Architecture

```
Fiend/
├── FiendApp.swift                     // @main, ModelContainer, milestone-celebration gate
├── Models/                            // @Model SwiftData entities + value types
│   ├── UrgeLog.swift
│   ├── Slip.swift
│   ├── UserProfile.swift              // adds why, home loc, notifications, BYOK flag, milestone tracking
│   └── Milestone.swift                // pure value type — milestone table
├── Services/                          // pure logic, no views
│   ├── LocationService.swift          // CoreLocation, async one-shot
│   ├── AnalyticsEngine.swift          // stateless analytics
│   ├── MilestoneService.swift         // milestone math
│   ├── NotificationService.swift      // peak-time + region + milestone alerts
│   ├── KeychainService.swift          // BYOK key storage
│   ├── LLMService.swift               // protocol + AnthropicCounselor implementation
│   ├── SpeechService.swift            // on-device speech recognition for grounding
│   └── WidgetBridge.swift             // app-group snapshot for WidgetKit
├── DesignSystem/Theme.swift
├── Features/
│   ├── Onboarding/
│   ├── Home/                          // HomeView + SoberCountdownView + HomeCards
│   ├── Logger/
│   ├── Refocus/                       // voice-gated grounding
│   ├── Slip/
│   ├── History/                       // list + swipe delete
│   ├── Counselor/                     // BYOK LLM digest
│   ├── Milestones/                    // celebration overlay
│   ├── Dashboard/
│   └── Settings/
├── Assets.xcassets
├── Info.plist                         // adds mic, speech, location-always strings
└── Fiend.entitlements                 // App Group for widgets
FiendWidgets/                          // widget extension (manual setup — see below)
├── FiendWidgetsBundle.swift
├── SobrietyWidget.swift
├── Info.plist
└── FiendWidgets.entitlements
```

### Why these choices

- **SwiftUI + SwiftData.** Modern Apple stack. SwiftData is migration-friendly and CloudKit-ready if we ever want sync.
- **Feature folders, not MVC stacks.** Each feature owns its views and local state. No cross-feature imports.
- **Pure-function services.** `AnalyticsEngine` and `MilestoneService` are structs/enums with no I/O — easy to unit-test and easy to swap out for a server-backed equivalent later.
- **`LLMService` is a protocol.** `AnthropicCounselor` is the default; swapping in OpenAI, a local model, or a managed subscription service is one new file.
- **Keychain for the BYOK key.** Never in UserDefaults, never in the SwiftData store, never logged.
- **`SpeechService` is its own `@MainActor` ObservableObject.** Used today by grounding; reusable later for voice slip-reflection or hands-free urge logging.
- **`WidgetBridge` writes a flat JSON snapshot to an App Group.** Widgets read the same blob. Lets us extend the widget surface area without touching SwiftData migrations.

## Enabling widgets (manual step)

Widget extensions require their own target. To keep the project file portable across signing setups (free Apple IDs don't get App Groups), the widget target is not in the pbxproj by default. You can wire it up in two minutes:

1. In Xcode, **File → New → Target → Widget Extension**. Name it **FiendWidgets**, bundle id `com.yourname.fiend.FiendWidgets`. Uncheck "Include Configuration Intent."
2. Xcode will create a starter file; delete the auto-generated Swift file and the new Info.plist.
3. Right-click the `FiendWidgets` group → **Add Files** → pick the existing `FiendWidgets/` folder in the repo. Make sure target membership is set to **FiendWidgets**.
4. Set the target's **Info.plist** to `FiendWidgets/Info.plist` and **Code Signing Entitlements** to `FiendWidgets/FiendWidgets.entitlements`.
5. Add the **App Groups** capability to both `Fiend` and `FiendWidgets` targets, with the same group id `group.com.fiendapp.fiend` (or change both to your own).
6. Build and run on device. Long-press the home screen → "+" → search "Fiend."

If you only want a free-signing personal build, skip steps 1–6 entirely. The main app works without widgets.

## Path to App Store

| Item | What it takes |
| --- | --- |
| Apple Developer Program | $99/yr, App Store Connect record |
| App Icon | drop a 1024×1024 PNG into `Assets.xcassets/AppIcon.appiconset` |
| Privacy labels | "Data Not Collected" — declare LLM key usage if BYOK enabled |
| Medical disclaimer | already in onboarding + Settings |
| Location strings | already in Info.plist (verbatim from spec) |
| Mic + speech strings | already in Info.plist |
| Notification permission | requested only when user enables the relevant toggle |
| iCloud sync | flip `cloudKitDatabase:` on the SwiftData ModelConfiguration; add entitlement |
| LLM counselor as subscription | swap `KeychainService.get` for a server-issued token; rest of the architecture stays the same |
| Accessibility pass | run Xcode Accessibility Inspector; tap targets are already ≥44pt |
| TestFlight | archive → distribute → invite |

## Feature map → spec

| Spec item | Implementation |
| --- | --- |
| One-tap urge logger | `HomeView` → `UrgeLoggerView` |
| 1-5 intensity slider | animated intensity ring in `UrgeLoggerView` |
| HALT / emotional tags | `EmotionalTag` enum + adaptive chip grid |
| Automatic timestamp + geolocation | `UrgeLog.init` + `LocationService.oneShotLocation()` |
| EMI refocus (intensity 4/5) | `RefocusView` — 4-7-8 pacer + voice-gated 5-4-3-2-1 grounding |
| Compassionate sobriety counter | `SoberCountdownView` + `SoberDaysBadge` |
| Slip log + clean-days-of-30 | `SlipLoggerView` + `AnalyticsEngine.cleanDaysInLast30(cleanStart:)` |
| Time-of-day heatmap | `HourHeatmapView` |
| Day-of-week trends | `WeekdayChartView` |
| Trigger location map / danger zones | `DangerZoneMapView` + `AnalyticsEngine.dangerZones` |
| Refocus success rate | `SuccessRateView` |
| Urge wave predictor | `UrgeWaveView` |
| Contextual correlation card | `CorrelationInsightCard` + `AnalyticsEngine.topCorrelation` |
| Sober dividend | `SoberDividendView` |
| Delete individual urges + slips | `HistoryView` swipe + `HomeView` context menu |
| Peak-time + peak-location notifications | `NotificationService` with daily trigger + region monitoring |
| Mark Home location | Onboarding toggle + Settings button |
| LLM counselor BYOK | `CounselorView` + `AnthropicCounselor` + `KeychainService` |
| Milestones (last + next, celebration, notifications) | `MilestoneService` + `MilestoneCelebrationView` + `MilestoneTrackerCard` + `NotificationService.scheduleUpcomingMilestoneAlerts` |
| Home widgets | `FiendWidgets/` (manual target setup) |
| Why card | `WhyCard` + `WhyEditor` + onboarding step |
| Sleek countdown graph | `SoberCountdownView` — angular gradient ring + numeric ticker |
| Sober days badge | `SoberDaysBadge` |
| Location permission copy | Info.plist `NSLocationWhenInUseUsageDescription` |
| Medical disclaimer | Onboarding gate + Settings sheet |
| Privacy policy | Settings sheet + `PRIVACY_POLICY.md` |

## Reset / erase

Settings → **Erase all data** removes every urge and slip on-device. Deleting the app also wipes the SwiftData store.

## License

Personal use. Add a LICENSE file before public distribution.
