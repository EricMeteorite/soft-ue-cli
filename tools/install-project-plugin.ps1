param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Utf8NoBomFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$PluginSource = Join-Path $RepoRoot 'soft_ue_cli\plugin_data\SoftUEBridge'
$ResolvedProjectRoot = (Resolve-Path $ProjectRoot).Path

if (-not (Test-Path $PluginSource)) {
    throw "Plugin source not found: $PluginSource"
}

$uprojectFiles = @(Get-ChildItem -Path $ResolvedProjectRoot -Filter *.uproject -File)
if ($uprojectFiles.Count -eq 0) {
    throw "No .uproject file found in $ResolvedProjectRoot"
}

if ($uprojectFiles.Count -gt 1) {
    throw "Multiple .uproject files found in $ResolvedProjectRoot. Keep only one project file in the root when using this script."
}

$uprojectPath = $uprojectFiles[0].FullName
$pluginsRoot = Join-Path $ResolvedProjectRoot 'Plugins'
$pluginDest = Join-Path $pluginsRoot 'SoftUEBridge'

Write-Host "[1/4] Validating destination"
if ((Test-Path $pluginDest) -and (-not $Force)) {
    throw "Destination already exists: $pluginDest`nRe-run with -Force if you want to replace it."
}

Write-Host "[2/4] Copying project-local plugin files"
New-Item -ItemType Directory -Path $pluginsRoot -Force | Out-Null
if (Test-Path $pluginDest) {
    Remove-Item -Path $pluginDest -Recurse -Force
}
Copy-Item -Path $PluginSource -Destination $pluginDest -Recurse -Force

Write-Host "[3/4] Enabling plugin in the project file"
$uprojectText = Get-Content -Path $uprojectPath -Raw -Encoding UTF8
$uprojectJson = $uprojectText | ConvertFrom-Json

if ($null -eq $uprojectJson.Plugins) {
    $uprojectJson | Add-Member -MemberType NoteProperty -Name Plugins -Value @()
}

$pluginEntry = $uprojectJson.Plugins | Where-Object { $_.Name -eq 'SoftUEBridge' } | Select-Object -First 1
if ($null -eq $pluginEntry) {
    $uprojectJson.Plugins += [pscustomobject]@{
        Name = 'SoftUEBridge'
        Enabled = $true
    }
}
else {
    $pluginEntry.Enabled = $true
}

$uprojectContent = $uprojectJson | ConvertTo-Json -Depth 100
Write-Utf8NoBomFile -Path $uprojectPath -Content $uprojectContent

Write-Host "[4/4] Installation summary"
Write-Host "Project plugin installed at: $pluginDest"
Write-Host "Project file updated: $uprojectPath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Regenerate project files for the UE project."
Write-Host "  2. Build the project with your source-built engine."
Write-Host "  3. Launch the editor and wait for the SoftUEBridge server log line."
Write-Host "  4. From this repo, run: tools\\soft-ue-cli.cmd check-setup $ResolvedProjectRoot"
Write-Host ""
Write-Host "This script only changes the target project. It does not modify the engine or the system environment."