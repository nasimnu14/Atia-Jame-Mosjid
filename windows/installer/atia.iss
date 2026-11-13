; Inno Setup script for the Windows installer.
; Build:  iscc /DAppVersion=1.0.0 windows\installer\atia.iss
; (after `flutter build windows --release`). Output: build\installer\Atia-Setup-<version>.exe
;
; The installer is unsigned until the Windows code-signing certificate is bought
; (Windows shows an "unknown publisher" warning). To sign later, add a SignTool
; line and pass /S to iscc.
;
; Data safety: the program is installed in the user's program folder; the
; accounts data is in the per-user app-data folder (%APPDATA%), which this
; installer never touches, so updating or reinstalling cannot lose data.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

[Setup]
AppId={{B7A1D3E2-5C44-4C1B-9E55-0A7A1A71A001}
AppName=Atia Masjid Accounts
AppVersion={#AppVersion}
AppPublisher=Atia Jame Masjid
DefaultDirName={autopf}\AtiaMasjidAccounts
DefaultGroupName=Atia Masjid Accounts
DisableProgramGroupPage=yes
; Per-user install: no administrator password needed, and an update can replace the program.
PrivilegesRequired=lowest
OutputDir=..\..\build\installer
OutputBaseFilename=Atia-Setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
; Used by the in-app updater (/SILENT /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS).
CloseApplications=yes
RestartApplications=yes
UninstallDisplayIcon={app}\atia_masjid_accounts.exe

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{autoprograms}\Atia Masjid Accounts"; Filename: "{app}\atia_masjid_accounts.exe"
Name: "{autodesktop}\Atia Masjid Accounts"; Filename: "{app}\atia_masjid_accounts.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a desktop icon"; Flags: unchecked

[Run]
Filename: "{app}\atia_masjid_accounts.exe"; Description: "Start Atia Masjid Accounts"; Flags: nowait postinstall skipifsilent
