# Atia Jame Masjid Accounts App: Progress

## RESUME HERE

- **Last updated:** 2026-11-14 (Phase 4 finished)
- **Current phase / step:** Phase 5, step 5.1: update check (GitHub Releases), updater, installers, release checklist
- **Exact next action:** Build Phase 5. (1) `lib/features/updates/`: `UpdateService` that reads the latest GitHub Release (JSON from `https://api.github.com/repos/<owner>/<repo>/releases/latest`, owner/repo from a `--dart-define=GITHUB_REPO=owner/name`), compares versions (semver, test it), exposes `UpdateInfo` (version, notes bn/en, windows installer url, apk url). On Windows use `auto_updater` (WinSparkle appcast feed on the release) when available; on Android download the APK and open the installer (REQUEST_INSTALL_PACKAGES already in the manifest) via a small `ApkInstaller` interface; macOS test build: check only, no installer. UI: Settings `UpdateCard` button + 'Update available' dialog (board UpdateDialog; read it first), automatic check at start (once a day) with a notice on the dashboard. (2) The pre-upgrade DB copy and rollback already exist (`openAppDatabase`, tested); add a test that a failed upgrade keeps v-old working (done in `test/data`). (3) GitHub Actions workflow `.github/workflows/release.yml` (build Windows installer with Inno Setup or MSIX? choose Inno Setup script `windows/installer/atia.iss`, macOS test zip, signed Android APK from secrets) and a release checklist in docs/setup-notes.md sections 3 and 5. Cannot be proven on a Mac: Windows build/updater; say so.
- **Half-done / broken:** nothing broken. `lib/app/section_placeholder.dart` and `lib/features/google_drive/restore_launcher.dart` are deliberate stubs to be replaced (Phase 2/3 and Phase 4). `UpdateCard` only shows the version (update check = Phase 5).
- **Verify commands:**
  - `cd /Users/nasim/Documents/Projects/Personal/AtiaJameMasjid`
  - `flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`
  - `flutter analyze` (expect: No issues found)
  - `flutter test` (expect: all pass; ~200 at end of Phase 4; run `flutter test --concurrency=3`, more parallelism gets processes killed)
  - run: `flutter run -d macos` / `flutter run -d emulator-5554`
  - Screenshots without screen-capture permission: `SHOT_DIR=<dir> flutter test test/widget/screens_shot_test.dart`, then view the PNGs.
- **Working notes:** widget tests must use `testApp(...)`, and `h.run(() => <real async write>)` (NOT bare `tester.runAsync`) whenever a screen that listens for changes is open: a listener's reload starts inside the fake clock and would hold Drift's lock while the test waits, so the test hangs forever. `TestEnv.create(onDisk: true)` in a widget test must itself run inside `tester.runAsync`. Per-test timeout is 90 s. Widget tests must use `testApp(...)` (test/helpers/app_harness.dart) and `tester.runAsync` for real async (Drift, bcrypt isolates). Add translations with `tool/l10n_add.py` (keeps both ARB files identical) then `flutter gen-l10n`; multi-placeholder args are generated in alphabetical order. Tests folder is un-ignored in `.gitignore` because the user's global gitignore ignores `test/`.

## Phase checklist

| Phase | Name | Status | Finished |
|---|---|---|---|
| 0 | Set-up and risk checks | done | 2026-11-13 |
| 1 | Foundation: database, sign-in, language | done | 2026-11-13 |
| 2 | Income and expense | done | 2026-11-13 |
| 3 | Balance, summary, PDF | done | 2026-11-13 |
| 4 | Google Drive: backup and Excel | done (real Google not verified) | 2026-11-14 |
| 5 | Updates and installers | in progress | |
| 6 | Android app and sync | not started | |
| Review | 3+ review/fix cycles | not started | |

### Phase 0 results (risk checks)

1. **Bangla PDF:** the `pdf` package breaks Bangla (unjoined conjuncts, misplaced vowel signs). Fallback chosen (plan Risk 1): draw report pages with Flutter's text engine and embed them as images. Proven in `test/proof/bangla_raster_pdf_proof_test.dart`.
2. **Google Drive:** no credentials here; built behind an interface with a fake in Phase 4. Not verified against real Google.
3. **Wi-Fi sync:** `shelf` server + AES-GCM encrypted message over localhost works (`test/proof/sync_loopback_proof_test.dart`). Real phone↔desktop flow in Phase 6.
4. **Updater:** cannot be run here (Windows). GitHub Releases check built in Phase 5.
5. Build check: `flutter build macos --debug` and `flutter build apk --debug` both succeeded.

## Requirement tracker

Statuses: todo / partial / done / blocked. Update with `python3 tool/progress_set.py <status> <ids> [files] [tests]`.

<!-- REQ-TABLE-START -->
| ID | Status | Implemented in | Covered by |
|---|---|---|---|
| GEN-1 | partial | macOS+Android builds OK; Windows folder generated, not built | flutter build macos/apk |
| GEN-2 | partial | lib/l10n/*.arb (all screens built so far) | test/l10n_test.dart |
| GEN-3 | done | lib/app/app_state.dart, lib/features/sign_in/language_switch.dart | test/widget/sign_in_flow_test.dart |
| GEN-4 | partial | all screens through Phase 3 use Fmt | shared_utils_test.dart, reports_flow_test.dart (English/Bangla dashboard) |
| GEN-5 | done | lib/app/app_state.dart, lib/features/sign_in/language_switch.dart | test/widget/sign_in_flow_test.dart |
| GEN-6 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| GEN-7 | done | lib/shared/widgets/date_form_field.dart, lib/shared/date_parse.dart | test/shared/date_parse_test.dart, test/widget/date_field_test.dart |
| GEN-8 | done | lib/shared/widgets/date_form_field.dart, lib/shared/date_parse.dart | test/shared/date_parse_test.dart, test/widget/date_field_test.dart |
| USR-1 | partial | sign_in_screen.dart, user_service.dart (desktop done; phone in Phase 6) | test/widget/sign_in_flow_test.dart |
| USR-2 | done | lib/features/users/user_service.dart, users_screen.dart, lib/shared/permissions.dart | test/features/user_service_test.dart, test/widget/users_settings_test.dart, test/shared/shared_utils_test.dart |
| USR-3 | done | lib/features/google_drive/{restore_service,restore_panel,restore_launcher}.dart, lib/app/{app_host,app}.dart | test/features/drive_backup_test.dart, test/widget/drive_screens_test.dart (first-launch restore end to end) |
| USR-4 | done | lib/features/users/user_service.dart, users_screen.dart, lib/shared/permissions.dart | test/features/user_service_test.dart, test/widget/users_settings_test.dart, test/shared/shared_utils_test.dart |
| USR-5 | done | lib/features/users/user_service.dart, users_screen.dart, lib/shared/permissions.dart | test/features/user_service_test.dart, test/widget/users_settings_test.dart, test/shared/shared_utils_test.dart |
| USR-6 | done | lib/features/users/user_service.dart, users_screen.dart, lib/shared/permissions.dart | test/features/user_service_test.dart, test/widget/users_settings_test.dart, test/shared/shared_utils_test.dart |
| USR-7 | done | lib/features/users/user_service.dart, users_screen.dart, lib/shared/permissions.dart | test/features/user_service_test.dart, test/widget/users_settings_test.dart, test/shared/shared_utils_test.dart |
| USR-8 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| USR-9 | done | lib/shared/password_hasher.dart (bcrypt) | test/features/user_service_test.dart |
| INC-1 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-2 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-3 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-4 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-5 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-6 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-7 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-8 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-9 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| INC-10 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| EXP-1 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| EXP-2 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| EXP-3 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| EXP-4 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| EXP-5 | done | income and expense: list, details, edit, cancel, PDF, Excel | entries_flow_test, reports_flow_test, excel_builder_test |
| EXP-6 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| EXP-7 | done | settings_service.dart, settings_screen.dart | test/features/balance_test.dart, test/widget/users_settings_test.dart |
| EXP-8 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| FND-1 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-2 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-3 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-4 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-5 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-6 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-7 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-8 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| FND-9 | done | lib/features/entries/entry_list_screen.dart, lib/shared/widgets/period_selector.dart, lib/shared/period_choice.dart | test/widget/entries_flow_test.dart, test/shared/period_choice_test.dart |
| DET-1 | done | entry_details_screen.dart + PDF; Excel for expenses in Phase 4 | test/widget/entries_flow_test.dart |
| DET-2 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| DET-3 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| EDT-1 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| EDT-2 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| EDT-3 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| EDT-4 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| BAL-1 | done | lib/features/settings/settings_service.dart, settings_screen.dart | test/features/balance_test.dart, test/widget/users_settings_test.dart |
| BAL-2 | done | lib/features/settings/settings_service.dart, settings_screen.dart | test/features/balance_test.dart, test/widget/users_settings_test.dart |
| BAL-3 | done | lib/features/reports/{balance_service,dashboard_screen,summary_screen}.dart | test/features/balance_test.dart, test/widget/reports_flow_test.dart |
| BAL-4 | done | lib/features/reports/{balance_service,dashboard_screen,summary_screen}.dart | test/features/balance_test.dart, test/widget/reports_flow_test.dart |
| PDF-1 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| PDF-2 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| PDF-3 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| PDF-4 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| PDF-5 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| PDF-6 | done | lib/features/reports/{pdf/pdf_pages,pdf/report_blocks,report_pdf_service,pdf_report_screen,entry_pdf_button,save_pdf}.dart, lib/shared/file_saver.dart | test/features/report_pdf_test.dart, test/widget/reports_flow_test.dart |
| BAK-1 | partial | google_drive_auth.dart (real, NOT verified against Google), backup_screen.dart, connect_google.dart | test/widget/drive_screens_test.dart (fake) |
| BAK-2 | done | lib/features/google_drive/{backup_service,drive_scheduler,drive_service,backup_screen}.dart (tested with a fake Drive) | test/features/drive_backup_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| BAK-3 | done | lib/features/google_drive/{backup_service,drive_scheduler,drive_service,backup_screen}.dart (tested with a fake Drive) | test/features/drive_backup_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| BAK-4 | done | lib/features/google_drive/{backup_service,drive_scheduler,drive_service,backup_screen}.dart (tested with a fake Drive) | test/features/drive_backup_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| BAK-5 | done | lib/features/google_drive/{backup_service,drive_scheduler,drive_service,backup_screen}.dart (tested with a fake Drive) | test/features/drive_backup_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| BAK-6 | done | lib/features/google_drive/{restore_service,restore_panel,restore_launcher}.dart, lib/app/{app_host,app}.dart | test/features/drive_backup_test.dart, test/widget/drive_screens_test.dart (first-launch restore end to end) |
| BAK-7 | done | lib/features/google_drive/{backup_service,drive_scheduler,drive_service,backup_screen}.dart (tested with a fake Drive) | test/features/drive_backup_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| BAK-8 | done | lib/features/google_drive/{backup_service,drive_scheduler,drive_service,backup_screen}.dart (tested with a fake Drive) | test/features/drive_backup_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-1 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-2 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-3 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-4 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-5 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-6 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-7 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-8 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| XLS-9 | done | lib/features/google_drive/{excel_builder,excel_upload_service,excel_upload_screen}.dart | test/features/excel_builder_test.dart, drive_excel_scheduler_test.dart, test/widget/drive_screens_test.dart |
| UPD-1 | todo |  |  |
| UPD-2 | todo |  |  |
| UPD-3 | todo |  |  |
| UPD-4 | todo |  |  |
| UPD-5 | todo |  |  |
| UPD-6 | todo |  |  |
| MOB-1 | todo |  |  |
| MOB-2 | todo |  |  |
| MOB-3 | todo |  |  |
| MOB-4 | todo |  |  |
| MOB-5 | todo |  |  |
| SYN-1 | todo |  |  |
| SYN-2 | todo |  |  |
| SYN-3 | todo |  |  |
| SYN-4 | todo |  |  |
| SYN-5 | todo |  |  |
| SYN-6 | todo |  |  |
| SYN-7 | todo |  |  |
| SYN-8 | partial | duplicate flag + banner + filter + mark checked done; the flagging on import comes in Phase 6 | test/widget/entries_flow_test.dart |
| SYN-9 | todo |  |  |
| SYN-10 | todo |  |  |
<!-- REQ-TABLE-END -->

## Screen tracker

Source: design artifact https://claude.ai/artifact/RTKSQa6taiYR82S5cRzDgX (47 boards; macOS boards are the same screens in a macOS window).

| Screen | Platform | Phase | Status |
|---|---|---|---|
| Setup (first launch: create Super Admin or restore) | Desktop | 1 | done (restore button: Phase 4) |
| Sign in | Desktop | 1 | done |
| Dashboard (+ English) | Desktop | 3 | done |
| Income list | Desktop | 2 | done |
| Add income (duplicate warning, date picker) | Desktop | 2 | done |
| Income details | Desktop | 2 | done |
| Photo viewer | Desktop | 2 | done |
| Expense list | Desktop | 2 | done |
| Add expense | Desktop | 2 | done |
| Expense details (cancelled) | Desktop | 2 | done |
| Admin approval dialog | Desktop | 2 | done |
| Cancel entry dialog | Desktop | 2 | done |
| Summary | Desktop | 3 | done |
| PDF report | Desktop | 3 | done |
| Excel upload | Desktop | 4 | done |
| Phone sync QR | Desktop | 6 | todo |
| Users | Desktop | 1 | done |
| Add user | Desktop | 1 | done |
| Backup and restore | Desktop | 4 | done |
| Settings (language, opening balance, approvers, password, update) | Desktop | 1 | done (update check: Phase 5) |
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

- 2026-11-14: Phase 4 done (against a fake Drive; the real Google connection is written but NOT verified). Drive interfaces, `GoogleDriveAuth/Client` (googleapis, drive.file), `DriveService`, `BackupService` (VACUUM INTO snapshot, gzip, photos uploaded once per account, 1-year retention keeping the newest, no backup of an empty installation), `RestoreService` (download, verify, copy current aside, replace, fetch missing photos), `ExcelUploadService` + `buildEntriesWorkbook` (real numbers/dates), `DriveScheduler` (4 h, at start if overdue, retry every 2 min after failure, daily Excel with catch-up), screens Backup / Excel / first-launch Restore, `AppHost` to replace the data after a restore. Schema v2 (drive_uploaded_photos, drive_log) with a real migration test (drift_dev schema dump/generate, `test/data/migration_test.dart`). Bugs found by tests and fixed: missing `onUpgrade` (migration test), notice banner not shown after restore, test-harness deadlocks (see Working notes). macOS entitlements (network client/server, file save) and Android minSdk 31 + permissions set. docs/setup-notes.md written.
- 2026-11-13: Phase 3 done. Dashboard, Summary (day/week/month breakdown), PDF report screen with preview, entry PDF, PDF engine (pages painted with Flutter's text engine, embedded as images; header repeated on continued pages), FileSaver interface. Visually checked: Bangla conjuncts, digits, cancelled strike-through, photos with labels. Limitation: PDF text is an image (not selectable). Bug found and fixed by tests: RadioListTile ink hidden by coloured card.
- 2026-11-13: Phase 2 done. Entry list (periods, search, open-by-number, paging, duplicate banner), add/edit form (suggested number, duplicate warning, approver dropdown, photos with labels), details (history, photos), photo viewer, approval and cancel dialogs, period selector, photo shrinker/picker. Bugs found by tests and fixed: corrupt image made the decoder throw RangeError (now PhotoUnreadableException), photo-label dialog disposed its controller too early. 127 tests pass, analyzer clean.
- 2026-11-13: Phase 1 done. Settings screen (language, opening balance, approvers, password, version), Users screen + dialogs, Setup and Sign-in screens, desktop shell with role-aware menu, date field, l10n (bn/en) with parity test. Bugs found by tests and fixed: LIKE wildcards in search (`%`/`_`), `context.fmt` using `watch` in handlers, wrong argument order for `dateDayInvalid`, Users table horizontal-scroll layout, button text losing the Bangla font. 106 tests pass, analyzer clean.
- 2026-11-13: Data layer: Drift schema, db opener with pre-migration copy + restore on failure, UserService/EntryService/BalanceService/SettingsService, parsing and period helpers, 80+ tests.
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
