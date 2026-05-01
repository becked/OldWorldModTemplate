#Requires -Version 5.1

BeforeAll {
    . "$PSScriptRoot/../template/scripts/helpers.ps1"
    $FixturesDir = "$PSScriptRoot/fixtures"
}

Describe 'Import-DotEnv' {
    BeforeEach {
        $tempEnv = Join-Path ([System.IO.Path]::GetTempPath()) "test-$(Get-Random).env"
    }
    AfterEach {
        if (Test-Path $tempEnv) { Remove-Item $tempEnv }
    }

    It 'parses unquoted values' {
        "MY_VAR=hello" | Set-Content $tempEnv
        Import-DotEnv -Path $tempEnv | Should -Be $true
        [System.Environment]::GetEnvironmentVariable('MY_VAR', 'Process') | Should -Be 'hello'
    }

    It 'parses double-quoted values' {
        'MY_VAR="hello world"' | Set-Content $tempEnv
        Import-DotEnv -Path $tempEnv | Should -Be $true
        [System.Environment]::GetEnvironmentVariable('MY_VAR', 'Process') | Should -Be 'hello world'
    }

    It 'parses single-quoted values' {
        "MY_VAR='hello world'" | Set-Content $tempEnv
        Import-DotEnv -Path $tempEnv | Should -Be $true
        [System.Environment]::GetEnvironmentVariable('MY_VAR', 'Process') | Should -Be 'hello world'
    }

    It 'skips comments and blank lines' {
        @(
            '# this is a comment',
            '',
            'REAL_VAR=value'
        ) | Set-Content $tempEnv
        Import-DotEnv -Path $tempEnv | Should -Be $true
        [System.Environment]::GetEnvironmentVariable('REAL_VAR', 'Process') | Should -Be 'value'
    }

    It 'returns false when file does not exist' {
        Import-DotEnv -Path 'nonexistent.env' | Should -Be $false
    }
}

Describe 'Get-XmlTagValue' {
    It 'reads displayName from ModInfo.xml' {
        $result = Get-XmlTagValue -FilePath "$FixturesDir/valid-project/ModInfo.xml" -TagName 'displayName'
        $result | Should -Be 'Test Mod'
    }

    It 'reads modversion from ModInfo.xml' {
        $result = Get-XmlTagValue -FilePath "$FixturesDir/valid-project/ModInfo.xml" -TagName 'modversion'
        $result | Should -Be '1.0.0'
    }

    It 'returns null for missing tag' {
        $result = Get-XmlTagValue -FilePath "$FixturesDir/missing-modversion/ModInfo.xml" -TagName 'modversion'
        $result | Should -BeNullOrEmpty
    }

    It 'returns null for missing file' {
        $result = Get-XmlTagValue -FilePath 'nonexistent.xml' -TagName 'displayName'
        $result | Should -BeNullOrEmpty
    }
}

Describe 'Set-XmlTagValue' {
    BeforeEach {
        $tempXml = Join-Path ([System.IO.Path]::GetTempPath()) "test-$(Get-Random).xml"
        Copy-Item "$FixturesDir/valid-project/ModInfo.xml" $tempXml
    }
    AfterEach {
        if (Test-Path $tempXml) { Remove-Item $tempXml }
    }

    It 'updates modversion value' {
        Set-XmlTagValue -FilePath $tempXml -TagName 'modversion' -Value '2.0.0' | Should -Be $true
        Get-XmlTagValue -FilePath $tempXml -TagName 'modversion' | Should -Be '2.0.0'
    }

    It 'returns false for missing tag' {
        Set-XmlTagValue -FilePath $tempXml -TagName 'nonexistent' -Value 'x' | Should -Be $false
    }

    It 'returns false for missing file' {
        Set-XmlTagValue -FilePath 'nonexistent.xml' -TagName 'modversion' -Value 'x' | Should -Be $false
    }
}

Describe 'Get-ModioTag' {
    BeforeEach {
        $tempXml = Join-Path ([System.IO.Path]::GetTempPath()) "test-$(Get-Random).xml"
        [System.Environment]::SetEnvironmentVariable('MODIO_TAGS', $null, 'Process')
    }
    AfterEach {
        if (Test-Path $tempXml) { Remove-Item $tempXml }
        [System.Environment]::SetEnvironmentVariable('MODIO_TAGS', $null, 'Process')
    }

    It 'derives Singleplayer and Multiplayer from ModInfo.xml flags' {
        @"
<?xml version="1.0"?>
<ModInfo>
  <singlePlayer>true</singlePlayer>
  <multiplayer>true</multiplayer>
</ModInfo>
"@ | Set-Content $tempXml
        Get-ModioTag -ModInfoPath $tempXml | Should -Be 'Singleplayer,Multiplayer'
    }

    It 'omits Multiplayer when flag is false' {
        @"
<?xml version="1.0"?>
<ModInfo>
  <singlePlayer>true</singlePlayer>
  <multiplayer>false</multiplayer>
</ModInfo>
"@ | Set-Content $tempXml
        Get-ModioTag -ModInfoPath $tempXml | Should -Be 'Singleplayer'
    }

    It 'appends MODIO_TAGS env values' {
        @"
<?xml version="1.0"?>
<ModInfo>
  <singlePlayer>true</singlePlayer>
  <multiplayer>true</multiplayer>
</ModInfo>
"@ | Set-Content $tempXml
        [System.Environment]::SetEnvironmentVariable('MODIO_TAGS', 'UI,Other', 'Process')
        Get-ModioTag -ModInfoPath $tempXml | Should -Be 'Singleplayer,Multiplayer,UI,Other'
    }

    It 'trims whitespace from MODIO_TAGS entries' {
        @"
<?xml version="1.0"?>
<ModInfo>
  <singlePlayer>true</singlePlayer>
  <multiplayer>false</multiplayer>
</ModInfo>
"@ | Set-Content $tempXml
        [System.Environment]::SetEnvironmentVariable('MODIO_TAGS', ' UI , Other ', 'Process')
        Get-ModioTag -ModInfoPath $tempXml | Should -Be 'Singleplayer,UI,Other'
    }
}

Describe 'Set-ModInfoPlatform' {
    BeforeEach {
        $tempXml = Join-Path ([System.IO.Path]::GetTempPath()) "test-$(Get-Random).xml"
        @"
<?xml version="1.0"?>
<ModInfo>
  <displayName>Test</displayName>
  <author>tester</author>
  <modversion>1.0</modversion>
  <singlePlayer>true</singlePlayer>
  <multiplayer>true</multiplayer>
</ModInfo>
"@ | Set-Content $tempXml
    }
    AfterEach {
        if (Test-Path $tempXml) { Remove-Item $tempXml }
    }

    It 'injects mod.io platform fields' {
        Set-ModInfoPlatform -FilePath $tempXml -Platform 'Modio' -ModioId '12345' -WorkshopId '' -Build '1.0.83082' | Should -Be $true
        [xml]$doc = Get-Content $tempXml
        $doc.ModInfo.modplatform | Should -Be 'Modio'
        $doc.ModInfo.modioID | Should -Be '12345'
        $doc.ModInfo.modioFileID | Should -Be '0'
        $doc.ModInfo.modbuild | Should -Be '1.0.83082'
        $doc.ModInfo.workshopFileID | Should -BeNullOrEmpty
    }

    It 'injects Workshop platform fields' {
        Set-ModInfoPlatform -FilePath $tempXml -Platform 'Workshop' -ModioId '' -WorkshopId '999888' -Build '1.0.83082' | Should -Be $true
        [xml]$doc = Get-Content $tempXml
        $doc.ModInfo.modplatform | Should -Be 'Workshop'
        $doc.ModInfo.workshopFileID | Should -Be '999888'
        $doc.ModInfo.modbuild | Should -Be '1.0.83082'
        $doc.ModInfo.modioID | Should -BeNullOrEmpty
    }

    It 'is idempotent across re-runs' {
        Set-ModInfoPlatform -FilePath $tempXml -Platform 'Modio' -ModioId '12345' -WorkshopId '' -Build '1.0.83082' | Out-Null
        Set-ModInfoPlatform -FilePath $tempXml -Platform 'Modio' -ModioId '12345' -WorkshopId '' -Build '1.0.83082' | Out-Null
        [xml]$doc = Get-Content $tempXml
        # Each platform field should appear exactly once
        $doc.ModInfo.SelectNodes('modplatform').Count | Should -Be 1
        $doc.ModInfo.SelectNodes('modioID').Count | Should -Be 1
        $doc.ModInfo.SelectNodes('modbuild').Count | Should -Be 1
    }

    It 'returns false for missing file' {
        Set-ModInfoPlatform -FilePath 'nonexistent.xml' -Platform 'Modio' -ModioId '1' -WorkshopId '' -Build '1.0' | Should -Be $false
    }
}

Describe 'Get-GameBuild' {
    BeforeEach {
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_BUILD', $null, 'Process')
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_PATH', $null, 'Process')
    }
    AfterEach {
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_BUILD', $null, 'Process')
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_PATH', $null, 'Process')
    }

    It 'returns OLDWORLD_BUILD override when set' {
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_BUILD', '1.2.3', 'Process')
        Get-GameBuild | Should -Be '1.2.3'
    }

    It 'returns null and writes error when nothing is set' {
        $result = Get-GameBuild 2>$null
        $result | Should -BeNullOrEmpty
    }

    It 'strips trailing ".0" from 4-part Windows FileVersion' {
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_PATH', '/fake/oldworld', 'Process')
        Mock Test-Path { $Path -like '*OldWorld.exe' }
        Mock Get-Item {
            [PSCustomObject]@{
                VersionInfo = [PSCustomObject]@{ FileVersion = '1.0.83082.0' }
            }
        }
        Get-GameBuild | Should -Be '1.0.83082'
    }

    It 'preserves 3-part FileVersion unchanged' {
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_PATH', '/fake/oldworld', 'Process')
        Mock Test-Path { $Path -like '*OldWorld.exe' }
        Mock Get-Item {
            [PSCustomObject]@{
                VersionInfo = [PSCustomObject]@{ FileVersion = '1.0.83082' }
            }
        }
        Get-GameBuild | Should -Be '1.0.83082'
    }

    It 'preserves 4-part FileVersion when 4th component is non-zero' {
        [System.Environment]::SetEnvironmentVariable('OLDWORLD_PATH', '/fake/oldworld', 'Process')
        Mock Test-Path { $Path -like '*OldWorld.exe' }
        Mock Get-Item {
            [PSCustomObject]@{
                VersionInfo = [PSCustomObject]@{ FileVersion = '1.0.83082.5' }
            }
        }
        Get-GameBuild | Should -Be '1.0.83082.5'
    }
}

Describe 'Get-ChangelogForVersion' {
    It 'extracts correct section for version 1.0.0' {
        $result = Get-ChangelogForVersion -Version '1.0.0' -ChangelogPath "$FixturesDir/CHANGELOG.md"
        $result | Should -Match 'Initial release'
        $result | Should -Match 'Basic functionality'
    }

    It 'extracts correct section for version 2.0.0' {
        $result = Get-ChangelogForVersion -Version '2.0.0' -ChangelogPath "$FixturesDir/CHANGELOG.md"
        $result | Should -Match 'Major overhaul'
        $result | Should -Match 'New feature added'
        $result | Should -Match 'Breaking change'
    }

    It 'does not include entries from other versions' {
        $result = Get-ChangelogForVersion -Version '2.0.0' -ChangelogPath "$FixturesDir/CHANGELOG.md"
        $result | Should -Not -Match 'Initial release'
    }

    It 'returns empty string when version not found' {
        $result = Get-ChangelogForVersion -Version '9.9.9' -ChangelogPath "$FixturesDir/CHANGELOG.md"
        $result | Should -BeNullOrEmpty
    }

    It 'returns empty string when file does not exist' {
        $result = Get-ChangelogForVersion -Version '1.0.0' -ChangelogPath 'nonexistent.md'
        $result | Should -BeNullOrEmpty
    }
}
