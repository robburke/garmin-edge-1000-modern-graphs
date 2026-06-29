# Build all three Varia-Safe graph fields (Power, Cadence, HR) — PowerShell.
# Requires: Connect IQ SDK on PATH (monkeyc), a developer_key in repo root.
param([string]$Device = "edge_1000")   # SDK device id for the Edge 1000 is edge_1000 (underscore)
if (-not (Test-Path "developer_key")) {
    Write-Error "developer_key not found. Generate one (see README) before building."
    exit 1
}
New-Item -ItemType Directory -Force -Path bin | Out-Null
foreach ($f in @("power","cadence","hr")) {
    monkeyc -d $Device -f "$f.jungle" -o "bin/VariaSafe-$f.prg" -y developer_key
    if ($LASTEXITCODE -ne 0) { Write-Error "build failed for $f"; exit 1 }
    Write-Output "built bin/VariaSafe-$f.prg ($Device)"
}
