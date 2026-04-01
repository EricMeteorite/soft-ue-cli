param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
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

$ResolvedProjectRoot = (Resolve-Path $ProjectRoot).Path
$uprojectFiles = @(Get-ChildItem -Path $ResolvedProjectRoot -Filter *.uproject -File)

if ($uprojectFiles.Count -eq 0) {
    throw "No .uproject file found in $ResolvedProjectRoot"
}

if ($uprojectFiles.Count -gt 1) {
    throw "Multiple .uproject files found in $ResolvedProjectRoot. Keep only one project file in the root when using this script."
}

$uprojectPath = $uprojectFiles[0].FullName
$pluginDest = Join-Path $ResolvedProjectRoot 'Plugins\SoftUEBridge'
$bridgeStateDir = Join-Path $ResolvedProjectRoot '.soft-ue-bridge'

Write-Host "[1/3] Removing project-local plugin files"
if (Test-Path $pluginDest) {
    Remove-Item -Path $pluginDest -Recurse -Force
}

Write-Host "[2/3] Removing plugin entry from the project file"
$uprojectText = Get-Content -Path $uprojectPath -Raw -Encoding UTF8
$uprojectJson = $uprojectText | ConvertFrom-Json
if ($null -ne $uprojectJson.Plugins) {
    $uprojectJson.Plugins = @($uprojectJson.Plugins | Where-Object { $_.Name -ne 'SoftUEBridge' })
    $uprojectContent = $uprojectJson | ConvertTo-Json -Depth 100
    Write-Utf8NoBomFile -Path $uprojectPath -Content $uprojectContent
}

Write-Host "[3/3] Cleaning bridge runtime state"
if (Test-Path $bridgeStateDir) {
    Remove-Item -Path $bridgeStateDir -Recurse -Force
}

Write-Host "Plugin integration removed from the project."
Write-Host "Regenerate project files before the next build if the project had already compiled the plugin."