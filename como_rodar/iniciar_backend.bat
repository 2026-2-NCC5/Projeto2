@echo off
title ASA Connect - Backend FastAPI (Porta 8000)
echo ====================================================
echo    INICIANDO BACKEND FASTAPI - ASA CONNECT
echo ====================================================
echo.

set "BACKEND_DIR=%~dp0..\api"
if not exist "%BACKEND_DIR%\app\main.py" (
    set "BACKEND_DIR=%~dp0..\src\backend"
)

if not exist "%BACKEND_DIR%\app\main.py" (
    echo [ERRO] Pasta do backend nao encontrada.
    pause
    exit /b 1
)

cd /d "%BACKEND_DIR%"
echo Pasta do backend: %CD%

if exist ".venv\Scripts\activate.bat" (
    echo Ativando ambiente virtual .venv...
    call .venv\Scripts\activate.bat
)

echo.
echo Iniciando servidor Uvicorn em http://localhost:8000 ...
echo Documentacao Swagger disponivel em: http://localhost:8000/docs
echo.
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
if %errorlevel% neq 0 (
    echo.
    echo [AVISO] Tentando executar com uvicorn direto...
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
)

pause
