# Changelog

All notable changes to this project will be documented in this file.

## [0.4.0] - 2026-04-01

- Add `--monorepo` flag to `create-mod.sh` and `-Monorepo` to `create-mod.ps1` for scaffolding mods inside an existing monorepo
- Monorepo mode creates only mod-specific files (ModInfo.xml, Infos/, Source/, CHANGELOG.md, workshop.vdf, mod-description.html) with a per-mod `.env` and skeleton `CLAUDE.md`
- Skips shared infrastructure (scripts/, docs/, .gitignore, .env.example) that lives at the monorepo root

## [0.3.3] - 2026-03-28

- Migrate mod.io upload script from deprecated `api.mod.io` domain to new `*.modapi.io` API URL (requires `MODIO_API_URL` in `.env`)
- Add validation check for ModInfo.xml `<description>` length (mod.io 250-character limit)

## [0.3.2] - 2026-03-25

- Fix text-add.xml template using `<English>` instead of `<en-US>` (game silently ignores `<English>`)

## [0.3.1] - 2026-03-09

- Fix deploy scripts using displayName (with spaces) as mod folder name; use project directory name instead (#4)

## [0.3.0] - 2026-02-22

- Add curl-able `create-mod.sh` and `create-mod.ps1` installer scripts for one-liner mod scaffolding
- Add `bump-version` scripts (bash + PowerShell) with changelog scaffolding and modbuild sync
- Split modding docs into separate XML and C# guides
- Fix `create-mod.sh` pipe bug when reading user input
- Add bold tag (`<b>` → `[b]`) BBCode conversion in workshop-upload scripts

## [0.2.0] - 2026-02-15

- Add PowerShell versions of all scripts (validate, deploy, workshop-upload, modio-upload, install-hooks) for Windows users
- Add shared helpers.ps1 with common functions (env loading, XML parsing, changelog extraction, mod.io API)
- Add GitHub Actions CI with PSScriptAnalyzer linting and Pester tests on Windows, plus bash validation on Ubuntu
- Add Pester test suite with fixtures for validate.ps1 and deploy.ps1

## [0.1.0] - YYYY-MM-DD

- Initial release
