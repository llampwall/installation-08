#requires -Version 7
# SPDX-License-Identifier: AGPL-3.0-only. Additional terms: see NOTICE.md.
<#
.SYNOPSIS
    Embeds the app's PE manifest (cmd\infinite-theater-3d\app.manifest) into a finished
    Windows exe, replacing the default manifest Go's linker writes in.

.DESCRIPTION
    Go links a single default manifest (long-path awareness, asInvoker) into every exe;
    a second name-1 manifest from a .syso only sits behind it, because Windows loads the
    first one found. mt.exe -outputresource:exe;1 replaces that one default with
    app.manifest (per-monitor-v2 DPI awareness, long-path awareness, Common Controls v6,
    Windows 10). The exe must have been built WITHOUT a user manifest resource, which is
    what cmd\infinite-theater-3d\resources.rc guarantees.

.PARAMETER Exe
    The built exe to modify in place.
#>
param(
    [Parameter(Mandatory = $true)][string]$Exe
)

$ErrorActionPreference = 'Stop'
$scriptDir = Split-Path -Parent $PSCommandPath
$manifest = Join-Path (Join-Path (Split-Path -Parent $scriptDir) 'cmd\infinite-theater-3d') 'app.manifest'
if (-not (Test-Path $manifest)) { throw "manifest not found: $manifest" }
if (-not (Test-Path $Exe)) { throw "exe not found: $Exe" }

# Find mt.exe: a Windows Kits 10 SDK on the system, newest version first.
$kitsBin = 'C:\Program Files (x86)\Windows Kits\10\bin'
$mt = $null
if (Test-Path $kitsBin) {
    $candidates = Get-ChildItem $kitsBin -Directory -Filter '10.*' |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName 'x64\mt.exe' } |
        Where-Object { Test-Path $_ }
    if ($candidates) { $mt = @($candidates)[0] }
}
if (-not $mt) { throw 'mt.exe was not found in a Windows Kits 10 SDK' }

& $mt '-manifest' $manifest "-outputresource:$Exe;1"
if ($LASTEXITCODE -ne 0) { throw "mt.exe failed (exit $LASTEXITCODE)" }
Write-Host "Embedded $manifest into $Exe"
