[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ServerRoot,

    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,

    [string]$OutputLog = "",

    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    $line = "[$(Get-Date -Format o)] [restore_territory] $Message"
    Write-Host $line
    if ($script:OutputLogResolved) {
        Add-Content -Path $script:OutputLogResolved -Value $line
    }
}

if (-not (Test-Path -LiteralPath $ServerRoot)) {
    throw "ServerRoot no existeix: $ServerRoot"
}

if (-not (Test-Path -LiteralPath $ManifestPath)) {
    throw "Manifest no trobat: $ManifestPath"
}

$script:OutputLogResolved = $null
if ($OutputLog) {
    $script:OutputLogResolved = (Resolve-Path -LiteralPath (Split-Path -Path $OutputLog -Parent) -ErrorAction SilentlyContinue)
    if (-not $script:OutputLogResolved) {
        $logDir = Split-Path -Path $OutputLog -Parent
        if ($logDir -and -not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $script:OutputLogResolved = $OutputLog
    }
}

Write-Step "Carregant manifest territorial: $ManifestPath"
$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json

if (-not $manifest.regions) {
    throw "Manifest invàlid: falta la propietat 'regions'."
}

$regions = @($manifest.regions)
if ($regions.Count -eq 0) {
    $msg = "Manifest buit: no hi ha regions per restaurar."
    if ($Strict) { throw $msg } else { Write-Warning $msg; return }
}

Write-Step "Regions al manifest: $($regions.Count)"

# Placeholder d'integració real:
# - Opció A: escriure a DB directament (SQLite/MySQL)
# - Opció B: generar fitxer d'import i executar comanda del plugin
# Aquí creem un fitxer transaccional perquè el plugin el processi a l'arrencada.
$importDir = Join-Path $ServerRoot "rustearth"
$importFile = Join-Path $importDir "territory_restore_queue.json"

if (-not (Test-Path -LiteralPath $importDir)) {
    if ($PSCmdlet.ShouldProcess($importDir, "Crear directori d'import")) {
        New-Item -ItemType Directory -Path $importDir -Force | Out-Null
    }
}

$payload = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    source_manifest = (Resolve-Path -LiteralPath $ManifestPath).Path
    strict = [bool]$Strict
    regions = $regions
}

if ($PSCmdlet.ShouldProcess($importFile, "Escriure cua de restauració territorial")) {
    $payload | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $importFile -Encoding UTF8
}

$countryBreakdown = $regions | Group-Object owner_country_id | Sort-Object Name
foreach ($entry in $countryBreakdown) {
    Write-Step "owner_country_id=$($entry.Name) regions=$($entry.Count)"
}

Write-Step "Restauració preparada correctament. Fitxer de cua: $importFile"
