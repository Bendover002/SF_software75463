# Spotify Multi-Account Installer

Automatically sets up **5 isolated Spotify instances** on Ubuntu or Windows — each with its own login, so you can run multiple accounts simultaneously.

---

## Install

### Ubuntu / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/spotify-multi-installer/main/install.sh | bash
```

> Installs Spotify (via Snap) and Firejail if not already present, then creates 5 sandboxed launchers in your app drawer.

---

### Windows

Open **PowerShell** and run:

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/spotify-multi-installer/main/install.ps1 | iex
```

> Installs Spotify (via winget) if not already present, then creates 5 Desktop shortcuts — each pointing to an isolated data directory.

---

## How it works

| Platform | Isolation method |
|----------|-----------------|
| Linux    | [Firejail](https://firejail.wordpress.com/) sandbox with a private home directory per account |
| Windows  | `%APPDATA%` override — each launcher points Spotify at its own data folder |

Each instance is completely independent. Logging into one won't affect the others.

---

## First launch

On first open, each instance shows the normal Spotify login screen. Sign in with a different account — credentials are saved and persist across reboots.

**Linux** — account data lives at:
```
~/.spotify-account1  through  ~/.spotify-account5
```

**Windows** — account data lives at:
```
%LOCALAPPDATA%\SpotifyAccounts\Account1  through  Account5
```

---

## Requirements

| Platform | Requirement |
|----------|------------|
| Linux    | Ubuntu 20.04+ · `apt` · `snap` · internet access |
| Windows  | Windows 10/11 · PowerShell 5.1+ · `winget` · internet access |

> If Spotify is already installed, the scripts skip the install step and go straight to setup.

---

## Repo structure

```
spotify-multi-installer/
├── README.md
├── install.sh      # Linux installer
└── install.ps1     # Windows installer
```

---

## Uninstall

**Linux** — remove the launchers and data folders:
```bash
rm ~/.local/share/applications/spotify-account{1..5}.desktop
rm -rf ~/.spotify-account{1..5}
update-desktop-database ~/.local/share/applications/
```

**Windows** — delete the Desktop shortcuts and the accounts folder:
```
%LOCALAPPDATA%\SpotifyAccounts\
```
