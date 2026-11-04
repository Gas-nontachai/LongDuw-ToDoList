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
intentionally unchanged. `app_update_policy.json` remains the initial 1.0.4
rollout policy (minimum 1.0.3). The separate `app_update_policy.1.0.5.json` is a
future policy with minimum/latest 1.0.5. Fill in real Store URLs and publish that
value only after 1.0.5 is available to everyone on the applicable platform.
Do not raise the minimum beyond the version available to the affected users.
Committing these JSON files or pushing a Git tag does not publish Remote Config.

## Where to create release tags

Merge the implementation into `main` first. The workflow rejects a tag whose
commit is not an ancestor of `origin/main`. After merging the 1.0.4 changes:

```sh
git switch main
git pull --ff-only
git tag -a v1.0.4 -m "Release 1.0.4"
git push origin v1.0.4
```

For the later 1.0.5 release, merge its changes into `main` and repeat with tag
`v1.0.5`. CI derives the app version from the tag, so no pubspec version edit is
required. The existing workflow publishes a signed Android APK to GitHub Releases;
it does not upload to Google Play or build/upload iOS to the App Store.

Before tagging, configure `FIREBASE_ANDROID_CONFIG` in GitHub repository
Settings → Secrets and variables → Actions → Variables. After making the release
available through its actual Store listing, publish the appropriate policy as
`app_update_policy` in Firebase Console → Remote Config. GitHub Releases alone
will not update a Google Play or Apple App Store listing.

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
