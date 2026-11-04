# Force update release setup

The Android/iOS app reads Firebase Remote Config string parameter
`app_update_policy`. Paste `app_update_policy.json` as its JSON value and publish.
The initial minimum is **1.0.3**, latest **1.0.4**, separately for each platform.
No minimum is compiled into app logic. `latest_version` is validated metadata;
only `minimum_version` controls access.

This repository has no Firebase project registration or published Store listing.
Register the existing Android application ID and iOS bundle ID in your Firebase
project. Provide these Firebase app settings using `--dart-define` or a
`--dart-define-from-file` JSON file, separately for each platform:

- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID` (platform-specific Firebase app ID)
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`

The app initializes Firebase explicitly with those options; no Google Services
Gradle plugin or bundled native config is needed for Remote Config. If a default
Firebase app is already initialized, it is reused. For the Android release
workflow, set repository variable `FIREBASE_ANDROID_CONFIG` to a JSON object with
those four keys. The workflow passes it to the Flutter build. Do not use service
account credentials as app configuration.

Populate `store_url` with the actual HTTPS Google Play listing
(`play.google.com/store/apps/details?id=...`) or Apple App Store listing
(`apps.apple.com/.../id...`). Empty URLs are accepted during setup: if enforcement
is enabled without a listing, the update screen stays blocked and displays an
unavailable message. Publish and verify the listing **before raising the minimum**.

Release with tag `v1.0.4` using the existing release workflow; pubspec version is
intentionally unchanged. Once 1.0.5 is available to everyone, change both the
minimum and latest fields to at least 1.0.5 for the applicable platform and publish.
Do not raise the minimum beyond the version available to the affected users.

The app checks on startup and once after each background session. Firebase
fetches are limited to once per hour; foreground rebuilds do not fetch. A fetch
has a five-second Firebase timeout and an eight-second caller timeout. Only a
validated policy is saved in a dedicated, non-backup shared-preferences key.
Failures/malformed values retain the last valid policy, including offline blocks.
With no valid cached policy (or no readable installed version), access is allowed.
A new installation offline cannot learn a newly raised minimum. Changing Remote
Config does not affect old app builds that predate this mechanism (including
existing 1.0.3 installations).

To recover from an incorrect block, publish a corrected policy and reopen/resume
the app after the Firebase fetch interval. Do not rely on this client-side gate
as server-side authorization or a security boundary.
