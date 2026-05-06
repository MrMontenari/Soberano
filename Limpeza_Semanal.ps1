# ==============================================================================
# LIMPEZA_SEMANAL.PS1
# Limpeza profunda de disco e serviÃ§os. Agendada semanalmente.
# SÃ³ age se o diretÃ³rio tiver tamanho relevante (evita custo desnecessÃ¡rio).
# ==============================================================================

#Requires -RunAsAdministrator
$ErrorActionPreference = "SilentlyContinue"

$logDir  = "C:\Soberania\Logs"
$logPath = "$logDir\limpeza_$(Get-Date -Format 'yyyy-MM-dd').log"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

# Limiar mÃ­nimo em MB para uma pasta ser considerada relevante para limpeza
$LIMIAR_MB = 1

$totalLiberado = 0.0

function Write-Log {
    param([string]$msg, [string]$nivel = "INFO")
    $linha = "$(Get-Date -Format 'HH:mm:ss') [$nivel] $msg"
    Add-Content -Path $logPath -Value $linha
}

function Get-TamanhoMB {
    param([string]$path)
    $bytes = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue |
              Measure-Object -Property Length -Sum).Sum
    return [math]::Round(($bytes) / 1MB, 2)
}

function Clear-Diretorio {
    param([string]$path, [string]$nome)

    if (!(Test-Path $path)) { return }

    $tamanho = Get-TamanhoMB $path

    if ($tamanho -lt $LIMIAR_MB) {
        Write-Log "Ignorado: $nome ($tamanho MB - abaixo do limiar de $LIMIAR_MB MB)" "INFO"
        return
    }

    Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    $script:totalLiberado += $tamanho
    Write-Log "Limpo: $nome - $tamanho MB liberados" "ACAO"
}

Write-Log "=== LIMPEZA SEMANAL INICIADA ==="

# ==============================================================================
# 1. NEUTRALIZAR SERVIÃ‡OS BANIDOS
# Reaplica apÃ³s possÃ­veis updates da semana.
# ==============================================================================
$servicosBanidos = @{
    "DiagTrack"          = "Telemetria principal"
    "dmwappushservice"   = "Push de dados WAP"
    "RetailDemo"         = "Modo loja"
    "XblAuthManager"     = "Xbox Live Auth"
    "XblGameSave"        = "Xbox Live Save"
    "XboxNetApiSvc"      = "Xbox Network"
    "WMPNetworkSvc"      = "Windows Media Player Network"
    "lfsvc"              = "Geolocalizacao"
    "MapsBroker"         = "Mapas offline"
    "wlidsvc"            = "Microsoft Account"
    "wisvc"              = "Windows Insider Service"
    "WerSvc"             = "Windows Error Reporting"
    "PcaSvc"             = "Program Compatibility Assistant"
    "DoSvc"              = "Delivery Optimization"
    "Fax"                = "Fax"
    "TabletInputService" = "Tablet Input"
    "WSearch"            = "Windows Search Indexer"
    "InventorySvc"       = "Inventario/compatibilidade"
    "UDCService"         = "Telemetria Lenovo"
    "SysMain"            = "Superfetch"
    "TrkWks"             = "Rastreamento de links"
    "ImControllerService" = "Lenovo Vantage"
    "PhoneSvc"           = "Telefonia"
    "TextInputManagementService" = "Painel de emojis"
    "WpnService"         = "Notificacoes Push"
}

$servicosNeutralizados = 0
foreach ($svc in $servicosBanidos.GetEnumerator()) {
    $s = Get-Service -Name $svc.Key -ErrorAction SilentlyContinue
    if (!$s) { continue }

    $changed = $false
    if ($s.Status -eq "Running") {
        Stop-Service -Name $svc.Key -Force
        $changed = $true
    }
    if ($s.StartType -ne "Disabled") {
        Set-Service -Name $svc.Key -StartupType Disabled
        $changed = $true
    }
    if ($changed) {
        Write-Log "Neutralizado: $($svc.Key) - $($svc.Value)" "ACAO"
        $servicosNeutralizados++
    }
}

# Neutralizar variantes por usuario (WpnUserService_*)
Get-Service "WpnUserService_*" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.Status -eq "Running") { Stop-Service $_.Name -Force }
    Set-Service $_.Name -StartupType Disabled
    Write-Log "Neutralizado variante: $($_.Name)" "ACAO"
}

Write-Log "Servicos neutralizados: $servicosNeutralizados" "OK"

# ==============================================================================
# 1.1 CONFIGURAR SERVIÃ‡OS PARA MANUAL (Demand)
# ==============================================================================
$servicosManual = @(
    "Spooler", "SSDPSRV", "RmSvc", "BITS", "UsoSvc", "InstallService",
    "AppXSvc", "TokenBroker", "CDPSvc", "DusmSvc", "LanmanServer",
    "LanmanWorkstation", "lmhosts", "RasMan", "SstpSvc", "PolicyAgent",
    "IKEEXT", "Themes", "ShellHWDetection", "BDESVC", "DPS",
    "webthreatdefsvc", "wscsvc"
)

foreach ($svcName in $servicosManual) {
    $s = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($s -and $s.StartType -ne "Manual") {
        Set-Service -Name $svcName -StartupType Manual
        Write-Log "Configurado para Manual: $svcName" "ACAO"
    }
}

# Variantes Manual (cbdhsvc_*, CDPUserSvc_*, webthreatdefusersvc_*)
Get-Service "cbdhsvc_*", "CDPUserSvc_*", "webthreatdefusersvc_*" -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.StartType -ne "Manual") {
        Set-Service $_.Name -StartupType Manual
        Write-Log "Configurado para Manual variante: $($_.Name)" "ACAO"
    }
}

# ==============================================================================
# 2. LIMPEZA DE DISCO (sÃ³ age se tiver tamanho relevante)
# ==============================================================================
$diretorios = @{
    "$env:SystemRoot\Prefetch"                                    = "Prefetch"
    "$env:SystemRoot\Temp"                                        = "Temp sistema"
    "$env:TEMP"                                                   = "Temp usuario"
    "$env:LOCALAPPDATA\Temp"                                      = "Temp local usuario"
    "$env:ProgramData\Microsoft\Diagnosis"                        = "Diagnosis telemetria"
    "$env:ProgramData\Microsoft\Windows\WER"                      = "WER ProgramData"
    "$env:LOCALAPPDATA\Microsoft\Windows\WER"                     = "WER Local"
    "$env:ProgramData\USOPrivate\UpdateStore"                     = "Update Store"
    "$env:SystemRoot\Logs"                                        = "Logs sistema"
    "$env:SystemRoot\System32\winevt\Logs"                        = "Logs de eventos"
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"               = "Cache Internet"
    "$env:LOCALAPPDATA\Microsoft\Windows\WebCache"                = "WebCache"
    "$env:APPDATA\Microsoft\Windows\Recent"                       = "Arquivos recentes"
    "$env:SystemRoot\SoftwareDistribution\DataStore\Logs"         = "Logs Windows Update"
    "$env:SystemRoot\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache" = "Delivery Optimization Cache"
}

foreach ($dir in $diretorios.GetEnumerator()) {
    Clear-Diretorio -path $dir.Key -nome $dir.Value
}

# Thumbcache (wildcard)
$thumbDir = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
if (Test-Path $thumbDir) {
    $thumbFiles = Get-Item "$thumbDir\thumbcache_*" -ErrorAction SilentlyContinue
    if ($thumbFiles) {
        $tamanho = ($thumbFiles | Measure-Object -Property Length -Sum).Sum
        $tamanhoMB = [math]::Round($tamanho / 1MB, 2)
        if ($tamanhoMB -ge $LIMIAR_MB) {
            $thumbFiles | Remove-Item -Force -ErrorAction SilentlyContinue
            $totalLiberado += $tamanhoMB
            Write-Log "Limpo: Thumbcache - $tamanhoMB MB liberados" "ACAO"
        }
    }
}

# Cache Windows Update (sÃ³ se serviÃ§o parado)
$wuSvc = Get-Service "wuauserv" -ErrorAction SilentlyContinue
if ($wuSvc -and $wuSvc.Status -ne "Running") {
    Clear-Diretorio -path "$env:SystemRoot\SoftwareDistribution\Download" -nome "Windows Update Download"       
}

# ==============================================================================
# 3. CLEANMGR SILENCIOSO
# ==============================================================================
$cleanKey   = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$cleanFlags = @(
    "Active Setup Temp Folders", "Downloaded Program Files", "Internet Cache Files",
    "Memory Dump Files", "Old ChkDsk Files", "Recycle Bin", "Setup Log Files",
    "System error memory dump files", "Temporary Files", "Temporary Setup Files",
    "Thumbnail Cache", "Update Cleanup",
    "Windows Error Reporting Archive Files",
    "Windows Error Reporting Queue Files",
    "Windows Error Reporting System Archive Files"
)

foreach ($flag in $cleanFlags) {
    $kp = "$cleanKey\$flag"
    if (Test-Path $kp) {
        Set-ItemProperty -Path $kp -Name "StateFlags0099" -Value 2 -Type DWord -ErrorAction SilentlyContinue    
    }
}

$cleanmgr = Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:99" -WindowStyle Hidden -PassThru
Write-Log "Cleanmgr disparado (PID $($cleanmgr.Id)) - aguardando conclusao..." "ACAO"
$cleanmgr.WaitForExit(120000)  # Aguarda atÃ© 2 minutos
Write-Log "Cleanmgr concluido." "OK"

# ==============================================================================
# SUMÃRIO
# ==============================================================================
$disco = Get-PSDrive C -ErrorAction SilentlyContinue
$livreGB = [math]::Round($disco.Free / 1GB, 1)

Write-Log "--- SUMARIO ---" "INFO"
Write-Log "Total liberado nesta limpeza: ~$([math]::Round($totalLiberado, 1)) MB" "OK"
Write-Log "Espaco livre em C: $livreGB GB" "OK"
Write-Log "Servicos neutralizados: $servicosNeutralizados" "OK"
Write-Log "=== LIMPEZA SEMANAL CONCLUIDA ===" "INFO"
Write-Log "" "INFO"
