# Atia Jame Masjid Accounts App: Progress

## RESUME HERE

- **Last updated:** 2026-11-13 (session start)
- **Current phase / step:** Phase 0, step 0.1 (project scaffolding, dependencies)
- **Exact next action:** Finish `flutter pub add` of dependencies (running), verify `flutter pub get` works, commit "chore: scaffold Flutter project". Then build the Phase 0 risk proofs (Bangla PDF, Drive interface, Wi-Fi sync loopback, updater check).
- **Half-done / broken:** nothing yet.
- **Verify commands:**
  - `cd /Users/nasim/Documents/Projects/Personal/AtiaJameMasjid`
  - `flutter pub get && flutter analyze`
  - `flutter test`
  - run macOS: `flutter run -d macos`; Android emulator: `flutter run -d emulator-5554`

## Phase checklist

| Phase | Name | Status | Finished |
|---|---|---|---|
| 0 | Set-up and risk checks | in progress | |
| 1 | Foundation: database, sign-in, language | not started | |
| 2 | Income and expense | not started | |
| 3 | Balance, summary, PDF | not started | |
| 4 | Google Drive: backup and Excel | not started | |
| 5 | Updates and installers | not started | |
| 6 | Android app and sync | not started | |
| Review | 3+ review/fix cycles | not started | |

## Requirement tracker

(To be filled as phases complete. Statuses: todo / partial / done / blocked.)

## Screen tracker

Source: design artifact https://claude.ai/artifact/RTKSQa6taiYR82S5cRzDgX (47 boards; macOS boards are the same screens in a macOS window).

| Screen | Platform | Phase | Status |
|---|---|---|---|
| Setup (first launch: create Super Admin or restore) | Desktop | 1 | todo |
| Sign in | Desktop | 1 | todo |
| Dashboard (+ English) | Desktop | 3 | todo |
| Income list | Desktop | 2 | todo |
| Add income (duplicate warning, date picker) | Desktop | 2 | todo |
| Income details | Desktop | 2 | todo |
| Photo viewer | Desktop | 2 | todo |
| Expense list | Desktop | 2 | todo |
| Add expense | Desktop | 2 | todo |
| Expense details (cancelled) | Desktop | 2 | todo |
| Admin approval dialog | Desktop | 2 | todo |
| Cancel entry dialog | Desktop | 2 | todo |
| Summary | Desktop | 3 | todo |
| PDF report | Desktop | 3 | todo |
| Excel upload | Desktop | 4 | todo |
| Phone sync QR | Desktop | 6 | todo |
| Users | Desktop | 1 | todo |
| Add user | Desktop | 1 | todo |
| Backup and restore | Desktop | 4 | todo |
| Settings (language, opening balance, approvers, password, update) | Desktop | 1 | todo |
| Update available dialog | Desktop | 5 | todo |
| Pair with desktop | Android | 6 | todo |
| Sign in | Android | 6 | todo |
| Home (this phone only) | Android | 6 | todo |
| Income list / Expense list | Android | 6 | todo |
| Add income / Add expense | Android | 6 | todo |
| Details (synced read-only) | Android | 6 | todo |
| Photo viewer | Android | 6 | todo |
| Admin approval sheet | Android | 6 | todo |
| Summary (this phone only) | Android | 6 | todo |
| PDF report | Android | 6 | todo |
| Scan desktop QR | Android | 6 | todo |
| Sync finished | Android | 6 | todo |
| More (language, password, sign out) | Android | 6 | todo |

## Log (newest first)

- 2026-11-13: Session started. No progress file existed. Read requirements, plan, test cases list, design artifact (palette: primary #0F5C46, dark #0F3D30, bg #F4F6F3, expense #9A3709, font Hind Siliguri). `flutter create` for macos, windows, android done. Added dependencies.

## Review cycles

(none yet)

## Assumptions

- Drive backups: the requirements say keep one year (BAK-7). The task text mentions a default of 10; the requirements doc is the source of truth, so one year is used.
- State management: `provider` (ChangeNotifier), chosen for simplicity.
- Password hash: bcrypt (pure Dart, works on all three platforms).
- Phone notifications: PushNotification is skipped by the tool while the terminal is active; milestones are still attempted.

## Known gaps / needs a human

- Windows: not run (cannot build on a Mac).
- Google Drive: not verified against real Google (no credentials).
- Windows auto-updater: cannot be proven here.

## Environment

- Flutter 3.44.5, Dart 3.12.2, Xcode 26.2, macOS 26.5.1.
- Android emulator `emulator-5554` (API 36) running. AVDs: Managed_Test, Phone_1, Phone_2. Android SDK licences status "unknown" in `flutter doctor`.
- Packages: see pubspec.yaml.
