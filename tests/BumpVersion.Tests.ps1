#Requires -Version 5.1

BeforeAll {
    $BumpScript = (Resolve-Path "$PSScriptRoot/../scripts/bump-version.ps1").Path
    $FixturesDir = (Resolve-Path "$PSScriptRoot/fixtures").Path

    $PwshExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
}

Describe 'bump-version.ps1' {
    BeforeEach {
        $TempDir = Join-Path ([System.IO.Path]::GetTempPath()) "bump-test-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Copy-Item "$FixturesDir/valid-project/ModInfo.xml" $TempDir
    }
    AfterEach {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'shows usage when called with no arguments' {
        & $PwshExe -NoProfile -File $BumpScript -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Be 1
    }

    It 'bumps patch version' {
        & $PwshExe -NoProfile -File $BumpScript patch -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Be 0

        [xml]$doc = Get-Content (Join-Path $TempDir 'ModInfo.xml')
        $doc.ModInfo.modversion | Should -Be '1.0.1'
    }

    It 'bumps minor version' {
        & $PwshExe -NoProfile -File $BumpScript minor -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Be 0

        [xml]$doc = Get-Content (Join-Path $TempDir 'ModInfo.xml')
        $doc.ModInfo.modversion | Should -Be '1.1.0'
    }

    It 'bumps major version' {
        & $PwshExe -NoProfile -File $BumpScript major -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Be 0

        [xml]$doc = Get-Content (Join-Path $TempDir 'ModInfo.xml')
        $doc.ModInfo.modversion | Should -Be '2.0.0'
    }

    It 'sets explicit version' {
        & $PwshExe -NoProfile -File $BumpScript 3.5.7 -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Be 0

        [xml]$doc = Get-Content (Join-Path $TempDir 'ModInfo.xml')
        $doc.ModInfo.modversion | Should -Be '3.5.7'
    }

    It 'rejects invalid version format' {
        & $PwshExe -NoProfile -File $BumpScript 'abc' -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Not -Be 0
    }

    It 'scaffolds CHANGELOG.md entry' {
        Copy-Item "$FixturesDir/CHANGELOG.md" $TempDir
        & $PwshExe -NoProfile -File $BumpScript patch -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Be 0

        $content = Get-Content (Join-Path $TempDir 'CHANGELOG.md') -Raw
        $content | Should -Match '## \[1\.0\.1\] - \d{4}-\d{2}-\d{2}'
    }

    It 'skips changelog when file does not exist' {
        & $PwshExe -NoProfile -File $BumpScript patch -ProjectDir $TempDir 2>$null
        $LASTEXITCODE | Should -Be 0

        # Should still bump version successfully even without CHANGELOG.md
        [xml]$doc = Get-Content (Join-Path $TempDir 'ModInfo.xml')
        $doc.ModInfo.modversion | Should -Be '1.0.1'
    }
}
