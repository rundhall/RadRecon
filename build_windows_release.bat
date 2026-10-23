@echo off
setlocal

if "%1"=="--clean" (
  echo 0^) Flutter clean...
  call flutter clean
  if errorlevel 1 goto :error
)

echo 1) Flutter pub get...
call flutter pub get
if errorlevel 1 goto :error

echo 2) Flutter build windows...
call flutter build windows --release
if errorlevel 1 goto :error

echo 3) Inno Setup installer keszitese...
rem Remove old installers so only the fresh one is picked up below.
for /r "build\windows" %%f in (RadRecon-x86_64-*-Installer.exe) do del /q "%%f"
call dart run inno_bundle --release
if errorlevel 1 goto :error

echo 4) Installer atnevezese verzio nelkul...
set "FOUND="
for /r "build\windows" %%f in (RadRecon-x86_64-*-Installer.exe) do set "FOUND=%%f"
if not defined FOUND (
  echo Nem talalhato installer a build\windows mappaban.
  goto :error
)
for %%F in ("%FOUND%") do set "OUTDIR=%%~dpF"
move /y "%FOUND%" "%OUTDIR%RadRecon-x86_64-Installer.exe"
if errorlevel 1 goto :error
copy /y "%OUTDIR%RadRecon-x86_64-Installer.exe" "%~dp0landingpage\downloads\RadRecon-x86_64-Installer.exe"
if errorlevel 1 goto :error

echo.
echo Kesz. Az installer: %OUTDIR%RadRecon-x86_64-Installer.exe
echo Masolat: landingpage\downloads\RadRecon-x86_64-Installer.exe
goto :eof

:error
echo Hiba tortent, nezd meg a fenti uzenetet.
exit /b 1
