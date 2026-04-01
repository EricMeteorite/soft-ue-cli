Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$VenvDir = Join-Path $RepoRoot '.venv'
$VenvPython = Join-Path $VenvDir 'Scripts\python.exe'

function Get-PythonInvocation {
    $candidates = @(
        @{ Exe = 'py'; Args = @('-3') },
        @{ Exe = 'python'; Args = @() },
        @{ Exe = 'python3'; Args = @() }
    )

    foreach ($candidate in $candidates) {
        if (-not (Get-Command $candidate.Exe -ErrorAction SilentlyContinue)) {
            continue
        }

        try {
            $versionText = & $candidate.Exe @($candidate.Args) -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
            if ($LASTEXITCODE -ne 0) {
                continue
            }

            $version = [version]::Parse("$versionText.0")
            if ($version.Major -gt 3 -or ($version.Major -eq 3 -and $version.Minor -ge 10)) {
                return $candidate
            }
        }
        catch {
            continue
        }
    }

    return $null
}

Write-Host "[1/4] Resolving Python 3.10+"
$pythonInvocation = Get-PythonInvocation
if ($null -eq $pythonInvocation) {
    throw "Python 3.10+ was not found. Install Python first, or point the script to a local portable Python inside this folder."
}

Write-Host "[2/4] Creating or reusing local virtual environment"
if (-not (Test-Path $VenvPython)) {
    & $pythonInvocation.Exe @($pythonInvocation.Args) -m venv $VenvDir
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create .venv"
    }
}

Write-Host "[3/4] Installing soft-ue-cli into the local virtual environment"
& $VenvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) {
    throw "Failed to upgrade pip inside .venv"
}

& $VenvPython -m pip install -e $RepoRoot pytest
if ($LASTEXITCODE -ne 0) {
    throw "Failed to install project dependencies inside .venv"
}

Write-Host "[4/4] Running local validation"
& $VenvPython -m soft_ue_cli --help | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "soft_ue_cli --help failed"
}

& $VenvPython -m pytest -q
if ($LASTEXITCODE -ne 0) {
    throw "pytest failed"
}

Write-Host ""
Write-Host "Local deployment completed successfully."
Write-Host "Run commands with:"
Write-Host "  tools\\soft-ue-cli.cmd --help"
Write-Host "or"
Write-Host "  powershell -ExecutionPolicy Bypass -File tools\\soft-ue-cli.ps1 --help"