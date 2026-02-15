# My Mod Name

An Old World mod that does X.

## Features

- Feature 1
- Feature 2

## Installation

Subscribe on [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=TODO) or [mod.io](https://mod.io/g/oldworld/m/TODO), or copy the mod folder to your Old World mods directory manually.

## Compatibility

- Single-player and multiplayer
- No DLC required

## Development

### Setup

1. Clone this repo
2. Copy `.env.example` to `.env` and fill in your paths
3. Set up the Reference symlink (see [CLAUDE.md](CLAUDE.md#setting-up-the-reference-symlink))
4. Install the pre-commit hook: `./scripts/install-hooks.sh`

### XML-Only Mods

Add or modify XML files in `Infos/`. No build step needed — just deploy:

```bash
./scripts/deploy.sh
```

### C# Mods

The template includes a `.csproj` and `Source/ModEntryPoint.cs` with Harmony scaffolding. To use:

1. Rename `MyMod.csproj` to match your mod name
2. Update `AssemblyName` and `RootNamespace` in the `.csproj`
3. Set `OLDWORLD_PATH` in your `.env` (path to Old World game install)
4. Edit `Source/ModEntryPoint.cs` with your mod logic

The deploy and upload scripts automatically detect the `.csproj` and build before deploying. If you don't need C#, delete `MyMod.csproj` and `Source/` — the scripts will skip the build step.

See `docs/modding-guide.md` for a comprehensive C# modding guide covering both GameFactory and Harmony approaches.

### Deploy and Upload

```bash
./scripts/deploy.sh                          # Local testing
./scripts/workshop-upload.sh [--dry-run]     # Steam Workshop
./scripts/modio-upload.sh [--dry-run]        # mod.io
```
