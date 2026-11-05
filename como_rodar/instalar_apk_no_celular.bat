@echo off
title ASA Connect - Instalador do APK no Celular
echo ====================================================
echo    INSTALANDO ASA CONNECT NO SEU CELULAR
echo ====================================================
echo.

set "ADB=adb"
where adb >nul 2>nul
if %errorlevel% neq 0 (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    ) else (
        echo [ERRO] O comando adb nao foi encontrado.
        pause
        exit /b 1
    )
)

set "APK_FILE=%~dp0asa-connect.apk"
if not exist "%APK_FILE%" (
    echo [ERRO] O arquivo asa-connect.apk nao foi encontrado nesta pasta.
    pause
    exit /b 1
)

echo 1. Verificando conexao com o celular...
"%ADB%" devices
echo.

echo 2. Limpando instalacao antiga para remover qualquer cache antigo do celular...
"%ADB%" uninstall com.fecap.asaconnect >nul 2>nul
"%ADB%" uninstall com.example.asa_connect >nul 2>nul

echo 3. Enviando e instalando o aplicativo (%APK_FILE%)...
"%ADB%" install -r "%APK_FILE%"

if %errorlevel% equ 0 (
    echo.
    echo ====================================================
    echo    APLICATIVO INSTALADO COM SUCESSO!
    echo ====================================================
    echo Abrindo o app na tela do seu celular...
    "%ADB%" shell am start -S -n com.fecap.asaconnect/.MainActivity 2>nul
    "%ADB%" shell am start -S -n com.example.asa_connect/.MainActivity 2>nul
) else (
    echo.
    echo [ERRO] Falha ao instalar no celular. Verifique se a tela esta desbloqueada.
)

echo.
pause
