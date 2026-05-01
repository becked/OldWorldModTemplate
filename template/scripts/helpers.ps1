#Requires -Version 5.1
# helpers.ps1 - Shared functions for PowerShell mod scripts
#
# Usage: dot-source from other scripts:
#   . "$ScriptDir\helpers.ps1"

function Import-DotEnv {
    param([string]$Path = '.env')
    if (-not (Test-Path $Path)) { return $false }
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { return }
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $key = $Matches[1]
            $val = $Matches[2].Trim()
            # Strip surrounding quotes
            if (($val.StartsWith('"') -and $val.EndsWith('"')) -or
                ($val.StartsWith("'") -and $val.EndsWith("'"))) {
                $val = $val.Substring(1, $val.Length - 2)
            }
            [System.Environment]::SetEnvironmentVariable($key, $val, 'Process')
        }
    }
    return $true
}

function Get-XmlTagValue {
    param(
        [string]$FilePath,
        [string]$TagName
    )
    if (-not (Test-Path $FilePath)) { return $null }
    [xml]$doc = Get-Content $FilePath
    $node = $doc.SelectSingleNode("//$TagName")
    if ($node) { return $node.InnerText }
    return $null
}

function Set-XmlTagValue {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$FilePath,
        [string]$TagName,
        [string]$Value
    )
    if (-not (Test-Path $FilePath)) { return $false }
    [xml]$doc = Get-Content $FilePath
    $node = $doc.SelectSingleNode("//$TagName")
    if (-not $node) { return $false }
    if ($PSCmdlet.ShouldProcess($FilePath, "Set <$TagName> to '$Value'")) {
        $node.InnerText = $Value
        $doc.Save((Resolve-Path $FilePath).Path)
    }
    return $true
}

function Invoke-CSharpBuild {
    param(
        [string]$CsprojPath,
        [string]$OldWorldPath
    )
    if (-not $OldWorldPath) {
        Write-Error "OLDWORLD_PATH not set in .env (required for C# build)"
        return
    }
    Write-Host ""
    Write-Host "=== Building C# mod ==="
    & dotnet build $CsprojPath -c Release -p:OldWorldPath="$OldWorldPath"
    if ($LASTEXITCODE -ne 0) { throw "dotnet build failed with exit code $LASTEXITCODE" }
}

function Get-ChangelogForVersion {
    param(
        [string]$Version,
        [string]$ChangelogPath = 'CHANGELOG.md'
    )
    if (-not (Test-Path $ChangelogPath)) { return '' }
    $lines = Get-Content $ChangelogPath
    $found = $false
    $result = @()
    foreach ($line in $lines) {
        if ($line -match '^## \[') {
            if ($found) { break }
            if ($line -match [regex]::Escape("[$Version]")) {
                $found = $true
                continue
            }
        }
        if ($found -and $line.Trim() -ne '') {
            $result += $line
        }
    }
    if ($result.Count -gt 20) {
        $result = $result[0..19]
    }
    return ($result -join "`n")
}

function Invoke-ModioApi {
    param(
        [string]$Method,
        [string]$Uri,
        [string]$Token,
        [hashtable]$FormFields = @{},
        [string[]]$FormArrayFields = @(),
        [string]$FilePath = $null,
        [string]$FileFieldName = $null,
        [switch]$UrlEncoded
    )

    Add-Type -AssemblyName System.Net.Http

    $client = [System.Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.Add('Authorization', "Bearer $Token")
    $client.DefaultRequestHeaders.Add('Accept', 'application/json')

    # mod.io's PUT and tag/metadata endpoints require application/x-www-form-urlencoded.
    # Multipart works for everything else (creates, file uploads).
    $useUrlEncoded = $UrlEncoded -or ($Method -eq 'PUT')

    try {
        if ($FilePath) {
            # Multipart form data with file upload
            $content = [System.Net.Http.MultipartFormDataContent]::new()
            foreach ($field in $FormFields.GetEnumerator()) {
                $content.Add([System.Net.Http.StringContent]::new($field.Value), $field.Key)
            }
            foreach ($entry in $FormArrayFields) {
                $idx = $entry.IndexOf('=')
                if ($idx -lt 0) { continue }
                $content.Add(
                    [System.Net.Http.StringContent]::new($entry.Substring($idx + 1)),
                    $entry.Substring(0, $idx)
                )
            }
            $fileStream = [System.IO.File]::OpenRead((Resolve-Path $FilePath).Path)
            $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
            $content.Add($fileContent, $FileFieldName, [System.IO.Path]::GetFileName($FilePath))

            $response = $client.PostAsync($Uri, $content).Result
            $body = $response.Content.ReadAsStringAsync().Result
            $fileStream.Dispose()
            $content.Dispose()

            return @{
                StatusCode = [int]$response.StatusCode
                Body       = $body | ConvertFrom-Json
                RawBody    = $body
            }
        }
        elseif ($useUrlEncoded) {
            # URL-encoded form data (PUT or tags/metadata POST)
            $parts = @()
            foreach ($field in $FormFields.GetEnumerator()) {
                $parts += "$($field.Key)=$([System.Uri]::EscapeDataString($field.Value))"
            }
            foreach ($entry in $FormArrayFields) {
                $idx = $entry.IndexOf('=')
                if ($idx -lt 0) { continue }
                $key = $entry.Substring(0, $idx)
                $val = $entry.Substring($idx + 1)
                $parts += "$key=$([System.Uri]::EscapeDataString($val))"
            }
            $formEncoded = $parts -join '&'

            $httpContent = [System.Net.Http.StringContent]::new(
                $formEncoded,
                [System.Text.Encoding]::UTF8,
                'application/x-www-form-urlencoded'
            )

            if ($Method -eq 'PUT') {
                $response = $client.PutAsync($Uri, $httpContent).Result
            } elseif ($Method -eq 'DELETE') {
                $req = [System.Net.Http.HttpRequestMessage]::new('DELETE', $Uri)
                $req.Content = $httpContent
                $response = $client.SendAsync($req).Result
                $req.Dispose()
            } else {
                $response = $client.PostAsync($Uri, $httpContent).Result
            }
            $body = $response.Content.ReadAsStringAsync().Result
            $httpContent.Dispose()

            return @{
                StatusCode = [int]$response.StatusCode
                Body       = $(try { $body | ConvertFrom-Json } catch { $null })
                RawBody    = $body
            }
        }
        elseif ($Method -eq 'DELETE') {
            $response = $client.DeleteAsync($Uri).Result
            $body = $response.Content.ReadAsStringAsync().Result
            return @{
                StatusCode = [int]$response.StatusCode
                Body       = $(try { $body | ConvertFrom-Json } catch { $null })
                RawBody    = $body
            }
        }
        else {
            # Simple POST without file (multipart)
            $content = [System.Net.Http.MultipartFormDataContent]::new()
            foreach ($field in $FormFields.GetEnumerator()) {
                $content.Add([System.Net.Http.StringContent]::new($field.Value), $field.Key)
            }
            foreach ($entry in $FormArrayFields) {
                $idx = $entry.IndexOf('=')
                if ($idx -lt 0) { continue }
                $content.Add(
                    [System.Net.Http.StringContent]::new($entry.Substring($idx + 1)),
                    $entry.Substring(0, $idx)
                )
            }

            $response = $client.PostAsync($Uri, $content).Result
            $body = $response.Content.ReadAsStringAsync().Result
            $content.Dispose()

            return @{
                StatusCode = [int]$response.StatusCode
                Body       = $body | ConvertFrom-Json
                RawBody    = $body
            }
        }
    }
    finally {
        $client.Dispose()
    }
}

function Get-GameBuild {
    # Bare game build number (e.g. "1.0.83082"). Used for <modbuild> in
    # ModInfo.xml and metadata_blob on mod.io. Resolution order:
    #   1. $env:OLDWORLD_BUILD (manual override — required on Linux)
    #   2. Windows: $env:OLDWORLD_PATH\OldWorld.exe FileVersion
    #   3. macOS: $env:OLDWORLD_PATH/OldWorld.app/Contents/Info.plist
    $override = [System.Environment]::GetEnvironmentVariable('OLDWORLD_BUILD', 'Process')
    if ($override) { return $override }

    $owPath = [System.Environment]::GetEnvironmentVariable('OLDWORLD_PATH', 'Process')
    if (-not $owPath) {
        Write-Error "Cannot determine game build. Set OLDWORLD_BUILD in .env (e.g. OLDWORLD_BUILD=`"1.0.83082`") or set OLDWORLD_PATH to the game install."
        return $null
    }

    $exe = Join-Path $owPath 'OldWorld.exe'
    if (Test-Path $exe) {
        $info = (Get-Item $exe).VersionInfo
        if ($info.FileVersion) {
            # FileVersion may be "1.0.83082.0" — strip trailing ".0" if present
            return ($info.FileVersion -split '\s')[0]
        }
    }

    $plist = Join-Path $owPath 'OldWorld.app/Contents/Info.plist'
    if (Test-Path $plist) {
        [xml]$doc = Get-Content $plist
        $node = $doc.SelectNodes("//key[. = 'CFBundleShortVersionString']/following-sibling::string[1]")
        if ($node.Count -gt 0) {
            return ($node[0].InnerText -split '\s')[0]
        }
    }

    Write-Error "Cannot determine game build. Set OLDWORLD_BUILD in .env."
    return $null
}

function Get-ModioTag {
    # Comma-separated mod.io tags. Auto-derives Singleplayer/Multiplayer from
    # ModInfo.xml flags, then appends $env:MODIO_TAGS from .env. Old World's
    # mod.io taxonomy (game 634):
    #   Translation, Map, Other, Multiplayer, Singleplayer, MapScript, Nation,
    #   Tribe, Character, Family, GameInfo, Event, Scenario, AI, UI, Conversion
    param(
        [string]$ModInfoPath = 'ModInfo.xml'
    )
    $tags = @()
    if (Test-Path $ModInfoPath) {
        [xml]$doc = Get-Content $ModInfoPath
        if ($doc.SelectSingleNode("//singlePlayer[. = 'true']")) { $tags += 'Singleplayer' }
        if ($doc.SelectSingleNode("//multiplayer[. = 'true']")) { $tags += 'Multiplayer' }
    }
    $extra = [System.Environment]::GetEnvironmentVariable('MODIO_TAGS', 'Process')
    if ($extra) {
        foreach ($t in ($extra -split ',')) {
            $trimmed = $t.Trim()
            if ($trimmed) { $tags += $trimmed }
        }
    }
    return ($tags -join ',')
}

function Set-ModInfoPlatform {
    # Inject platform fields into a staged ModInfo.xml so the runtime mod loader
    # can detect updates. Pass empty string for fields that don't apply (e.g.
    # WorkshopId='' on a mod.io upload). Idempotent — strips existing platform
    # tags first, so safe on copies that may have inherited stale fields.
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$FilePath,
        [string]$Platform,
        [string]$ModioId,
        [string]$WorkshopId,
        [string]$Build
    )
    if (-not (Test-Path $FilePath)) { return $false }
    if (-not $PSCmdlet.ShouldProcess($FilePath, "Inject platform=$Platform build=$Build")) { return $true }

    [xml]$doc = Get-Content $FilePath
    $root = $doc.DocumentElement
    foreach ($name in @('modplatform','modioID','modioFileID','workshopOwnerID','workshopFileID','modbuild')) {
        $existing = $root.SelectSingleNode($name)
        if ($existing) { [void]$root.RemoveChild($existing) }
    }
    function Add-Element([string]$tag, [string]$value) {
        $el = $doc.CreateElement($tag)
        $el.InnerText = $value
        [void]$root.AppendChild($el)
    }
    if ($Platform)   { Add-Element 'modplatform' $Platform }
    if ($ModioId)    { Add-Element 'modioID' $ModioId; Add-Element 'modioFileID' '0' }
    if ($WorkshopId) { Add-Element 'workshopFileID' $WorkshopId }
    if ($Build)      { Add-Element 'modbuild' $Build }
    $doc.Save((Resolve-Path $FilePath).Path)
    return $true
}
