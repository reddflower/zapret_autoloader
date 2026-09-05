@echo off
set "LOCAL_VERSION=1.0"
set "GITHUB_VERSION_URL=https://reddflower.github.io/autoloader_version.html"
set "GITHUB_DOWNLOAD_URL=https://github.com/reddflower/zapret_autoloader/releases/latest"
chcp 437 > nul
setlocal enableDelayedExpansion

color 0F

if not exist "%~dp0service.bat" set "no-zapret=0"

if "%no-zapret%"=="0" (
    echo.
    call :PrintRed "Zapret not found"
    echo.
    call :PrintYellow "Push AUTOLOADER.bat in Zapret folder"
    echo.
    pause
    exit
)

echo Patch: replace general*.bat...
powershell -NoProfile -Command "$file='service.bat'; $old='Get-ChildItem -LiteralPath ''.'' -Filter ''*.bat'' | Where-Object { $_.Name -notlike ''service*'' } | Sort-Object { [Regex]::Replace($_.Name, ''(\d+)'', { $args[0].Value.PadLeft(8, ''0'') }) } | ForEach-Object { $_.Name }'; $new='Get-ChildItem -LiteralPath ''.'' -Filter ''general*.bat'' | Sort-Object { [Regex]::Replace($_.Name, ''(\d+)'', { $args[0].Value.PadLeft(8, ''0'') }) } | ForEach-Object { $_.Name }'; $content=Get-Content $file -Raw; $content=$content.Replace($old, $new); Set-Content $file -Value $content -Encoding OEM"

if errorlevel 1 (
    call :PrintRed "Unknown error"

) else (
    goto menu
)

:: MENU ===========================================================

:menu
cls
set "menu_choice=null"

:: Get the latest version from GitHub
for /f "delims=" %%A in ('powershell -NoProfile -Command "(Invoke-WebRequest -Uri \"%GITHUB_VERSION_URL%\" -Headers @{\"Cache-Control\"=\"no-cache\"} -UseBasicParsing -TimeoutSec 5).Content.Trim()" 2^>nul') do set "GITHUB_VERSION=%%A"

echo.
if "%LOCAL_VERSION%"=="%GITHUB_VERSION%" (
echo      ZAPRET AUTOLOADER v!LOCAL_VERSION!
) else ( 
set "new_version=avaible"
echo      ZAPRET AUTOLOADER v!LOCAL_VERSION!
call :PrintGreen "     NEW VERSION AVAIBLE: %GITHUB_VERSION% "
)
echo   ----------------------------------------
echo.
echo      1. Install AutoLoader
echo      2. Uninstall AutoLoader
echo      3. Check Status
echo.
echo      4. Open Zapret Service
echo.
echo      5. Minecraft fix (25565 port)
echo      0. Exit
if "%new_version%"=="avaible" call :PrintGreen "     upd. For update"
echo.
echo   ----------------------------------------
echo.

set /p menu_choice=   Select option (1-5): 

if "%menu_choice%"=="1" goto service_updater
if "%menu_choice%"=="2" goto service_uninstall
if "%menu_choice%"=="3" goto check_status
if "%menu_choice%"=="4" goto zapret_menu
if "%menu_choice%"=="5" goto minecraft_fix
if "%menu_choice%"=="0" exit /b
if "%menu_choice%"=="upd" start "" "%GITHUB_DOWNLOAD_URL%"
goto menu

:: Minecraft fix ========================================================

:minecraft_fix
cls

echo The following files will be updated (minecraft fix 25565):
echo.
set "count=0"

for /f "delims=" %%F in ('powershell -NoProfile -Command "Get-ChildItem -LiteralPath '.' -Filter 'general*.bat' | Where-Object { $_.Name -notlike 'service*' } | Where-Object { $_.Name -notlike 'hello_world*' } | Sort-Object { [Regex]::Replace($_.Name, '(\d+)', { $args[0].Value.PadLeft(8, '0') }) } | ForEach-Object { $_.Name }"') do (
    set /a count+=1
    echo !count!. %%F
)
echo.

if !count! equ 0 (
    echo.
    call :PrintRed "Generals not found"
    echo.
    pause
    goto menu
)

pause

echo Install 25565 port and script...
echo.

for %%i in (general*.bat) do (
    echo Processing: %%i
    powershell -Command "$file='%%i'; $content=Get-Content $file -Raw; $already=$content -match '--filter-tcp=25565'; if (-not $already) { $content=$content -replace '--wf-tcp=80,443,2053,2083,2087,2096,8443,%%GameFilterTCP%%', '--wf-tcp=80,443,2053,2083,2087,2096,8443,25565,%%GameFilterTCP%%'; $content=$content -replace '--dpi-desync-cutoff=n([2-4])\s*$', ('--dpi-desync-cutoff=n$1 --new ^' + [Environment]::NewLine + '--filter-tcp=25565 --ipset-exclude=\"' + [char]37 + 'LISTS' + [char]37 + 'ipset-exclude.txt\" --dpi-desync-any-protocol=1 --dpi-desync-cutoff=n5 --dpi-desync=multisplit --dpi-desync-split-seqovl=582 --dpi-desync-split-pos=1 --dpi-desync-split-seqovl-pattern=\"' + [char]37 + 'BIN' + [char]37 + 'tls_clienthello_4pda_to.bin\"'); Set-Content $file -Value $content -Encoding OEM; Write-Host 'Applied' -ForegroundColor Green } else { Write-Host 'Already patched, skipped' -ForegroundColor Red }"
)

pause
goto menu

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

if !all_count! equ 0 (
echo.
call :PrintRed "Generals not found"
echo.
pause
goto menu
)

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

if !count! equ 0 (
echo.
call :PrintRed "Generals not found"
echo.
pause
goto menu
)

if exist "generals_copy\" echo.
md generals_copy
copy "general*.bat" "./generals_copy" 
cls

pause

echo.
for %%i in (general*.bat) do (
    echo Processing: %%i
    powershell -Command "& { (Get-Content '%%i') | ForEach-Object { $_.Replace('--hostlist=\"%%LISTS%%list-general-user.txt\"', '--hostlist-auto=\"%%LISTS%%list-general-user.txt\"') } | Set-Content '%%i' }"
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

if !count! equ 0 (
echo.
call :PrintRed "Generals not found"
echo.
pause
goto menu
)

pause

echo.
for %%i in (general*.bat) do (
    echo Processing: %%i
    powershell -Command "& { (Get-Content '%%i') | ForEach-Object { $_.Replace('--hostlist-auto=\"%%LISTS%%list-general-user.txt\"', '--hostlist=\"%%LISTS%%list-general-user.txt\"') } | Set-Content '%%i' }"
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




:: "winws.exe" ^ DONT. INSTALL. AUTOLOADER. FROM. INSTALL SERVICE. FROM SERVICE.BAT. run autoloader.bat yourself, dolbaeb
