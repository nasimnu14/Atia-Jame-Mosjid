/// The Super Admin that every new computer installation starts with (the
/// owner's request: no set-up screen on the computer). The password is stored
/// only as a bcrypt hash in the database, but it is written here, so it is
/// readable by anyone who can read the source code: change it in Settings
/// after the first sign-in.
const builtInAdminName = 'Nasim';
const builtInAdminUsername = 'nasimnu14';
const builtInAdminPassword = 'Sa@1234';
