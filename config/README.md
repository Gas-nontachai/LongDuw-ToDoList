# Optional update release setup

The Android/iOS app reads Firebase Remote Config string parameter
`app_update_policy`. Paste `app_update_policy.json` as its JSON value and publish.
The app compares its installed version to `latest_version` for its platform.
It shows a dismissible banner with Update Now and Later actions. Startup,
back navigation, deep links, and offline use are never blocked. Dismissal lasts
for this app session for the advertised version; a newer version may be shown.
`minimum_version` is a legacy field and is ignored, even in old cached policies.

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
(`apps.apple.com/.../id...`). When the URL is empty, the Update Now button is
disabled and Later remains available. No production listing is invented.

The initial `app_update_policy.json` advertises 1.0.4. The separate
`app_update_policy.1.0.5.json` advertises 1.0.5. Both keep the legacy minimum at
1.0.3. Publish the appropriate JSON value only after the advertised release is
available through its real Store listing. Committing the files or pushing a Git
tag does not publish Remote Config. The pubspec app version is unchanged.

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
Failures/malformed values retain the last valid update information. With no
valid policy or installed version, the notice stays hidden. Slow network checks
never delay application startup. Existing cached force-update policies are treated
only as optional latest-version notices by this build. Older released builds
retain their own behavior until users install the new build.
