#Requires -Version 5.1

BeforeAll {
    $ValidateScript = (Resolve-Path "$PSScriptRoot/../scripts/validate.ps1").Path
    $FixturesDir = (Resolve-Path "$PSScriptRoot/fixtures").Path

    # Detect PowerShell executable (pwsh for Core, powershell for Windows PS)
    $PwshExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
}

Describe 'validate.ps1' {
    It 'passes on a valid project' {
        & $PwshExe -NoProfile -File $ValidateScript -ProjectDir "$FixturesDir/valid-project" 2>$null
        $LASTEXITCODE | Should -Be 0
    }

    It 'fails when text file is missing BOM' {
        & $PwshExe -NoProfile -File $ValidateScript -ProjectDir "$FixturesDir/missing-bom" 2>$null
        $LASTEXITCODE | Should -Be 1
    }

    It 'fails on malformed XML' {
        & $PwshExe -NoProfile -File $ValidateScript -ProjectDir "$FixturesDir/malformed-xml" 2>$null
        $LASTEXITCODE | Should -Be 1
    }

    It 'fails when modversion tag is missing' {
        & $PwshExe -NoProfile -File $ValidateScript -ProjectDir "$FixturesDir/missing-modversion" 2>$null
        $LASTEXITCODE | Should -Be 1
    }

    It 'fails when Infos/ directory is missing' {
        & $PwshExe -NoProfile -File $ValidateScript -ProjectDir "$FixturesDir/no-infos" 2>$null
        $LASTEXITCODE | Should -Be 1
    }
}
