# Atia Jame Masjid Accounts App — Development Plan

| | |
|---|---|
| **Status** | Draft |
| **Date** | 13 November 2026 |
| **Based on** | `docs/atia-jame-masjid-accounts-requirement.md` (requirements), `docs/test_cases/atia-jame-masjid-accounts.md` (test cases), screens canvas: https://claude.ai/artifact/RTKSQa6taiYR82S5cRzDgX |

---

## In Short

- Build **one app with Flutter** (confirmed). The same code runs on Windows and Android for the mosque, and on macOS for testing.
- Build it in **8 phases**. The desktop comes first because it holds the master record. Android comes last because it depends on the desktop's sync.
- In week 1, **test the four riskiest parts** before building any real screens: Bangla text in PDFs, Google Drive sign-in, phone-to-desktop Wi-Fi sync, and automatic updates.
- **Rough time: about 15 weeks (3.5 months) for one full-time developer.** This is a first guess and will be checked again after week 1.

---

## 1. Technology

### Chosen: Flutter (confirmed 13 Nov 2026)

| Why | Requirement it helps |
|---|---|
| One codebase for Windows, macOS and Android. Two separate apps would roughly double the work and drift apart over time. | GEN-1, MOB-1 |
| Shows Bangla text correctly on screen, including joined letters, when the app ships its own Bangla font. | GEN-2, GEN-4 |
| Has built-in support for two languages: one file of Bangla text, one of English. | GEN-2, GEN-3 |
| Has a good local database library with tested upgrade steps, so updates never lose data. | UPD-3, UPD-4 |

**Option considered and not chosen:** a desktop app built with web technology (Electron or Tauri) plus a separate Android app. It was not chosen because it means two apps to build, test and keep in step.

### Tools for each job

| Job | Tool | Requirements |
|---|---|---|
| Screens on all three platforms | Flutter | GEN-1, MOB-1 |
| Bangla and English text | Flutter's translation files | GEN-2, GEN-3 |
| Bangla font | Hind Siliguri or Noto Sans Bengali, bundled with the app | GEN-2, PDF-4 |
| Local database | SQLite, through the Drift library (supports tested upgrade steps) | UPD-3, UPD-4 |
| Passwords | A slow password hash (Argon2id or bcrypt), never plain text | USR-9 |
| Photos | Camera and gallery on Android, file picker on desktop. Photos are shrunk before saving. | INC-6, INC-9, MOB-2 |
| PDF | The `pdf` and `printing` libraries. Bangla must be checked first (see Risk 1). | PDF-1 to PDF-6, DET-2 |
| Excel | The `excel` library (.xlsx files) | XLS-1 to XLS-9 |
| Google Drive | Google's official Drive library, with the "drive.file" permission, so the app only sees files it made | BAK, XLS |
| Show and scan QR code | `qr_flutter` (desktop shows), `mobile_scanner` (phone scans) | SYN-2 |
| Wi-Fi sync | A small server inside the desktop app (`shelf`), running only while the sync screen is open | SYN-1 to SYN-10 |
| Windows updates | `auto_updater` (WinSparkle), reading a feed on GitHub Releases. The macOS test build has no updater. | UPD-1, UPD-2 |
| Android updates | APK version: the app checks GitHub Releases and downloads the new APK file. Google Play version (later): updates only through Google Play. | UPD-1, UPD-2, UPD-6 |
| Saving the Google sign-in safely | `flutter_secure_storage` | BAK-1 |

---

## 2. How the Pieces Fit

```
                        +------------------------------+
                        |         Google Drive         |
                        |  - backup every 4 hours      |
                        |  - one Excel file per day    |
                        +---------------^--------------+
                                        |
+------------------+    new     +-------+-----------------------------+
| GitHub Releases  | ---------> |  DESKTOP APP (Windows; macOS test)  |
| (new versions)   |  versions  |  - holds the master record          |
+------------------+            |  - database + photos folder         |
                                |  - sync screen: QR code + local     |
                                |    server (same Wi-Fi only)         |
                                +-------^-----------------+-----------+
                     entries + photos   |                 |  user accounts +
                     (unsynced only)    |                 |  approver list
                                +-------+-----------------v-----------+
                                |  ANDROID APP                        |
                                |  - its own small database           |
                                +-------------------------------------+
```

### Rules that keep the data safe

1. **Data lives in the computer's app-data folder, never in the install folder.** Installing an update cannot touch it (UPD-3).
2. **Every entry gets its own unique ID when it is created.** The receipt number is not the ID, because the phone and the desktop can both have the same number (SYN-8). This also means an entry sent twice is only saved once (SYN-5).
3. **Amounts are stored as whole Taka (whole numbers).** Totals are always exact; there are no rounding errors.
4. **Nothing is ever deleted.** Cancelling only changes an entry's status (EDT-3). Users are disabled, never deleted (USR-6).
5. **The database is copied before every upgrade.** If the upgrade fails, the copy is put back (UPD-4, UPD-5).

---

## 3. What the Database Stores

| Table | What it holds | Main fields |
|---|---|---|
| **users** | People who can sign in | name, username, password hash, role (Super Admin / Admin / User), active or disabled |
| **entries** | Every income and expense | ID, type (income or expense), receipt number, date, name (donor or payee), purpose*, approver name*, amount, address, status (active or cancelled), cancel reason, who added / edited / cancelled it and when, which device it was made on, synced flag, duplicate flag |
| **photos** | Photos of an entry (up to 10 each) | entry ID, file name, label, position |
| **approvers** | The approver list | name, active |
| **settings** | Single values | language, opening balance and its date, Google account, time of last backup, time of last Excel upload |
| **sync_log** | One row per phone sync | phone name, time, number of entries and photos received |

\* Expense only.

- If the donor name is left blank, it is stored empty and shown as "অজ্ঞাত" / "Unknown" (INC-3).
- The approver's name is copied into the expense as text, so later changes to the approver list don't change old expenses (EXP-8).
- Photo files are stored in a folder next to the database. The database only holds their file names.

---

## 4. Code Layout

```
lib/
  app/          start-up, navigation, colours, fonts
  l10n/         Bangla and English text
  data/         database tables and upgrade steps
  features/
    sign_in/      first launch, sign in, change password
    users/        user management (Super Admin)
    entries/      income and expense: forms, lists, details, photos, edit, cancel
    reports/      dashboard balance, summary, PDF
    google_drive/ backup, restore, Excel upload
    sync/         QR code, desktop server, phone sender
    settings/     language, opening balance, approver list
    updates/      update check and install
  shared/       date field with calendar, Bangla digits, money format, role checks
test/           automated tests
```

---

## 5. Phases

Each phase ends with something that works and can be shown to the committee.

### Phase 0 — Set-up and risk checks · about 1 week

**Build**
- A Flutter project for Windows, macOS and Android, in this Git repository.
- Automatic builds on GitHub for all three platforms.
- The bundled Bangla font, and one test screen in Bangla.
- Four small throw-away proofs:
  1. **Bangla PDF:** a one-page PDF with joined letters (e.g. ক্ষ, ন্ত্র, যুক্তাক্ষর), opened on Windows and macOS.
  2. **Google Drive:** sign in from the desktop app and upload a file.
  3. **Wi-Fi sync:** a phone scans a QR code on the desktop and sends a short message to it.
  4. **Updates:** on Windows, install version 0.0.1, publish 0.0.2 on GitHub Releases, and watch the app update itself.

**Done when**
- [ ] All four proofs work, or a fallback is chosen for any that don't (see Section 8).
- [ ] The time estimate in this plan has been checked again.

### Phase 1 — Foundation: database, sign-in, language · about 2 weeks

**Build**
- The database tables, with a test setup for upgrade steps.
- First launch: create the Super Admin. The "restore from backup" button is shown now and starts working in Phase 4.
- Sign in, sign out, and change own password.
- Users screen (Super Admin only): add a user, change their role, disable them, reset their password.
- Role checks, used by every screen.
- Language switch (Bangla by default) and Bangla digits.
- The shared date field: type the date or pick it from the calendar; accept Bangla or English digits; refuse dates that don't exist.
- Settings: opening balance and the approver list.

**Covers:** GEN-1 to GEN-8, USR-1 to USR-9, BAL-1, BAL-2, EXP-6, EXP-7

**Done when**
- [ ] The Super Admin can set up the app and add an Admin and a User.
- [ ] Each of them can sign in and sees only what their role allows.
- [ ] Switching language changes every screen.
- [ ] The GEN and USR test cases pass.

### Phase 2 — Income and expense · about 3 weeks

**Build**
- Add-income and add-expense forms, with required-field checks, the suggested next receipt number and the duplicate warning.
- Up to 10 photos per entry, shrunk before saving.
- A label for each photo. The app asks for one; if it is left blank, the entry's description plus a number is used.
- Lists for today, this week, this month, this year, any chosen day / week / month / year, and any date range. Search by receipt number or name. Every list shows its count and total.
- The details screen with all fields, history and photos, plus the full-size photo viewer.
- Editing (Admin or Super Admin, or a User with an Admin's approval on the spot).
- Cancelling with a reason. Cancelled entries stay visible but are not counted.
- Saving who added, edited or cancelled each entry, and when.

**Covers:** INC-1 to INC-10, EXP-1 to EXP-8, FND-1 to FND-9, DET-1, EDT-1 to EDT-4, USR-8

**Done when**
- [ ] One month of entries copied from the paper ledgers can be entered, found and corrected.
- [ ] The INC, EXP, FND, DET and EDT test cases pass.

### Phase 3 — Balance, summary and PDF · about 1.5 weeks

**Build**
- The dashboard with the current balance.
- A summary for any period: total income, total expense, income − expense.
- PDF reports: income only, expense only, or both with a summary. Cancelled entries are shown, marked, and not counted.
- A PDF of a single entry, with all its photos.

**Covers:** BAL-3, BAL-4, PDF-1 to PDF-6, DET-2, DET-3

**Done when**
- [ ] The balance matches a hand calculation for the test month.
- [ ] The PDFs open on another computer and the Bangla text looks right.

### Phase 4 — Google Drive: backup and Excel · about 1.5 weeks

**Build**
- Connect the Google account in settings.
- Back up every 4 hours while the app is open, straight away at start if a backup is overdue, and again when the internet comes back after a failure.
- Restore from a backup (Super Admin only), including from the first-launch screen on a new computer.
- Keep backups for one year and delete older ones automatically. Photo files are uploaded once and never deleted from Drive, so each 4-hour backup only uploads the database and any new photos. Any backup from the last year can then be restored with all its photos, without filling up Drive.
- When a different Google account is connected (the mosque's own account, later), make a full backup to it straight away.
- Upload one dated Excel file every day at 12 AM, or at the next start if the app was closed then.
- Upload Excel by hand for a day, week, month or date range.
- Show the time of the last backup and upload, with clear failure messages.

**Covers:** BAK-1 to BAK-8, XLS-1 to XLS-9

**Done when**
- [ ] With the internet off, a backup fails and says so. With it back on, the backup succeeds.
- [ ] Restoring on a second computer brings back every entry, photo and user.
- [ ] Connecting a second Google account puts a full backup there straight away.
- [ ] A backup dated more than one year ago is deleted, and every newer one can still be restored.
- [ ] The amounts in the Excel file add up correctly in Excel.

### Phase 5 — Updates and installers · about 1 week

**Build**
- A Windows installer. It is unsigned at first, and signed once the Windows certificate is bought.
- A test build for the developer's Mac (macOS 26). It is not signed and not given to users.
- The update check against GitHub Releases, and installing an update from inside the app.
- A backup of the database before every upgrade, which is put back if the upgrade fails.
- The release checklist (Section 7).

**Covers:** UPD-1 to UPD-5

**Done when**
- [ ] Updating from 1.0 to 1.1, where 1.1 changes the database, keeps every entry, photo, user and setting.
- [ ] If an update fails, version 1.0 still opens with all its data.

### Phase 6 — Android app and sync · about 3 weeks

**Build**
- The Android version of the screens, laid out for a phone.
- Pairing with the desktop by QR code, and signing in with the desktop accounts.
- Taking photos with the camera, or picking them from the gallery.
- Phone-only balance and summary, with a clear note that they are not the mosque's real balance.
- On the desktop: the sync screen. Its QR code works once and carries a secret key, all data sent is scrambled (encrypted) with that key, and the local server only runs while the screen is open.
- On the phone: send unsynced entries and their photos. Mark each one synced only after the desktop confirms it, then lock it.
- The desktop sends back the user accounts and the approver list, flags duplicate receipt numbers, and keeps a sync history.
- Release the Android app as a signed APK file on GitHub Releases, with the in-app update check.
- Keep the Android signing key safe and backed up. Google Play will need the same key later (Risk 9).

**Covers:** MOB-1 to MOB-5, SYN-1 to SYN-10, UPD-6 (APK part)

**Done when**
- [ ] Turning off Wi-Fi halfway through a sync loses nothing and saves nothing twice.
- [ ] A password changed on the desktop works on the phone after its next sync.
- [ ] The MOB and SYN test cases pass.

### Phase 7 — Trial at the mosque and hand-over · about 1.5 weeks of work

**Build**
- Install the app at the mosque. Set the opening balance, add the users and connect the Google account.
- Run the app alongside the paper books for two weeks, comparing the totals each week.
- Fix whatever the trial finds.
- Write a short user guide in Bangla: adding entries, syncing a phone, and what to do if the computer breaks (restore from backup).

**Done when**
- [ ] Two weeks of totals in the app match the paper books.
- [ ] The committee agrees the app can replace the paper books.

### Later — Google Play · not counted in the timeline

**When:** after the APK version has been in use and the customer's feedback is in.

**Steps**
- Create a Google Play developer account (25 USD, one time).
- Write the store listing in Bangla and English, and a privacy policy. One is needed because the app uses the camera and stores names and amounts.
- Fill in Google Play's data-safety form.
- Make a Google Play build without the APK self-update. Google Play does not allow apps to update themselves, so this build updates only through Google Play (UPD-6).
- Sign it with the same key as the APK. Phones can then move to the Google Play version without uninstalling, which would delete any unsynced entries.
- Run Google Play's closed test. New personal developer accounts currently need at least 12 testers for 14 days before the app can go public. Check the current rule before starting.

**Done when**
- [ ] The app is public on Google Play.
- [ ] A phone that had the APK version moves to the Google Play version without losing any entries.

### Timeline at a glance

| Phase | What | Rough weeks | Running total |
|---|---|---|---|
| 0 | Set-up and risk checks | 1 | 1 |
| 1 | Database, sign-in, language | 2 | 3 |
| 2 | Income and expense | 3 | 6 |
| 3 | Balance, summary, PDF | 1.5 | 7.5 |
| 4 | Google Drive backup and Excel | 1.5 | 9 |
| 5 | Updates and installers | 1 | 10 |
| 6 | Android app and sync | 3 | 13 |
| 7 | Trial and hand-over | 1.5 | 14.5 |

The two-week trial in Phase 7 runs in calendar time alongside the fixing work, so expect about 15–16 weeks from start to hand-over.

---

## 6. Testing

- **Automated tests** for everything where a mistake costs money or data:
  - balances and totals, with cancelled entries left out
  - reading typed dates (Bangla and English digits, dates that don't exist)
  - what each role is allowed to do
  - every database upgrade, from each older version to the newest
  - a sync sent twice saving each entry only once
  - Excel amounts and dates saved as real numbers and dates
- **Manual tests:** at the end of each phase, run that phase's cases from `docs/test_cases/atia-jame-masjid-accounts.md`.
- **Devices:** one Windows 10 or 11 PC, the developer's Mac (macOS 26, for testing only), one Android 12 phone (the oldest supported), and one newer Android phone.

---

## 7. Releasing a New Version

The developer publishes every new version, after getting the customer's feedback.

1. Collect the customer's feedback and decide what goes into the new version.
2. Raise the version number.
3. If the database changed, add an upgrade step and a test for it.
4. Run all tests, and let GitHub build Windows, Android and the macOS test build.
5. On a test computer and a test phone with realistic data, install the new version over the old one. Check that nothing is lost.
6. Publish the Windows installer and the Android APK on GitHub Releases, with short notes in Bangla and English. Once the app is on Google Play, upload the Google Play build there too.
7. The apps find the new version at their next update check.

---

## 8. Risks

| # | Risk | What could go wrong | What we do |
|---|---|---|---|
| 1 | **Bangla in PDFs** | Flutter's PDF library is weak at joining Bangla letters, so they may break or show as boxes. | Test it in Phase 0. **Fallback:** draw each PDF page as a picture inside the PDF. The Bangla is then always right, but the text can't be selected or searched and the files are bigger. |
| 2 | **Unsigned Windows installer** | Windows shows an "unknown publisher" warning when installing. | The warning can be clicked through. The Windows signing certificate will be bought later, and installers will be signed from then on. macOS needs nothing, because it is only used for testing. |
| 3 | **Google set-up** | Google needs a Cloud project and a sign-in consent screen. Wider Drive permissions need a long security review. | Use only the "drive.file" permission, which avoids that review. Create the project under the mosque's own Google account. |
| 4 | **Wi-Fi sync blocked** | The Windows firewall blocks the sync, or the mosque has no Wi-Fi. | The user guide explains the firewall prompt. A phone hotspot can act as the shared network. |
| 5 | **Data is only as safe as the last backup** | If the computer dies, up to 4 hours of entries can be lost. Unsynced entries are lost if a phone is lost. | Phone entries are backed up by syncing them to the desktop (decided). The user guide asks people to sync their phones often, and explains the 4-hour gap. |
| 6 | **Forgotten Super Admin password** | Nobody can add users or restore a backup any more. | The requirements decided there is no recovery. The user guide asks the Super Admin to keep the password somewhere safe. |
| 7 | **Someone else on the same Wi-Fi** | They could read entries or account data while it is being sent. | All sync data is scrambled with the one-time key in the QR code, and the server only runs while the sync screen is open. |
| 8 | **University Google account** | Backups go to a university student account (1505011.mnu@ugrad.cse.buet.ac.bd). Such accounts are often closed some time after graduation, which would delete every backup. The university can also stop outside apps from using Drive. | In Phase 0, check that the app can sign in and upload with this account, and how much storage it has. A Google account for the mosque will be added later. Connecting it needs no new version of the app (BAK-1), and a full backup goes to it straight away (BAK-8). |
| 9 | **Losing the Android signing key** | Google Play needs the same key as the APK. If the key is lost, phones must uninstall the APK version first, which deletes any unsynced entries. | Back up the signing key and its password in two safe places from the first APK release. Sync all phones before anyone moves to Google Play. |
| 10 | **Google Drive filling up** | A backup every 4 hours for a year is about 2,200 backups. Copying every photo each time would quickly fill the account. | Photos are uploaded only once. Each backup holds just the database, which is small. Phase 0 checks how much storage the account has. |

---

## 9. Decisions

### Decided (13 November 2026)

| Topic | Decision |
|---|---|
| Technology | **Flutter** |
| macOS | **Testing only**, on the developer's Mac (macOS 26). Not given to users, so no Apple Developer account is needed. |
| Google account | **1505011.mnu@ugrad.cse.buet.ac.bd** for now: it owns the Google Cloud project, the backups and the Excel files. A Google account for the mosque will be added later (see Risk 8). |
| Backups kept | **One year.** Older backups are deleted automatically. |
| Phone data safety | **Synced to the desktop**, which backs it up to Google Drive. No separate phone backup. |
| Photo labels | **Ask for a label**, otherwise use the entry's description plus a number. |
| Windows signing certificate | **Bought later.** Installers are unsigned until then. |
| Android delivery | **APK on GitHub Releases first**, then **Google Play** later. Each phone must allow "install unknown apps" for the APK. |
| Publishing | **The developer** publishes each new version after the customer's feedback. |

### Still open

Nothing right now. Development can start with Phase 0.
