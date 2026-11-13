# Atia Jame Masjid Accounts App: Progress

## RESUME HERE

- **Last updated:** 2026-11-13 (Phase 2 UI finished)
- **Current phase / step:** Phase 3, step 3.1: dashboard, summary screen, PDF reports (rasterised pages), entry PDF
- **Exact next action:** Build Phase 3. (1) Dashboard screen replacing the `Section.dashboard` placeholder (design boards Main / MainEnglish): current balance via `BalanceService.currentBalance()`, today/month stat cards, recent entries, status cards. (2) Summary screen (board Summary) using `PeriodSelector` + `BalanceService.summary`. (3) PDF: render pages with Flutter's text engine into PNG and embed in a PDF (see test/proof/bangla_raster_pdf_proof_test.dart), report for income/expense/both with summary (PDF-1..6), single-entry PDF with photos (DET-2/3) replacing the stub `lib/features/reports/entry_pdf_button.dart`; save location via `file_selector` `getSaveLocation`. Read boards Main, Summary, PdfExport first.
- **Half-done / broken:** nothing broken. `lib/app/section_placeholder.dart` and `lib/features/google_drive/restore_launcher.dart` are deliberate stubs to be replaced (Phase 2/3 and Phase 4). `UpdateCard` only shows the version (update check = Phase 5).
- **Verify commands:**
  - `cd /Users/nasim/Documents/Projects/Personal/AtiaJameMasjid`
  - `flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`
  - `flutter analyze` (expect: No issues found)
  - `flutter test` (expect: all pass; 127 at end of Phase 2)
  - run: `flutter run -d macos` / `flutter run -d emulator-5554`
  - Screenshots without screen-capture permission: `SHOT_DIR=<dir> flutter test test/widget/screens_shot_test.dart`, then view the PNGs.
- **Working notes:** widget tests must use `testApp(...)` (test/helpers/app_harness.dart) and `tester.runAsync` for real async (Drift, bcrypt isolates). Add translations with `tool/l10n_add.py` (keeps both ARB files identical) then `flutter gen-l10n`; multi-placeholder args are generated in alphabetical order. Tests folder is un-ignored in `.gitignore` because the user's global gitignore ignores `test/`.

## Phase checklist

| Phase | Name | Status | Finished |
|---|---|---|---|
| 0 | Set-up and risk checks | done | 2026-11-13 |
| 1 | Foundation: database, sign-in, language | done | 2026-11-13 |
| 2 | Income and expense | done | 2026-11-13 |
| 3 | Balance, summary, PDF | in progress (BalanceService done) | |
| 4 | Google Drive: backup and Excel | not started | |
| 5 | Updates and installers | not started | |
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
| GEN-4 | partial | lib/shared/formatters.dart, bangla.dart | test/shared/shared_utils_test.dart, date_field_test.dart |
| GEN-5 | done | lib/app/app_state.dart, lib/features/sign_in/language_switch.dart | test/widget/sign_in_flow_test.dart |
| GEN-6 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| GEN-7 | done | lib/shared/widgets/date_form_field.dart, lib/shared/date_parse.dart | test/shared/date_parse_test.dart, test/widget/date_field_test.dart |
| GEN-8 | done | lib/shared/widgets/date_form_field.dart, lib/shared/date_parse.dart | test/shared/date_parse_test.dart, test/widget/date_field_test.dart |
| USR-1 | partial | sign_in_screen.dart, user_service.dart (desktop done; phone in Phase 6) | test/widget/sign_in_flow_test.dart |
| USR-2 | done | lib/features/users/user_service.dart, users_screen.dart, lib/shared/permissions.dart | test/features/user_service_test.dart, test/widget/users_settings_test.dart, test/shared/shared_utils_test.dart |
| USR-3 | partial | setup_screen.dart (restore button wired in Phase 4) | test/widget/sign_in_flow_test.dart |
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
| EXP-5 | partial | lists/details work for expenses; PDF/Excel pending | test/widget/entries_flow_test.dart |
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
| DET-1 | partial | lib/features/entries/entry_details_screen.dart (PDF button in Phase 3) | test/widget/entries_flow_test.dart |
| DET-2 | todo |  |  |
| DET-3 | todo |  |  |
| EDT-1 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| EDT-2 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| EDT-3 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| EDT-4 | done | lib/features/entries/{approval_dialog,cancel_dialog,entry_details_screen}.dart | test/features/entry_service_test.dart, test/widget/entries_flow_test.dart |
| BAL-1 | done | lib/features/settings/settings_service.dart, settings_screen.dart | test/features/balance_test.dart, test/widget/users_settings_test.dart |
| BAL-2 | done | lib/features/settings/settings_service.dart, settings_screen.dart | test/features/balance_test.dart, test/widget/users_settings_test.dart |
| BAL-3 | partial | service layer done (entry_service.dart, balance_service.dart); screens pending | test/features/entry_service_test.dart, balance_test.dart |
| BAL-4 | partial | service layer done (entry_service.dart, balance_service.dart); screens pending | test/features/entry_service_test.dart, balance_test.dart |
| PDF-1 | todo |  |  |
| PDF-2 | todo |  |  |
| PDF-3 | todo |  |  |
| PDF-4 | todo |  |  |
| PDF-5 | todo |  |  |
| PDF-6 | todo |  |  |
| BAK-1 | todo |  |  |
| BAK-2 | todo |  |  |
| BAK-3 | todo |  |  |
| BAK-4 | todo |  |  |
| BAK-5 | todo |  |  |
| BAK-6 | todo |  |  |
| BAK-7 | todo |  |  |
| BAK-8 | todo |  |  |
| XLS-1 | todo |  |  |
| XLS-2 | todo |  |  |
| XLS-3 | todo |  |  |
| XLS-4 | todo |  |  |
| XLS-5 | todo |  |  |
| XLS-6 | todo |  |  |
| XLS-7 | todo |  |  |
| XLS-8 | todo |  |  |
| XLS-9 | todo |  |  |
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
| Dashboard (+ English) | Desktop | 3 | todo |
| Income list | Desktop | 2 | done |
| Add income (duplicate warning, date picker) | Desktop | 2 | done |
| Income details | Desktop | 2 | done |
| Photo viewer | Desktop | 2 | done |
| Expense list | Desktop | 2 | done |
| Add expense | Desktop | 2 | done |
| Expense details (cancelled) | Desktop | 2 | done |
| Admin approval dialog | Desktop | 2 | done |
| Cancel entry dialog | Desktop | 2 | done |
| Summary | Desktop | 3 | todo |
| PDF report | Desktop | 3 | todo |
| Excel upload | Desktop | 4 | todo |
| Phone sync QR | Desktop | 6 | todo |
| Users | Desktop | 1 | done |
| Add user | Desktop | 1 | done |
| Backup and restore | Desktop | 4 | todo |
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
