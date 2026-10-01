# WipeReady

GUI app to inventory your PC **before wiping it**: hardware, Windows product key, disk health, installed programs (with a keep-checklist), user folder sizes, driver and Wi-Fi backup, browser profiles, plus a one-shot reinstall kit via `winget`.

Runs as admin by itself (needed for the driver and Wi-Fi exports) and writes everything to `Desktop\wipeready\`.

## Usage (on the PC to be formatted)

Double-click `WipeReady.exe` **or**, if you prefer the script:

```powershell
powershell -ExecutionPolicy Bypass -File src/App.ps1
```

Then, before formatting: export drivers and Wi-Fi, save the program checklist, copy your folders to the external drive, and generate `reinstall.json` + `setup.ps1`.

## Tabs

### Summary

- This PC: machine, CPU, RAM, GPU, OS, product key and disk health (SMART warns you before trusting the drive)
- **Export drivers** — saves installed third-party drivers to `drivers\` (restore later with `pnputil`)
- **Export Wi-Fi** — saves Wi-Fi profiles (with keys) to `wifi\`
- **HTML report** — builds `report.html` with hardware, programs, folder sizes and startup items

### Programs

- Checklist of installed programs (machine and per-user), with a search filter
- Keyboard: `Tab` enters the list, `Up`/`Down` move, `Enter` toggles and advances, `Space` toggles, `Ctrl+S` saves
- **Save selection** writes `selection.json`/`selection.csv`; the checklist also auto-saves when the app closes
- **Compare…** diffs the current programs against a `selection.csv` from another inventory

### Backup

- **Scan folders** measures each user folder (Desktop, Documents, …)
- Check what matters (AppData starts unchecked) and see the selected GB total
- **Copy to external drive** copies the checked folders with `robocopy`
- **Backup browsers** copies Chrome/Edge/Firefox profiles (bookmarks, passwords, extensions)

### Restore

- **Export winget** writes `reinstall.json` with exact versions
- **Make setup script** generates `setup.ps1`: one-shot restore (winget + Wi-Fi + drivers) for the new install
- **Install drivers** reinstalls the saved drivers on this PC (`pnputil`)
- **Verify backup** checks drivers, Wi-Fi, `reinstall.json` and `selection.csv` before formatting
- **Export .zip** packs the whole `wipeready` folder into a single zip on the Desktop
- Post-format checklist, persisted to `checklist.json`

## After formatting

Reinstall the programs, then restore drivers and Wi-Fi:

```powershell
winget import -i reinstall.json --accept-source-agreements --accept-package-agreements
```

Or run `setup.ps1` from the wipeready folder as admin to do everything in one shot.

## Output

Everything goes to `Desktop\wipeready\`:

```
report.html           hardware, programs, folders, startup
selection.json/.csv   programs to keep
reinstall.json        winget reinstall kit
setup.ps1             one-shot restore script
checklist.json        post-format checklist state
drivers\              exported drivers
wifi\                 Wi-Fi profiles
browsers\             browser profile backups
```

Copy that folder to the external drive along with your files.

## Requirements

- Windows 10/11 with PowerShell 5.1 (built in)
- Admin rights: the app elevates itself
- `winget` (App Installer) on the formatted PC for the reinstall kit

## Build from source

```powershell
powershell -ExecutionPolicy Bypass -File build/Build.ps1
```

Requires the `ps2exe` module (`Install-Module ps2exe -Scope CurrentUser`). The build bundles `src/*.ps1` into `dist/` and compiles `WipeReady.exe`.

## Project layout

```
src/        PowerShell sources (App entry, Theme, Collect, MainForm, Tabs/)
build/      Build script (bundle + compile to exe)
dist/       Build output (git-ignored)
```

## License

MIT
