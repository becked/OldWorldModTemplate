# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repo produces a mod template for Old World (turn-based strategy game). Users run a one-liner (`create-mod.sh` or `create-mod.ps1`) which downloads and scaffolds a new mod project. The repo itself is the *source* for that template — it is not a mod.

## Repo Structure

```
├── create-mod.sh              # Curl-able installer (bash)
├── create-mod.ps1             # Curl-able installer (PowerShell)
├── README.md                  # How to use the template
├── CLAUDE.md                  # This file
├── OLDWORLD-CHANGELOG.md      # Game-update diffs for modders
├── .github/workflows/ci.yml   # CI for the template itself
├── tests/                     # Pester tests for template scripts
│   ├── *.Tests.ps1
│   └── fixtures/
├── template/                  # Files that get shipped to users
│   ├── ModInfo.xml            # Mod metadata and version
│   ├── CHANGELOG.md
│   ├── .env.example
│   ├── gitignore              # Renamed to .gitignore by create-mod scripts
│   ├── mod-description.html
│   ├── workshop.vdf
│   ├── MyMod.csproj           # C# build config (removed for XML-only mods)
│   ├── Infos/                 # Mod XML files (game loads from here)
│   │   ├── *-add.xml          # Add new entries (bonuses, events, etc.)
│   │   └── text*-add.xml      # UI text strings (needs UTF-8 BOM)
│   ├── Source/                # C# source files (removed for XML-only mods)
│   │   └── ModEntryPoint.cs   # Mod entry point with Harmony scaffolding
│   ├── scripts/               # Deploy, validate, and upload scripts
│   │   ├── bump-version.sh / .ps1
│   │   ├── deploy.sh / .ps1
│   │   ├── workshop-upload.sh / .ps1
│   │   ├── modio-upload.sh / .ps1
│   │   ├── validate.sh / .ps1
│   │   ├── install-hooks.sh / .ps1
│   │   └── helpers.ps1
│   └── docs/
│       ├── modding-guide-xml.md
│       ├── modding-guide-csharp.md
│       ├── memory-levels.md
│       └── event-lottery-weight-system.md
└── Reference/ -> (symlink)    # Game source code and vanilla XML data
```

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

## Template Scripts (in template/scripts/)

All scripts are available as both bash (`.sh`) and PowerShell (`.ps1`). All scripts run validation before deploying/uploading. If a `.csproj` file is present, scripts automatically build the C# mod and include DLLs. Use `--dry-run` / `-DryRun` to preview uploads.

## create-mod Scripts

`create-mod.sh` and `create-mod.ps1` at the repo root are the user-facing installers. They:
1. Download the `template/` directory from GitHub as a tarball/zip
2. Ask for mod name, author, and XML-only vs C# choice
3. Apply configuration (rename files, sed/replace placeholders)
4. Drop a ready-to-go mod folder

Placeholders that get replaced: `My Mod Name`, `Your Name`, `MyMod` (namespace/assembly), `com.yourname.mymod` (Harmony ID), `[MyMod]` (log tags).

## Two Types of Mods

### XML-Only Mods
Most Old World mods only need XML. Add or override game data in `Infos/` — bonuses, events, units, etc. No `.csproj` or `Source/` needed. See `template/docs/modding-guide-xml.md`.

### C# DLL Mods (Harmony)
For changes that can't be made through XML (camera behavior, UI modifications, custom game logic). Uses Harmony to patch methods at runtime. See `template/docs/modding-guide-csharp.md`.

**Key constraint**: Mods cannot reference `Assembly-CSharp.dll` at compile time. Use `AccessTools.TypeByName()` and `Traverse` for runtime type resolution.

## Critical: Text Files Need UTF-8 BOM

Text files (`text*-add.xml`) **must** have a UTF-8 BOM (`ef bb bf`). Without the BOM, the game silently fails to load text. The validation scripts catch missing BOMs automatically.

## Version Management

Single source of truth: `template/ModInfo.xml` `<modversion>` tag. The `bump-version` scripts update it and scaffold CHANGELOG.md entries.
