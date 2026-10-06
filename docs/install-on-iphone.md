# Getting Fiend onto your iPhone — permanently

Findings from the repo: SwiftUI + SwiftData, iOS 17+, no package dependencies,
no backend, Automatic signing, bundle ID `com.fiendapp.fiend`, no
`DEVELOPMENT_TEAM` set. The main target already signs with
`Fiend/Fiend.entitlements` (App Group `group.com.fiendapp.fiend`), so it needs
a **paid** team: free Apple IDs cannot sign App Groups. The widget target is
**not** in the pbxproj (files are in `FiendWidgets/`). The app icon set is
empty, and App Store Connect rejects uploads without a 1024×1024 icon.

Same path as FlightDeck (`flighty-pro/docs/install-on-iphone.md`):
Xcode install to verify, then TestFlight + Xcode Cloud so it stays installed
with no Mac.

| Route | Lasts | Needs Mac each time? |
|---|---|---|
| Paid program, Xcode install | ~1 year (dev profile) | yes, to rebuild |
| **Paid program, TestFlight** | **90 days per build, renewed by each new build** | **no (with Xcode Cloud)** |

## 1. Once, when Apple approves you
1. developer.apple.com → Account: status "Active"; note the **Team ID**.
2. Accept agreements (Account → Agreements, and App Store Connect → Business).
   Apple ID 2FA on.
3. iPhone: Settings → Privacy & Security → **Developer Mode** → On → reboot.
   Plug in via USB, tap **Trust**.
4. Install **TestFlight** from the App Store on the phone.
5. Mac with Xcode 16+ for the first build.

## 2. First install via Xcode
1. `git clone https://github.com/pbswimmer3/Fiend_Urge_Tracker && open Fiend.xcodeproj`
2. Target **Fiend → Signing & Capabilities**: *Automatically manage signing*,
   **Team** = your paid team.
3. If the bundle ID is taken, use something unique (e.g. `com.<you>.fiend`)
   and change the App Group to `group.com.<you>.fiend` in **all four** places:
   `Fiend/Fiend.entitlements`, `FiendWidgets/FiendWidgets.entitlements`,
   `Fiend/Services/WidgetBridge.swift` and `FiendWidgets/SobrietyWidget.swift`
   (`appGroupID`).
4. Pick your iPhone → **Run (⌘R)**. Location, microphone/speech and
   notification prompts are expected.
5. Counselor (optional): Settings → paste your own Anthropic API key (stored
   in Keychain; nothing to configure at build time).

## 3. Widgets (optional)
Follow "Enabling widgets" in the README (File → New → Target → Widget
Extension `FiendWidgets`, add the repo's `FiendWidgets/` files, set its
Info.plist and entitlements, App Groups on both targets with the same group).
Commit the updated pbxproj so Xcode Cloud builds include the widget.

## 4. Make it permanent: TestFlight
1. Add a 1024×1024 PNG to `Fiend/Assets.xcassets/AppIcon.appiconset` (upload
   fails validation without it).
2. appstoreconnect.apple.com → Apps → **+ New App**: iOS, name, bundle ID from
   step 2, any SKU.
3. Xcode: destination *Any iOS Device (arm64)* → Product → **Archive** →
   Distribute App → **TestFlight & App Store** → Upload.
4. App Store Connect → TestFlight: wait for processing; export compliance:
   standard HTTPS only → "No" (or add `ITSAppUsesNonExemptEncryption = NO`
   to `Fiend/Info.plist` to skip the question every time).
5. TestFlight → **Internal Testing** → new group, add your Apple ID, enable
   automatic distribution. Internal builds need **no App Review**.
6. On the iPhone, open TestFlight, accept the invite, Install.

## 5. Automate with Xcode Cloud (no Mac afterwards)
1. Xcode → Product → Xcode Cloud → Create Workflow; grant access to the
   GitHub repo (install the Xcode Cloud GitHub app when prompted).
2. Start condition: push to the default branch
   (`claude/build-fiend-ios-app-Mv1ZC` today; consider renaming to `main`).
   Action: **Archive – iOS**. Post-action: **TestFlight Internal Testing**.
3. Build numbers are set by Xcode Cloud automatically.

## Keeping it alive
- TestFlight builds expire after **90 days**: push anything (or re-run the
  workflow) at least every ~2 months. A monthly reminder or Xcode Cloud
  scheduled start condition covers it.
- Developer Program renews yearly ($99); if it lapses, TestFlight apps stop.

## Troubleshooting
- "Provisioning profile doesn't support the App Groups capability": the team
  is a free Personal Team; switch to the paid team.
- "No account for team": Xcode → Settings → Accounts → re-add your Apple ID.
- Widget shows placeholder data: the app and widget App Group IDs differ.
