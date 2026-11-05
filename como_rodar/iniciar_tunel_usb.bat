@echo off
title ASA Connect - Tunel Reverso USB (Porta 8000)
echo ====================================================
echo    INICIANDO TUNEL REVERSO USB (PORTA 8000)
echo ====================================================
echo.

set "ADB=adb"
where adb >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    ) else (
        echo [ERRO] O comando adb nao foi encontrado.
        echo Certifique-se de que o Android SDK esta instalado.
        pause
        exit /b 1
    )
)

echo Verificando dispositivos conectados via USB...
"%ADB%" devices
echo.
echo Ativando e mantendo o tunel reverso (tcp:8000 -> tcp:8000)...
echo [MANTENHA ESTA JANELA ABERTA ENQUANTO TESTA NO CELULAR]
echo.

:loop
"%ADB%" reverse tcp:8000 tcp:8000 >nul 2>nul
timeout /t 3 /nobreak >nul
goto loop
