#Requires -RunAsAdministrator
$ErrorActionPreference = "SilentlyContinue"

# ==============================================================================
# VERIFICACAO_SOBERANA.PS1 v5.1
# Script de Diagnóstico do Projeto Soberano
# ==============================================================================

function Exibir-Titulo {
    param([string]$txt)
    Write-Host "`n─── $txt ──────────────────────────────────" -ForegroundColor Cyan
}

function Exibir-Status {
    param([string]$label, [string]$status, [string]$cor)
    Write-Host "  │ " -NoNewline -ForegroundColor DarkGray
    Write-Host "$($label.PadRight(40))" -NoNewline -ForegroundColor Gray
    Write-Host " [$status]" -ForegroundColor $cor
}

Clear-Host
Write-Host "  SOBERANIA CHECK v5.1" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────────────────────────────────────" -ForegroundColor Gray

# FASE 1: Estrutura
Exibir-Titulo "FASE 1: ESTRUTURA E ARQUIVOS"
$scripts = "Guardiao_Processos.ps1", "Limpeza_Semanal.ps1", "Otimizar.ps1", "Instalar_Soberania.ps1", "Painel_Soberano.ps1"
foreach ($s in $scripts) {
    $path = "C:\Soberania\$s"
    if (Test-Path $path) {
        Exibir-Status $s "PRESENTE" "Green"
    } else {
        Exibir-Status $s "AUSENTE" "Red"
    }
}

$logs = Get-ChildItem "C:\Soberania\Logs" | Sort-Object LastWriteTime -Descending
Exibir-Status "Total de Logs encontrados" "$($logs.Count)" "Cyan"

# FASE 2: Tarefas Agendadas
Exibir-Titulo "FASE 2: TAREFAS AGENDADAS"
$tarefas = "Soberania_Guardiao", "Soberania_Limpeza_Semanal"
foreach ($t in $tarefas) {
    $task = Get-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue
    if ($task) {
        $info = Get-ScheduledTaskInfo -TaskName $t
        $cor = if ($task.State -eq "Ready") { "Green" } else { "Yellow" }
        Exibir-Status $t "$($task.State)" $cor
    } else {
        Exibir-Status $t "NÃO INSTALADA" "Red"
    }
}

# FASE 3: Processos e Guardião
Exibir-Titulo "FASE 3: MONITORAMENTO ATIVO"
$guardiaoProc = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like "*Guardiao_Processos*" }
if ($guardiaoProc) {
    Exibir-Status "Guardião de Processos" "ATIVO (PID $($guardiaoProc.ProcessId))" "Green"
} else {
    Exibir-Status "Guardião de Processos" "INATIVO" "Red"
}

# FASE 10: Recursos do Sistema
Exibir-Titulo "RECURSOS DO SISTEMA"
$os = Get-CimInstance Win32_OperatingSystem
$mem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$cpu = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average, 1)

Exibir-Status "RAM Livre" "$mem GB" (if ($mem -gt 2) { "Green" } else { "Yellow" })
Exibir-Status "Uso de CPU" "$cpu %" (if ($cpu -lt 50) { "Green" } else { "Red" })

Write-Host "`n  ─────────────────────────────────────────────────────────────" -ForegroundColor Gray
Write-Host "  Verificação Concluída." -ForegroundColor Cyan
Write-Host ""
