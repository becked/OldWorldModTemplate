# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an XML-only mod template for Old World (turn-based strategy game). It provides the scaffolding, deployment scripts, and validation tooling needed to create a new mod. No C# code — uses the game's existing XML modding system.

## Game Reference Data

`Reference/` is a symlink to the game's install directory containing:
- `Reference/XML/Infos/` — all vanilla XML data (bonuses, events, subjects, memory levels, etc.)
- `Reference/Source/Base/` — decompiled C# game source (succession logic, event system, etc.)

Use these to look up vanilla behavior, available subject types, bonus fields, memory levels, etc.

### Setting Up the Reference Symlink

The symlink is machine-specific and not checked into git. Create it after cloning:

```bash
# macOS/Linux — adjust the path to your Old World installation
ln -s "/path/to/Steam/steamapps/common/Old World/Reference" Reference

# Common macOS Steam path:
ln -s "$HOME/Library/Application Support/Steam/steamapps/common/Old World/Reference" Reference

# Common Linux Steam path:
ln -s "$HOME/.steam/steam/steamapps/common/Old World/Reference" Reference
```

On Windows (run as administrator):
```cmd
mklink /D Reference "C:\Program Files (x86)\Steam\steamapps\common\Old World\Reference"
```

## Deployment

**Local testing** (requires `.env` with `OLDWORLD_MODS_PATH`):
```bash
./scripts/deploy.sh
```

**Steam Workshop** (requires `steamcmd`, `.env` with `STEAM_USERNAME`, `workshop.vdf` template):
```bash
./scripts/workshop-upload.sh [--dry-run] [changelog]
```

**mod.io** (requires `.env` with `MODIO_ACCESS_TOKEN`, `MODIO_GAME_ID`, `MODIO_MOD_ID`):
```bash
./scripts/modio-upload.sh [--dry-run] [changelog]
```

**Validation only:**
```bash
./scripts/validate.sh
```

All scripts run validation before deploying/uploading. All scripts read version from `ModInfo.xml` and changelog from `CHANGELOG.md` (or CLI argument). Use `--dry-run` to preview uploads without sending.

## Critical: Text Files Need UTF-8 BOM

Text files (`text*-add.xml`) **must** have a UTF-8 BOM (`ef bb bf`) at the start of the file. Without the BOM, the game silently fails to load text and events won't fire. Event and bonus XMLs do NOT need a BOM.

The pre-commit hook and `scripts/validate.sh` catch missing BOMs automatically. To set up the hook after a fresh clone: `./scripts/install-hooks.sh`

```bash
# Add BOM to a text file manually
printf '\xef\xbb\xbf' > temp.xml && cat original.xml >> temp.xml && mv temp.xml original.xml
```

## File Structure

```
├── ModInfo.xml               # Mod metadata and version (single source of truth)
├── CLAUDE.md
├── logo-512.png              # 512x512 mod icon (used by Steam/mod.io)
├── Infos/                    # Mod XML files (game loads from here)
│   ├── *-add.xml             # Add new entries (bonuses, events, etc.)
│   └── text*-add.xml         # UI text strings (needs UTF-8 BOM)
├── docs/
│   ├── modding-lessons-learned.md    # Troubleshooting and modding patterns
│   ├── memory-levels.md             # Vanilla memory level reference table
│   └── event-lottery-weight-system.md # How event selection works
├── CHANGELOG.md              # Release notes (parsed by upload scripts)
├── scripts/
│   ├── deploy.sh             # Deploy to local mods folder
│   ├── workshop-upload.sh    # Upload to Steam Workshop via SteamCMD
│   ├── modio-upload.sh       # Upload to mod.io via API
│   ├── validate.sh           # BOM + XML validation (also used as pre-commit hook)
│   └── install-hooks.sh      # Install git pre-commit hook
└── Reference/ -> (symlink)   # Game source code and vanilla XML data
```
## Version Management

Single source of truth: `ModInfo.xml` `<modversion>` tag. When bumping the version, also add a new `## [x.y.z] - YYYY-MM-DD` section to `CHANGELOG.md` — the upload scripts automatically extract notes for the current version.
