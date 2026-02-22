# create-mod.ps1 - Download and scaffold a new Old World mod
#
# Usage (interactive):
#   irm https://raw.githubusercontent.com/becked/OldWorldModTemplate/main/create-mod.ps1 | iex
#
# Or download and run locally:
#   .\create-mod.ps1
#
# Non-interactive (for CI / scripting):
#   .\create-mod.ps1 -ModName "My Mod" -Author "Jeff" -ModType xml
#   .\create-mod.ps1 -ModName "My Mod" -ModType csharp -TemplateDir ./template

param(
    [string]$ModName,
    [string]$Author,
    [ValidateSet('xml', 'csharp', '')]
    [string]$ModType,
    [string]$TemplateDir
)

$ErrorActionPreference = 'Stop'

$Repo = 'becked/OldWorldModTemplate'
$Branch = 'main'
$ZipUrl = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Read-Prompt {
    param([string]$Prompt, [string]$Default)
    if ($Default) {
        $response = Read-Host "$Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($response)) { return $Default } else { return $response }
    } else {
        return Read-Host $Prompt
    }
}

function ConvertTo-PascalCase {
    param([string]$Name)
    $cleaned = $Name -replace '[^a-zA-Z0-9 ]', ''
    $parts = $cleaned -split '\s+' | Where-Object { $_ -ne '' }
    return ($parts | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }) -join ''
}

function ConvertTo-HarmonyId {
    param([string]$Author, [string]$ModName)
    $a = ($Author -replace '[^a-zA-Z0-9]', '').ToLower()
    $m = ($ModName -replace '[^a-zA-Z0-9]', '').ToLower()
    if ([string]::IsNullOrEmpty($a)) { $a = 'yourname' }
    return "com.$a.$m"
}

# ── Interactive prompts (skipped when params are provided) ───────────────────

Write-Host ''
Write-Host 'Old World Mod Creator'
Write-Host '====================='
Write-Host ''

if ([string]::IsNullOrWhiteSpace($ModName)) {
    $ModName = Read-Prompt -Prompt 'Mod name' -Default 'My Mod'
}
if (-not $PSBoundParameters.ContainsKey('Author')) {
    $Author = Read-Prompt -Prompt 'Author name' -Default ''
}

if ([string]::IsNullOrWhiteSpace($ModType)) {
    Write-Host ''
    Write-Host 'Mod type:'
    Write-Host '  1) XML only (recommended for most mods)'
    Write-Host '  2) XML + C# (Harmony patching)'
    $ModTypeChoice = Read-Prompt -Prompt 'Choose' -Default '1'
} else {
    switch ($ModType) {
        'xml'    { $ModTypeChoice = '1' }
        'csharp' { $ModTypeChoice = '2' }
    }
}

# ── Download and extract template ────────────────────────────────────────────

$PascalName = ConvertTo-PascalCase -Name $ModName
$FolderName = $PascalName

if (Test-Path $FolderName) {
    Write-Host ''
    Write-Error "Directory '$FolderName' already exists."
}

if ($TemplateDir) {
    # Local mode: copy from a local template directory (for CI / development)
    if (-not (Test-Path $TemplateDir)) {
        Write-Error "TemplateDir '$TemplateDir' does not exist."
    }
    Write-Host ''
    Write-Host "Copying template from $TemplateDir..."
    Copy-Item -Path $TemplateDir -Destination $FolderName -Recurse
} else {
    Write-Host ''
    Write-Host 'Downloading template...'

    $TmpDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "oldworld-mod-$([guid]::NewGuid().ToString('N').Substring(0,8))"
    New-Item -ItemType Directory -Path $TmpDir | Out-Null
    $ZipPath = Join-Path -Path $TmpDir -ChildPath 'template.zip'

    try {
        Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing
        Expand-Archive -Path $ZipPath -DestinationPath $TmpDir

        $Extracted = Join-Path -Path $TmpDir -ChildPath "OldWorldModTemplate-$Branch/template"
        if (-not (Test-Path $Extracted)) {
            Write-Error 'Could not find template/ in downloaded archive.'
        }

        Move-Item -Path $Extracted -Destination $FolderName
    } finally {
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
    }
}

# ── Configure the mod ────────────────────────────────────────────────────────

Push-Location $FolderName
try {
    # Rename gitignore → .gitignore
    Rename-Item 'gitignore' '.gitignore'

    # ModInfo.xml
    $modInfo = Get-Content 'ModInfo.xml' -Raw
    $modInfo = $modInfo -replace '<displayName>My Mod Name</displayName>', "<displayName>$ModName</displayName>"
    if (-not [string]::IsNullOrWhiteSpace($Author)) {
        $modInfo = $modInfo -replace '<author>Your Name</author>', "<author>$Author</author>"
    }
    Set-Content 'ModInfo.xml' $modInfo -NoNewline

    # workshop.vdf
    $vdf = Get-Content 'workshop.vdf' -Raw
    $vdf = $vdf -replace '"title"\s+"My Mod Name"', "`"title`"`t`t`"$ModName`""
    Set-Content 'workshop.vdf' $vdf -NoNewline

    # CHANGELOG.md — reset to clean starting point
    @"
# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - YYYY-MM-DD

- Initial release
"@ | Set-Content 'CHANGELOG.md'

    if ($ModTypeChoice -eq '2') {
        # C# mod: rename and configure
        $HarmonyId = ConvertTo-HarmonyId -Author $Author -ModName $ModName

        Rename-Item 'MyMod.csproj' "$PascalName.csproj"

        $csproj = Get-Content "$PascalName.csproj" -Raw
        $csproj = $csproj -replace '<AssemblyName>MyMod</AssemblyName>', "<AssemblyName>$PascalName</AssemblyName>"
        $csproj = $csproj -replace '<RootNamespace>MyMod</RootNamespace>', "<RootNamespace>$PascalName</RootNamespace>"
        Set-Content "$PascalName.csproj" $csproj -NoNewline

        $cs = Get-Content 'Source/ModEntryPoint.cs' -Raw
        $cs = $cs -replace 'namespace MyMod', "namespace $PascalName"
        $cs = $cs -replace 'com\.yourname\.mymod', $HarmonyId
        $cs = $cs -replace '\[MyMod\]', "[$PascalName]"
        Set-Content 'Source/ModEntryPoint.cs' $cs -NoNewline
    } else {
        # XML-only: remove C# files
        Remove-Item 'MyMod.csproj' -ErrorAction SilentlyContinue
        Remove-Item 'Source' -Recurse -ErrorAction SilentlyContinue

        # Strip C#-only entries from .gitignore
        $gi = Get-Content '.gitignore' | Where-Object { $_ -notmatch '^bin/' -and $_ -notmatch '^obj/' }
        Set-Content '.gitignore' $gi
    }
} finally {
    Pop-Location
}

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host "Created '$ModName' in ./$FolderName/"
Write-Host ''
Write-Host 'What''s inside:'
Write-Host '  ModInfo.xml          Mod metadata (name, author, version)'
Write-Host '  Infos/               XML data files (bonuses, events, text, etc.)'
if ($ModTypeChoice -eq '2') {
    Write-Host "  Source/               C# source files (Harmony patches)"
    Write-Host "  $PascalName.csproj   C# build configuration"
}
Write-Host '  scripts/             Deploy, validate, and upload scripts'
Write-Host '  docs/                Modding guides and reference'
Write-Host ''
Write-Host 'Next steps:'
Write-Host "  1. cd $FolderName"
Write-Host '  2. Copy .env.example to .env and set OLDWORLD_MODS_PATH'
Write-Host '  3. Add your mod content to Infos/'
Write-Host '  4. Run .\scripts\deploy.ps1 to test locally'
Write-Host ''
