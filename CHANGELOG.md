# Changelog

## 2.2.1

- Fonts disposed on close (no-op fixup release)

- Browser profile backup (Chrome, Edge, Firefox)
- Generated setup.ps1: one-shot restore (winget + Wi-Fi + drivers)
- One-click saved-driver install; pre-format readiness check
- Post-format checklist (persisted); export everything to a single .zip
- Disk health (SMART) in Summary; per-user (HKCU) programs
- Inventory diff against another selection.csv

- Removed the subtitle header; pages gained the space

- Title bar uses flow layout (version never overlapped/clipped); header
  shows a single purpose line instead of the repeated app name

- Title-bar icons are drawn (no font glyphs): minimize, maximize/restore, close

- Borderless window with custom title bar (drag, minimize, maximize, close, resize grip)
- Custom dark navigation (no white TabControl chrome), per-monitor DPI
- UTF-8 BOM everywhere (no more garbled characters)
- Resize-loop and event-scope hardening

- Exports verify completion (`$LASTEXITCODE` for winget/netsh, `-ErrorAction Stop` for drivers)
- Backup reports partial failures instead of always succeeding
- `selection.json` is always an array, even with 0 or 1 items
- RowFilter also escapes `]`; program count shows filtered total
- Backup totals use numeric `Tag` (no culture-dependent parsing)
- DialogResult compared as enum; fonts disposed on close; HTML values encoded
- Programs now include per-user (`HKCU`) installs
- Build bundler tolerates trailing comments on dot-source lines

## 2.0.3

- Pages parented before data binding (grid columns no longer null)

## 2.0.2

- Event handlers use sender (no dead-scope locals)

## 2.0.1

- Custom dark navigation (no white TabControl chrome), per-monitor DPI, dark title bar, UTF-8 BOM everywhere

- Renamed to WipeReady, everything in English
- Reorganized: `src/` (App, Theme, Collect, MainForm, Tabs), `build/` (bundle + exe)
- Output folder is now `Desktop\wipeready`

## 1.2.0

- Backup tab is actionable: per-folder checkboxes, selected GB total, copy to external drive, open folder

## 1.1.0

- UI refactor: header, owner-drawn tabs, style helpers
- Folder scan on demand (used to block startup)

## 1.0.0

- Initial WinForms app: summary, program checklist, folder sizes, winget restore kit
