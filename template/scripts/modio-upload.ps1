#Requires -Version 5.1
# modio-upload.ps1 - Upload mod to mod.io
#
# Prerequisites:
#   1. Get an OAuth2 access token from https://mod.io/me/access (read+write)
#   2. Copy your API URL from https://mod.io/me/access (e.g. https://u-XXXX.modapi.io/v1)
#   3. .env file with MODIO_API_URL, MODIO_ACCESS_TOKEN, MODIO_GAME_ID (MODIO_MOD_ID created automatically on first run)
#
# Usage: .\scripts\modio-upload.ps1 [-DryRun] [[-Changelog] "message"]
# Examples:
#   .\scripts\modio-upload.ps1                         # Upload with changelog from CHANGELOG.md
#   .\scripts\modio-upload.ps1 -Changelog "Fixed X"    # Upload with custom changelog
#   .\scripts\modio-upload.ps1 -DryRun                 # Preview without uploading

param(
    [switch]$DryRun,
    [string]$Changelog = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
. "$ScriptDir\helpers.ps1"
Push-Location $ProjectDir

try {
    # Load .env
    if (-not (Import-DotEnv)) {
        Write-Error ".env file not found"
    }

    # Check required variables
    $Token = [System.Environment]::GetEnvironmentVariable('MODIO_ACCESS_TOKEN', 'Process')
    if (-not $Token) {
        Write-Error "MODIO_ACCESS_TOKEN not set in .env. Get one from https://mod.io/me/access (OAuth 2 section, read+write)"
    }

    $ApiUrl = [System.Environment]::GetEnvironmentVariable('MODIO_API_URL', 'Process')
    if (-not $ApiUrl) {
        Write-Error "MODIO_API_URL not set in .env. Copy your API URL from https://mod.io/me/access (e.g. https://u-XXXX.modapi.io/v1)"
    }

    $GameId = [System.Environment]::GetEnvironmentVariable('MODIO_GAME_ID', 'Process')
    if (-not $GameId) {
        Write-Error "MODIO_GAME_ID must be set in .env"
    }

    $ModId = [System.Environment]::GetEnvironmentVariable('MODIO_MOD_ID', 'Process')

    $GameBuild = Get-GameBuild
    if (-not $GameBuild) { exit 1 }
    $Tags = Get-ModioTag -ModInfoPath 'ModInfo.xml'
    Write-Host "Game build: $GameBuild"
    Write-Host "mod.io tags: $Tags"

    # Validate mod content (run as subprocess so validate's exit doesn't terminate us)
    $psExe = (Get-Process -Id $PID).Path
    & $psExe -NoProfile -ExecutionPolicy Bypass -File "$ScriptDir\validate.ps1"
    if ($LASTEXITCODE -ne 0) { exit 1 }

    # Build C# mod if project file exists
    $csproj = Get-ChildItem "$ProjectDir\*.csproj" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($csproj) {
        $owPath = [System.Environment]::GetEnvironmentVariable('OLDWORLD_PATH', 'Process')
        Invoke-CSharpBuild $csproj.FullName $owPath
    }

    # Read version from ModInfo.xml (single source of truth)
    $Version = Get-XmlTagValue 'ModInfo.xml' 'modversion'
    if (-not $Version) {
        Write-Error "Could not extract version from ModInfo.xml"
    }
    Write-Host "Version: $Version"

    # Changelog: use parameter if provided, otherwise extract from CHANGELOG.md
    if (-not $Changelog) {
        $Changelog = Get-ChangelogForVersion -Version $Version
    }

    # Read mod metadata from ModInfo.xml
    $ModName = Get-XmlTagValue 'ModInfo.xml' 'displayName'
    $ModSummary = Get-XmlTagValue 'ModInfo.xml' 'description'
    if (-not $ModName) {
        Write-Error "Could not extract mod name from ModInfo.xml"
    }

    # Read description from file if available
    $Description = ''
    if (Test-Path 'mod-description.html') {
        $Description = Get-Content 'mod-description.html' -Raw
    }

    if ($DryRun) {
        Write-Host ""
        Write-Host "=== Dry run summary ==="
        Write-Host "Version: $Version"
        Write-Host "Changelog: $(if ($Changelog) { $Changelog } else { '(none)' })"
        Write-Host ""
        Write-Host "Files to upload:"
        Get-ChildItem 'Infos', 'ModInfo.xml' -ErrorAction SilentlyContinue | ForEach-Object { Write-Host "  $($_.Name)" }
        if (Test-Path 'logo-512.png') { Write-Host "  logo-512.png" }
        Write-Host ""
        Write-Host "Dry run complete - nothing was uploaded."
        exit 0
    }

    $BaseUrl = "$ApiUrl/games/$GameId"

    # Step 1: Create or update mod profile
    if (-not $ModId) {
        # Create new mod
        Write-Host ""
        Write-Host "=== Creating new mod on mod.io ==="

        $fields = @{
            'name'              = $ModName
            'summary'           = $ModSummary
            'community_options' = '1'
            'metadata_blob'     = ";;;$GameBuild"
        }
        if ($Description) {
            $fields['description'] = $Description
        }

        $result = Invoke-ModioApi -Method 'POST' -Uri "$BaseUrl/mods" -Token $Token `
            -FormFields $fields -FilePath 'logo-512.png' -FileFieldName 'logo'

        if ($result.StatusCode -eq 201) {
            $ModId = [string]$result.Body.id
            Write-Host "Mod created successfully! Mod ID: $ModId"

            # Save mod ID to .env for future runs
            $envContent = Get-Content '.env'
            if ($envContent -match '^#?MODIO_MOD_ID=') {
                $envContent = $envContent -replace '^#?MODIO_MOD_ID=.*', "MODIO_MOD_ID=`"$ModId`""
            } else {
                $envContent += "MODIO_MOD_ID=`"$ModId`""
            }
            $envContent | Set-Content '.env'
            Write-Host "Saved MODIO_MOD_ID=$ModId to .env"
        } else {
            Write-Host "Mod creation failed (HTTP $($result.StatusCode))"
            Write-Host ($result.RawBody | ConvertFrom-Json | ConvertTo-Json -Depth 5)
            exit 1
        }
    } else {
        # Update existing mod profile
        Write-Host ""
        Write-Host "=== Updating mod profile (text fields) ==="

        $fields = @{
            'name'              = $ModName
            'summary'           = $ModSummary
            'community_options' = '1'
            'metadata_blob'     = ";;;$GameBuild"
        }
        if ($Description) {
            $fields['description'] = $Description
        }

        $result = Invoke-ModioApi -Method 'PUT' -Uri "$BaseUrl/mods/$ModId" -Token $Token `
            -FormFields $fields

        if ($result.StatusCode -eq 200) {
            Write-Host "Profile text fields updated successfully"
        } else {
            Write-Host "Warning: Profile update failed (HTTP $($result.StatusCode))"
            try {
                Write-Host ($result.RawBody | ConvertFrom-Json | ConvertTo-Json -Depth 5)
            } catch {
                Write-Host $result.RawBody
            }
        }
    }

    # Replace tags unconditionally — script is source of truth
    if ($Tags) {
        Write-Host ""
        Write-Host "=== Setting tags ==="
        [void](Invoke-ModioApi -Method 'DELETE' -Uri "$BaseUrl/mods/$ModId/tags" -Token $Token)

        $tagFields = @($Tags -split ',' | ForEach-Object { "tags[]=$_" })
        $tagResult = Invoke-ModioApi -Method 'POST' -Uri "$BaseUrl/mods/$ModId/tags" -Token $Token `
            -FormArrayFields $tagFields -UrlEncoded
        if ($tagResult.StatusCode -eq 201 -or $tagResult.StatusCode -eq 200) {
            Write-Host "Tags set: $Tags"
        } else {
            Write-Host "Warning: Tag update failed (HTTP $($tagResult.StatusCode))"
            Write-Host $tagResult.RawBody
        }
    }

    # Step 2: Upload logo
    if (Test-Path 'logo-512.png') {
        Write-Host ""
        Write-Host "=== Uploading logo ==="

        $result = Invoke-ModioApi -Method 'POST' -Uri "$BaseUrl/mods/$ModId/media" -Token $Token `
            -FilePath 'logo-512.png' -FileFieldName 'logo'

        if ($result.StatusCode -eq 201) {
            Write-Host "Logo uploaded successfully"
        } else {
            Write-Host "Warning: Logo upload failed (HTTP $($result.StatusCode))"
            try {
                Write-Host ($result.RawBody | ConvertFrom-Json | ConvertTo-Json -Depth 5)
            } catch {
                Write-Host $result.RawBody
            }
        }
    } else {
        Write-Host "Warning: logo-512.png not found, skipping logo upload"
    }

    # Step 3: Prepare and upload modfile
    Write-Host ""
    Write-Host "=== Preparing upload package ==="
    if (Test-Path 'modio_content') { Remove-Item 'modio_content' -Recurse -Force }
    if (Test-Path 'modio_upload.zip') { Remove-Item 'modio_upload.zip' -Force }
    New-Item -ItemType Directory -Path 'modio_content' -Force | Out-Null

    Copy-Item 'ModInfo.xml' 'modio_content\'
    Set-ModInfoPlatform -FilePath 'modio_content\ModInfo.xml' -Platform 'Modio' -ModioId $ModId -WorkshopId '' -Build $GameBuild | Out-Null
    if (Test-Path 'logo-512.png') { Copy-Item 'logo-512.png' 'modio_content\' }
    Copy-Item -Path 'Infos' -Destination 'modio_content\Infos' -Recurse

    # Copy built DLLs if C# mod
    if ($csproj) {
        Copy-Item "$ProjectDir\bin\*.dll" 'modio_content\'
    }

    Write-Host "Content prepared:"
    Get-ChildItem 'modio_content' -Recurse | ForEach-Object {
        Write-Host "  $($_.FullName.Substring((Resolve-Path 'modio_content').Path.Length + 1))"
    }

    # Create zip file
    Write-Host ""
    Write-Host "=== Creating zip file ==="
    Compress-Archive -Path 'modio_content\*' -DestinationPath 'modio_upload.zip' -Force
    $zipSize = (Get-Item 'modio_upload.zip').Length
    Write-Host "Created modio_upload.zip ($([math]::Round($zipSize / 1KB, 1)) KB)"

    # Upload modfile
    Write-Host ""
    Write-Host "=== Uploading modfile to mod.io ==="
    Write-Host "Game ID: $GameId"
    Write-Host "Mod ID: $ModId"

    $fields = @{}
    if ($Version) {
        Write-Host "Version: $Version"
        $fields['version'] = $Version
    }
    if ($Changelog) {
        Write-Host "Changelog: $Changelog"
        $fields['changelog'] = $Changelog
    }

    Write-Host ""

    $result = Invoke-ModioApi -Method 'POST' -Uri "$BaseUrl/mods/$ModId/files" -Token $Token `
        -FormFields $fields -FilePath 'modio_upload.zip' -FileFieldName 'filedata'

    if ($result.StatusCode -eq 201) {
        Write-Host "Modfile upload successful!"
        Write-Host ""
        Write-Host "Response:"
        try {
            Write-Host ($result.Body | ConvertTo-Json -Depth 5)
        } catch {
            Write-Host $result.RawBody
        }
    } else {
        Write-Host "Modfile upload failed (HTTP $($result.StatusCode))"
        Write-Host ""
        Write-Host "Response:"
        try {
            Write-Host ($result.RawBody | ConvertFrom-Json | ConvertTo-Json -Depth 5)
        } catch {
            Write-Host $result.RawBody
        }
        exit 1
    }

    # Cleanup
    Remove-Item 'modio_content' -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item 'modio_upload.zip' -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "=== Upload complete ==="
} finally {
    Pop-Location
}
