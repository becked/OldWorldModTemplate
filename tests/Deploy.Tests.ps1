#Requires -Version 5.1

BeforeAll {
    $DeployScript = (Resolve-Path "$PSScriptRoot/../template/scripts/deploy.ps1").Path
    $FixturesDir = (Resolve-Path "$PSScriptRoot/fixtures").Path

    # Detect PowerShell executable (pwsh for Core, powershell for Windows PS)
    $PwshExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
}

Describe 'deploy.ps1' {
    BeforeAll {
        $TempModsDir = Join-Path ([System.IO.Path]::GetTempPath()) "deploy-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempModsDir -Force | Out-Null
        $EnvFile = Join-Path $FixturesDir 'valid-project/.env'
        "OLDWORLD_MODS_PATH=`"$TempModsDir`"" | Set-Content $EnvFile
    }
    AfterAll {
        Remove-Item $TempModsDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $FixturesDir 'valid-project/.env') -ErrorAction SilentlyContinue
    }

    It 'deploys files to the target folder' {
        $fixtureDir = Join-Path $FixturesDir 'valid-project'
        & $PwshExe -NoProfile -File $DeployScript -ProjectDir $fixtureDir 2>$null
        $LASTEXITCODE | Should -Be 0

        $deployedDir = Join-Path $TempModsDir 'Test Mod'
        Test-Path (Join-Path $deployedDir 'ModInfo.xml') | Should -Be $true
        Test-Path (Join-Path $deployedDir 'Infos') | Should -Be $true
    }
}
