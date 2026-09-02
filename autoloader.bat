@echo off
chcp 437 > nul
setlocal enableDelayedExpansion

color 0F

:: COPY =========================================================

if exist "generals_copy\" echo.
md generals_copy
copy "general*.bat" "./generals_copy" 
cls

:: MENU ===========================================================

:menu
cls
set "menu_choice=null"

echo.
echo   ZAPRET AUTOLOADER
echo   ----------------------------------------
echo.
echo      1. Install AutoLoader
echo      2. Uninstall AutoLoader
echo      3. Check Status
echo.
echo      4. Open Zapret Service
echo      5. Exit
echo.
echo   ----------------------------------------
echo.

set /p menu_choice=   Select option (1-5): 

if "%menu_choice%"=="1" goto service_updater
if "%menu_choice%"=="2" goto service_uninstall
if "%menu_choice%"=="3" goto check_status
if "%menu_choice%"=="4" goto zapret_menu
if "%menu_choice%"=="5" exit /b

:: ZAPRET MENU ========================================================

:zapret_menu
cls

echo.
echo Starting Zapret...:
start service.bat

goto menu

:: CHECK STATUS ========================================================

:check_status
cls

set "status_count=0"
set "all_count=0"

for %%f in (general*.bat) do (
    set /a all_count+=1
    findstr /c:"--hostlist-auto=" "%%f" >nul 2>&1
    if !errorlevel! equ 0 (
        findstr /c:"%%LISTS%%" "%%f" >nul 2>&1
        if !errorlevel! equ 0 (
            set /a status_count+=1
            echo ^"Auto^" detected: %%f
        )
    )
)
echo.

if !status_count! equ 0 (
call :PrintRed "Total ^"Auto^": !status_count! / !all_count!"
) else (

if !all_count! equ !status_count! (
call :PrintGreen "Total ^"Auto^": !status_count! / !all_count!"

) else (
call :PrintYellow "Total ^"Auto^": !status_count! / !all_count!"
	)
)

pause
goto menu

:: UPDATE ========================================================

:service_updater
cls



echo.
echo The following files will be updated and sent to backups (generals_copy):
set "count=0"

for /f "delims=" %%F in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '.' -Filter 'general*.bat' | Where-Object { $_.Name -notlike 'service*' } | Where-Object { $_.Name -notlike 'hello_world*' } | Sort-Object { [Regex]::Replace($_.Name, '(\d+)', { $args[0].Value.PadLeft(8, '0') }) } | ForEach-Object { $_.Name }"') do (
    set /a count+=1
    echo !count!. %%F
)

pause

echo.
for %%i in (general*.bat) do (
    echo Processing: %%i
    powershell -Command "& { (Get-Content '%%i') | ForEach-Object { $_.Replace('--hostlist=\"%%LISTS%%list-general.txt\"', '--hostlist-auto=\"%%LISTS%%list-general.txt\"') } | Set-Content '%%i' }"
)

pause

goto menu


:: UNINSTALL ========================================================

:service_uninstall
cls



echo.
echo The update will be deleted from the following files:
set "count=0"

for /f "delims=" %%F in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '.' -Filter 'general*.bat' | Where-Object { $_.Name -notlike 'service*' } | Where-Object { $_.Name -notlike 'hello_world*' } | Sort-Object { [Regex]::Replace($_.Name, '(\d+)', { $args[0].Value.PadLeft(8, '0') }) } | ForEach-Object { $_.Name }"') do (
    set /a count+=1
    echo !count!. %%F
)

pause

echo.
for %%i in (general*.bat) do (
    echo Processing: %%i
    powershell -Command "& { (Get-Content '%%i') | ForEach-Object { $_.Replace('--hostlist-auto=\"%%LISTS%%list-general.txt\"', '--hostlist=\"%%LISTS%%list-general.txt\"') } | Set-Content '%%i' }"
)

pause

goto menu

:: COLORA ============================================

:PrintGreen
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Green"
exit /b

:PrintRed
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Red"
exit /b

:PrintYellow
powershell -NoProfile -Command "Write-Host \"%~1\" -ForegroundColor Yellow"
exit /b
