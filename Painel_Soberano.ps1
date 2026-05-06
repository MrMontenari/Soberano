#Requires -RunAsAdministrator
$ErrorActionPreference = "SilentlyContinue"

# ==============================================================================
# PAINEL_SOBERANO.PS1 v1.0.3
# REDESIGN TUI - PROJETO SOBERANO
# ==============================================================================

# 1. VARIAVEIS GLOBAIS
$versaoAtual  = "1.0.3"
$githubUser   = "MrMontenari"
$githubRepo   = "Soberano"
$githubBranch = "main"
$urlBase      = "https://raw.githubusercontent.com/$githubUser/$githubRepo/refs/heads/$githubBranch"
$urlVersion   = "$urlBase/version.txt"

if ($PSScriptRoot) { $scriptDir = $PSScriptRoot } else { $scriptDir = Split-Path $MyInvocation.MyCommand.Path }

# 2. FUNCOES DE INTERFACE (TUI REDESIGN)

function Mostrar-Progresso {
    param([int]$atual, [int]$total, [string]$msg)
    $largura = 20
    $percent = [int](($atual / $total) * 100)
    $preenchido = [int](($atual / $total) * $largura)
    $vazio = $largura - $preenchido
    $barra = ("█" * $preenchido) + ("░" * $vazio)
    Write-Host "`r  $msg [$barra] $percent% " -NoNewline -ForegroundColor Gray
}

function Exibir-Cabecalho {
    Clear-Host
    $os = Get-CimInstance Win32_OperatingSystem
    $user = $env:USERNAME
    $hostn = $env:COMPUTERNAME
    $hora = Get-Date -Format "HH:mm:ss"
    $boot = $os.LastBootUpTime
    $uptimeTs = (Get-Date) - $boot
    $uptime = "$([int]$uptimeTs.TotalHours)h $([int]$uptimeTs.Minutes)m"
    
    $cpu = [math]::Round((Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average, 1)
    $totalRam = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $usedRam = [math]::Round($totalRam - $freeRam, 1)

    $linhas = @(
        "  ╔═════════════════════════════════════════════════════════════╗",
        "  ║  ____  ___  ____  ____ ____   _   _  ___    U: $($user.PadRight(10)) ║",
        "  ║ / ___|/ _ \| __ )| ___|  _ \ / \ | \| | | |   H: $($hostn.PadRight(10)) ║",
        "  ║ \___ \ | | |  _ \|  _| | _/ / _ \|  | | | |   T: $($hora.PadRight(10)) ║",
        "  ║  ___) | |_| | |_) | |__|  \ / ___ \ |\  |_| |  U: $($uptime.PadRight(10)) ║",
        "  ║ |____/ \___/|____/|____|_|_\_/   \_\_| \___/  V: $($versaoAtual.PadRight(10)) ║",
        "  ╚═════════════════════════════════════════════════════════════╝"
    )

    foreach ($l in $linhas) {
        if ($l -match "║") {
            $partes = $l.Split("║")
            Write-Host "  ║" -NoNewline -ForegroundColor DarkGray
            Write-Host $partes[1].Substring(0, 46) -NoNewline -ForegroundColor Cyan
            Write-Host $partes[1].Substring(46) -NoNewline -ForegroundColor Magenta
            Write-Host "║" -ForegroundColor DarkGray
        } else {
            Write-Host $l -ForegroundColor DarkGray
        }
        Start-Sleep -Milliseconds 30
    }

    Write-Host "    CPU: $cpu%  │  RAM: $usedRam GB / $totalRam GB" -ForegroundColor DarkGray
    Write-Host "  " + ("─" * 61) -ForegroundColor DarkGray
    Write-Host ""
}

function Pausa {
    Write-Host ""
    Write-Host "  ╚══ [0] Voltar  [CTRL+C] Sair ══╝" -ForegroundColor DarkGray
    $null = [Console]::ReadKey($true)
}

function Exibir-Mensagem {
    param([string]$msg, [string]$tipo = "INFO")
    Write-Host "  " -NoNewline
    switch ($tipo) {
        "OK"    { Write-Host "✔ " -NoNewline -ForegroundColor Green;   Write-Host $msg -ForegroundColor Gray }
        "ERRO"  { Write-Host "✖ " -NoNewline -ForegroundColor Red;     Write-Host $msg -ForegroundColor White }
        "AVISO" { Write-Host "⚠ " -NoNewline -ForegroundColor Yellow;  Write-Host $msg -ForegroundColor Gray }
        default { Write-Host "· " -NoNewline -ForegroundColor Cyan;    Write-Host $msg -ForegroundColor Gray }
    }
}

# --- [1] INSTALAR ---
function Menu-Instalar {
    Exibir-Cabecalho
    Write-Host "  ╔══ INSTALAÇÃO DE COMPONENTES ════════════════════════════════╗" -ForegroundColor Cyan
    $opcoes = @(
        "[1] Guardião de Processos   sistema de monitoramento",
        "[2] Limpeza Semanal         agendamento automático  ",
        "[3] Atalho Otimizar         acesso rápido desktop   ",
        "[4] Atalho Painel           acesso rápido desktop   "
    )
    foreach ($o in $opcoes) {
        Write-Host "  ║  " -NoNewline -ForegroundColor DarkGray
        Write-Host $o.Substring(0,3) -NoNewline -ForegroundColor Cyan
        Write-Host $o.Substring(3,24) -NoNewline -ForegroundColor White
        Write-Host $o.Substring(27).PadRight(28) -NoNewline -ForegroundColor DarkGray
        Write-Host " ║" -ForegroundColor DarkGray
    }
    Write-Host "  ╚═════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    $resp = Read-Host "  > Escolha os itens (ex: 1,2)"
    $itens = $resp.Split(",")

    foreach ($i in $itens) {
        $val = $i.Trim()
        if ($val -eq "1") {
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File `"$scriptDir\Guardiao_Processos.ps1`""
            $trigger = New-ScheduledTaskTrigger -AtStartup
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 0) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            Unregister-ScheduledTask -TaskName "Soberania_Guardiao" -Confirm:$false 2>$null
            Register-ScheduledTask -TaskName "Soberania_Guardiao" -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
            Start-ScheduledTask -TaskName "Soberania_Guardiao" 2>$null    
            Exibir-Mensagem "Guardião registrado." "OK"
        }
        if ($val -eq "2") {
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -NonInteractive -File `"$scriptDir\Limpeza_Semanal.ps1`""
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3am
            $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 15)
            $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
            Unregister-ScheduledTask -TaskName "Soberania_Limpeza_Semanal" -Confirm:$false 2>$null
            Register-ScheduledTask -TaskName "Soberania_Limpeza_Semanal" -Action $action -Trigger $trigger -Settings $settings -Principal $principal | Out-Null
            Exibir-Mensagem "Limpeza agendada." "OK"
        }
        if ($val -eq "3") {
            try {
                $shell = New-Object -ComObject WScript.Shell
                $lnk = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Otimizar.lnk")
                $lnk.TargetPath = "powershell.exe"
                $lnk.Arguments = "-ExecutionPolicy Bypass -File `"$scriptDir\Otimizar.ps1`""
                $lnk.IconLocation = "imageres.dll,109"
                $lnk.Save()
                Exibir-Mensagem "Atalho Otimizar criado." "OK"
            } catch { Exibir-Mensagem "Erro no atalho Otimizar." "ERRO" } 
        }
        if ($val -eq "4") {
            try {
                $shell = New-Object -ComObject WScript.Shell
                $lnk = $shell.CreateShortcut("$env:USERPROFILE\Desktop\Painel Soberano.lnk")
                $lnk.TargetPath = "$scriptDir\Painel_Soberano.bat"        
                $lnk.IconLocation = "imageres.dll,114"
                $lnk.Save()
                Exibir-Mensagem "Atalho Painel criado." "OK"
            } catch { Exibir-Mensagem "Erro no atalho Painel." "ERRO" }   
        }
    }
    Pausa
}

# --- [2] VERIFICAR ---
function Menu-Verificar {
    Exibir-Cabecalho
    Write-Host "  ┌── STATUS DOS ARQUIVOS ──────────────────────────────────────┐" -ForegroundColor Cyan
    $scriptsVer = @("Guardiao_Processos.ps1", "Limpeza_Semanal.ps1", "Otimizar.ps1", "Painel_Soberano.ps1")
    foreach ($s in $scriptsVer) {
        $status = "◎ AUSENTE "
        $cor = "Red"
        if (Test-Path "$scriptDir\$s") { $status = "◉ PRESENTE"; $cor = "Green" }
        Write-Host "  │  $($s.PadRight(35)) " -NoNewline -ForegroundColor Gray
        Write-Host $status -ForegroundColor $cor
    }
    Write-Host "  ├── TAREFAS AGENDADAS ────────────────────────────────────────┤" -ForegroundColor Cyan
    $tasks = @("Soberania_Guardiao", "Soberania_Limpeza_Semanal")
    foreach ($t in $tasks) {
        $task = Get-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue
        if ($task) {
            $badge = "▶ ATIVO  "; $cor = "Green"
            if ($task.State -ne "Ready" -and $task.State -ne "Running") { $badge = "■ INATIVO"; $cor = "Yellow" }
            Write-Host "  │  $($t.PadRight(35)) " -NoNewline -ForegroundColor Gray
            Write-Host $badge -ForegroundColor $cor
        } else {
            Write-Host "  │  $($t.PadRight(35)) " -NoNewline -ForegroundColor Gray
            Write-Host "✕ N/A    " -ForegroundColor Red
        }
    }
    Write-Host "  └── MONITORAMENTO ────────────────────────────────────────────┘" -ForegroundColor Cyan
    $proc = Get-CimInstance Win32_Process -Filter "CommandLine LIKE '%Guardiao_Processos%'" | Select-Object -First 1
    if ($proc) { Write-Host "     ▶ Guardião Ativo (PID: $($proc.ProcessId))" -ForegroundColor Green }
    else { Write-Host "     ■ Guardião Inativo" -ForegroundColor Red }
    
    Write-Host "`n  [ÚLTIMOS EVENTOS DO LOG]" -ForegroundColor Cyan
    $log = Get-ChildItem "$scriptDir\Logs\guardiao_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($log) {
        $linhas = Get-Content $log.FullName -Tail 8
        foreach ($l in $linhas) {
            Write-Host "    " -NoNewline
            if ($l -match "ELIMINADO|ERRO") { Write-Host "✖ " -NoNewline -ForegroundColor Red }
            elseif ($l -match "ALERTA")      { Write-Host "⚠ " -NoNewline -ForegroundColor Yellow }
            elseif ($l -match "OK")          { Write-Host "✔ " -NoNewline -ForegroundColor Green }
            else                             { Write-Host "· " -NoNewline -ForegroundColor DarkGray }
            Write-Host $l -ForegroundColor Gray
        }
    }
    Pausa
}

# --- [3] CONFIG ---
function Menu-Config {
    while ($true) {
        Exibir-Cabecalho
        Write-Host "  ╔══ CONFIGURAÇÕES DE SERVIÇO ═════════════════════════════════╗" -ForegroundColor Cyan
        $opcoes = @(
            "[1] Ativar Guardião         iniciar monitoramento  ",
            "[2] Desativar Guardião      parar monitoramento    ",
            "[3] Ativar Limpeza          agendamento semanal    ",
            "[4] Desativar Limpeza       remover agendamento    ",
            "[0] Voltar                  retornar ao menu       "
        )
        foreach ($o in $opcoes) {
            Write-Host "  ║  " -NoNewline -ForegroundColor DarkGray
            Write-Host $o.Substring(0,3) -NoNewline -ForegroundColor Cyan
            Write-Host $o.Substring(3,24) -NoNewline -ForegroundColor White
            Write-Host $o.Substring(27).PadRight(28) -NoNewline -ForegroundColor DarkGray
            Write-Host " ║" -ForegroundColor DarkGray
        }
        Write-Host "  ╚═════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
        Write-Host ""
        $c = Read-Host "  > Selecione"
        if ($c -eq "1") { Enable-ScheduledTask "Soberania_Guardiao"; Start-ScheduledTask "Soberania_Guardiao"; Exibir-Mensagem "Ativado." "OK"; Start-Sleep 1 }
        if ($c -eq "2") { Disable-ScheduledTask "Soberania_Guardiao"; $gProcs = Get-CimInstance Win32_Process -Filter "CommandLine LIKE '%Guardiao_Processos%'"; if($gProcs){$gProcs | Stop-Process -Force}; Exibir-Mensagem "Desativado." "AVISO"; Start-Sleep 1 }
        if ($c -eq "3") { Enable-ScheduledTask "Soberania_Limpeza_Semanal"; Exibir-Mensagem "Ativado." "OK"; Start-Sleep 1 }
        if ($c -eq "4") { Disable-ScheduledTask "Soberania_Limpeza_Semanal"; Exibir-Mensagem "Desativado." "AVISO"; Start-Sleep 1 }
        if ($c -eq "0") { return }
    }
}

# --- [4] LIMPEZA AGORA ---
function Menu-Limpeza {
    Exibir-Cabecalho
    Exibir-Mensagem "Confirmar limpeza manual agora? [S/N]" "AVISO"
    $r = Read-Host "  "
    if ($r -eq "S" -or $r -eq "s") {
        Start-ScheduledTask "Soberania_Limpeza_Semanal"
        Exibir-Mensagem "Processo iniciado em background." "OK"
    }
    Pausa
}

# --- [5] UPDATE ---
function Menu-Update {
    Exibir-Cabecalho
    Exibir-Mensagem "Verificando repositório..." "INFO"
    try {
        $remote = (Invoke-WebRequest -Uri $urlVersion -UseBasicParsing -TimeoutSec 10).Content.Trim()
        $local = "0.0.0"
        if (Test-Path "$scriptDir\version.txt") { $local = (Get-Content "$scriptDir\version.txt").Trim() }
        if ($remote -eq $local) { Exibir-Mensagem "Sistema atualizado ($local)." "OK" }
        else {
            Exibir-Mensagem "Nova versão: $remote (Local: $local)" "AVISO"
            $r = Read-Host "  > Baixar? [S/N]"
            if ($r -eq "S" -or $r -eq "s") {
                $files = @("Guardiao_Processos.ps1", "Limpeza_Semanal.ps1", "Otimizar.ps1", "Painel_Soberano.ps1", "version.txt", "Painel_Soberano.bat")
                $count = 0
                foreach ($f in $files) {
                    $count++
                    Mostrar-Progresso $count $files.Count "Baixando $f"
                    Invoke-WebRequest -Uri "$urlBase/$f" -OutFile "$scriptDir\$f" -UseBasicParsing
                }
                Write-Host ""
                Exibir-Mensagem "Sucesso! Reinicie o painel." "OK"      
            }
        }
    } catch { Exibir-Mensagem "Erro de conexão." "ERRO" }
    Pausa
}

# LOOP PRINCIPAL
while ($true) {
    Exibir-Cabecalho
    Write-Host "  ╔══ MENU PRINCIPAL ═══════════════════════════════════════════╗" -ForegroundColor Cyan
    $opcoes = @(
        "[1] Instalar / Reinstalar   configurar ambiente    ",
        "[2] Verificar Status        diagnóstico completo   ",
        "[3] Configurações           ajustar serviços       ",
        "[4] Limpeza Manual          executar agora         ",
        "[5] Atualizações            checar versão git      ",
        "[0] Sair do Painel          encerrar aplicação     "
    )
    foreach ($o in $opcoes) {
        Write-Host "  ║  " -NoNewline -ForegroundColor DarkGray
        Write-Host $o.Substring(0,3) -NoNewline -ForegroundColor Cyan
        Write-Host $o.Substring(3,24) -NoNewline -ForegroundColor White
        Write-Host $o.Substring(27).PadRight(28) -NoNewline -ForegroundColor DarkGray
        Write-Host " ║" -ForegroundColor DarkGray
    }
    Write-Host "  ╚═════════════════════════════════════════════════════════════╝" -ForegroundColor DarkGray
    Write-Host ""
    $opt = Read-Host "  > Selecione uma opção"
    if ($opt -eq "1") { Menu-Instalar }
    elseif ($opt -eq "2") { Menu-Verificar }
    elseif ($opt -eq "3") { Menu-Config }
    elseif ($opt -eq "4") { Menu-Limpeza }
    elseif ($opt -eq "5") { Menu-Update }
    elseif ($opt -eq "0") { exit }
}
