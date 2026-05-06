#Requires -RunAsAdministrator
# Otimizar.ps1 - O Otimizador do Projeto Soberano
$ErrorActionPreference = "SilentlyContinue"

function Exibir-Cabecalho {
    Clear-Host
    Write-Host "   _____  ____  ____  _____ ____    _    _   _  ___  " -ForegroundColor Cyan
    Write-Host "  / ___|/ __ \|  _ \| ____|  _ \  / \  | \ | |/ _ \ " -ForegroundColor Cyan
    Write-Host "  \___ \| |  | | |_) |  _| | |_) |/ _ \ |  \| | | | |" -ForegroundColor Cyan
    Write-Host "   ___) | |__| |  _ <| |___|  _ < / ___ \| |\  | |_| |" -ForegroundColor Cyan
    Write-Host "  |____/ \____/|_| \_\_____|_| \_/_/   \_\_| \_|\___/ " -ForegroundColor Cyan
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "   MODO DE ALTA PERFORMANCE ATIVO | Projeto Soberano" -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
}

# 1. VERIFICAR ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRO: Este script precisa ser executado como Administrador." -ForegroundColor Red
    exit
}

Exibir-Cabecalho

# 2. PLANO DE ENERGIA
$planoAltoDesempenho = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$planoEquilibrado = "381b4222-f694-41f0-9685-ff5bb260df2e"

Write-Host "  [i] Ativando Plano de Alto Desempenho..." -ForegroundColor Cyan
powercfg /setactive $planoAltoDesempenho

function RestaurarPlano {
    Write-Host "`n  [!] Restaurando Plano Equilibrado..." -ForegroundColor Yellow
    powercfg /setactive $planoEquilibrado
    Start-Sleep -Seconds 2
}

try {
    # 3. MATAR PROCESSOS (Logica de Allowlist)
    $allowlist = @(
        "Idle", "System", "Registry", "smss", "csrss", "wininit", "services", "lsass",
        "winlogon", "svchost", "fontdrvhost", "dwm", "RuntimeBroker",
        "ctfmon", "taskhostw", "conhost", "powershell", "pwsh",
        "VirtualBox", "VBoxSVC", "VBoxNetDHCP", "VBoxNetNAT", "ShellExperienceHost", "StartMenuExperienceHost",       
        "sihost", "simplewall"
    )

    $mortos = @()
    $processoAtual = $PID
    $filhos = Get-CimInstance Win32_Process -Filter "ParentProcessId = $PID" | Select-Object -ExpandProperty ProcessId

    Write-Host "  [i] Analisando processos para otimização..." -ForegroundColor Cyan

    $todosProcessos = Get-Process
    foreach ($p in $todosProcessos) {
        try {
            if ($p.Id -eq $processoAtual) { continue }   
            if ($p.SessionId -eq 0) { continue }
            if ($allowlist -contains $p.ProcessName) { continue }
            if ($filhos -contains $p.Id) { continue }    

            $nome = $p.ProcessName
            $id = $p.Id
            Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
            $mortos += "$nome"
        } catch { }
    }

    # 4. PARAR SERVICOS
    $servicos = @("SysMain", "WpnService", "Spooler", "TextInputManagementService", "ImControllerService", "WSearch", "DiagTrack")
    foreach ($s in $servicos) {
        if ((Get-Service $s -ErrorAction SilentlyContinue).Status -eq 'Running') {
            Stop-Service $s -Force -ErrorAction SilentlyContinue
        }
    }

    # 5. LIBERAR RAM
    Get-Process | ForEach-Object { try { $_.EmptyWorkingSet() } catch { } }

    # 6. RELATORIO
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  [✔] Otimização Concluída!" -ForegroundColor Green
    Write-Host "  [✔] $($mortos.Count) processos desnecessários encerrados." -ForegroundColor Gray
    Write-Host "  [!] Mantenha esta janela aberta para manter o plano de energia." -ForegroundColor Yellow
    Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor DarkGray

    while ($true) { Start-Sleep -Seconds 10 }

} finally {
    RestaurarPlano
}
