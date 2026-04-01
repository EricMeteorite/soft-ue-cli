Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$VenvPython = Join-Path $RepoRoot '.venv\Scripts\python.exe'

if (-not (Test-Path $VenvPython)) {
    throw "Local virtual environment not found. Run tools\\bootstrap-local.ps1 first."
}

& $VenvPython -m soft_ue_cli @Args
exit $LASTEXITCODE