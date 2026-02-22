#Requires -Version 5.1

BeforeAll {
    $CreateModScript = (Resolve-Path "$PSScriptRoot/../create-mod.ps1").Path
    $TemplateDir = (Resolve-Path "$PSScriptRoot/../template").Path

    $PwshExe = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
}

Describe 'create-mod.ps1 PascalCase naming' {
    # Tests ConvertTo-PascalCase through the script's output folder name
    AfterEach {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'converts multi-word name to PascalCase folder' {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-pascal-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'My Cool Mod' -Author '' -ModType xml -TemplateDir $TemplateDir 2>$null
            Test-Path (Join-Path -Path $TempDir -ChildPath 'MyCoolMod') | Should -Be $true
        } finally { Pop-Location }
    }

    It 'handles single-word name' {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-pascal-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'Overhaul' -Author '' -ModType xml -TemplateDir $TemplateDir 2>$null
            Test-Path (Join-Path -Path $TempDir -ChildPath 'Overhaul') | Should -Be $true
        } finally { Pop-Location }
    }

    It 'strips special characters from folder name' {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-pascal-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'My Mod! (v2)' -Author '' -ModType xml -TemplateDir $TemplateDir 2>$null
            Test-Path (Join-Path -Path $TempDir -ChildPath 'MyModV2') | Should -Be $true
        } finally { Pop-Location }
    }
}

Describe 'create-mod.ps1 Harmony ID generation' {
    # Tests ConvertTo-HarmonyId through the C# scaffolding output

    It 'generates correct harmony id from author and mod name' {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-hid-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'Cool Mod' -Author 'Jeff' -ModType csharp -TemplateDir $TemplateDir 2>$null
            $cs = Get-Content (Join-Path -Path $TempDir -ChildPath 'CoolMod/Source/ModEntryPoint.cs') -Raw
            $cs | Should -Match 'com\.jeff\.coolmod'
        } finally {
            Pop-Location
            Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'falls back to yourname when author is empty' {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-hid-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'Solo Mod' -Author '' -ModType csharp -TemplateDir $TemplateDir 2>$null
            $cs = Get-Content (Join-Path -Path $TempDir -ChildPath 'SoloMod/Source/ModEntryPoint.cs') -Raw
            $cs | Should -Match 'com\.yourname\.solomod'
        } finally {
            Pop-Location
            Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe 'create-mod.ps1 XML-only scaffolding' {
    BeforeAll {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-xml-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }
    AfterAll {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'scaffolds successfully' {
        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'Test Mod' -Author 'TestAuthor' -ModType xml -TemplateDir $TemplateDir 2>$null
            $LASTEXITCODE | Should -Be 0
        } finally {
            Pop-Location
        }
    }

    It 'creates the PascalCase folder' {
        Test-Path (Join-Path -Path $TempDir -ChildPath 'TestMod') | Should -Be $true
    }

    It 'sets displayName in ModInfo.xml' {
        [xml]$doc = Get-Content (Join-Path -Path $TempDir -ChildPath 'TestMod/ModInfo.xml')
        $doc.ModInfo.displayName | Should -Be 'Test Mod'
    }

    It 'sets author in ModInfo.xml' {
        [xml]$doc = Get-Content (Join-Path -Path $TempDir -ChildPath 'TestMod/ModInfo.xml')
        $doc.ModInfo.author | Should -Be 'TestAuthor'
    }

    It 'sets title in workshop.vdf' {
        $vdf = Get-Content (Join-Path -Path $TempDir -ChildPath 'TestMod/workshop.vdf') -Raw
        $vdf | Should -Match '"title"\s+"Test Mod"'
    }

    It 'renames gitignore to .gitignore' {
        Test-Path (Join-Path -Path $TempDir -ChildPath 'TestMod/.gitignore') | Should -Be $true
        Test-Path (Join-Path -Path $TempDir -ChildPath 'TestMod/gitignore') | Should -Be $false
    }

    It 'strips bin/ and obj/ from .gitignore' {
        $gi = Get-Content (Join-Path -Path $TempDir -ChildPath 'TestMod/.gitignore') -Raw
        $gi | Should -Not -Match '^bin/'
        $gi | Should -Not -Match '^obj/'
    }

    It 'removes MyMod.csproj' {
        Test-Path (Join-Path -Path $TempDir -ChildPath 'TestMod/MyMod.csproj') | Should -Be $false
        # No .csproj files at all
        (Get-ChildItem -Path (Join-Path -Path $TempDir -ChildPath 'TestMod') -Filter '*.csproj').Count | Should -Be 0
    }

    It 'removes Source/ directory' {
        Test-Path (Join-Path -Path $TempDir -ChildPath 'TestMod/Source') | Should -Be $false
    }

    It 'resets CHANGELOG.md' {
        $cl = Get-Content (Join-Path -Path $TempDir -ChildPath 'TestMod/CHANGELOG.md') -Raw
        $cl | Should -Match '## \[0\.1\.0\] - YYYY-MM-DD'
        $cl | Should -Match 'Initial release'
    }

    It 'preserves Infos/ directory' {
        Test-Path (Join-Path -Path $TempDir -ChildPath 'TestMod/Infos') | Should -Be $true
    }
}

Describe 'create-mod.ps1 C# scaffolding' {
    BeforeAll {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-cs-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'Cool Strategy Mod' -Author 'Jeff' -ModType csharp -TemplateDir $TemplateDir 2>$null
        } finally {
            Pop-Location
        }

        $ModDir = Join-Path -Path $TempDir -ChildPath 'CoolStrategyMod'
    }
    AfterAll {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates the PascalCase folder' {
        Test-Path $ModDir | Should -Be $true
    }

    It 'renames .csproj to PascalCase name' {
        Test-Path (Join-Path -Path $ModDir -ChildPath 'CoolStrategyMod.csproj') | Should -Be $true
        Test-Path (Join-Path -Path $ModDir -ChildPath 'MyMod.csproj') | Should -Be $false
    }

    It 'updates AssemblyName in .csproj' {
        [xml]$doc = Get-Content (Join-Path -Path $ModDir -ChildPath 'CoolStrategyMod.csproj')
        $doc.Project.PropertyGroup[0].AssemblyName | Should -Be 'CoolStrategyMod'
    }

    It 'updates RootNamespace in .csproj' {
        [xml]$doc = Get-Content (Join-Path -Path $ModDir -ChildPath 'CoolStrategyMod.csproj')
        $doc.Project.PropertyGroup[0].RootNamespace | Should -Be 'CoolStrategyMod'
    }

    It 'updates namespace in ModEntryPoint.cs' {
        $cs = Get-Content (Join-Path -Path $ModDir -ChildPath 'Source/ModEntryPoint.cs') -Raw
        $cs | Should -Match 'namespace CoolStrategyMod'
        $cs | Should -Not -Match 'namespace MyMod'
    }

    It 'sets correct Harmony ID' {
        $cs = Get-Content (Join-Path -Path $ModDir -ChildPath 'Source/ModEntryPoint.cs') -Raw
        $cs | Should -Match 'com\.jeff\.coolstrategymod'
        $cs | Should -Not -Match 'com\.yourname\.mymod'
    }

    It 'replaces all log tags' {
        $cs = Get-Content (Join-Path -Path $ModDir -ChildPath 'Source/ModEntryPoint.cs') -Raw
        $cs | Should -Match '\[CoolStrategyMod\]'
        $cs | Should -Not -Match '\[MyMod\]'
    }

    It 'retains bin/ and obj/ in .gitignore' {
        $gi = Get-Content (Join-Path -Path $ModDir -ChildPath '.gitignore') -Raw
        $gi | Should -Match 'bin/'
        $gi | Should -Match 'obj/'
    }
}

Describe 'create-mod.ps1 edge cases' {
    It 'fails when output directory already exists' {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-dup-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
        # Pre-create the output folder
        New-Item -ItemType Directory -Path (Join-Path -Path $TempDir -ChildPath 'TestMod') | Out-Null

        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'Test Mod' -Author 'X' -ModType xml -TemplateDir $TemplateDir 2>$null
            $LASTEXITCODE | Should -Not -Be 0
        } finally {
            Pop-Location
            Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It 'uses default author placeholder when author is empty' {
        $TempDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "createmod-noauth-$(Get-Random)"
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

        Push-Location $TempDir
        try {
            & $PwshExe -NoProfile -File $CreateModScript -ModName 'NoAuthor Mod' -Author '' -ModType xml -TemplateDir $TemplateDir 2>$null
            $LASTEXITCODE | Should -Be 0

            [xml]$doc = Get-Content (Join-Path -Path $TempDir -ChildPath 'NoauthorMod/ModInfo.xml')
            # Author should remain as the original placeholder since empty author was provided
            $doc.ModInfo.author | Should -Be 'Your Name'
        } finally {
            Pop-Location
            Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
