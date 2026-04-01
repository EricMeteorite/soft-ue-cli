@echo off
setlocal
set "REPO_ROOT=%~dp0.."
set "VENV_PYTHON=%REPO_ROOT%\.venv\Scripts\python.exe"

if not exist "%VENV_PYTHON%" (
    echo [ERROR] Local virtual environment not found. Run tools\bootstrap-local.ps1 first.
    exit /b 1
)

"%VENV_PYTHON%" -m soft_ue_cli %*
exit /b %ERRORLEVEL%