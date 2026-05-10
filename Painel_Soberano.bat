@echo off
:: ==============================================================================
:: PROJETO SOBERANO - LAUNCHER AUTO-ELEVADO
:: Este arquivo abre o Painel Soberano como Administrador.
:: ==============================================================================

:: Caminho dinamico - encontra o .ps1 na mesma pasta do .bat
set SCRIPT_PATH=%~dp0Painel_Soberano.ps1

:: 1. Verificacao de privilegios de Administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_script
) else (
    goto :elevate
)

:elevate
echo [INFO] Solicitando privilegios de Administrador...
powershell -Command "Start-Process '%~f0' -Verb RunAs"
exit /b

:run_script
:: 2. Verificacao de existencia do script
if not exist "%SCRIPT_PATH%" (
    echo.
    echo [ERRO FATAL] O arquivo Painel_Soberano.ps1 nao foi encontrado.
    echo Pasta verificada: %~dp0
    echo Verifique se os arquivos foram extraidos corretamente.
    echo.
    pause
    exit /b
)

:: 3. Execucao do PowerShell
echo [OK] Iniciando Painel Soberano...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

:: 4. Manter janela aberta se houver erro
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [AVISO] O script encerrou com erro (Codigo: %ERRORLEVEL%)
    pause
)
