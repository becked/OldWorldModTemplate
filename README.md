# Old World Mod Template

Create a new [Old World](https://store.steampowered.com/app/597180/Old_World/) mod with one command. Gets you a ready-to-go project with XML scaffolding, validation scripts, and one-command deployment to Steam Workshop and mod.io.

## Quick Start

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/becked/OldWorldModTemplate/main/create-mod.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/becked/OldWorldModTemplate/main/create-mod.ps1 | iex
```

The script will ask for your mod name, author, and whether you want XML-only or C# (Harmony) support, then create a configured project folder.

### Prefer to inspect before running?

Download the script first, review it, then run it:

**macOS / Linux:**
```bash
curl -fsSL -o create-mod.sh https://raw.githubusercontent.com/becked/OldWorldModTemplate/main/create-mod.sh
less create-mod.sh        # review the script
bash create-mod.sh        # run it
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/becked/OldWorldModTemplate/main/create-mod.ps1 -OutFile create-mod.ps1
Get-Content create-mod.ps1   # review the script
.\create-mod.ps1             # run it
```

### Manual setup (no script)

1. Download the [latest zip](https://github.com/becked/OldWorldModTemplate/archive/refs/heads/main.zip) and extract the `template/` folder
2. Rename it to your mod name
3. Rename `gitignore` to `.gitignore`
4. Edit `ModInfo.xml` — set `<displayName>` and `<author>`
5. If XML-only, delete `MyMod.csproj` and `Source/`
6. If C#, rename `MyMod.csproj` and update `AssemblyName`/`RootNamespace` inside it, plus the namespace in `Source/ModEntryPoint.cs`

## What You Get

```
YourModName/
├── ModInfo.xml          Mod metadata (already filled in)
├── Infos/               XML data files — add bonuses, events, units, text here
├── scripts/             Deploy, validate, and upload scripts (bash + PowerShell)
├── docs/                Modding guides and reference
├── .env.example         Template for local paths and upload credentials
├── workshop.vdf         Steam Workshop upload config
└── (if C#) Source/ + .csproj with Harmony scaffolding
```

## After Creating Your Mod

1. `cd YourModName`
2. Copy `.env.example` to `.env` and set `OLDWORLD_MODS_PATH` to your Old World mods folder
3. Add your mod content to `Infos/`
4. Deploy locally to test:
   ```bash
   ./scripts/deploy.sh            # macOS/Linux
   .\scripts\deploy.ps1           # Windows
   ```
5. When ready, upload to Steam Workshop or mod.io:
   ```bash
   ./scripts/workshop-upload.sh   # Steam Workshop
   ./scripts/modio-upload.sh      # mod.io
   ```

See `docs/modding-guide-xml.md` in your generated project for an XML modding guide, or `docs/modding-guide-csharp.md` for C# / Harmony patching.

## Monorepo Mode

If you maintain multiple mods in a monorepo with shared scripts and docs, use `--monorepo` to create a mod directly inside the monorepo's `mods/` directory. This skips shared infrastructure (scripts, docs, .gitignore) and creates only mod-specific files plus a per-mod `.env` and `CLAUDE.md`.

**macOS / Linux:**
```bash
./create-mod.sh --monorepo /path/to/monorepo
```

**Windows (PowerShell):**
```powershell
.\create-mod.ps1 -Monorepo C:\path\to\monorepo
```

The monorepo must have a `mods/` directory and `scripts/helpers.sh` (or `helpers.ps1`).

## Features

- **XML and C# support** — start with XML-only or add Harmony-based C# patching; build scripts detect which mode you're using
- **One-command deploy and upload** — local testing, Steam Workshop (via `steamcmd`), and mod.io, with `--dry-run` support
- **Cross-platform** — every script ships as both bash and PowerShell
- **Automatic validation** — pre-commit hook and standalone validator catch missing UTF-8 BOMs and malformed XML before they reach the game
- **Version management** — `bump-version.sh` increments semver in ModInfo.xml and scaffolds changelog entries

## Resources

- **[Pinacotheca](https://becked.github.io/pinacotheca/)** — browsable gallery of all in-game art assets (portraits, icons, illustrations)
- **[dales.world](https://dales.world)** — Old World modding tutorials
- **[OLDWORLD-CHANGELOG.md](OLDWORLD-CHANGELOG.md)** — tracks game-update diffs, new APIs, and breaking changes between patches

## Contributing

This repo contains the template source and the `create-mod` scripts. To work on the template itself:

1. Clone this repo
2. Template files live in `template/` — this is what gets downloaded by `create-mod.sh`/`.ps1`
3. Tests are in `tests/` and run via GitHub Actions CI
