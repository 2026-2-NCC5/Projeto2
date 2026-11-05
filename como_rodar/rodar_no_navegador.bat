@echo off
title ASA Connect - Executar no Navegador (Web)
echo ====================================================
echo    INICIANDO ASA CONNECT NO NAVEGADOR (CHROME)
echo ====================================================
echo.

set "APP_DIR=%~dp0..\app"
if not exist "%APP_DIR%\pubspec.yaml" (
    set "APP_DIR=%~dp0..\src\mobile"
)

if not exist "%APP_DIR%\pubspec.yaml" (
    echo [ERRO] Pasta do app Flutter nao encontrada.
    pause
    exit /b 1
)

cd /d "%APP_DIR%"
echo Pasta do app: %CD%
echo.
echo Baixando dependencias...
flutter pub get
echo.
echo Iniciando no Google Chrome...
flutter run -d chrome
pause
