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
