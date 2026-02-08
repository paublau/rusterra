[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerRoot,

    [Parameter(Mandatory = $true)]
    [string]$BackupRoot,

    [string]$ServiceName = "RustDedicated",

    [string]$TerritoryManifestPath = "",

    [int]$WaitSeconds = 45,

    [switch]$SkipStart,
    [switch]$SkipRestore
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    $line = "[$(Get-Date -Format o)] [wipe_15d] $Message"
    Write-Host $line
    Add-Content -Path $script:LogFile -Value $line
}

function Ensure-Path {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Path no trobat: $Path"
    }
}

Ensure-Path -Path $ServerRoot
if (-not (Test-Path -LiteralPath $BackupRoot)) {
    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
}

$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$runDir = Join-Path $BackupRoot $runId
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$script:LogFile = Join-Path $runDir "wipe_15d.log"
Write-Step "Iniciant runbook de wipe. run_id=$runId"
Write-Step "ServerRoot=$ServerRoot BackupRoot=$BackupRoot Service=$ServiceName"

$worldFiles = Get-ChildItem -Path $ServerRoot -Recurse -File |
    Where-Object { $_.Name -match '\.(sav|map|db)$' -or $_.Name -match 'player\.(db|blueprints)' }

$territoryCandidates = Get-ChildItem -Path $ServerRoot -Recurse -File |
    Where-Object { $_.FullName -match 'rustearth|territory|regions' }

$backupDataDir = Join-Path $runDir "data"
New-Item -ItemType Directory -Path $backupDataDir -Force | Out-Null

Write-Step "Backup de fitxers de món i estat"
foreach ($f in $worldFiles) {
    $dest = Join-Path $backupDataDir ($f.FullName.Substring($ServerRoot.Length).TrimStart('\\','/'))
    $destDir = Split-Path -Path $dest -Parent
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if ($PSCmdlet.ShouldProcess($f.FullName, "Copiar a backup")) {
        Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
    }
}

if (-not $TerritoryManifestPath) {
    $TerritoryManifestPath = Join-Path $runDir "territory_manifest.json"
}

Write-Step "Generant manifest territorial de suport"
$regions = @()
foreach ($c in $territoryCandidates) {
    # Placeholder: en integració real aquí es llegeix DB o export del plugin.
    # Es deixa estructura mínima perquè el restore sigui deterministic.
}

$manifest = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    run_id = $runId
    notes = "Manifest placeholder. Substituir per export real de RustEarthTerritory."
    regions = $regions
}
if ($PSCmdlet.ShouldProcess($TerritoryManifestPath, "Escriure manifest territorial")) {
    $manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $TerritoryManifestPath -Encoding UTF8
}

Write-Step "Aturant servei $ServiceName"
$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($null -ne $svc -and $svc.Status -ne 'Stopped') {
    if ($PSCmdlet.ShouldProcess($ServiceName, "Stop-Service")) {
        Stop-Service -Name $ServiceName -Force
    }
}
Start-Sleep -Seconds $WaitSeconds

Write-Step "Executant wipe de fitxers de món"
$wipeTargets = Get-ChildItem -Path $ServerRoot -Recurse -File |
    Where-Object { $_.Name -match '\.(sav|map)$' -or $_.Name -eq 'proceduralmap.*' }

foreach ($w in $wipeTargets) {
    if ($PSCmdlet.ShouldProcess($w.FullName, "Eliminar fitxer de món")) {
        Remove-Item -LiteralPath $w.FullName -Force
    }
}

if (-not $SkipStart) {
    Write-Step "Arrencant servei $ServiceName"
    if ($null -ne $svc) {
        if ($PSCmdlet.ShouldProcess($ServiceName, "Start-Service")) {
            Start-Service -Name $ServiceName
        }
    } else {
        Write-Warning "Servei $ServiceName no trobat. Arrencada manual requerida."
        Write-Step "Servei no trobat; arrencada manual requerida"
    }
    Start-Sleep -Seconds ([Math]::Min([Math]::Max($WaitSeconds, 10), 120))
}

if (-not $SkipRestore) {
    Write-Step "Cridant restore_territory.ps1"
    $restoreScript = Join-Path $PSScriptRoot "restore_territory.ps1"
    if (-not (Test-Path -LiteralPath $restoreScript)) {
        throw "No trobo $restoreScript"
    }

    $restoreArgs = @(
        "-File", $restoreScript,
        "-ServerRoot", $ServerRoot,
        "-ManifestPath", $TerritoryManifestPath,
        "-OutputLog", $script:LogFile
    )

    if ($WhatIfPreference) {
        $restoreArgs += "-WhatIf"
    }

    & pwsh @restoreArgs
    if ($LASTEXITCODE -ne 0) {
        throw "restore_territory.ps1 ha fallat amb codi $LASTEXITCODE"
    }
}

Write-Step "Wipe 15d finalitzat correctament"
Write-Step "Logs: $script:LogFile"
