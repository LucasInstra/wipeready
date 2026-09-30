# WipeReady

GUI app to inventory your PC **before wiping it**: hardware, Windows product key, installed programs (with a keep-checklist), user folder sizes, driver and Wi-Fi backup, plus a one-shot reinstall kit via `winget`.

## Usage (on the PC to be formatted)

Double-click `WipeReady.exe` (asks for admin by itself) **or**, if you prefer the script:

```powershell
powershell -ExecutionPolicy Bypass -File src/App.ps1
```

## Tabs

- **Summary** — machine, CPU, RAM, GPU, OS and key; exports drivers and Wi-Fi; generates `report.html`
- **Programs** — check what to keep and save the selection (`selection.json`/`selection.csv`)
- **Backup** — check user folders, see the selected GB total, copy them to the external drive
- **Restore** — exports `reinstall.json` from winget

## After formatting

```powershell
winget import -i reinstall.json --accept-source-agreements --accept-package-agreements
```

## Output

Everything goes to `Desktop\wipeready\`. Copy that folder to the external drive along with your files.

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
