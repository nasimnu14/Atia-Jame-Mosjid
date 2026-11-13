# Test Cases — Atia Jame Masjid Accounts App (v1)

> Source: `docs/atia-jame-masjid-accounts-requirement.md` (Draft, 13 Nov 2026), with `docs/idea.md` for background
> Type: Feature (whole-product requirements) · Generated: 13 Nov 2026

## Scope
Manual test cases for every **Must-have (v1)** requirement: General (GEN), Users and sign-in (USR), Income (INC), Expense (EXP), Finding and listing (FND), Entry details (DET), Editing and cancelling (EDT), Balance (BAL), PDF reports (PDF), Google Drive backup (BAK), Excel uploads (XLS), Updates (UPD), Android app (MOB) and Phone → desktop sync (SYN). Nice-to-have items (NTH-1 to NTH-5) are not covered. Out-of-scope items are only checked where the app must *not* offer them (e.g. no permanent delete, no desktop → phone entries).

## Test Data

Cases refer to these fixtures. **"Today" is 13/11/2026 (a Friday).** If testing on another day, shift all dates by the same number of days, keeping the weekdays.

| Fixture | Contents |
|---|---|
| **Accounts** | `superadmin` / `Sa@12345` (Super Admin, name "Super Admin") · `admin1` / `Admin@123` (Admin) · `user1` / `User@123` (User) · `olduser` / `Old@1234` (User, **disabled**) |
| **Approvers** | সভাপতি, সেক্রেটারী, ক্যাশিয়ার |
| **Opening balance** | ৳10,000 dated 01/10/2026 |
| **Data set D1** (desktop) | **Income:** #101 আব্দুল করিম, 13/11/2026, ৳5,000, ঠিকানা "আটিয়া" · #102 name blank, 13/11/2026, ৳500 · #103 ডাব বিক্রি, 05/11/2026, ৳1,200 · #104 মৃত: হাজী রহিম উদ্দিন, 20/10/2026, ৳2,000 · #105 সেলিম মিয়া, 13/11/2026, ৳3,000, **cancelled** by `admin1`, reason "ভুল এন্ট্রি" <br>**Expense:** #201 রহিম ট্রেডার্স, খরচ বাবদ "বালু ২ টলি", সেক্রেটারী, 13/11/2026, ৳4,000 · #202 করিম মিস্ত্রি, খরচ বাবদ "মজুরি", ক্যাশিয়ার, 10/11/2026, ৳1,500 · #203 নুর হার্ডওয়্যার, খরচ বাবদ "রড", সভাপতি, 13/11/2026, ৳800, **cancelled**, reason "দুইবার লেখা হয়েছে" |
| **Expected D1 figures** | Current balance **৳13,200** (10,000 + 8,700 − 5,500) · Nov 2026: income ৳6,700 (3 entries + 1 cancelled), expense ৳5,500 (2 + 1 cancelled), net ৳1,200 · Oct 2026: income ৳2,000 · Year 2026: income ৳8,700, expense ৳5,500, net ৳3,200 · This week (Sat 07/11 – Fri 13/11): income #101, #102 (+#105 cancelled) = ৳5,500; expense #201, #202 (+#203 cancelled) = ৳5,500 |
| **Photos** | `P-small.jpg` (~300 KB, 1200×1600) · `P-large.jpg` (~8 MB, 4000×6000 phone photo of a paper receipt with handwriting) · `P1.jpg` … `P11.jpg` (11 ordinary photos) |
| **Phone** | Android 12+ device on the same Wi-Fi as the desktop, app installed |

## Open Questions
- **No implementation exists yet** (repo has only `docs/` and `images/`), so every rule below is taken from the requirements doc, not code. Re-check boundaries once the app is built.
- **Receipt number format:** INC-4 ("highest + 1") implies numbers only. Are letters, leading zeros (e.g. `007`) or spaces allowed? What is suggested when no entry exists yet (assumed `1`)?
- **Cancelled receipt numbers:** does a cancelled entry's number still count for "highest + 1" and for the duplicate warning? Cases below assume **yes** (the paper receipt was used).
- **Duplicate receipt number on desktop:** INC-5 says "warn". Can the user save anyway after the warning, or is it blocked? Cases assume **warn, then allow save on confirmation**.
- **Amount format:** whole Taka only (assumption). Is `100.50` rejected or rounded? Is there a maximum amount? Cases assume decimals are **rejected**.
- **Lakh grouping in Bangla:** is ৳১,০০,০০০ (Bangladeshi grouping) or ৳১০০,০০০ expected for amounts ≥ 1 lakh? Same question for English mode.
- **Future dates / dates before the opening-balance date:** allowed for entries? Is "From" after "To" in a date range rejected?
- **Password rules and usernames:** minimum length/complexity? Are usernames unique and case-insensitive? What if a disabled user is signed in at the moment they are disabled?
- **Editing scope:** which fields can an Admin edit (receipt number? date?) Can a cancelled entry be edited or un-cancelled?
- **EDT-2 approval:** does one approval cover only that one action, or a session? Is the approving Admin recorded as the editor, or the User?
- **Approver list:** can approvers be removed/hidden, or only added and renamed?
- **"Large photo":** what size/resolution triggers shrinking, and what is the target?
- **MOB-3:** does the phone balance include entries already synced from that phone, or only unsynced ones?
- **SYN-8 duplicate flag:** how does an Admin see and clear the "duplicate" mark? Are phone-to-phone duplicates (two phones, same number) flagged too?
- **SYN-3:** does the QR code expire after a time limit as well as after one use?
- **Daily Excel (XLS-1/2/9):** which date names the 12 AM file (the day that just ended, or the new day)? If the app was closed for several days, is one file uploaded per missed day or just one? Which Drive folder?
- **Backup retention** (doc Open Question 1), **lost phone** (Q2), **oldest macOS version** (Q4) and **photo labels** (Q5) are still open and affect BAK, MOB and compatibility cases.

## Test Cases

### Positive / Happy Path

#### General (GEN) and compatibility

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-001 | App starts in Bangla by default (GEN-3) | Fresh install on desktop, no data | 1. Launch the app. | First-run screen and all labels are in Bangla. | High |
| TC-002 | Switch language to English and it is remembered (GEN-2, GEN-3) | D1 loaded, signed in as `user1`, app in Bangla | 1. Open the language switch and choose English.<br>2. Visit Home, Income, Expense, Settings.<br>3. Close and reopen the app; sign in. | Every screen, button and message is in English after step 1, and the app reopens in English after step 3. | High |
| TC-003 | Bangla digits for amounts and dates (GEN-4, GEN-5) | D1 loaded, app in Bangla | 1. Look at the current balance on Home.<br>2. Open the Income list for this month. | Balance shows "৳ ১৩,২০০"; dates show e.g. "১৩/১১/২০২৬"; counts and totals use Bangla digits; every amount has the ৳ sign. | High |
| TC-004 | English digits in English mode (GEN-4) | D1 loaded, app in English | 1. Look at the balance and the Income list for this month. | Balance shows "৳ 13,200"; dates show "13/11/2026". | Medium |
| TC-005 | Type a date with English digits (GEN-7) | Signed in as `user1` | 1. Open Add Income.<br>2. Type `05/11/2026` in তারিখ.<br>3. Fill রশিদ নং `300`, টাকা `100`; save. | Entry saves with date 05/11/2026. | High |
| TC-006 | Type a date with Bangla digits (GEN-8) | Signed in as `user1` | 1. Open Add Income.<br>2. Type `০৫/১১/২০২৬` in তারিখ.<br>3. Fill রশিদ নং `301`, টাকা `100`; save. | Entry saves with date 05/11/2026 (shown as ০৫/১১/২০২৬ in Bangla). | High |
| TC-007 | Calendar opens on the date already in the field (GEN-7) | Add Income open | 1. Type `20/10/2026` in তারিখ.<br>2. Click the calendar button next to the field. | Calendar opens on October 2026 with the 20th highlighted. | Medium |
| TC-008 | Calendar opens on today when the field is empty; picking fills the field (GEN-7) | Add Income open, তারিখ empty | 1. Click the calendar button.<br>2. Pick 12 November 2026. | Calendar opens on November 2026 with 13th marked as today; after picking, the field shows 12/11/2026. | Medium |
| TC-009 | Same features on Windows and macOS (GEN-1) | App installed on Windows 10, Windows 11 and the agreed oldest macOS | 1. On each OS, run TC cases for: first-run setup, add income, add expense, search, PDF, backup, Excel upload, sync. | All cases pass with the same behaviour and layout on every OS. | High |
| TC-010 | Android app installs and runs on Android 12 (Constraints) | Android 12 device | 1. Install the Android app.<br>2. Open it. | App installs and opens to the "scan desktop QR code" screen. | High |
| TC-011 | Everything except backup and update check works offline (Constraints) | D1 loaded, desktop Wi-Fi/ethernet disconnected | 1. Add an income and an expense.<br>2. Search, list, open details, make a PDF.<br>3. Sync a phone over a local Wi-Fi with no internet. | All steps succeed; only backup/Excel upload/update check report that there is no internet. | High |

#### Users and sign-in (USR)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-012 | First run: set up a new Super Admin (USR-3) | Fresh install, no data | 1. Launch the app.<br>2. Choose "set up new Super Admin".<br>3. Enter name `Super Admin`, username `superadmin`, password `Sa@12345`; submit. | Two choices are offered (new Super Admin / restore from Google Drive). After step 3 the account is created and the sign-in screen (or Home) appears. | High |
| TC-013 | Sign in with valid credentials (USR-1) | Accounts fixture exists | 1. Launch the app.<br>2. Enter `user1` / `User@123`; sign in. | Home screen opens showing the current balance; nothing is reachable before sign-in. | High |
| TC-014 | Super Admin adds an Admin (USR-4) | Signed in as `superadmin` | 1. Open Users.<br>2. Add name `Admin Two`, username `admin2`, password `Admin2@123`, role Admin; save.<br>3. Sign out; sign in as `admin2`. | `admin2` is listed with role Admin and can sign in; Admin-only actions (Edit, Cancel, Settings) are available. | High |
| TC-015 | Super Admin adds a User (USR-4) | Signed in as `superadmin` | 1. Add username `user2`, password `User2@123`, role User.<br>2. Sign in as `user2`. | `user2` signs in; Edit, Cancel, Settings, Users and opening balance are not available. | High |
| TC-016 | Role choice offers only Admin and User (USR-3, USR-4) | Signed in as `superadmin`, Add User form open | 1. Open the role selector. | Only "Admin" and "User" are offered; "Super Admin" is not. | High |
| TC-017 | Super Admin changes a user's role (USR-5) | Signed in as `superadmin`; `user1` is a User | 1. Change `user1` role to Admin; save.<br>2. Sign out; sign in as `user1`. | `user1` now has Admin actions (Edit, Cancel, opening balance). | High |
| TC-018 | Super Admin resets a user's password (USR-5) | Signed in as `superadmin` | 1. Reset `user1` password to `NewUser@1`.<br>2. Sign in as `user1` with `User@123`.<br>3. Sign in as `user1` with `NewUser@1`. | Step 2 fails; step 3 succeeds. | High |
| TC-019 | Super Admin disables a user; history kept (USR-5, USR-6) | D1 loaded; `user1` added income #101 | 1. As `superadmin`, disable `user1`.<br>2. Open the details of income #101. | `user1` shows as disabled in Users (not deleted); #101 still shows "added by user1". | High |
| TC-020 | User changes own password (USR-7) | Signed in as `user1` | 1. Open Change Password.<br>2. Current `User@123`, new `User@999`; save.<br>3. Sign out; sign in with `User@999`. | Password changes; sign-in with the new password works and the old one does not. | High |
| TC-021 | Super Admin changes own password (USR-5, USR-7) | Signed in as `superadmin` | 1. Change Password: current `Sa@12345`, new `Sa@99999`.<br>2. Sign out; sign in with `Sa@99999`. | Sign-in succeeds with the new password. | High |
| TC-022 | Entry records who added it and when (USR-8) | Signed in as `user1` at a noted time | 1. Add income #400, ৳100.<br>2. Open its details. | Details show "added by user1" and the date and time it was saved. | High |
| TC-023 | Entry records who edited and cancelled it and when (USR-8) | Income #400 exists (added by `user1`) | 1. As `admin1`, edit #400 amount to ৳150.<br>2. As `superadmin`, cancel #400 with reason "পরীক্ষা".<br>3. Open details. | Details show added by `user1`, edited by `admin1` with time, cancelled by `superadmin` with time and reason. | High |
| TC-024 | Role matrix for User (USR-2) | Signed in as `user1` | 1. Check every menu, list and details screen. | Available: add entries, search, list, details, PDF, Excel upload, sync QR, change own password. Not available: edit, cancel, opening balance, approver list, Google account/backup/settings, restore, users. | High |
| TC-025 | Role matrix for Admin (USR-2) | Signed in as `admin1` | 1. Check every menu. | Admin has all User actions plus edit, cancel, opening balance, approver list, Google account/backup/settings. Restore and Users are not available. | High |
| TC-026 | Passwords are not stored as plain text (USR-9) | Accounts fixture on desktop; phone synced | 1. Open the desktop data file and the phone's app data (debug build / device file explorer).<br>2. Search for `User@123`. | The plain password is not found; only a hashed value is stored, on both desktop and phone. | High |

#### Income — আয় (INC)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-027 | Add income with all fields (INC-1) | Signed in as `user1`; highest income receipt is 105 | 1. Open Add Income.<br>2. রশিদ নং `106`, দাতার নাম `মোঃ হাসান`, তারিখ `13/11/2026`, টাকা `2500`, ঠিকানা `ঘোড়াশাল`, attach `P-small.jpg`.<br>3. Save. | Entry saves and appears in this month's Income list with all values; balance rises by ৳2,500. | High |
| TC-028 | Blank name is saved as unknown (INC-3) | Signed in as `user1` | 1. Add income #107, name blank, 13/11/2026, ৳300; save.<br>2. View it in Bangla, then switch to English. | Name shows "অজ্ঞাত" in Bangla and "Unknown" in English, in the list and details. | High |
| TC-029 | Next receipt number is suggested (INC-4) | D1 loaded (highest income #105) | 1. Open Add Income. | রশিদ নং is pre-filled with `106`. | High |
| TC-030 | Suggested receipt number can be changed (INC-4) | D1 loaded | 1. Open Add Income (106 suggested).<br>2. Change it to `250`; fill ৳100 and today's date; save.<br>3. Open Add Income again. | Entry saves as #250; the next suggestion is `251`. | Medium |
| TC-031 | Attach 10 photos (INC-6) | Signed in as `user1` | 1. Add income #108, ৳100.<br>2. Attach `P1.jpg` … `P10.jpg`; save.<br>3. Open details. | All 10 photos are saved and shown on the details screen. | High |
| TC-032 | View a photo at full size (INC-7) | Income with `P-small.jpg` attached | 1. Open its details.<br>2. Click the photo. | Photo opens at full size and can be closed to return to details. | Medium |
| TC-033 | Large photo is shrunk but readable (INC-9) | Signed in as `user1` | 1. Add income #109 with `P-large.jpg`; save.<br>2. Open the photo at full size.<br>3. Check the stored photo's file size (data folder or exported backup). | Stored photo is much smaller than 8 MB; the handwriting on the receipt is still readable. | High |
| TC-034 | Admin adds and removes a photo on a saved entry (INC-8) | Signed in as `admin1`; income #101 has no photos | 1. Edit #101, add `P-small.jpg`; save.<br>2. Edit #101, remove it; save.<br>3. Open details. | Both changes save; details show #101 as edited by `admin1`. | Medium |

#### Expense — ব্যয় (EXP)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-035 | Add expense with all fields (EXP-1) | Signed in as `user1`; D1 loaded | 1. Open Add Expense.<br>2. ভাউচার নং `204`, নাম `রহিম ট্রেডার্স`, খরচ বাবদ `সিমেন্ট ১০ বস্তা`, অনুমোদনকারী `সভাপতি`, তারিখ `13/11/2026`, টাকা `5500`, ঠিকানা `পলাশ`, attach `P-small.jpg`.<br>3. Save. | Entry saves and appears in this month's Expense list; balance falls by ৳5,500. | High |
| TC-036 | Expense numbers are a separate series (EXP-3) | D1 loaded (income #101 exists) | 1. Add expense with ভাউচার নং `101`, valid other fields; save. | Saves with no duplicate warning. | High |
| TC-037 | Next voucher number is suggested (EXP-4) | D1 loaded (highest expense #203) | 1. Open Add Expense. | ভাউচার নং is pre-filled with `204` (not based on income numbers). | High |
| TC-038 | Approver is chosen from the list (EXP-6) | Approvers fixture | 1. Open Add Expense.<br>2. Open অনুমোদনকারী. | A list shows exactly সভাপতি, সেক্রেটারী, ক্যাশিয়ার; one can be selected. | High |
| TC-039 | Admin adds an approver (EXP-7) | Signed in as `admin1` on desktop | 1. Open the approver list; add `কোষাধ্যক্ষ`; save.<br>2. Open Add Expense → অনুমোদনকারী. | `কোষাধ্যক্ষ` appears in the list. | High |
| TC-040 | Renaming an approver does not change old expenses (EXP-8) | D1 loaded (#201 approved by সেক্রেটারী); signed in as `admin1` | 1. Rename সেক্রেটারী to `সাধারণ সম্পাদক`.<br>2. Open #201 details.<br>3. Open Add Expense → অনুমোদনকারী. | #201 still shows "সেক্রেটারী"; the list for new expenses shows "সাধারণ সম্পাদক". | High |
| TC-041 | Expense photos up to 10 and full-size view (EXP-4) | Signed in as `user1` | 1. Add expense #205 with `P1.jpg` … `P10.jpg`; save.<br>2. Open a photo at full size. | All 10 saved; photo opens at full size. | Medium |

#### Finding and listing (FND)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-042 | Open income by receipt number (FND-1) | D1 loaded | 1. On Income, type `103` in receipt search. | Details of #103 ডাব বিক্রি, ৳1,200 open. | High |
| TC-043 | Open expense by voucher number (FND-1, EXP-5) | D1 loaded | 1. On Expense, type `201`. | Details of #201 রহিম ট্রেডার্স open (not income #201 or anything else). | High |
| TC-044 | Partial name search (FND-2) | D1 loaded | 1. On Income, search `করিম`.<br>2. On Expense, search `করিম`. | Step 1 lists #101 আব্দুল করিম; step 2 lists #202 করিম মিস্ত্রি. | High |
| TC-045 | List entries on a chosen date (FND-3) | D1 loaded | 1. On Income, choose date 13/11/2026. | Lists #101, #102 and #105 (cancelled) — count 3, total ৳5,500. | High |
| TC-046 | Today (FND-4) | D1 loaded; today 13/11/2026 | 1. On Expense, choose "Today". | Lists #201 and #203 (cancelled); total ৳4,000. | High |
| TC-047 | This week starts on Saturday (FND-4, Constraints) | D1 loaded; today Fri 13/11/2026 | 1. On Income, choose "This week". | Shows 07/11–13/11/2026: #101, #102, #105 (cancelled); #103 (05/11) is not included; total ৳5,500. | High |
| TC-048 | Income screen opens on this month (FND-4, FND-6) | D1 loaded | 1. Open Income. | Shows November 2026 by default: #101, #102, #103, #105 (cancelled); count 4, total ৳6,700. | High |
| TC-049 | Expense screen opens on this month (FND-6, EXP-5) | D1 loaded | 1. Open Expense. | Shows November 2026: #201, #202, #203 (cancelled); total ৳5,500. | High |
| TC-050 | This year (FND-4) | D1 loaded | 1. On Income, choose "This year". | All 5 income entries; total ৳8,700. | Medium |
| TC-051 | Chosen month, week, day and year (FND-4) | D1 loaded | 1. Choose month October 2026.<br>2. Choose the week containing 05/11/2026.<br>3. Choose day 20/10/2026.<br>4. Choose year 2025. | 1: #104 only (৳2,000). 2: 31/10–06/11 shows #103 only. 3: #104 only. 4: empty list, count 0, total ৳0. | High |
| TC-052 | Date range (FND-5) | D1 loaded | 1. On Income, set From `01/11/2026`, To `10/11/2026`. | Only #103 (৳1,200); count 1. | High |
| TC-053 | Every list shows count and total (FND-7) | D1 loaded | 1. Open each list type: today, week, month, year, date, range, name search. | Each shows the number of entries and the total amount. | High |
| TC-054 | Selecting a row opens details (FND-9) | D1 loaded | 1. Click #102 in the Income list.<br>2. Click #202 in a name search result. | The matching details screen opens each time. | High |

#### Entry details (DET)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-055 | Details show every field and all photos (DET-1) | Income #106 from the "add income with all fields" case | 1. Open #106 details. | Shows receipt no., name, date, amount, address, added by and time, and all attached photos. | High |
| TC-056 | Details show edit and cancellation info (DET-1) | D1 loaded (#105 cancelled by `admin1`) | 1. Open #105 details. | Shows it is cancelled, by `admin1`, when, and the reason "ভুল এন্ট্রি". | High |
| TC-057 | Export an income entry as PDF with photos (DET-2, DET-3) | Income with 3 photos; app in Bangla | 1. Open its details; choose Export PDF.<br>2. Choose the Desktop folder; save.<br>3. Open the PDF. | PDF is saved where chosen and contains every field, added/edited info and all 3 photos, in Bangla. | High |
| TC-058 | Export an expense entry as PDF (DET-2, EXP-5) | D1 loaded; app in English | 1. Open #201 details; Export PDF; save.<br>2. Open the PDF. | PDF shows voucher no., payee, purpose, approver, date, amount, address, in English. | Medium |

#### Editing and cancelling (EDT)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-059 | Admin edits an entry (EDT-1) | D1 loaded; signed in as `admin1` | 1. Edit income #103 amount from ৳1,200 to ৳1,500; save.<br>2. Check Home balance and November total. | Entry shows ৳1,500; balance becomes ৳13,500; November income total ৳7,000. | High |
| TC-060 | User gets an edit approved on the spot (EDT-2) | D1 loaded; signed in as `user1` | 1. Open #102; choose Edit.<br>2. When asked, enter `admin1` / `Admin@123`.<br>3. Change amount to ৳600; save. | Edit is allowed and saved; details record the edit (who/when). | High |
| TC-061 | User gets a cancel approved on the spot (EDT-2) | D1 loaded; signed in as `user1` | 1. Open #102; choose Cancel.<br>2. Enter `superadmin` / `Sa@12345`.<br>3. Reason "ভুল তারিখ"; confirm. | #102 is cancelled with the reason. | High |
| TC-062 | Admin cancels with a reason (EDT-3) | D1 loaded; signed in as `admin1` | 1. Open expense #202; Cancel.<br>2. Reason "ভুল ভাউচার"; confirm. | #202 shows as cancelled with the reason; it stays in the list. | High |
| TC-063 | Cancelled entry leaves all totals (EDT-4) | Previous case done (#202 cancelled) | 1. Check Home balance.<br>2. Check November expense total and summary. | Balance rises to ৳14,700; November expense total is ৳4,000; summary net is ৳2,700. | High |

#### Balance and summary (BAL)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-064 | Set the opening balance (BAL-1) | Fresh data; signed in as `admin1` | 1. Open opening balance.<br>2. Enter ৳10,000, date 01/10/2026; save. | Home shows current balance ৳10,000. | High |
| TC-065 | Current balance formula (BAL-3) | D1 loaded | 1. Open Home. | Shows ৳13,200 (cancelled #105 and #203 not counted). | High |
| TC-066 | Balance updates right after a new entry (BAL-3) | D1 loaded | 1. Add income ৳1,000.<br>2. Add expense ৳300.<br>3. Return to Home. | Balance is ৳13,900. | High |
| TC-067 | Change the opening balance later (BAL-2) | D1 loaded; signed in as `superadmin` | 1. Change opening balance to ৳12,000; save. | Current balance becomes ৳15,200. | High |
| TC-068 | Period summary (BAL-4) | D1 loaded | 1. Open summary for "This month".<br>2. Open summary for range 01/10/2026–31/10/2026. | 1: income ৳6,700, expense ৳5,500, income − expense ৳1,200. 2: income ৳2,000, expense ৳0, net ৳2,000. | High |

#### PDF reports (PDF)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-069 | Income-only PDF for this month (PDF-1, PDF-2, PDF-3) | D1 loaded; app in Bangla | 1. Reports → PDF; period "This month"; contents "Income only".<br>2. Save and open. | Header has আটিয়া জামে মসজিদ and address (আটিয়া, ঘোড়াশাল, পলাশ, নরসিংদী) and the period; rows show date, receipt no., name, amount; total ৳৬,৭০০. | High |
| TC-070 | Expense-only PDF includes purpose (PDF-3) | D1 loaded | 1. PDF for "This month", "Expense only". | Rows show date, voucher no., name, purpose (খরচ বাবদ), amount; total ৳5,500. | High |
| TC-071 | Both with summary (PDF-2, PDF-3) | D1 loaded | 1. PDF for "This year", "Both". | Contains income list (৳8,700), expense list (৳5,500) and income − expense ৳3,200. | High |
| TC-072 | Bangla PDF renders joined letters (PDF-4) | D1 loaded; app in Bangla | 1. Make a "This year", "Both" PDF.<br>2. Zoom in on মৃত: হাজী রহিম উদ্দিন, রহিম ট্রেডার্স, নুর হার্ডওয়্যার, সেক্রেটারী, ক্যাশিয়ার. | All Bangla text, including যুক্তাক্ষর (দ্দ, ক্র, র্ড, ্য), displays correctly with no broken or boxed characters; digits are Bangla. | High |
| TC-073 | English PDF (PDF-4) | D1 loaded; app in English | 1. Make an income PDF for this month. | Headings, labels and digits are English; Bangla names still display correctly. | Medium |
| TC-074 | User chooses where to save (PDF-5) | D1 loaded | 1. Make any PDF.<br>2. In the save dialog choose `Documents`, name `nov-report.pdf`. | File is saved at Documents/nov-report.pdf. | High |
| TC-075 | Cancelled entries in PDF (PDF-6) | D1 loaded | 1. Make a "This month", "Both" PDF. | #105 and #203 are listed and marked cancelled; totals are ৳6,700 / ৳5,500 (they are not counted). | High |
| TC-076 | Custom range PDF (PDF-1) | D1 loaded | 1. PDF for range 15/10/2026–06/11/2026, "Income only". | Contains #104 and #103 only; total ৳3,200; period printed as 15/10/2026 – 06/11/2026. | Medium |

#### Google Drive backup (BAK)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-077 | Connect a Google account (BAK-1) | Signed in as `admin1`; internet on | 1. Settings → connect Google account.<br>2. Complete Google sign-in and consent. | Settings shows the connected Google account. | High |
| TC-078 | Automatic backup every 4 hours (BAK-2) | Google connected; D1 with photos; app left open | 1. Note the last backup time.<br>2. Wait 4 hours (or move the system clock forward 4 h).<br>3. Check Google Drive. | A new backup appears on Drive about 4 hours after the previous one; last backup time updates. | High |
| TC-079 | Backup holds data, photos and settings (BAK-2) | A backup made from D1 with photos, language English, approver কোষাধ্যক্ষ added | 1. Restore that backup on a clean install (see restore case).<br>2. Check entries, photos, language, approvers, opening balance. | Everything matches the source. | High |
| TC-080 | Last successful backup time shown (BAK-5) | At least one successful backup | 1. Open Settings/Backup. | Date and time of the last successful backup are shown. | High |
| TC-081 | Backup on start if more than 4 hours have passed (BAK-4) | Last backup 5 hours ago; app closed; internet on | 1. Open the app; sign in. | A backup starts straight away and the last backup time updates. | High |
| TC-082 | Retry when the internet returns (BAK-3) | Google connected; internet off when a backup is due | 1. Wait until a backup is due.<br>2. Turn internet on. | Backup runs soon after the connection returns, without user action. | High |
| TC-083 | Restore on a new computer at first run (BAK-6, USR-3) | Backup of D1 on Drive; fresh install on another computer | 1. Launch; choose "restore from Google Drive backup".<br>2. Connect the same Google account; pick the latest backup.<br>3. Sign in as `superadmin` / `Sa@12345`. | All D1 entries, photos, users, settings and balance ৳13,200 are back; the old Super Admin password works. | High |
| TC-084 | Super Admin restores from settings (BAK-6) | D1 backed up; then income #500 ৳1,000 added locally | 1. As `superadmin`, Settings → Restore; choose the D1 backup.<br>2. Confirm the warning. | A warning says current data will be replaced; after restore #500 is gone and balance is ৳13,200. | High |

#### Excel on Google Drive (XLS)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-085 | Daily upload at 12 AM (XLS-1) | D1 loaded; Google connected; app open and online at 11:55 PM | 1. Wait past 12:00 AM.<br>2. Check Google Drive. | A new .xlsx file named with the date is on Drive, containing all income and expense entries and no photos. | High |
| TC-086 | Missed daily upload when the app was closed (XLS-2) | App closed from 11 PM to 9 AM | 1. Open the app at 9 AM; sign in. | The missed day's file is uploaded straight away. | High |
| TC-087 | Missed daily upload when offline (XLS-2) | App open, internet off at 12 AM | 1. Turn internet on at 2 AM. | The day's file is uploaded once online. | High |
| TC-088 | Manual upload for a month, both (XLS-3, XLS-4) | D1 loaded; signed in as `user1` | 1. Excel → Upload; period month November 2026; "Both".<br>2. Open the file on Drive. | Income sheet has #101, #102, #103, #105; expense sheet has #201, #202, #203. | High |
| TC-089 | Manual upload income only and expense only (XLS-4) | D1 loaded | 1. Upload "This month", "Income only".<br>2. Upload "This month", "Expense only". | First file has only an income sheet; second only an expense sheet. | Medium |
| TC-090 | Manual upload for a day, a week and a custom range (XLS-3) | D1 loaded | 1. Upload day 13/11/2026.<br>2. Upload week of 07/11/2026.<br>3. Upload range 01/10/2026–31/10/2026. | Each file contains only the entries in that period. | Medium |
| TC-091 | Sheet layout and cancelled status (XLS-5) | Upload of D1 for this year | 1. Open the file. | Separate income and expense sheets; one row per entry; one column per field; a status column marks #105 and #203 as cancelled with their reasons. | High |
| TC-092 | Amounts and dates are real Excel values (XLS-6) | Upload of D1 made with app in Bangla | 1. Open in Excel.<br>2. Sort by date; in an empty cell, SUM the income amount column. | Values use English digits; sorting by date is in date order; SUM works (its result includes every row, cancelled ones too — the file has raw values). | High |
| TC-093 | Column headings follow app language (XLS-7) | D1 loaded | 1. Upload with app in Bangla.<br>2. Switch to English; upload again. | First file has Bangla headings (তারিখ, রশিদ নং …); second has English headings. | Medium |
| TC-094 | Upload result and last daily upload time (XLS-8) | Google connected | 1. Do a manual upload.<br>2. Open the Excel/Backup status area. | A success message appears; the date and time of the last successful daily upload is shown. | High |
| TC-095 | Each day makes a new file (XLS-9) | Daily uploads ran on 12/11 and 13/11 | 1. Check the Drive folder. | Two separate dated files exist; the earlier file is not replaced. | High |

#### Updates (UPD)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-096 | New version is announced (UPD-1) | Version 1.0.0 installed; 1.0.1 published on GitHub Releases; internet on | 1. Open the app. | App tells the user that version 1.0.1 is available. | High |
| TC-097 | Install the update from inside the app (UPD-2) | Previous case | 1. Choose Install/Update.<br>2. Let the app restart. | App restarts as 1.0.1 (version shown in About). | High |
| TC-098 | All data intact after update (UPD-3) | D1 with photos, extra users, approvers, Google account, language English, duplicate-flagged phone entry | 1. Update to the new version.<br>2. Check entries, photos, users and roles, settings, approvers, sync/duplicate flags, balance. | Everything is unchanged; balance ৳13,200. | High |
| TC-099 | Data conversion is backed up first (UPD-4) | A test release that changes the data format | 1. Update.<br>2. Check for a backup made just before conversion.<br>3. Check entries. | A pre-conversion backup exists with a time just before the update; all data is present and correct after conversion. | High |

#### Android app (MOB)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-100 | New phone must scan the QR code before sign-in (MOB-5) | Fresh install on phone | 1. Open the app.<br>2. Scan the desktop QR code. | Before scanning, only the scan screen is available (no sign-in). After scanning, the sign-in screen appears. | High |
| TC-101 | Sign in on phone with desktop credentials (MOB-4) | Phone has scanned the QR code once | 1. Sign in as `user1` / `User@123`. | Sign-in succeeds; role is User (no edit/cancel). | High |
| TC-102 | Add income on phone with a camera photo (MOB-1, MOB-2) | Signed in on phone as `user1` | 1. Add income #110, ৳700.<br>2. Add a photo using the camera; save. | Entry saved on phone with the photo; marked not synced. | High |
| TC-103 | Add expense on phone with a gallery photo (MOB-1, MOB-2) | Phone synced at least once (approver list received) | 1. Add expense #210, payee `রহিম ট্রেডার্স`, purpose `বালু`, approver from list, ৳1,000.<br>2. Pick a gallery photo; save. | Approver list matches desktop; entry saves with the photo. | High |
| TC-104 | Phone balance covers only this phone's entries (MOB-3) | Phone has income ৳700 and expense ৳1,000 of its own; desktop has D1 | 1. Open phone Home. | Phone shows −৳300 (or its own figures only) with a clear note that this is not the mosque's real balance. | High |
| TC-105 | Phone features and language match desktop (MOB-1) | Phone with several own entries | 1. Switch Bangla/English.<br>2. Search by receipt no. and name, list by period, open details, view summary, make a PDF and a single-entry PDF. | All work as on desktop for the phone's own entries; Bangla digits and text display correctly. | High |
| TC-106 | Admin edits and cancels an unsynced entry on phone (MOB-1) | Signed in on phone as `admin1`; unsynced income #110 exists | 1. Edit #110 amount to ৳750.<br>2. Cancel another unsynced entry with a reason. | Both actions succeed and are recorded. | Medium |
| TC-107 | Phone photos are shrunk (INC-9, MOB-2) | Phone camera at max resolution | 1. Add an entry with a camera photo of a receipt.<br>2. View it full size. | Photo is smaller than the original and still readable. | Medium |

#### Phone → desktop sync (SYN)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-108 | Desktop shows a sync QR code (SYN-2) | Signed in on desktop as `user1` | 1. Open the Sync screen. | A QR code is shown. | High |
| TC-109 | New phone entries start as not synced (SYN-1) | Signed in on phone | 1. Add income #111. | #111 is shown as not synced. | High |
| TC-110 | Sync sends unsynced entries with all photos (SYN-4, SYN-9) | Phone has 3 unsynced entries (one with 10 photos) | 1. Desktop: open Sync.<br>2. Phone: scan the QR code; wait to finish.<br>3. Desktop: open each entry. | Desktop says 3 entries received; all 3 entries and all photos are on the desktop; desktop balance and lists include them. | High |
| TC-111 | Entries become synced and read-only on phone (SYN-5, SYN-7) | Previous case completed | 1. On phone, open a synced entry as `admin1`. | Entry shows as synced; edit, cancel and photo changes are not available. | High |
| TC-112 | Next sync sends only new entries (SYN-4) | One sync done; 1 new entry added on phone | 1. Sync again with a new QR code. | Desktop says 1 entry received; no earlier entry is duplicated. | High |
| TC-113 | New user reaches the phone (SYN-10) | Desktop: `superadmin` added `user3` / `User3@123` after the last sync | 1. Sync the phone.<br>2. On phone, sign in as `user3`. | Sign-in succeeds with the desktop role. | High |
| TC-114 | Password change reaches the phone (SYN-10) | `user1` changed password to `User@999` on desktop after last sync | 1. Sync.<br>2. On phone, sign in with `User@123`, then `User@999`. | Old password fails; new one works. | High |
| TC-115 | Approver list change reaches the phone (SYN-10) | Desktop added কোষাধ্যক্ষ after last sync | 1. Sync.<br>2. On phone, Add Expense → অনুমোদনকারী. | কোষাধ্যক্ষ is listed. | Medium |
| TC-116 | More than one phone syncs to the same desktop (Constraints) | Phones A and B each with 2 unsynced entries | 1. Sync phone A.<br>2. Show a new QR code; sync phone B. | Desktop receives 2 + 2 entries; nothing is mixed up or lost. | Medium |
| TC-117 | Sync works on local Wi-Fi with no internet (Constraints) | Router with no internet; phone and desktop on it | 1. Sync. | Sync completes. | High |

### Negative

#### General (GEN)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-118 | Impossible date 31/02/2026 is rejected (GEN-8) | Add Income open | 1. Type `31/02/2026`; try to save. | Not saved; message says the date does not exist. | High |
| TC-119 | 29/02 in a non-leap year is rejected (GEN-8) | Add Income open | 1. Type `29/02/2026`; try to save. | Not saved; message says the date does not exist. | Medium |
| TC-120 | Month 13 is rejected (GEN-8) | Add Expense open | 1. Type `১৩/১৩/২০২৬`; try to save. | Not saved; message explains the date is invalid. | Medium |
| TC-121 | Non-date text is rejected (GEN-7) | Add Income open | 1. Type `ab/cd/efgh` and then `2026-11-13`; try to save each. | Neither is saved; the message asks for DD/MM/YYYY. | Medium |

#### Users and permissions (USR)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-122 | Wrong password (USR-1) | Accounts fixture | 1. Sign in as `user1` / `wrong`. | Sign-in refused with a message; no data shown. | High |
| TC-123 | Disabled user cannot sign in (USR-6) | `olduser` is disabled | 1. Sign in as `olduser` / `Old@1234`. | Sign-in refused; message says the account is disabled (or credentials are not accepted). | High |
| TC-124 | Admin cannot manage users (USR-4, USR-5) | Signed in as `admin1` | 1. Look for Users / Add User / reset password / disable. | None are available. | High |
| TC-125 | Nobody can reset the Super Admin password (USR-5) | Signed in as `superadmin` | 1. Open Users; select the `superadmin` row. | No reset-password, disable or change-role option for the Super Admin. | High |
| TC-126 | Super Admin role cannot be handed over (USR-3) | Signed in as `superadmin` | 1. Try to change `admin1` role; open the role list.<br>2. Try to change own role. | "Super Admin" is never offered; own role cannot be changed. | High |
| TC-127 | Change own password with wrong current password (USR-7) | Signed in as `user1` | 1. Change Password: current `bad`, new `X@12345`. | Refused; old password still works. | High |
| TC-128 | User cannot set opening balance or open settings (USR-2, BAL-2) | Signed in as `user1` | 1. Look for opening balance, Google account, backup, app settings. | Not available. | High |
| TC-129 | Admin cannot restore a backup (BAK-6) | Signed in as `admin1` | 1. Open Settings/Backup. | No restore option. | High |
| TC-130 | User cannot edit the approver list (EXP-7) | Signed in as `user1` | 1. Look for approver list management. | Not available. | Medium |
| TC-131 | Approver list cannot be edited on the phone (EXP-7) | Signed in on phone as `admin1` | 1. Look for approver list management. | Not available on the phone. | Medium |

#### Income and expense entry (INC, EXP)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-132 | Income without receipt number (INC-2) | Add Income open | 1. Clear রশিদ নং; fill date and ৳100; save. | Not saved; the field is marked required. | High |
| TC-133 | Income without date (INC-2) | Add Income open | 1. Clear তারিখ; fill #300 and ৳100; save. | Not saved; date marked required. | High |
| TC-134 | Income without amount (INC-2) | Add Income open | 1. Leave টাকা empty; save. | Not saved; amount marked required. | High |
| TC-135 | Income amount 0 (INC-2) | Add Income open | 1. Enter টাকা `0`; save. | Not saved; message says amount must be more than 0. | High |
| TC-136 | Income amount negative (INC-2) | Add Income open | 1. Enter টাকা `-500`; save. | Not saved (or minus sign not accepted). | High |
| TC-137 | Non-numeric and decimal amount (INC-2, Constraints) | Add Income open | 1. Enter `abc`; save.<br>2. Enter `100.50`; save. | Neither is saved; message asks for a whole Taka amount (see Open Questions). | Medium |
| TC-138 | Duplicate income receipt number warns (INC-5) | D1 loaded | 1. Add income with রশিদ নং `101`, ৳100. | A warning says #101 is already used before saving. | High |
| TC-139 | 11th photo is not allowed (INC-6) | Add Income with `P1.jpg` … `P10.jpg` attached | 1. Try to add `P11.jpg`. | Not allowed; a message says the limit is 10 photos. | High |
| TC-140 | User cannot add/remove photos on a saved entry without approval (INC-8) | Signed in as `user1`; #101 saved | 1. Open #101; try to add or remove a photo. | Not allowed unless an Admin/Super Admin approves (EDT-2). | High |
| TC-141 | Expense without payee, purpose or approver (EXP-2) | Add Expense open | 1. Leave নাম empty; save.<br>2. Fill নাম, leave খরচ বাবদ empty; save.<br>3. Fill খরচ বাবদ, leave অনুমোদনকারী empty; save. | Each attempt is refused, naming the missing field. | High |
| TC-142 | Expense amount 0 (EXP-2) | Add Expense open | 1. All fields valid, টাকা `0`; save. | Not saved. | High |
| TC-143 | Approver cannot be typed freely (EXP-6) | Add Expense open | 1. Click অনুমোদনকারী and type `রফিক`. | Free text is not accepted; only list values can be chosen. | High |
| TC-144 | Duplicate expense voucher number warns (EXP-4) | D1 loaded | 1. Add expense with ভাউচার নং `201`. | Duplicate warning shown. | High |

#### Finding (FND)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-145 | Receipt number not found (FND-1) | D1 loaded | 1. On Income, search receipt `999`. | Clear "not found" message; no crash. | Medium |
| TC-146 | Name search with no match (FND-2) | D1 loaded | 1. Search name `জাহাঙ্গীর`. | Empty result with count 0, total ৳0. | Medium |
| TC-147 | Date range with From after To (FND-5) | D1 loaded | 1. From `30/11/2026`, To `01/11/2026`. | Not run; message asks for a valid range (see Open Questions). | Low |

#### Editing and cancelling (EDT)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-148 | User cannot edit without approval (EDT-1) | Signed in as `user1` | 1. Open #101; choose Edit; when asked for approval, choose Cancel/Back. | Entry cannot be changed. | High |
| TC-149 | Approval with User credentials is refused (EDT-2) | Signed in as `user1`; approval prompt open | 1. Enter `user2` / `User2@123`. | Refused; message says an Admin or Super Admin is needed. | High |
| TC-150 | Approval with wrong Admin password is refused (EDT-2) | Approval prompt open | 1. Enter `admin1` / `wrong`. | Refused; entry not editable. | High |
| TC-151 | Approval by a disabled Admin is refused (EDT-2, USR-6) | `admin2` disabled; approval prompt open | 1. Enter `admin2` / `Admin2@123`. | Refused. | Medium |
| TC-152 | Cancel without a reason (EDT-3) | Signed in as `admin1` | 1. Cancel #103; leave reason empty; confirm. | Not cancelled; reason marked required. | High |
| TC-153 | No permanent delete anywhere (EDT-3, Out of Scope) | Signed in as `superadmin` | 1. Look in lists, details, right-click menus and keyboard Delete key on desktop and phone. | No delete option exists; Delete key does nothing to the entry. | High |

#### Backup, Excel and updates (BAK, XLS, UPD)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-154 | Backup failure is reported (BAK-5) | Google connected; internet off when backup is due | 1. Wait until a backup is due. | User is told the backup failed; last successful time is unchanged. | High |
| TC-155 | Google access revoked (BAK-5) | Google connected, then app access removed in the Google account | 1. Wait for or trigger the next backup. | Failure is reported with a hint to reconnect the account. | Medium |
| TC-156 | Manual Excel upload offline (XLS-8) | Internet off | 1. Upload this month's Excel. | Failure message; no false "success". | High |
| TC-157 | Failed update keeps the old version working (UPD-5) | 1.0.0 with D1; an update that fails (e.g. internet cut mid-download, or a corrupt installer) | 1. Start the update; make it fail.<br>2. Open the app. | Version 1.0.0 opens and all D1 data is there. | High |
| TC-158 | No update available (UPD-1) | Latest version installed | 1. Open the app / check for updates. | No update prompt; a manual check says the app is up to date. | Low |

#### Android and sync (MOB, SYN)

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-159 | Wrong password on phone (MOB-4) | Phone synced | 1. Sign in as `user1` / `wrong`. | Refused. | High |
| TC-160 | Disabled user cannot sign in on phone after sync (SYN-10, USR-6) | `user1` disabled on desktop after last sync | 1. Sync.<br>2. Sign in on phone as `user1`. | Refused. | High |
| TC-161 | A QR code works for one sync only (SYN-3) | Phone A synced using QR code Q1 | 1. Without refreshing the desktop, make phone B (or A again) scan Q1. | Rejected; desktop receives nothing; phone says to scan a new code. | High |
| TC-162 | Only the phone that scanned the current QR code may send (SYN-3) | Desktop showed Q1, then refreshed to Q2 | 1. A phone sends using Q1. | Rejected; no entries saved. | High |
| TC-163 | Desktop never sends entries to the phone (SYN-6) | D1 on desktop; phone with no entries | 1. Sync.<br>2. Open phone lists for this year. | Phone has no D1 entries; only users and approvers arrived. | High |
| TC-164 | Synced entry cannot be changed on phone (SYN-7) | Synced entry on phone; signed in as `superadmin` | 1. Try edit, cancel, add photo. | All blocked; message says corrections are made on the desktop. | High |
| TC-165 | Phone and desktop on different networks (Constraints) | Phone on mobile data, desktop on Wi-Fi | 1. Scan the QR code. | Phone reports it cannot reach the desktop; entries stay not synced. | Medium |

### Edge Cases

| ID | Title | Preconditions | Steps | Expected Result | Priority |
|---|---|---|---|---|---|
| TC-166 | First receipt number with no entries (INC-4) | Fresh data | 1. Open Add Income.<br>2. Open Add Expense. | Both suggest `1` (see Open Questions). | Low |
| TC-167 | Cancelled highest number still counts (INC-4, INC-5) | D1 (highest income #105 is cancelled) | 1. Open Add Income.<br>2. Type `105`. | Suggests `106`; typing 105 shows the duplicate warning (see Open Questions). | Medium |
| TC-168 | Minimum amount ৳1 (INC-2) | Add Income open | 1. Enter টাকা `1`; save. | Saved. | Medium |
| TC-169 | Large amount and lakh grouping (GEN-4) | Add Income open, app in Bangla | 1. Enter ৳1,25,00,000; save.<br>2. Check the list, balance and PDF. | Saved; shown with the agreed grouping (see Open Questions) in every place, with no overflow or cut-off. | Medium |
| TC-170 | Valid leap day (GEN-8) | Add Income open | 1. Type `29/02/2028`; save. | Saved. | Low |
| TC-171 | Exactly 10 photos, remove one, add another (INC-6) | New entry with 10 photos attached | 1. Remove one photo.<br>2. Add `P11.jpg`; save. | Allowed; entry has 10 photos. | Medium |
| TC-172 | Week boundary: Friday vs Saturday (FND-4) | Entries on Fri 06/11/2026 and Sat 07/11/2026 | 1. Choose the week of 07/11/2026. | Includes 07/11, excludes 06/11. | Medium |
| TC-173 | Range across a year boundary (FND-5) | Entries on 30/12/2026 and 02/01/2027 | 1. Range 25/12/2026–05/01/2027. | Both entries listed; totals correct. | Low |
| TC-174 | Empty period PDF (PDF-1) | No entries in March 2026 | 1. Make a PDF for March 2026, "Both". | PDF is made with headers, an empty list and totals ৳0 (no error). | Low |
| TC-175 | Many-page PDF (PDF-3) | 300 entries in 2026 | 1. Make a "This year", "Both" PDF. | All 300 rows appear across pages; headings repeat or remain clear; totals correct. | Medium |
| TC-176 | Edit changes receipt number to a used one (INC-5, EDT-1) | Signed in as `admin1`; D1 | 1. Edit #103, change number to `101`. | Duplicate warning shown. | Medium |
| TC-177 | Edit an expense after its approver was renamed (EXP-8) | #201 approved by সেক্রেটারী; renamed to সাধারণ সম্পাদক | 1. As `admin1`, edit #201 amount only; save. | Approver stays "সেক্রেটারী" unless the Admin picks a new one. | Medium |
| TC-178 | Role changed while the user is signed in (USR-5) | `user1` signed in on desktop | 1. As `superadmin` on the same desktop (switch user), make `user1` an Admin.<br>2. `user1` signs in again. | New role applies from the next sign-in at the latest. | Low |
| TC-179 | Language switch mid-form (GEN-3) | Add Income with fields filled | 1. Switch language before saving. | Typed values are kept (or a clear warning is shown before they are lost); after saving the entry is correct. | Low |
| TC-180 | Backup interrupted midway (BAK-3, BAK-5) | Large backup (many photos) running | 1. Cut internet during upload.<br>2. Restore internet. | Failure reported; backup retried; previous backup on Drive is not damaged. | High |
| TC-181 | App closed during a scheduled backup (BAK-4) | Backup due while the app is closed for 6 hours | 1. Open the app. | Backup runs at start. | Medium |
| TC-182 | Daily upload with cancelled entries and photos excluded (XLS-1, XLS-5) | D1 with photos | 1. Check the daily file. | No photo data or links; cancelled rows present with status and reason. | Medium |
| TC-183 | Sync interrupted halfway (SYN-5) | Phone has 5 unsynced entries with photos | 1. Start sync; turn off phone Wi-Fi after the desktop shows the first entries arriving.<br>2. Turn Wi-Fi on; sync with a new QR code.<br>3. Compare desktop entries with the phone. | No entry is lost or saved twice; all 5 end up on the desktop exactly once and marked synced on the phone. | High |
| TC-184 | Phone killed during sync (SYN-5) | Sync in progress | 1. Force-stop the phone app mid-sync.<br>2. Reopen; sync again. | Same as above: no loss, no duplicates. | High |
| TC-185 | Phone entry with a receipt number the desktop already has (SYN-8) | Desktop has income #101; phone has unsynced income #101 | 1. Sync. | Desktop saves the phone entry and marks it as a duplicate for an Admin to check. | High |
| TC-186 | Same number in the other series is not a duplicate (SYN-8, EXP-3) | Desktop has income #101; phone has unsynced **expense** #101 | 1. Sync. | Saved with no duplicate mark. | Medium |
| TC-187 | Sync with no unsynced entries (SYN-9, SYN-10) | Phone fully synced; a new user added on desktop | 1. Sync. | Desktop shows 0 entries received; the new user can sign in on the phone. | Medium |
| TC-188 | Phone sign-in offline after sync (MOB-4) | Phone synced; then all networks off | 1. Sign in on phone. | Sign-in works with the stored accounts. | Medium |
| TC-189 | Old accounts used until next sync (Constraints) | `user1` disabled on desktop; phone not yet synced | 1. Sign in on phone as `user1`. | Still allowed (accounts change only at next sync); refused after the next sync. | Low |
| TC-190 | Phone app sent to background while adding an entry (MOB-2) | Add Income with fields filled | 1. Open the camera from the form; take a photo.<br>2. Switch to another app for a minute; return. | Form data and the new photo are still there. | Medium |
| TC-191 | Android version below 12 (Constraints) | Android 11 device | 1. Try to install the app. | Install is blocked (or the store/APK reports the device is not supported). | Low |
| TC-192 | Restore on a computer that already has data (BAK-6) | D1 on desktop; an older backup on Drive | 1. As `superadmin`, restore the older backup. | Clear warning before replacing; after restore, data exactly matches the older backup. | High |
