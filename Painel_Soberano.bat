@echo off
:: ==============================================================================
:: PROJETO SOBERANO - LAUNCHER AUTO-ELEVADO
:: Este arquivo abre o Painel Soberano como Administrador.
:: ==============================================================================

set SCRIPT_PATH=C:\Soberania\Painel_Soberano.ps1

:: 1. Verificação de privilégios de Administrador
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
:: 2. Verificação de existência do script
if not exist "%SCRIPT_PATH%" (
    echo.
    echo [ERRO FATAL] O arquivo Painel_Soberano.ps1 nao foi encontrado em C:\Soberania\
    echo Verifique se os arquivos foram extraidos corretamente.
    echo.
    pause
    exit /b
)

:: 3. Execução do PowerShell com a lógica solicitada
echo [OK] Iniciando Painel Soberano...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"

:: 4. Manter a janela aberta se houver erro no script
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [AVISO] O script encerrou com erro (Codigo: %ERRORLEVEL%)
    pause
)
