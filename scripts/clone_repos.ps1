Param(
    [string]$Root = "."
)

$ErrorActionPreference = "Stop"

function Clone-IfMissing {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$Target
    )

    if (Test-Path $Target) {
        Write-Host "[SKIP] Ja existeix: $Target"
        return
    }

    $parent = Split-Path -Parent $Target
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Write-Host "[CLONE] $Url -> $Target"
    git clone $Url $Target
}

Push-Location $Root
try {
    Clone-IfMissing -Url "https://github.com/GameServerManagers/LinuxGSM.git" -Target "server/lgsm"
    Clone-IfMissing -Url "https://github.com/CarbonCommunity/Carbon.git" -Target "framework/carbon"
    Clone-IfMissing -Url "https://github.com/OxideMod/Oxide.Rust.git" -Target "framework/oxide"
    Clone-IfMissing -Url "https://github.com/Facepunch/webrcon.git" -Target "integrations/rcon-tools/webrcon"

    Write-Host "\nCompletat. Revisa REPOS_STACK_BASE.md per context i riscos."
}
finally {
    Pop-Location
}
