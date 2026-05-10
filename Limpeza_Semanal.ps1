#Requires -RunAsAdministrator
# LIMPEZA_SEMANAL.PS1 - PROJETO SOBERANO
$ErrorActionPreference = "SilentlyContinue"

# 1. VERIFICAR ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "  [!] ERRO: Execute como Administrador." -ForegroundColor Red
    exit
}

$logDir  = "C:\Soberania\Logs"
$logPath = "$logDir\limpeza_$(Get-Date -Format 'yyyy-MM-dd').log"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$LIMIAR_MB = 0.1
$totalLiberado = 0.0
$pastasLimpas = @()
$servicosStatus = @()

function Get-TamanhoMB {
    param([string]$path)
    if (!(Test-Path $path)) { return 0 }
    $bytes = (Get-ChildItem $path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if (!$bytes) { return 0 }
    return [math]::Round(($bytes) / 1MB, 2)
}

function Clear-Diretorio {
    param([string]$path, [string]$nome)
    if (!(Test-Path $path)) { return }
    
    $tamanho = Get-TamanhoMB $path
    if ($tamanho -lt $LIMIAR_MB) { return }

    Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    $script:totalLiberado += $tamanho
    $script:pastasLimpas += [PSCustomObject]@{ Pasta = $nome; MB = $tamanho }
}

Write-Host "`n  [*] Iniciando Limpeza Soberana..." -ForegroundColor Cyan

# 2. NEUTRALIZAR SERVICOS
$servicosBanidos = @{
    "DiagTrack"          = "Telemetria principal"
    "dmwappushservice"   = "Push de dados WAP"
    "XblAuthManager"     = "Xbox Live Auth"
    "XblGameSave"        = "Xbox Live Save"
    "XboxNetApiSvc"      = "Xbox Network"
    "WSearch"            = "Windows Search Indexer"
    "SysMain"            = "Superfetch"
    "WpnService"         = "Notificacoes Push"
}

foreach ($svc in $servicosBanidos.GetEnumerator()) {
    $s = Get-Service -Name $svc.Key -ErrorAction SilentlyContinue
    if (!$s) { continue }
    
    if ($s.Status -eq "Running") { Stop-Service -Name $svc.Key -Force }
    if ($s.StartType -ne "Disabled") { Set-Service -Name $svc.Key -StartupType Disabled }
    $servicosStatus += $svc.Key
}

# 3. LIMPEZA DE DISCO
$diretorios = @{
    "$env:SystemRoot\Prefetch"            = "Prefetch"
    "$env:SystemRoot\Temp"                = "Temp Sistema"
    "$env:TEMP"                           = "Temp Usuario"
    "$env:LOCALAPPDATA\Temp"              = "Temp Local"
    "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" = "Cache Internet"
    "$env:APPDATA\Microsoft\Windows\Recent" = "Arquivos Recentes"
}

foreach ($dir in $diretorios.GetEnumerator()) {
    Clear-Diretorio -path $dir.Key -nome $dir.Value
}

# 4. CLEANMGR
$cleanmgr = Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:99" -WindowStyle Hidden -PassThru
$cleanmgr.WaitForExit(60000)

# 5. RELATORIO FINAL
Write-Host "  -------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  [V] LIMPEZA CONCLUIDA" -ForegroundColor Green
Write-Host ""
Write-Host "  PASTAS LIMPAS:" -ForegroundColor Magenta
if ($pastasLimpas.Count -gt 0) {
    foreach ($p in $pastasLimpas) {
        $espLen = [math]::Max(1, 25 - $p.Pasta.Length)
        $espacos = " " * $espLen
        $linha = "  |  " + $p.Pasta + $espacos + [math]::Round($p.MB, 2) + " MB"
        Write-Host $linha -ForegroundColor Gray
    }
} else {
    Write-Host "  |  Nenhuma pasta relevante limpa." -ForegroundColor Gray
}

Write-Host ""
Write-Host "  SERVICOS RECONFIRMADOS (DESATIVADOS):" -ForegroundColor Magenta
$count = 0
Write-Host "  |  " -NoNewline
foreach ($s in $servicosStatus) {
    Write-Host ("$s  ") -NoNewline -ForegroundColor Gray
    $count++
    if ($count % 3 -eq 0) { Write-Host "`n  |  " -NoNewline }
}
Write-Host ""

Write-Host ""
$totalStr = "  [ TOTAL LIBERADO: " + [math]::Round($totalLiberado, 1) + " MB ]"
Write-Host $totalStr -ForegroundColor Green
Write-Host "  -------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Pressione qualquer tecla para voltar..." -ForegroundColor DarkGray
$null = [Console]::ReadKey($true)
