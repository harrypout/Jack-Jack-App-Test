# TestFlight upload walkthrough

Prepared 20 September 2026 for the reliability and meter amendments.

## Current candidate

- Working folder: `/Users/Harry/Projects/jackjack`.
- GitHub repository: `harrypout/Jack-Jack-App-Test`.
- Branch: `codex/regression-test-baseline`.
- Flutter: **3.41.4**; retain `pubspec.lock`, `ios/Podfile.lock` and the existing BLE/SwiftProtobuf pins.
- Full preflight: **106 tests pass** on 20 September; strict core analysis passes.
- The local `.env` contains real BLE identifiers. All six active service/characteristic pairs match both supplied August firmware source variants. It is ignored by Git.
- Current source version: **1.0.2+4**. Choose the next unused build only after inspecting App Store Connect.
- App identity still requires App Store Connect verification: Git config uses `com.jackjack`; the previous local archive and historical handoff use `com.jackjack1234`. Local signing profiles exist for both under **Jack Jack Pty Ltd / L9MCWXCMY7**. The old project team setting must be aligned with the verified app before archiving.
- Physical iPhone/Pebble acceptance is **not run**. This TestFlight candidate will be used to perform it.

## 1. Confirm the existing Apple app

Sign in to [App Store Connect](https://appstoreconnect.apple.com/), open **Apps → the existing Jack Jack app** and check:

- **App Information → Bundle ID**.
- **TestFlight → iOS → latest uploaded version and build**, including builds still processing.
- The selected organization is **Jack Jack Pty Ltd**.

Record these values here when verified. Use the existing app record so the upload reaches the current testers.

## 2. Save and push the tested source

Commit the amendments on the candidate branch and push it to GitHub. The **Validate Jack Jack** workflow runs tests, an unsigned iOS simulator compile and an Android debug compile. Its synthetic `.env` is for CI only; its outputs are unsuitable for device distribution.

Build the TestFlight archive from this working folder with the real `.env`. Preserve the uploaded Git commit in the acceptance record. A Git push saves the source; the Apple upload is a separate operation.

## 3. Set the version and signing

Update `version:` in `pubspec.yaml` after confirming Apple's build history. For example, **1.0.2+5** is suitable only if **1.0.2 (4)** is the latest build and build 5 has not been used. If Apple already has a later marketing version, use that version or the next intended version instead.

Open `/Users/Harry/Projects/jackjack/ios/Runner.xcworkspace` in Xcode. Select the **Runner app target → Signing & Capabilities**, enable automatic signing, and use the verified bundle ID and **Jack Jack Pty Ltd** team for the app's build configurations. Resolve any account sign-in prompt in Xcode's **Settings → Accounts**. Keep credentials out of the repository and chat.

Commit and push the confirmed version/signing changes before making the final archive.

## 4. Create the release archive

From the project folder, using Flutter 3.41.4:

```bash
flutter pub get --enforce-lockfile
dart run build_runner build --delete-conflicting-outputs
flutter build ipa --release --export-method app-store
```

This creates an archive in `build/ios/archive/` and, when export succeeds, an IPA in `build/ios/ipa/`. If signing/export fails, keep the log and resolve the exact reported issue; do not delete the dependency locks or create a different Apple app to bypass the error.

## 5. Validate and upload

Open the newly created `.xcarchive` in Xcode Organizer. Confirm its version, build, bundle ID and team against step 1, then **Validate App**. After validation succeeds, use **Distribute App → App Store Connect → Upload** (the current Organizer may offer a direct App Store Connect distribution choice). Keep symbol upload enabled.

If using **TestFlight Internal Only**, that archive can only be assigned to internal testers. Use the ordinary App Store Connect upload when the intended tester group is external. Existing tester groups can have automatic distribution enabled, so check group settings before uploading when access needs to remain limited.

Uploading to App Store Connect does not submit the app for a public App Store release.

## 6. Make it available in TestFlight

Wait for Apple processing to finish. In the app's **TestFlight** tab, open the new build and check for processing, compliance or other outstanding messages. The app currently declares `ITSAppUsesNonExemptEncryption = false`; assess any new Apple question against the actual app rather than automatically accepting a different declaration.

Add the build to the intended existing tester group and add the notes below. External testing may require Beta App Review. On the iPhone, open TestFlight, select Jack Jack, install/update, and verify that the displayed version/build is the new one.

## What to Test

This build improves Bluetooth reconnection, threshold saving, alert controls, battery warnings, notification history and the sound-level meter. Fonts are bundled for offline use. Live listening is hidden in this milestone.

Please check:

1. Connect a Pebble, save a threshold and confirm it remains after a device power cycle.
2. Trigger sound alerts with the app visible, the screen locked and another app open; check notification history and repeat timing.
3. Move out of Bluetooth range and back, then turn Bluetooth off and on; confirm monitoring and alerts recover.
4. Turn Alerts off; confirm phone banners, sound and vibration stop while history continues. Turn Alerts back on.
5. Check meter rise/fall, missing-reading state, battery refresh and two-device selection where hardware is available.

Record the app build, iPhone/iOS version, Pebble microphone and exact installed firmware, together with actual results, in [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md). Complete its longer overnight, permission and interruption checks before broader release sign-off.

## References

- [Flutter's iOS archive and TestFlight guide](https://docs.flutter.dev/deployment/ios).
- [Apple: Upload builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).
- [Apple: Add testers to builds](https://developer.apple.com/help/app-store-connect/test-a-beta-version/add-testers-to-builds/).
