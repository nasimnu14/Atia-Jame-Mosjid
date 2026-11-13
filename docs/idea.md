I want to build a simple windows application for keeping accounce.
The localization must be in bangla. You can keep English as well. Two language should be supported.
The follwing feature should be available: 

- Income (আয়): There should a receipt numbe for each income. There might have name or by default unknown should be placed if not provided. Date of income, amount, address of the provider (optional). 
 * The application should be able to fetch the details of an income by id or search by name or date.
 * All the income should be shown for the current month, month, week, year or day. 
 * We should able to see all the income selected by date range. 
 * An optinal photo can be added.
- Expense (ব্যয়): A receipt number should be attached for that Expense. Every expnse must have a name. There must be an amount. The person who approved the expense should be present. Date, amountand optional address should be present. 
 * All the feature of income shold also be available for expense as well.

- Every entry can be edited if an admin password is provided. 
- Sample images are in images/ folder.
- Summary: Income - Expense. 

 * User should be able to create a pdf including Income, expense or with both.
- Current Balance.
- The data should be backed up to google drive in every 4 hours basis.
- The applciation must have updating feature. No data should be lost if we upgrade the applciation.
- The mobile phone should have all the feature. A QR code should be shown by which mobile app can transfer all his data to the desktop app. So there must be synced flag for each data. ONly the unsynced data will be passed.