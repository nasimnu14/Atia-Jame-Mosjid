# Atia Jame Masjid Accounts App — Requirements

| | |
|---|---|
| **Status** | Draft |
| **Date** | 13 November 2026 |
| **Sources** | `docs/idea.md`, sample photos in `images/`, Q&A with the requester on 13 Nov 2026 |

---

## Summary

A simple desktop app for **Windows and macOS** for **আটিয়া জামে মসজিদ** (আটিয়া, ঘোড়াশাল, পলাশ, নরসিংদী) to keep its accounts. It records every income (আয়) and expense (ব্যয়) with its paper receipt number, makes entries easy to find, shows the current balance, and exports PDF reports. The app works in **Bangla and English**, backs itself up to **Google Drive every 4 hours**, uploads an **Excel copy of all entries to Google Drive every day**, and can be updated without losing data. An **Android app** with the same features sends its new entries to the desktop when it scans a QR code. Everyone signs in with their own account, and only the **Super Admin** can add new users.

## Background / Problem

The mosque keeps its accounts on paper today (see `images/`):

- **Income:** Each donation or sale gets a numbered receipt. It is then copied into an income ledger with the columns *তারিখ* (date), *দাতার নাম* (donor name), *রশিদ নং* (receipt no.) and *টাকা* (amount). Not all income is a donation. Some is from sales (e.g. *ডাব বিক্রি*, *ভাঙ্গারি বিক্রি*), and some donations are given in the name of a deceased person (*মৃত: …*). Some rows have no donor name.
- **Expense:** Each payment has a printed voucher with *ক্রমিক নং* (serial no.), *তারিখ*, *নাম* (payee), *ঠিকানা* (address), *খরচ বাবদ* (purpose), the amount in figures and in words, and signatures from the receiver, cashier and secretary. It is then copied into an expense ledger with the columns *তারিখ*, *বিবরণ* (description), *ভাউচার নং* (voucher no.), *টাকার পরিমাণ* (amount) and *মন্তব্য* (remarks).

Finding one entry, adding up a month, or working out the current balance means going through the books by hand, and the books are the only copy of the records.

## Goals

1. Every income and expense is recorded once, with its receipt number, and can be found by number, name or date.
2. The committee can see the current balance, and income minus expense for any period, at any time.
3. Reports and single entries can be shared as PDF files, and the records as Excel sheets on Google Drive.
4. No data is lost: records are backed up automatically, and updating the app keeps all data.
5. Entries made on a phone reach the desktop without anyone typing them in again.

## Users / Stakeholders

| Who | Role in the app |
|---|---|
| **Super Admin** | One person. Can do everything an Admin can. Is the only one who can add users, change their roles, disable them, reset their passwords, and restore a backup. |
| **Admin** | Edits and cancels entries, sets the opening balance, manages backup and settings. |
| **User** (data-entry person) | Adds income and expense entries on the desktop or the phone, searches entries, views details, makes PDF and Excel reports. |
| **Mosque committee** (e.g. secretary, cashier) | Reads balances and PDF reports. Approves expenses. The approver's name is saved on each expense. |
| **Donors and payees** | Appear in the records. They do not use the app. |

## Decisions So Far

These were agreed with the requester on 13 Nov 2026:

| Topic | Decision |
|---|---|
| Phone ↔ desktop sync | **Entries go one way only: phone → desktop.** The desktop holds the master record. |
| Mobile platform | **Android only.** |
| Receipt numbers | **Typed from the paper receipt book.** The app suggests the next number and warns about duplicates. |
| Expense "name" | **Payee + purpose**, as on the paper voucher: who was paid (*নাম*) and what for (*খরচ বাবদ*). |
| Starting balance | **One opening balance** is entered. Old paper entries are not typed in. |
| Removing a wrong entry | **An Admin or the Super Admin cancels it, with a reason.** The entry stays visible but is left out of all totals. Nothing is permanently deleted. |
| Users and roles | Everyone signs in with their own account. There are three roles: **Super Admin, Admin, User.** Only the Super Admin can add users. |
| Phone sign-in | **Same username and password as on the desktop.** User accounts are copied to the phone each time it scans the desktop's QR code. |
| Desktop platforms | **Windows and macOS.** |
| Super Admin password | **Only the Super Admin can change it.** Nobody else can reset it, and there is no recovery. |
| Handing over Super Admin | **Not allowed.** The Super Admin role stays with the person who set it up. |
| Publishing updates | **GitHub Releases.** |
| Expense approver | **Chosen from a list** that an Admin or the Super Admin adds to and edits. |
| Cancelled entries in PDFs | **Shown and marked as cancelled**, and left out of the totals. |
| Oldest Android version | **Android 12.** |
| Number of desktops | **Only one** desktop computer runs the app. |
| Photos | **Up to 10 photos per entry.** Large photos are shrunk. |
| Daily Excel upload | **A new file for each day**, uploaded at **12 AM**, or when the app next opens if it was closed then. Uploading manually is also possible. |
| Date fields | **Type the date or pick it from a calendar.** |

---

## Requirements

Each requirement has an ID (e.g. **INC-3**) so it can be referred to later.

### Must-have (required for v1)

#### General (GEN)

- **GEN-1** The desktop app must run on Windows and macOS computers, with the same features on both.
- **GEN-2** Every screen, message and PDF report must be available in both Bangla and English.
- **GEN-3** The user must be able to switch between Bangla and English inside the app. The app must remember the choice and start in Bangla by default.
- **GEN-4** In Bangla mode, numbers, amounts and dates must be shown with Bangla digits (e.g. ১৩/১১/২০২৬, ৳ ৫,০০০).
- **GEN-5** All amounts must be in Bangladeshi Taka (৳).
- **GEN-6** Any signed-in user can add a new entry.
- **GEN-7** Every date field must let the user either type the date (DD/MM/YYYY) or pick it from a calendar that opens from a button next to the field. The calendar must open on the date already in the field, or on today if the field is empty.
- **GEN-8** A typed date may use Bangla or English digits. The app must not accept a date that does not exist (e.g. 31/02/2026) and must say why.

#### Users and sign-in (USR)

What each role can do:

| Action | User | Admin | Super Admin |
|---|:-:|:-:|:-:|
| Add income and expense entries | ✓ | ✓ | ✓ |
| Search, list, view details, make PDFs, upload Excel | ✓ | ✓ | ✓ |
| Sync a phone (show the QR code) | ✓ | ✓ | ✓ |
| Change own password | ✓ | ✓ | ✓ |
| Edit or cancel entries | — | ✓ | ✓ |
| Set the opening balance | — | ✓ | ✓ |
| Add and edit the expense approver list | — | ✓ | ✓ |
| Connect the Google account, manage backup and app settings | — | ✓ | ✓ |
| Restore data from a backup | — | — | ✓ |
| Add users, change roles, disable users, reset passwords | — | — | ✓ |

- **USR-1** Everyone must sign in with their own username and password before using the app, on both desktop and phone.
- **USR-2** Each user has exactly one role: Super Admin, Admin or User. The table above shows what each role can do.
- **USR-3** The first time the desktop app starts, it must offer two choices: set up a new Super Admin account (name, username, password), or restore everything from a Google Drive backup (BAK-6). There is only one Super Admin, and the role cannot be passed to another person.
- **USR-4** Only the Super Admin can add a new user and choose their role (Admin or User).
- **USR-5** Only the Super Admin can change a user's role, reset a user's password, or disable a user. The Super Admin's own password cannot be reset by anyone; only the Super Admin can change it (USR-7).
- **USR-6** A disabled user cannot sign in. Users are never deleted, so the records always show who added each entry.
- **USR-7** Every user can change their own password by entering their current one.
- **USR-8** Every entry must record which user added it and when. If it is edited or cancelled, the entry must also record who did it and when.
- **USR-9** Passwords must be stored in a protected (hashed) form, never as plain text, on both desktop and phone.

#### Income — আয় (INC)

Each income entry has these fields:

| Field | Bangla | Required? | Notes |
|---|---|---|---|
| Receipt number | রশিদ নং | Yes | Typed from the paper receipt book |
| Name | দাতার নাম | No | Shown as "অজ্ঞাত" / "Unknown" if left blank |
| Date | তারিখ | Yes | |
| Amount | টাকা | Yes | Must be more than 0 |
| Address | ঠিকানা | No | |
| Photos | ছবি | No | Up to 10 photos, e.g. the paper receipt or the item that was sold |

- **INC-1** The user must be able to add an income entry with the fields above.
- **INC-2** The app must not save an income entry if a required field is missing or the amount is 0 or less.
- **INC-3** If the name is left blank, the entry must be saved as unknown and shown as "অজ্ঞাত" in Bangla and "Unknown" in English.
- **INC-4** When a new income entry is started, the app must suggest the next receipt number (the highest income receipt number + 1). The user must be able to change it.
- **INC-5** The app must warn the user when the receipt number is already used by another income entry.
- **INC-6** The user must be able to attach up to 10 photos to an entry, for example a photo of the receipt and photos of the item sold or bought. The app must not allow an 11th photo.
- **INC-7** The user must be able to view each photo of an entry at full size.
- **INC-8** Adding or removing a photo on a saved entry counts as an edit, so only an Admin or the Super Admin can do it (see EDT-1 and EDT-2).
- **INC-9** When a large photo is attached, the app must shrink it before saving, so it stays clear enough to read the receipt but takes less space in backups and syncs. This applies on both desktop and phone.

#### Expense — ব্যয় (EXP)

Each expense entry has these fields:

| Field | Bangla | Required? | Notes |
|---|---|---|---|
| Receipt number | ভাউচার নং | Yes | Typed from the paper voucher book |
| Payee name | নাম | Yes | The person or shop that was paid |
| Purpose | খরচ বাবদ | Yes | What the money was for, e.g. "বালু ২ টলি" |
| Approved by | অনুমোদনকারী | Yes | Chosen from the approver list (EXP-6) |
| Date | তারিখ | Yes | |
| Amount | টাকা | Yes | Must be more than 0 |
| Address | ঠিকানা | No | |
| Photos | ছবি | No | Up to 10 photos, e.g. the paper voucher or the item that was bought |

- **EXP-1** The user must be able to add an expense entry with the fields above.
- **EXP-2** The app must not save an expense entry if a required field is missing or the amount is 0 or less.
- **EXP-3** Expense receipt numbers must be a separate series from income receipt numbers. The same number may appear once in income and once in expense.
- **EXP-4** Receipt number suggestion, the duplicate warning and photos must work for expenses exactly as INC-4 to INC-9 describe for income.
- **EXP-5** Every feature in the sections below (finding, listing, entry details, editing, cancelling, PDF, Excel) must work for expenses as well as for income.
- **EXP-6** "Approved by" must be chosen from an approver list (e.g. সভাপতি, সেক্রেটারী, ক্যাশিয়ার). It cannot be typed freely.
- **EXP-7** Only an Admin or the Super Admin can add a name to the approver list or edit one, on the desktop.
- **EXP-8** Each expense must keep the approver name it was saved with. Editing the approver list later must not change existing expenses.

#### Finding and listing entries (FND)

These apply to both income and expense.

- **FND-1** The user must be able to open an entry by typing its receipt number.
- **FND-2** The user must be able to search entries by name. Typing part of a name must be enough.
- **FND-3** The user must be able to list all entries on a chosen date.
- **FND-4** The user must be able to list entries for: today, this week, this month, this year, and any chosen day, week, month or year.
- **FND-5** The user must be able to list entries between two chosen dates (a date range).
- **FND-6** The income and expense screens must open on the current month.
- **FND-7** Every list must show how many entries it contains and their total amount.
- **FND-8** Cancelled entries must appear in lists clearly marked as cancelled, and must not be counted in any total.
- **FND-9** Selecting an entry in any list or search result must open its details screen (see DET-1).

#### Entry details (DET)

These apply to both income and expense.

- **DET-1** Every entry must have a details screen that shows all of its information: every field, who added it and when, any edit or cancellation (who, when and the reason), and all of its photos.
- **DET-2** From the details screen, the user must be able to export the entry as a PDF that contains all of its information and all of its photos.
- **DET-3** The entry PDF must follow PDF-4 (app language, correct Bangla text) and PDF-5 (user chooses where to save it).

#### Editing and cancelling (EDT)

- **EDT-1** Only an Admin or the Super Admin can edit a saved entry.
- **EDT-2** When a User needs an entry edited or cancelled, an Admin or the Super Admin must be able to approve it on the spot by entering their own username and password.
- **EDT-3** A wrong entry can only be cancelled, not deleted. Only an Admin or the Super Admin can cancel an entry, and they must write a reason.
- **EDT-4** A cancelled entry must stay in the records with its reason and must be left out of all totals, the balance and the summaries.

#### Balance and summary (BAL)

- **BAL-1** An Admin or the Super Admin must be able to enter one opening balance and its date. This is the cash in hand when the mosque starts using the app.
- **BAL-2** Only an Admin or the Super Admin can change the opening balance later.
- **BAL-3** The main screen must always show the current balance:
  **Current balance = opening balance + all income − all expense** (cancelled entries are not counted).
- **BAL-4** For any period in FND-4 or FND-5, the user must be able to see a summary showing total income, total expense, and income − expense.

#### PDF reports (PDF)

- **PDF-1** The user must be able to make a PDF for any period in FND-4 or FND-5.
- **PDF-2** The user must be able to choose what the PDF contains: income only, expense only, or both with a summary.
- **PDF-3** The PDF must show the mosque name and address, the chosen period, a list of entries (date, receipt number, name, and purpose for expenses, amount), and the totals. A PDF with both income and expense must also show income − expense.
- **PDF-4** The PDF must be in the language the app is set to, and Bangla text must display correctly, including joined letters (যুক্তাক্ষর).
- **PDF-5** The user must be able to choose where the PDF file is saved.
- **PDF-6** Cancelled entries must be listed in the PDF, clearly marked as cancelled, and left out of all totals.

#### Google Drive backup (BAK)

- **BAK-1** An Admin or the Super Admin must be able to connect the app to a Google account once, in settings.
- **BAK-2** The app must back up all data, including photos and settings, to Google Drive every 4 hours.
- **BAK-3** If a backup is due but there is no internet, the app must try again when the connection comes back.
- **BAK-4** If more than 4 hours have passed since the last successful backup when the app starts, the app must back up straight away.
- **BAK-5** The app must show the date and time of the last successful backup, and must tell the user when a backup fails.
- **BAK-6** The Super Admin must be able to restore all data from a Google Drive backup, for example on a new computer. Only the Super Admin can restore, because restoring replaces all current data.

#### Excel sheets on Google Drive (XLS)

- **XLS-1** Every day at 12 AM, the desktop app must upload an Excel file (.xlsx) containing all income and expense entries to the Google account connected in BAK-1. Photos are not included.
- **XLS-2** If a day's upload is missed because the app was closed at 12 AM or there was no internet, the app must do it as soon as it is next open and online.
- **XLS-3** The user must be able to upload an Excel file to Google Drive at any time for a chosen period: a day, a week, a month, or a custom date range.
- **XLS-4** For an upload, the user must be able to choose income only, expense only, or both.
- **XLS-5** In the Excel file, income and expense must be on separate sheets, with one row per entry and one column per field. Cancelled entries must be included and marked in a status column, along with the reason.
- **XLS-6** Amounts and dates must be saved as real Excel numbers and dates, so they can be sorted and added up in Excel. Excel shows them with English digits, even when the app is in Bangla.
- **XLS-7** Column headings must be in the language the app is set to.
- **XLS-8** The app must tell the user whether each upload succeeded or failed, and must show the date and time of the last successful daily upload.
- **XLS-9** Each day's upload must be a new file named with its date, so Google Drive keeps a dated history. Earlier files must not be replaced.

#### Updates (UPD)

- **UPD-1** New versions are published on GitHub Releases. The app must check there for a newer version and tell the user when one is available.
- **UPD-2** The user must be able to install the update from inside the app.
- **UPD-3** After an update, every entry, photo, setting, user account and sync flag must still be there and unchanged.
- **UPD-4** If an update changes how data is stored, the app must convert the existing data automatically, and must back it up before converting.
- **UPD-5** If an update fails, the previous version must still open and work with all its data.

#### Android app (MOB)

- **MOB-1** There must be an Android app with the same income, expense, finding, listing, entry details, editing, cancelling, summary and PDF features as the desktop app, and the same Bangla/English support.
- **MOB-2** On the phone, the user must be able to add an entry's photos by taking them with the camera or picking them from the gallery.
- **MOB-3** The phone app must show balances and summaries only for entries made on that phone, and must say so clearly on screen so they are not mistaken for the mosque's real balance.
- **MOB-4** People must sign in on the phone with the same username, password and role they have on the desktop (see SYN-10).
- **MOB-5** A new phone must scan the desktop's QR code once before anyone can sign in on it.

#### Phone → desktop sync (SYN)

- **SYN-1** Every entry must have a **synced** flag. A new entry made on a phone starts as *not synced*.
- **SYN-2** The desktop app must have a sync screen that shows a QR code. The phone connects to the desktop by scanning it.
- **SYN-3** Only a phone that has scanned the current QR code may send data, and each QR code must work for one sync only.
- **SYN-4** Only *not synced* entries are sent, each with all of its photos.
- **SYN-5** The phone must mark an entry as synced only after the desktop confirms it has saved it. If the transfer stops halfway, nothing is lost and nothing is saved twice. The remaining entries are sent next time.
- **SYN-6** Entries go one way only, from phone to desktop. The desktop never sends entries to the phone.
- **SYN-7** Once an entry is synced, it must become read-only on the phone. Any later correction is made on the desktop, which holds the master record.
- **SYN-8** If a phone entry arrives with a receipt number the desktop already has (in the same series), the desktop must still save it and mark it as a duplicate for an Admin to check.
- **SYN-9** The desktop must show how many entries were received in each sync.
- **SYN-10** Each time a phone scans the QR code, the desktop must also send it the current user accounts (names, usernames, roles and protected passwords). This way new users, password changes and disabled users reach the phone. It must also send the current approver list (EXP-6). User accounts and the approver list are the only data that goes from desktop to phone.

### Nice-to-have (later / optional)

- **NTH-1** Print a single receipt or voucher in the same layout as the paper book, including the amount in words (*কথায়*).
- **NTH-2** Keep a history of every edit and cancellation: who, when, the old value and the new value.
- **NTH-3** A "Back up now" button.
- **NTH-4** Search expenses by purpose as well as by payee name (e.g. find all *রড* purchases).
- **NTH-5** Income types (e.g. donation, sale) so reports can be split by type.

---

## Out of Scope (v1)

- Sending entries from the desktop to the phone (two-way sync).
- An iPhone (iOS) app.
- Typing in the old paper ledger entries. Only an opening balance is entered.
- Permanently deleting entries.
- Running the desktop app on more than one computer at the same time.
- Recovering a forgotten Super Admin password, or handing the Super Admin role to another person.
- Bank accounts, budgets, or double-entry bookkeeping. The app tracks cash income and expense only.
- A website or online access to the records.

## Constraints & Assumptions

These are assumptions where `idea.md` gave no detail. Please confirm or correct them.

- The desktop app supports Windows 10 and 11, and recent versions of macOS. The Android app supports Android 12 and newer.
- A change to a user account (new user, new password, disabled user) reaches a phone only at its next sync. Until then, the phone uses the accounts it last received.
- Only one desktop computer runs the app. It holds the master record, and all data is stored on it.
- Every feature except backup and the update check works without internet.
- Phone and desktop sync over the same local Wi-Fi network. The QR code tells the phone how to reach the desktop, so no internet or online server is needed.
- More than one phone may sync with the same desktop.
- Dates use the English (Gregorian) calendar, as the paper ledgers do.
- The week starts on Saturday.
- If the Super Admin forgets their password, it cannot be recovered. Restoring a backup brings back the same password, so nobody could add users, reset passwords or restore a backup again. The Super Admin must keep the password safe.
- Amounts are whole Taka with no paisa, as in the paper records.
- An expense's purpose is required because the expense ledger lists every expense by its description.
- Backups run while the desktop app is open. BAK-3 and BAK-4 cover the time when it is closed or offline.
- The daily Excel upload and manual Excel uploads are done from the desktop, because it holds the full records. The phone app does not upload Excel files.

## Open Questions

1. **Backup account:** which Google account will hold the backups, and how many old backups should be kept?
2. **Lost phone:** entries that haven't been synced exist only on the phone. Should the phone back them up somewhere too?
3. **Who publishes updates:** updates go on GitHub Releases, but who will publish new versions?
4. **Oldest macOS version:** the answer was "macOS 18", but there is no macOS 18. Apple went from macOS 15 (Sequoia) to macOS 26 (Tahoe). Which one is meant?
5. **Photo labels:** the answer was "item photo". Does this mean photos are only of the item (not the receipt), so no labels are needed? Or should every photo be labelled "item photo"?
