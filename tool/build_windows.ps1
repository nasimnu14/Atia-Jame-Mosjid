<#
Builds the Windows installer on a Windows PC (same steps as .github/workflows/release.yml).

Needs on the PC: Flutter (with Visual Studio "Desktop development with C++") and Inno Setup 6.

Run from the project folder:
  powershell -ExecutionPolicy Bypass -File tool\build_windows.ps1

Optional:
  -Version 1.0.1       default: the version in pubspec.yaml
  -Repo owner/name     default: nasimnu14/Atia-Jame-Mosjid (where the in-app updater looks for releases)

Google sign-in: set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET as environment variables first.
Without them the build works, but the Backup page says "Google sign-in is not set up in this build".

Output (share both files): build\installer\Atia-Setup-<version>.exe and the matching .exe.sha256
#>
param(
  [string]$Version,
  [string]$Repo = "nasimnu14/Atia-Jame-Mosjid"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

# Run a command and stop at the first failure (PowerShell does not do this for programs).
function Run {
  & $args[0] $args[1..($args.Length - 1)]
  if ($LASTEXITCODE -ne 0) { throw "Failed: $($args -join ' ')" }
}

if (-not $Version) {
  $Version = (Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9.]+)').Matches[0].Groups[1].Value
}

$iscc = @(
  "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
  "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
  "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw "Inno Setup 6 not found. Install it from https://jrsoftware.org/isinfo.php" }

if (-not $env:GOOGLE_CLIENT_ID -or -not $env:GOOGLE_CLIENT_SECRET) {
  Write-Warning "GOOGLE_CLIENT_ID / GOOGLE_CLIENT_SECRET not set: Google Drive backup will be disabled in this build."
}

Run flutter pub get
Run dart run build_runner build --delete-conflicting-outputs
Run flutter gen-l10n
Run flutter build windows --release `
  "--dart-define=GITHUB_REPO=$Repo" `
  "--dart-define=GOOGLE_CLIENT_ID=$env:GOOGLE_CLIENT_ID" `
  "--dart-define=GOOGLE_CLIENT_SECRET=$env:GOOGLE_CLIENT_SECRET"

Run $iscc "/DAppVersion=$Version" windows\installer\atia.iss

$name = "Atia-Setup-$Version.exe"
$file = "build\installer\$name"
$hash = (Get-FileHash $file -Algorithm SHA256).Hash.ToLower()
"$hash  $name" | Out-File "$file.sha256" -Encoding ascii

Write-Host ""
Write-Host "Done. Share these two files:"
Write-Host "  $file"
Write-Host "  $file.sha256"
