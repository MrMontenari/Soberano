#Requires -RunAsAdministrator

# ==============================================================================
# GUARDIAO_PROCESSOS.PS1 v2
# Guardião de Processos - Projeto Soberano
# Mantém o Windows limpo de processos invasivos e garante o Simplewall ativo.
# ==============================================================================

# 1. ELEVAÇÃO DE PRIORIDADE
# Garante que o Guardião tenha preferência de CPU para agir rápido
try {
    $processoAtual = [System.Diagnostics.Process]::GetCurrentProcess()
    $processoAtual.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::High
} catch { }

# 2. CONFIGURAÇÕES DE DIRETÓRIO E LOG
$diretorioLogs = "C:\Soberania\Logs"
if (-not (Test-Path $diretorioLogs)) {
    New-Item -ItemType Directory -Path $diretorioLogs -Force | Out-Null
}

# Função auxiliar para registrar eventos no log (corpo principal)
function Escrever-Log {
    param(
        [string]$Mensagem,
        [string]$Nivel = "INFO"
    )
    $hoje = Get-Date -Format 'yyyy-MM-dd'
    $arquivoLog = Join-Path $diretorioLogs "guardiao_$($hoje).log"
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $linha = "$timestamp [$Nivel] $Mensagem"
    
    Add-Content -Path $arquivoLog -Value $linha -ErrorAction SilentlyContinue
}

# 3. LISTA DE PROCESSOS BANIDOS
# Processos que serão mortos assim que tentarem iniciar
$processosBanidos = @(
    "msedge", "MicrosoftEdge", "msedgewebview2",
    "OneDrive", "OneDriveSetup",
    "Cortana", "SearchApp",
    "WidgetService", "Widgets",
    "YourPhone", "YourPhoneAppProxy",
    "GameBarFTServer", "GameBar", "XboxGipcServer",
    "WinStore.App", "WinStoreUI",
    "SkypeApp", "MixedRealityPortal",
    "Clipchamp", "MicrosoftTeams", "Teams",
    "copilot", "AIHost",
    "wermgr", "WerFault",
    "MusNotification", "CompatTelRunner",
    "wsappx"
)

# 4. LIMPEZA DE ASSINATURAS ANTERIORES
# Evita múltiplas instâncias de eventos se o script for reiniciado
Get-EventSubscriber -ErrorAction SilentlyContinue | Unregister-Event -ErrorAction SilentlyContinue

# 5. MONITORAMENTO WMI (MORTE NO NASCIMENTO)
foreach ($nome in $processosBanidos) {
    $query = "SELECT * FROM Win32_ProcessStartTrace WHERE ProcessName = '$nome.exe'"
    
    try {
        Register-WmiEvent -Query $query -SourceIdentifier "Ban_$nome" -Action {
            $e = $Event.SourceEventArgs.NewEvent
            $nomeProc = $e.ProcessName
            $pidProc  = $e.ProcessID
            
            # Executa o extermínio
            Stop-Process -Id $pidProc -Force -ErrorAction SilentlyContinue
            Stop-Process -Name ($nomeProc -replace '\.exe$', '') -Force -ErrorAction SilentlyContinue
            
            # Registro de log (recalculado para suportar mudança de dia e escopo)
            $logPathEvento = "C:\Soberania\Logs\guardiao_$(Get-Date -Format 'yyyy-MM-dd').log"
            $msgEvento = "$(Get-Date -Format 'HH:mm:ss') [ELIMINADO] $nomeProc (PID $pidProc) - morto no nascimento"
            Add-Content -Path $logPathEvento -Value $msgEvento -ErrorAction SilentlyContinue
        } | Out-Null
    } catch {
        Escrever-Log "Falha ao registrar WMI para $nome" "ERRO"
    }
}

# 6. VARREDURA INICIAL
# Limpa processos que já estavam rodando antes do Guardião iniciar
foreach ($nome in $processosBanidos) {
    $vivos = Get-Process -Name $nome -ErrorAction SilentlyContinue
    if ($vivos) {
        $vivos | ForEach-Object {
            $pidVivo = $_.Id
            $_ | Stop-Process -Force -ErrorAction SilentlyContinue
            Escrever-Log "$nome.exe (PID $pidVivo) - morto na varredura inicial" "VARREDURA"
        }
    }
}

# 7. WATCHDOG DO SIMPLEWALL
# Verifica a cada 60 segundos se o firewall está rodando
$timerWatcher = New-Object System.Timers.Timer
$timerWatcher.Interval = 60000 # 1 minuto
$timerWatcher.AutoReset = $true

Register-ObjectEvent -InputObject $timerWatcher -EventName Elapsed -SourceIdentifier "SimplewallWatchdog" -Action {
    $processoSW = Get-Process "simplewall" -ErrorAction SilentlyContinue
    if (-not $processoSW) {
        # Caminhos conhecidos do Simplewall
        $caminhosSW = @(
            "$env:ProgramFiles\simplewall\simplewall.exe",
            "${env:ProgramFiles(x86)}\simplewall\simplewall.exe",
            "$env:LOCALAPPDATA\simplewall\simplewall.exe"
        )
        
        foreach ($caminho in $caminhosSW) {
            if (Test-Path $caminho) {
                Start-Process $caminho -ErrorAction SilentlyContinue
                
                $logPathSW = "C:\Soberania\Logs\guardiao_$(Get-Date -Format 'yyyy-MM-dd').log"
                $msgSW = "$(Get-Date -Format 'HH:mm:ss') [ALERTA] Simplewall RELANÇADO (estava morto)"
                Add-Content -Path $logPathSW -Value $msgSW -ErrorAction SilentlyContinue
                break
            }
        }
    }
} | Out-Null

$timerWatcher.Start()

# 8. FINALIZAÇÃO
Escrever-Log "Guardiao v2 ativo. $($processosBanidos.Count) processos monitorados. Simplewall monitorado." "INFO"

# Loop infinito de baixo consumo para manter as assinaturas de eventos vivas
while ($true) {
    Wait-Event
}
