@echo off
title ASA Connect - Executar Flutter no Celular
echo ====================================================
echo    INICIANDO FLUTTER RUN NO CELULAR (USB)
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
echo Compilando e iniciando com Hot-Reload no seu celular...
flutter run
pause
