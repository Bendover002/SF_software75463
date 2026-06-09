#Requires -Version 5.1
# ============================================================
#  Spotify Multi-Account Installer — Windows
#  Creates 5 isolated Spotify instances via APPDATA override
#  Each account gets its own data folder and a Desktop shortcut.
#
#  HOW TO RUN:
#    Right-click the file → "Run with PowerShell"
#    OR in PowerShell (as your normal user — NOT admin):
#      Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#      .\install-spotify-multi.ps1
# ============================================================

$ErrorActionPreference = "Stop"

# ── Config ────────────────────────────────────────────────────
$NUM_ACCOUNTS  = 5
$BaseDir       = "$env:LOCALAPPDATA\SpotifyAccounts"
$SpotifyExe    = "$env:APPDATA\Spotify\Spotify.exe"
$DesktopPath   = [Environment]::GetFolderPath("Desktop")

function Write-Header {
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "  ║   Spotify Multi-Account Installer    ║" -ForegroundColor Cyan
    Write-Host "  ║   Windows  —  5 Accounts             ║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Step($n, $total, $msg) {
    Write-Host "[$n/$total] $msg" -ForegroundColor Cyan
}

function Write-Ok($msg)   { Write-Host "       ✓  $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "       ⚠  $msg" -ForegroundColor Yellow }
function Write-Fail($msg) { Write-Host "✗ Error: $msg"  -ForegroundColor Red; exit 1 }

# ── Header ────────────────────────────────────────────────────
Write-Header

# ── Step 1: Ensure Spotify is installed ───────────────────────
Write-Step 1 3 "Checking for Spotify..."

if (Test-Path $SpotifyExe) {
    Write-Ok "Spotify found at $SpotifyExe"
} else {
    Write-Warn "Spotify not found — attempting install via winget..."
    try {
        $winget = Get-Command winget -ErrorAction SilentlyContinue
        if (-not $winget) {
            Write-Fail "winget not available. Please install Spotify from https://www.spotify.com/download/windows/ then re-run this script."
        }
        winget install --id Spotify.Spotify --silent `
              --accept-package-agreements --accept-source-agreements
        # Give the installer a moment to finish
        Start-Sleep -Seconds 5
        if (!(Test-Path $SpotifyExe)) {
            Write-Fail "Spotify installed but not found at expected path: $SpotifyExe`nPlease open Spotify once manually, then re-run this script."
        }
        Write-Ok "Spotify installed"
    } catch {
        Write-Fail "Could not install Spotify automatically: $_`nInstall it manually from https://www.spotify.com/download/windows/ then re-run."
    }
}

# ── Step 2: Create base directory ─────────────────────────────
Write-Step 2 3 "Creating account directories in $BaseDir..."

New-Item -ItemType Directory -Force -Path $BaseDir | Out-Null
Write-Ok "Base directory ready"

# ── Step 3: Create per-account launchers and Desktop shortcuts ─
Write-Step 3 3 "Creating $NUM_ACCOUNTS sandboxed Spotify accounts..."

$WshShell = New-Object -ComObject WScript.Shell

for ($i = 1; $i -le $NUM_ACCOUNTS; $i++) {

    # Isolated data directory for this account
    $AccountDir = "$BaseDir\Account$i"
    New-Item -ItemType Directory -Force -Path $AccountDir | Out-Null

    # ------------------------------------------------------------------
    # Launcher strategy:
    #   A hidden PowerShell process sets %APPDATA% to the account folder
    #   before spawning Spotify.  Spotify writes its profile to
    #   %APPDATA%\Spotify, so each instance stays fully isolated.
    # ------------------------------------------------------------------

    # PowerShell launcher script (.ps1) — runs silently
    $LauncherPs1 = "$BaseDir\LaunchAccount$i.ps1"
    @"
# Spotify Account $i — sandboxed launcher
`$env:APPDATA = '$AccountDir'
Start-Process '$SpotifyExe'
"@ | Set-Content -Path $LauncherPs1 -Encoding UTF8

    # Wrapper VBScript — invokes the .ps1 with no visible window
    $LauncherVbs = "$BaseDir\LaunchAccount$i.vbs"
    @"
Dim shell
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & "$LauncherPs1" & """", 0, False
Set shell = Nothing
"@ | Set-Content -Path $LauncherVbs -Encoding ASCII

    # Desktop shortcut  →  VBScript wrapper
    $ShortcutPath = "$DesktopPath\Spotify Account $i.lnk"
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath      = "wscript.exe"
    $Shortcut.Arguments       = "`"$LauncherVbs`""
    $Shortcut.WorkingDirectory = $BaseDir
    $Shortcut.Description     = "Spotify Account $i (sandboxed)"
    $Shortcut.IconLocation    = "$SpotifyExe,0"
    $Shortcut.Save()

    Write-Ok "Account $i  →  $AccountDir"
}

# ── Done ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  ✅  Setup complete!                                  ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  $NUM_ACCOUNTS shortcuts created on your Desktop:"
for ($i = 1; $i -le $NUM_ACCOUNTS; $i++) {
    Write-Host "   • Spotify Account $i"
}
Write-Host ""
Write-Host "  On first launch, each will show the Spotify login screen."
Write-Host "  Sign in with a different account in each — credentials are"
Write-Host "  saved per-sandbox and persist across reboots."
Write-Host ""
Write-Host "  Account data directories:"
for ($i = 1; $i -le $NUM_ACCOUNTS; $i++) {
    Write-Host "   • $BaseDir\Account$i"
}
Write-Host ""

# Keep window open so the user can read the output
if ($Host.Name -eq "ConsoleHost") {
    Write-Host "Press any key to close..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
