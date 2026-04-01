@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul
set "REPO_ROOT=%cd%"
set "CLI_CMD=%REPO_ROOT%\tools\soft-ue-cli.cmd"
set "BOOTSTRAP=%REPO_ROOT%\tools\bootstrap-local.ps1"
set "INSTALL_PLUGIN=%REPO_ROOT%\tools\install-project-plugin.ps1"
set "UNINSTALL_PLUGIN=%REPO_ROOT%\tools\uninstall-project-plugin.ps1"
set "DOC_BEGINNER=%REPO_ROOT%\docs\BEGINNER_GUIDE_ZH-CN.md"
set "DOC_DEPLOY=%REPO_ROOT%\docs\LOCAL_DEPLOYMENT_ZH-CN.md"
set "DOC_AI=%REPO_ROOT%\docs\AI_CONTROL_GUIDE_ZH-CN.md"
set "MENU_TEXTS=%REPO_ROOT%\tools\menu-texts.json"

:menu
cls
call :show_text menuMain
echo.
call :show_text promptChoice
choice /c 123456789 /n /m "> "
if errorlevel 9 goto done
if errorlevel 8 goto querylevel
if errorlevel 7 goto status
if errorlevel 6 goto checksetup
if errorlevel 5 goto uninstall
if errorlevel 4 goto install
if errorlevel 3 goto help
if errorlevel 2 goto docs
if errorlevel 1 goto bootstrap
echo.
call :show_text invalidChoice
goto wait_return

:bootstrap
cls
call :show_text actionBootstrap
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOTSTRAP%"
goto wait_return

:docs
cls
call :show_text actionDocs
echo.
start "" "%DOC_BEGINNER%"
start "" "%DOC_DEPLOY%"
start "" "%DOC_AI%"
call :show_text actionDocsFallback
goto wait_return

:help
cls
call :show_text actionHelp
echo.
call "%CLI_CMD%" --help
goto wait_return

:install
cls
call :show_text actionInstall
echo.
call :read_project_path
if not defined PROJECT_PATH goto wait_return
powershell -NoProfile -ExecutionPolicy Bypass -File "%INSTALL_PLUGIN%" -ProjectRoot "%PROJECT_PATH%"
goto wait_return

:uninstall
cls
call :show_text actionUninstall
echo.
call :read_project_path
if not defined PROJECT_PATH goto wait_return
powershell -NoProfile -ExecutionPolicy Bypass -File "%UNINSTALL_PLUGIN%" -ProjectRoot "%PROJECT_PATH%"
goto wait_return

:checksetup
cls
call :show_text actionChecksetup
echo.
call :read_project_path
if not defined PROJECT_PATH goto wait_return
call "%CLI_CMD%" check-setup "%PROJECT_PATH%"
goto wait_return

:status
cls
call :show_text actionStatus
echo.
call :read_project_path
if not defined PROJECT_PATH goto wait_return
pushd "%PROJECT_PATH%" >nul
call "%CLI_CMD%" status
popd >nul
goto wait_return

:querylevel
cls
call :show_text actionQuerylevel
echo.
call :read_project_path
if not defined PROJECT_PATH goto wait_return
pushd "%PROJECT_PATH%" >nul
call "%CLI_CMD%" query-level --limit 20
popd >nul
goto wait_return

:read_project_path
set "PROJECT_PATH="
echo.
call :show_text promptProjectPath
set /p PROJECT_PATH=
if "%PROJECT_PATH%"=="" (
    echo.
    call :show_text pathCancelled
)
exit /b 0

:wait_return
echo.
call :show_text promptReturn
pause >nul
goto menu

:done
echo.
call :show_text exitMessage
exit /b 0

:show_text
powershell -NoProfile -ExecutionPolicy Bypass -Command "$json = Get-Content -Raw -Encoding UTF8 '%MENU_TEXTS%' | ConvertFrom-Json; $value = $json.%~1; if ($value -is [System.Array]) { $value | ForEach-Object { Write-Output $_ } } else { Write-Output $value }"
exit /b 0