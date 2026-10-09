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
dart run inno_bundle:build --release
if errorlevel 1 goto :error

echo.
echo Kesz. Az installer .exe eleresi utjat a fenti inno_bundle kimenet also sora mutatja
echo (jellemzoen a build\windows\x64\installer mappaban van).
goto :eof

:error
echo Hiba tortent, nezd meg a fenti uzenetet.
exit /b 1