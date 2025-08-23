@echo off
setlocal enabledelayedexpansion

echo =======================================================
echo   Froom Migration Script Launcher
echo =======================================================
echo.

:: Check if PowerShell is available
where powershell >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] PowerShell is not available on this system.
    echo Please install PowerShell or use the bash scripts on WSL/Git Bash.
    pause
    exit /b 1
)

:: Check current execution policy
echo [INFO] Checking PowerShell execution policy...
for /f "tokens=*" %%i in ('powershell -Command "Get-ExecutionPolicy"') do set current_policy=%%i
echo Current execution policy: %current_policy%

:: Check if current policy allows script execution
if /i "%current_policy%"=="Unrestricted" goto :policy_ok
if /i "%current_policy%"=="RemoteSigned" goto :policy_ok
if /i "%current_policy%"=="AllSigned" goto :policy_ok
if /i "%current_policy%"=="Bypass" goto :policy_ok

:: Policy is too restrictive
echo.
echo [WARNING] Current PowerShell execution policy (%current_policy%) prevents running scripts.
echo.
echo Available options:
echo   1. Temporarily bypass policy for this session (Recommended)
echo   2. Change execution policy to RemoteSigned (Requires admin rights)
echo   3. Exit and run manually
echo.
set /p choice="Please select an option (1-3): "

if "%choice%"=="1" goto :bypass_policy
if "%choice%"=="2" goto :change_policy
if "%choice%"=="3" goto :manual_instructions
echo Invalid choice. Please try again.
goto :policy_check

:bypass_policy
echo.
echo [INFO] Running migration script with bypassed execution policy...
goto :select_script

:change_policy
echo.
echo [INFO] Attempting to change execution policy to RemoteSigned...
echo This requires administrator privileges.
powershell -Command "Start-Process powershell -ArgumentList 'Set-ExecutionPolicy RemoteSigned -Force; Write-Host \"Execution policy changed to RemoteSigned\"; Read-Host \"Press Enter to continue\"' -Verb RunAs"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to change execution policy. You may need to run as administrator.
    goto :manual_instructions
)
goto :policy_ok

:policy_ok
echo [INFO] Execution policy allows script execution.
goto :select_script

:select_script
echo.
echo =======================================================
echo   Select Migration Script
echo =======================================================
echo.
echo Available migration scripts:
echo   1. migrate_floor_to_froom.ps1 (Floor to Froom migration)
echo   2. migrate_froom_to_floor.ps1 (Reverse migration for testing)
echo   3. migrate.ps1 (Simple version update)
echo   4. Exit
echo.
set /p script_choice="Please select a script (1-4): "

if "%script_choice%"=="1" set script_name=migrate_floor_to_froom.ps1
if "%script_choice%"=="2" set script_name=migrate_froom_to_floor.ps1
if "%script_choice%"=="3" set script_name=migrate.ps1
if "%script_choice%"=="4" goto :exit
if "%script_name%"=="" (
    echo Invalid choice. Please try again.
    goto :select_script
)

:: Check if script exists
if not exist "%script_name%" (
    echo [ERROR] Script %script_name% not found in current directory.
    echo Please ensure the script file exists.
    pause
    exit /b 1
)

:: Get script arguments for floor_to_froom and froom_to_floor scripts
if "%script_choice%"=="1" goto :get_args
if "%script_choice%"=="2" goto :get_args
if "%script_choice%"=="3" goto :run_script

:get_args
echo.
echo =======================================================
echo   Script Options
echo =======================================================
echo.
echo Available options for %script_name%:
echo   -Backup    Create backup before migration
echo   -Yes       Skip confirmation prompts
echo   (Leave empty for interactive mode)
echo.
set /p script_args="Enter options (optional): "
goto :run_script

:run_script
echo.
echo [INFO] Running %script_name%...
echo =======================================================
echo.

:: Run the script based on policy situation
if /i "%current_policy%"=="Restricted" (
    powershell -ExecutionPolicy Bypass -File "%script_name%" %script_args%
) else if /i "%current_policy%"=="AllSigned" (
    powershell -ExecutionPolicy Bypass -File "%script_name%" %script_args%
) else (
    powershell -File "%script_name%" %script_args%
)

set script_exit_code=%errorlevel%
echo.
echo =======================================================
if %script_exit_code% equ 0 (
    echo [SUCCESS] Migration script completed successfully!
) else (
    echo [ERROR] Migration script failed with exit code %script_exit_code%
)
echo =======================================================
goto :end

:manual_instructions
echo.
echo =======================================================
echo   Manual Instructions
echo =======================================================
echo.
echo To run the PowerShell scripts manually, you can:
echo.
echo 1. Open PowerShell as Administrator
echo 2. Run: Set-ExecutionPolicy RemoteSigned
echo 3. Navigate to this directory: cd "%cd%"
echo 4. Run the desired script:
echo    .\migrate_floor_to_froom.ps1
echo    .\migrate_froom_to_floor.ps1
echo    .\migrate.ps1
echo.
echo Or run with bypass policy:
echo    powershell -ExecutionPolicy Bypass -File ".\migrate_floor_to_froom.ps1"
echo.
goto :end

:exit
echo Exiting...
goto :end

:end
echo.
pause