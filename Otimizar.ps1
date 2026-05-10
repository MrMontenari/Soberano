#Requires -RunAsAdministrator
# Otimizar.ps1 - PROJETO SOBERANO
$ErrorActionPreference = "SilentlyContinue"

function Exibir-Cabecalho {
    Clear-Host
    Write-Host "   _____  ____  ____  _____ ____    _    _   _  ___  " -ForegroundColor Cyan
    Write-Host "  / ___|/ __ \|  _ \| ____|  _ \  / \  | \ | |/ _ \ " -ForegroundColor Cyan
    Write-Host "  \___ \| |  | | |_) |  _| | |_) |/ _ \ |  \| | | | |" -ForegroundColor Cyan
    Write-Host "   ___) | |__| |  _ <| |___|  _ < / ___ \| |\  | |_| |" -ForegroundColor Cyan
    Write-Host "  |____/ \____/|_| \_\_____|_| \_/_/   \_\_| \_|\___/ " -ForegroundColor Cyan
    Write-Host "  -------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "   PREPARANDO PC PARA VM | Projeto Soberano" -ForegroundColor Yellow
    Write-Host "  -------------------------------------------------------------" -ForegroundColor Gray
    Write-Host ""
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  [!] ERRO: Execute como Administrador." -ForegroundColor Red
    exit
}

Exibir-Cabecalho

# 1. CAPTURAR RAM INICIAL
$os = Get-CimInstance Win32_OperatingSystem
$ramInicial = $os.FreePhysicalMemory / 1KB

# 2. PLANO DE ENERGIA
$planoAltoDesempenho = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$planoEquilibrado = "381b4222-f694-41f0-9685-ff5bb260df2e"
powercfg /setactive $planoAltoDesempenho
Write-Host "  [+] Alto Desempenho Ativado." -ForegroundColor Green

# 3. MATAR PROCESSOS
$allowlist = @("Idle", "System", "Registry", "smss", "csrss", "wininit", "services", "lsass", "winlogon", "svchost", "fontdrvhost", "dwm", "RuntimeBroker", "ctfmon", "taskhostw", "conhost", "powershell", "pwsh", "VirtualBox", "VBoxSVC", "VBoxNetDHCP", "VBoxNetNAT", "ShellExperienceHost", "StartMenuExperienceHost", "sihost", "simplewall")
$mortos = @()
$todos = Get-Process
foreach ($p in $todos) {
    try {
        if ($p.Id -eq $PID -or $p.SessionId -eq 0 -or $allowlist -contains $p.ProcessName) { continue }
        $nome = $p.ProcessName
        $id = $p.Id
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
        $mortos += [PSCustomObject]@{ PID = $id; Nome = $nome }
    } catch { }
}

# 4. SERVICOS E WORKING SET
$servicos = @("SysMain", "WpnService", "Spooler", "TextInputManagementService", "ImControllerService", "WSearch", "DiagTrack")
foreach ($s in $servicos) { Stop-Service $s -Force -ErrorAction SilentlyContinue }
Get-Process | ForEach-Object { try { $_.EmptyWorkingSet() } catch { } }

# 5. CAPTURAR RAM FINAL
$os = Get-CimInstance Win32_OperatingSystem
$ramFinal = $os.FreePhysicalMemory / 1KB
$ganho = [math]::Round($ramFinal - $ramInicial, 1)

# 6. RELATORIO
Write-Host "  -------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  [V] OTIMIZACAO CONCLUIDA" -ForegroundColor Green
Write-Host ""
Write-Host "  GANHO DE RAM: " -NoNewline -ForegroundColor Magenta
Write-Host "$ganho MB" -ForegroundColor Green
Write-Host ""
Write-Host "  PROCESSOS ENCERRADOS:" -ForegroundColor Magenta

# Tabela em colunas
$colCount = 0
foreach ($m in $mortos) {
    $item = "[$($m.PID)] $($m.Nome)"
    $espLen = [math]::Max(1, 20 - $item.Length)
    $espacos = " " * $espLen
    Write-Host ("$item" + "$espacos") -NoNewline -ForegroundColor Gray
    $colCount++
    if ($colCount % 3 -eq 0) { Write-Host "" }
}
Write-Host "`n"

# Semaforo
if ($ganho -gt 500) { Write-Host "  STATUS: [*] OTIMO  " -ForegroundColor Green }
elseif ($ganho -gt 100) { Write-Host "  STATUS: [*] BOM    " -ForegroundColor Yellow }
else { Write-Host "  STATUS: [*] MINIMO " -ForegroundColor Red }

Write-Host ""
Write-Host "  [!] Mantenha esta janela aberta para manter o plano de energia." -ForegroundColor Yellow
Write-Host "  -------------------------------------------------------------" -ForegroundColor DarkGray

try {
    while ($true) { Start-Sleep -Seconds 10 }
} finally {
    powercfg /setactive $planoEquilibrado
}
