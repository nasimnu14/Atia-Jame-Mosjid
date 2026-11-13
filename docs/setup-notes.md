# Atia Jame Masjid Accounts App: Setup Notes

How to build and run each platform, how to set up Google Drive, and how to publish a release.

## 1. Build and run

Flutter 3.44 / Dart 3.12 (see `docs/progress/accounts-app.md`, "Environment").

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # database code (Drift)
flutter gen-l10n                                           # Bangla/English text
flutter analyze
flutter test --concurrency=3                               # more parallelism can get test processes killed
```

| Platform | Run | Build a release |
|---|---|---|
| macOS (testing only) | `flutter run -d macos` | `flutter build macos --release` |
| Windows (the mosque's PC) | `flutter run -d windows` (on a Windows PC) | `flutter build windows --release`, then package (see section 3) |
| Android 12+ | `flutter run -d <device>` | `flutter build apk --release` (needs the signing key, section 4) |

App data is stored in the per-user app-data folder, never next to the program, so installing a new
version cannot touch it:

- macOS: `~/Library/Containers/bd.atiamasjid.atiaMasjidAccounts/Data/Library/Application Support/...`
- Windows: `%APPDATA%\...` (the folder `path_provider` calls "application support")
- Android: the app's private storage

The database file is `atia_accounts.db`; photos are in `photos/<entry id>/`; copies made before an
upgrade or restore are in `backups/`.

Language: Bangla by default; switch in Settings (or on the first screen).

### Scripts and helpers

- `python3 tool/l10n_add.py` (as a module): adds a text to both `app_en.arb` and `app_bn.arb`.
- `python3 tool/progress_set.py`: updates the requirement tracker in `docs/progress/accounts-app.md`.
- Screenshots without screen-capture permission:
  `SHOT_DIR=/some/folder flutter test test/widget/screens_shot_test.dart`, then open the PNG files.

## 2. Google Drive (backup and Excel): one-time setup

The app talks to Google Drive with the **`drive.file`** permission only: it can see only the files it
created itself. This permission does not need Google's long security review (plan, Risk 3).

> **Not verified against real Google.** No Google credentials were available while building. All
> backup, restore and Excel logic is tested against a fake Drive; the real connection
> (`lib/features/google_drive/google_drive_auth.dart`) follows Google's documented flow but must be
> checked once by hand (section 2.4).

### 2.1 Create the Google Cloud project

Do this while signed in to the Google account that should **own** the project. The plan recommends
the mosque's own account (Risk 8: a university account can be closed after graduation).

1. Go to <https://console.cloud.google.com/> and create a project, e.g. "Atia Masjid Accounts".
2. **APIs & Services → Library →** search "Google Drive API" → **Enable**.
3. **APIs & Services → OAuth consent screen**:
   - User type **External** (or Internal if you have a Google Workspace).
   - App name "Atia Jame Masjid Accounts", a support e-mail, a developer e-mail.
   - Scopes: add `.../auth/drive.file` only.
   - While the app is in "Testing", add every Google account that will connect as a **test user**
     (including the university account until the mosque account takes over). Test users must
     re-sign-in about every 7 days in "Testing" mode; click **Publish app** to remove that limit
     (no Google review is needed for `drive.file`, but an "unverified app" warning is shown).

### 2.2 Create the OAuth client

1. **APIs & Services → Credentials → Create credentials → OAuth client ID.**
2. Application type: **Desktop app**. Name it "Atia Masjid Desktop".
3. Copy the **Client ID** and **Client secret**. (For a desktop app the secret is not truly secret;
   Google documents this. Still, do not commit it.)

### 2.3 Give the app its client ID

The app reads them at build time:

```bash
flutter run -d macos \
  --dart-define=GOOGLE_CLIENT_ID=1234-abcd.apps.googleusercontent.com \
  --dart-define=GOOGLE_CLIENT_SECRET=GOCSPX-xxxx

flutter build windows --release \
  --dart-define=GOOGLE_CLIENT_ID=... --dart-define=GOOGLE_CLIENT_SECRET=...
```

For releases built on GitHub, store them as repository **secrets** and pass them with
`--dart-define` in the workflow. Without them the Backup page says "Google sign-in is not set up in
this build" and nothing is uploaded.

The sign-in opens the user's browser; Google redirects back to a temporary `http://localhost:<port>`
address that the app listens on while signing in.

### 2.4 Check it once by hand (what to verify with a real account)

1. Backup page → **Connect**. The browser opens, sign in, allow. The page shows "Connected: <e-mail>".
2. Within a minute a first backup runs. In Google Drive a folder **Atia Jame Masjid Accounts** appears
   with `Backups/` (a `backup-….db.gz`), `Photos/` and `Excel/`.
3. Excel page → upload a month. Open the file in Excel: amounts and dates sort and add up; income and
   expense are on separate sheets.
4. Turn the Wi-Fi off, wait for the next attempt: the Backup page says it failed; turn Wi-Fi on: it
   succeeds within about two minutes.
5. **Restore test on a second computer** (or a fresh data folder): first screen → "Restore from a
   backup" → connect → choose the backup → sign in with the old Super Admin's password.
6. Check how much Drive storage the account has (plan, Risk 8 and 10). Photos are uploaded once;
   each backup is only the (compressed) database.

### 2.5 Switching to the mosque's own Google account later

Backup page → **Change account** → sign in with the mosque account. The app makes a full backup to the
new account at once (all photos and the database) and uploads a fresh Excel file. No new version of the
app is needed. The old account's files stay where they are.

### 2.6 Backup retention

Backups older than **one year** are deleted automatically after each new backup; the newest backup is
always kept. Photo files are never deleted from Drive, so any backup of the last year can be restored
with all its photos. (The task brief mentioned "keep 10 backups"; the requirements document says one
year and is the source of truth, so one year is implemented.)

## 3. Windows installer and updates (Phase 5)

See section 5 below once Phase 5 is done. The Windows build cannot be produced or run on a Mac; it is
built by GitHub Actions on a Windows runner, or on a Windows PC.

## 4. Android signing key (Phase 6)

Create the key once and back it up in **two safe places** with its password. Google Play will later need
the **same key** (plan, Risk 9). Details are added in Phase 6.

## 5. Publishing a release on GitHub

Filled in during Phase 5.
