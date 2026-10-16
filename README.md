# Carwaan

Flutter ride-sharing app. Maps and Firebase on Android are configured with local environment variables so API keys are not committed.

## Configure API keys

1. Copy the example env file:

   ```bash
   cp .env.example .env
   ```

2. Replace the placeholder values in `.env`:

   | Variable | Purpose |
   | --- | --- |
   | `GOOGLE_MAPS_API_KEY` | Android Maps SDK meta-data (`com.google.android.geo.API_KEY`) |
   | `FIREBASE_API_KEY` | Firebase API key (`current_key` in the generated `google-services.json`) |
   | `GOOGLE_OAUTH_CLIENT_ID` | Android `googleClientId` manifest placeholder |

   Create or restrict these in [Google Cloud Console](https://console.cloud.google.com/) and the Firebase console. Prefer API key restrictions (Android package `com.example.carwaan`, and only the APIs this app uses).

3. Build or run as usual (`flutter run`, `flutter build apk`). Gradle reads `../.env` from the `android/` project (the repo root) when the app module is configured.

A variable already exported in the shell overrides the same name in `.env`. That is the setting to use on CI.

If a variable is missing, configuration still succeeds. Maps then has an empty key, and Firebase gets the non-secret fallback `MISSING_FIREBASE_API_KEY`, so those SDKs will not accept requests until you set real values.

`android/app/google-services.json` is generated from `android/app/google-services.json.example` and is gitignored. Edit the example only to change non-secret project fields. Put the API key in `.env`, not in the example. Do not commit `.env` or the generated JSON.

Keys that were previously committed are still in git history. Restrict or rotate them in Google Cloud Console; deleting them from the current tree does not invalidate the old values.
