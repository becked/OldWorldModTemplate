# Changelog

All notable changes to this project will be documented in this file.

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
