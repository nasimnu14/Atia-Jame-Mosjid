# Atia Jame Masjid Accounts App: Progress

## RESUME HERE

- **Last updated:** 2026-11-14 (Phase 6 done and committed; review cycles next)
- **Current phase / step:** Review cycles (cycles 1 and 2 done and committed; cycle 3 next)
- **Exact next action:** Run at least 3 review->fix cycles over the whole code base against the requirement IDs, the 5 data-safety rules, role permissions, Bangla rendering (UI + PDFs), error handling; log each in 'Review cycles'; notify at the start and end of each; stop after a cycle that finds nothing. Things to look at: scheduler/AppState listener cleanup in `app.dart`; `context.read<ShellController>()` in SummaryScreen on the phone (provided by MobileShell); GEN-1/2/4 completeness; Windows config (cannot be built here); unused code. Then the final report (built per phase, tests, NOT verified list, manual checks) and the final notification. Do not push.
- **Half-done / broken:** nothing broken.
- **Verify commands:**
  - `cd /Users/nasim/Documents/Projects/Personal/AtiaJameMasjid`
  - `flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter gen-l10n`
  - `flutter analyze` (expect: No issues found)
  - `flutter test` (expect: all pass; 270 after review cycle 2; run `flutter test --concurrency=3`, more parallelism gets processes killed)
  - `flutter test integration_test -d macos` (2 tests: UI flow; sync over real sockets)
  - Manual phone sync without the desktop app: `dart run tool/sync_host.dart 10.0.2.2 /tmp/sync_code.txt`, then on the emulator choose 'type the code' and paste the file's text
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
| 5 | Updates and installers | done (Windows installer/updater not run) | 2026-11-14 |
| 6 | Android app and sync | done (code and tests; real phone not used) | 2026-11-14 |
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
| GEN-1 | done | macOS and Android build and run; Windows folder/config present, NOT built or run (needs Windows) | flutter build macos/apk; integration_test on macOS |
| GEN-2 | partial | lib/l10n/*.arb (all screens built so far) | test/l10n_test.dart |
| GEN-3 | done | lib/app/app_state.dart, lib/features/sign_in/language_switch.dart | test/widget/sign_in_flow_test.dart |
| GEN-4 | partial | all screens through Phase 3 use Fmt | shared_utils_test.dart, reports_flow_test.dart (English/Bangla dashboard) |
| GEN-5 | done | lib/app/app_state.dart, lib/features/sign_in/language_switch.dart | test/widget/sign_in_flow_test.dart |
| GEN-6 | done | lib/features/entries/{entry_service,entry_form_screen,photo_shrinker,photo_picker}.dart | test/features/entry_service_test.dart, photo_shrinker_test.dart, test/widget/entries_flow_test.dart |
| GEN-7 | done | lib/shared/widgets/date_form_field.dart, lib/shared/date_parse.dart | test/shared/date_parse_test.dart, test/widget/date_field_test.dart |
| GEN-8 | done | lib/shared/widgets/date_form_field.dart, lib/shared/date_parse.dart | test/shared/date_parse_test.dart, test/widget/date_field_test.dart |
| USR-1 | done | sign_in_screen.dart (desktop and phone) | test/widget/sign_in_flow_test.dart, sync_screens_test.dart |
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
| UPD-1 | done | lib/features/updates/{update_service,app_version_number,update_card,update_banner}.dart | test/features/update_test.dart, test/widget/update_screens_test.dart |
| UPD-2 | partial | update_installer.dart, update_dialog.dart (download+checksum+launch tested with fakes; real Windows/Android install NOT run) | test/features/update_test.dart, test/widget/update_screens_test.dart |
| UPD-3 | done | lib/data/db_opener.dart (copy before upgrade, restore on failure), windows/installer/atia.iss (never touches %APPDATA%), pre-update copy in update_dialog.dart | test/data/db_opener_test.dart, test/data/migration_test.dart |
| UPD-4 | done | lib/data/db_opener.dart (copy before upgrade, restore on failure), windows/installer/atia.iss (never touches %APPDATA%), pre-update copy in update_dialog.dart | test/data/db_opener_test.dart, test/data/migration_test.dart |
| UPD-5 | done | lib/data/db_opener.dart (copy before upgrade, restore on failure), windows/installer/atia.iss (never touches %APPDATA%), pre-update copy in update_dialog.dart | test/data/db_opener_test.dart, test/data/migration_test.dart |
| UPD-6 | partial | APK flow + PLAY_STORE_BUILD flag done; the Google Play build itself is out of scope | test/features/update_test.dart |
| MOB-1 | done | lib/app/mobile_shell.dart, lib/features/mobile/*, lib/features/sync/{pair,sync_scan,sync_done}_screen.dart, entry_list_screen.dart (cards), photo_picker.dart (camera/gallery) | test/widget/sync_screens_test.dart (typed code instead of camera) |
| MOB-2 | done | lib/app/mobile_shell.dart, lib/features/mobile/*, lib/features/sync/{pair,sync_scan,sync_done}_screen.dart, entry_list_screen.dart (cards), photo_picker.dart (camera/gallery) | test/widget/sync_screens_test.dart (typed code instead of camera) |
| MOB-3 | done | lib/app/mobile_shell.dart, lib/features/mobile/*, lib/features/sync/{pair,sync_scan,sync_done}_screen.dart, entry_list_screen.dart (cards), photo_picker.dart (camera/gallery) | test/widget/sync_screens_test.dart (typed code instead of camera) |
| MOB-4 | done | lib/app/mobile_shell.dart, lib/features/mobile/*, lib/features/sync/{pair,sync_scan,sync_done}_screen.dart, entry_list_screen.dart (cards), photo_picker.dart (camera/gallery) | test/widget/sync_screens_test.dart (typed code instead of camera) |
| MOB-5 | done | lib/app/mobile_shell.dart, lib/features/mobile/*, lib/features/sync/{pair,sync_scan,sync_done}_screen.dart, entry_list_screen.dart (cards), photo_picker.dart (camera/gallery) | test/widget/sync_screens_test.dart (typed code instead of camera) |
| SYN-1 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-2 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-3 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-4 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-5 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-6 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-7 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-8 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-9 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
| SYN-10 | done | lib/features/sync/{sync_crypto,sync_offer,sync_receiver,sync_server,sync_client,sync_screen,local_address}.dart, entry_service.dart (isPhone rules) | test/features/sync_test.dart (real sockets), test/widget/sync_screens_test.dart, integration_test/app_flow_test.dart |
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
| Phone sync QR | Desktop | 6 | done |
| Users | Desktop | 1 | done |
| Add user | Desktop | 1 | done |
| Backup and restore | Desktop | 4 | done |
| Settings (language, opening balance, approvers, password, update) | Desktop | 1 | done (update check: Phase 5) |
| Update available dialog | Desktop | 5 | done |
| Pair with desktop | Android | 6 | done |
| Sign in | Android | 6 | done |
| Home (this phone only) | Android | 6 | done |
| Income list / Expense list | Android | 6 | done |
| Add income / Add expense | Android | 6 | done |
| Details (synced read-only) | Android | 6 | done |
| Photo viewer | Android | 6 | done |
| Admin approval sheet | Android | 6 | done (shared dialog) |
| Summary (this phone only) | Android | 6 | done |
| PDF report | Android | 6 | done |
| Scan desktop QR | Android | 6 | done |
| Sync finished | Android | 6 | done |
| More (language, password, sign out) | Android | 6 | done |

## Log (newest first)

- 2026-11-14: Phase 6 emulator check (Android API 36, camera permission, Bangla UI) against a headless desktop (`tool/sync_host.dart`): pairing, account sync, sign-in on the phone, add income, sync it, entry becomes view-only: all worked. Three real bugs found and fixed: (1) closing pages on sign-out ran on every state change while nobody was signed in, so pairing a new phone closed the scan/done screens; now only when a signed-in user signs out (the widget tests for pairing caught it too); (2) an unexpected error during sync left the screen on 'syncing' forever; now shown as a message with the code field usable again (test added); (3) an entry made on the phone said 'from computer' in its details and entry PDF (test added).
- 2026-11-14: Phase 6 done. Sync: AES-256-GCM sealed messages (one-time key + single-use token in the QR), shelf server in the desktop app (runs only on the Sync page), `SyncClient` on the phone (accounts first, then entries one by one, marked synced only after the desktop confirms), idempotent receiver (sent twice saves once), duplicate receipt flagged, sync log updated as entries arrive. Phone rules: new entries unsynced, synced ones read-only, phone balance without opening balance. Android UI: shell with bottom bar, Home, lists as cards, forms with camera/gallery picker, details, Summary (phone-only note, no Excel), PDF via share sheet, pair/scan/done screens, More. Desktop Sync page with QR. Integration tests (macOS): full UI flow and sync over real sockets. Real bugs found: sync log missed entries of an interrupted session (now logged as they arrive), Summary table overflow on phone width, hidden ripple on code expander.
- 2026-11-14: Phase 5 done. `UpdateService` (GitHub latest release, semver compare, per-platform asset, bn/en notes, daily check, Play-build switch), `PlatformUpdateInstaller` (download, SHA-256 check, Windows installer launch / Android APK / macOS release page), update dialog (backs up first), Settings card, dashboard banner. Inno Setup script, CI and release GitHub workflows, Android release signing via `android/key.properties`. Deviation: no `auto_updater` (see setup notes section 3). One inconsistency found by a test and fixed: the dialog's "you are running" version came from a different source than the update check.
- 2026-11-14: Phase 4 done (against a fake Drive; the real Google connection is written but NOT verified). Drive interfaces, `GoogleDriveAuth/Client` (googleapis, drive.file), `DriveService`, `BackupService` (VACUUM INTO snapshot, gzip, photos uploaded once per account, 1-year retention keeping the newest, no backup of an empty installation), `RestoreService` (download, verify, copy current aside, replace, fetch missing photos), `ExcelUploadService` + `buildEntriesWorkbook` (real numbers/dates), `DriveScheduler` (4 h, at start if overdue, retry every 2 min after failure, daily Excel with catch-up), screens Backup / Excel / first-launch Restore, `AppHost` to replace the data after a restore. Schema v2 (drive_uploaded_photos, drive_log) with a real migration test (drift_dev schema dump/generate, `test/data/migration_test.dart`). Bugs found by tests and fixed: missing `onUpgrade` (migration test), notice banner not shown after restore, test-harness deadlocks (see Working notes). macOS entitlements (network client/server, file save) and Android minSdk 31 + permissions set. docs/setup-notes.md written.
- 2026-11-13: Phase 3 done. Dashboard, Summary (day/week/month breakdown), PDF report screen with preview, entry PDF, PDF engine (pages painted with Flutter's text engine, embedded as images; header repeated on continued pages), FileSaver interface. Visually checked: Bangla conjuncts, digits, cancelled strike-through, photos with labels. Limitation: PDF text is an image (not selectable). Bug found and fixed by tests: RadioListTile ink hidden by coloured card.
- 2026-11-13: Phase 2 done. Entry list (periods, search, open-by-number, paging, duplicate banner), add/edit form (suggested number, duplicate warning, approver dropdown, photos with labels), details (history, photos), photo viewer, approval and cancel dialogs, period selector, photo shrinker/picker. Bugs found by tests and fixed: corrupt image made the decoder throw RangeError (now PhotoUnreadableException), photo-label dialog disposed its controller too early. 127 tests pass, analyzer clean.
- 2026-11-13: Phase 1 done. Settings screen (language, opening balance, approvers, password, version), Users screen + dialogs, Setup and Sign-in screens, desktop shell with role-aware menu, date field, l10n (bn/en) with parity test. Bugs found by tests and fixed: LIKE wildcards in search (`%`/`_`), `context.fmt` using `watch` in handlers, wrong argument order for `dateDayInvalid`, Users table horizontal-scroll layout, button text losing the Bangla font. 106 tests pass, analyzer clean.
- 2026-11-13: Data layer: Drift schema, db opener with pre-migration copy + restore on failure, UserService/EntryService/BalanceService/SettingsService, parsing and period helpers, 80+ tests.
- 2026-11-13: Session started. No progress file existed. Read requirements, plan, test cases list, design artifact (palette: primary #0F5C46, dark #0F3D30, bg #F4F6F3, expense #9A3709, font Hind Siliguri). `flutter create` for macos, windows, android done. Added dependencies.

## Review cycles

### Cycle 1 (2026-11-14): three independent read-only reviewers (data safety / roles+errors / UI+Bangla+build)

Fixed (each with a test unless noted):
- Sync could write files outside the photo folder (entry id or photo name with `..`): now plain names only.
- Two phones using one code at the same moment both got in: the code is now spent before anything is awaited.
- Sync server read a huge body before checking anything: refuses by Content-Length first.
- Restore: if reopening the data failed, a spinner never ended: now an error page with "try again" (no test; needs a failing reopen).
- Removing a photo deleted its database row (data rule 4): now marked `removedAt` (schema v3, migration test 2->3, file and row stay and are still backed up).
- Backups stopped silently when the Google sign-in stopped working: now recorded as a failure and shown on the Backup page.
- Double click on Save could create two entries (guard added).
- Dialogs: Back during a check closed the wrong page; double click on Change role / Reset password; unhandled error on "mark reviewed"; approving an edit counted as a sign-in.
- Phone: a password changed on the phone was silently replaced at the next sync: a note now says so.
- The phone never checked for updates and had no update screen (UPD-1/2): daily check on every platform; update card on More; banner on Home.
- Windows in-app update did not reopen the app (installer `skipifsilent` removed; not run, Windows).
- PDF: a heading could be left alone at the foot of a page; "Cancelled" wrapped in English (column wider).
- More screen: long names overflowed on a phone.
- Excel daily file and phone balance cut off entries dated before 2000; date picker range now matches the parser (1900 to 2200).
- Removed unused `printing` dependency (its Windows build step downloads binaries).

Not changed (decision recorded):
- Backup/restore/update actions are hidden by role in the UI but not checked inside the services (the screens are the only callers; the requirements give updates to every user).
- The sync server trusts a paired phone's `createdBy`/status fields; a paired phone is trusted by design (QR code). Pairing key is one-time.
- The server listens on all network cards (the phone needs the Wi-Fi one); sealed messages protect content.
- Raw English error text inside some Bangla messages (GEN-2, minor); 11 unused translation keys; `PeriodKind` unused.
- A photo missing on the phone is skipped at sync (the entry still syncs).

### Cycle 2 (2026-11-14): reviewer of the cycle-1 fixes + reviewer walking all 192 manual test cases against the code

Fixed (each with a test):
- Regression from cycle 1: a phone entry with 10 photos where one was taken off and another added (11 rows) was refused by the desktop for ever, blocking all later entries. The limit now counts shown photos only; the phone's pending-photo count too.
- No internet was reported as "sign-in expired" (and logged every 2 minutes): offline is now told apart; a failure that cannot start is logged once, not at every retry.
- Choosing more photos than fit dropped the extras silently: now says the limit is 10.
- Dashboard "Sync" status on the computer always said "Not yet": it now records when a phone last synced.

Not changed (decision recorded):
- Moving to another menu item discards a half-filled form without a warning (TC-179). Found low; left as is.
- Typing a receipt number in the list filters it; opening it needs Enter (TC-042, as designed).
- Fresh installation has no approvers until an Admin adds them (the requirements list three as examples, not defaults).
- Restore's "photos missing" count includes photos that were taken off (still downloaded; harmless).
- No automated test for: role change while signed in, approver rename in the UI, very large (crore) amounts in list/PDF columns, phone sent to the background during camera capture (needs a device).

## Assumptions

- Drive backups: the requirements say keep one year (BAK-7). The task text mentions a default of 10; the requirements doc is the source of truth, so one year is used.
- State management: `provider` (ChangeNotifier), chosen for simplicity.
- Password hash: bcrypt (pure Dart, works on all three platforms).
- Updates: `auto_updater` (WinSparkle) from the plan was replaced by a GitHub-release download + installer launch flow (no appcast or extra signing key needed; unit-testable). Reason and details in docs/setup-notes.md section 3.
- Phone notifications: PushNotification is skipped by the tool while the terminal is active; milestones are still attempted.

## Known gaps / needs a human

- Windows: never built or run (this is a Mac). Windows config (`windows/`, Inno Setup script `windows/installer/atia.iss`) is written but unproven.
- Google Drive: only tested against a fake. Real sign-in, upload, restore and the OAuth consent screen are unverified (no credentials here). Needs the Google Cloud steps in `docs/setup-notes.md`.
- Windows installer and in-app update (download, SHA-256 check, installer launch): not run.
- Android: tested on an emulator only (API 36, virtual camera), not on a real phone. QR scanning of a real code and real Wi-Fi sync between two devices are unverified (the emulator used the typed-code path).
- PDF text is an image (Flutter text engine used to get correct Bangla), so it cannot be selected or searched.
- Android release signing key must be created by the owner (`android/key.properties`, see setup notes).
- Phase 7 and Google Play were skipped by instruction.
- Status bar icons on the phone's pairing/sign-in screens are light on a light background (cosmetic, not changed).

## Environment

- Flutter 3.44.5, Dart 3.12.2, Xcode 26.2, macOS 26.5.1.
- Android emulator `emulator-5554` (API 36). AVDs: Managed_Test, Phone_1, Phone_2. Android SDK licences status "unknown" in `flutter doctor`.
- Packages: see pubspec.yaml.
