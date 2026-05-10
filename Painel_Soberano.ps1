#Requires -RunAsAdministrator
# PAINEL_SOBERANO.PS1 - PROJETO SOBERANO
$ErrorActionPreference = "SilentlyContinue"

# 1. VARIAVEIS E AMBIENTE
$versaoAtual  = "1.1.1"
$scriptDir    = "C:\Soberania"
$githubUser   = "MrMontenari"
$githubRepo   = "Soberano"
$githubBranch = "main"
$urlBase      = "https://raw.githubusercontent.com/$githubUser/$githubRepo/refs/heads/$githubBranch"
$urlVersion   = "$urlBase/version.txt"

# 2. FUNCOES DE INTERFACE (Strict ASCII)
function Mostrar-Progresso {
    param([int]$atual, [int]$total, [string]$msg)
    $largura = 20
    $percent = [int](($atual / $total) * 100)
    $preenchido = [int](($atual / $total) * $largura)
    $vazio = $largura - $preenchido
    $barra = ("#" * $preenchido) + ("-" * $vazio)
    Write-Host ("`r  $msg [$barra] $percent% ") -NoNewline -ForegroundColor Gray
}

function Pausa {
    Write-Host ""
    Write-Host "  +-- [0] Voltar  [CTRL+C] Sair --+" -ForegroundColor DarkGray
    $null = [Console]::ReadKey($true)
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

    Write-Host "  +-------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  | " -NoNewline -ForegroundColor DarkGray
    Write-Host " ____  ___  ____  ____ ____   _   _  ___    " -NoNewline -ForegroundColor Cyan
    Write-Host "U: $($user.PadRight(10))" -NoNewline -ForegroundColor Magenta
    Write-Host " |" -ForegroundColor DarkGray
    
    Write-Host "  | " -NoNewline -ForegroundColor DarkGray
    Write-Host "/ ___|/ _ \| __ )| ___|  _ \ / \ | \| | | |   " -NoNewline -ForegroundColor Cyan
    Write-Host "H: $($hostn.PadRight(10))" -NoNewline -ForegroundColor Magenta
    Write-Host " |" -ForegroundColor DarkGray

    Write-Host "  | " -NoNewline -ForegroundColor DarkGray
    Write-Host "\___ \ | | |  _ \|  _| | _/ / _ \|  | | | |   " -NoNewline -ForegroundColor Cyan
    Write-Host "T: $($hora.PadRight(10))" -NoNewline -ForegroundColor Magenta
    Write-Host " |" -ForegroundColor DarkGray

    Write-Host "  | " -NoNewline -ForegroundColor DarkGray
    Write-Host " ___) | |_| | |_) | |__|  \ / ___ \ |\  |_| |  " -NoNewline -ForegroundColor Cyan
    Write-Host "U: $($uptime.PadRight(10))" -NoNewline -ForegroundColor Magenta
    Write-Host " |" -ForegroundColor DarkGray

    Write-Host "  | " -NoNewline -ForegroundColor DarkGray
    Write-Host "|____/ \___/|____/|____|_|_\_/   \_\_| \___/  " -NoNewline -ForegroundColor Cyan
    Write-Host "V: $($versaoAtual.PadRight(10))" -NoNewline -ForegroundColor Magenta
    Write-Host " |" -ForegroundColor DarkGray
    Write-Host "  +-------------------------------------------------------------+" -ForegroundColor DarkGray

    Write-Host "    CPU: $cpu%  |  RAM: $usedRam GB / $totalRam GB" -ForegroundColor DarkGray
    $sep = "    " + ("-" * 57)
    Write-Host $sep -ForegroundColor DarkGray
    Write-Host ""
}

function Exibir-Mensagem {
    param([string]$msg, [string]$tipo = "INFO")
    Write-Host "  " -NoNewline
    switch ($tipo) {
        "OK"    { Write-Host "[OK] " -NoNewline -ForegroundColor Green;   Write-Host $msg -ForegroundColor White }  
        "ERRO"  { Write-Host "[X]  " -NoNewline -ForegroundColor Red;     Write-Host $msg -ForegroundColor White } 
        "AVISO" { Write-Host "[!]  " -NoNewline -ForegroundColor Yellow;  Write-Host $msg -ForegroundColor White }  
        default { Write-Host "[*]  " -NoNewline -ForegroundColor Cyan;    Write-Host $msg -ForegroundColor White }  
    }
}

# --- [1] LIMPAR ---
function Menu-Limpeza {
    Exibir-Cabecalho
    Exibir-Mensagem "Removendo agendamentos automaticos..." "INFO"
    Unregister-ScheduledTask -TaskName "Soberania_Limpeza_Semanal" -Confirm:$false 2>$null
    
    Exibir-Mensagem "Iniciando limpeza manual..." "OK"
    Start-Sleep -Seconds 1
    if (Test-Path "$scriptDir\Limpeza_Semanal.ps1") {
        & "$scriptDir\Limpeza_Semanal.ps1"
    } else {
        Exibir-Mensagem "Erro: Limpeza_Semanal.ps1 nao encontrado." "ERRO"
        Pausa
    }
}

# --- [2] OTIMIZAR ---
function Menu-Otimizar {
    Exibir-Cabecalho
    Exibir-Mensagem "Iniciando otimizacao para VM..." "OK"
    Start-Sleep -Seconds 1
    if (Test-Path "$scriptDir\Otimizar.ps1") {
        & "$scriptDir\Otimizar.ps1"
    } else {
        Exibir-Mensagem "Erro: Otimizar.ps1 nao encontrado." "ERRO"
        Pausa
    }
}

# --- [3] ATALHOS ---
function Menu-Atalhos {
    Exibir-Cabecalho
    Write-Host "  [3] CRIAR ATALHOS NA AREA DE TRABALHO" -ForegroundColor Cyan
    Write-Host ""
    
    $desktop = [Environment]::GetFolderPath("Desktop")
    $atalho1 = Join-Path $desktop "Limpar.lnk"
    $atalho2 = Join-Path $desktop "Otimizar.lnk"

    # Atalho Limpar
    if (Test-Path $atalho1) {
        Exibir-Mensagem "O atalho 'Limpar' ja existe. Substituir? [S/N]" "AVISO"
        $resp = Read-Host "  > "
        if ($resp -eq "S" -or $resp -eq "s") {
            $shell = New-Object -ComObject WScript.Shell
            $lnk = $shell.CreateShortcut($atalho1)
            $lnk.TargetPath = "powershell.exe"
            $lnk.Arguments = "-ExecutionPolicy Bypass -File `"$scriptDir\Limpeza_Semanal.ps1`""
            $lnk.IconLocation = "imageres.dll,51"
            $lnk.Save()
            Exibir-Mensagem "Atalho 'Limpar' atualizado." "OK"
        }
    } else {
        $shell = New-Object -ComObject WScript.Shell
        $lnk = $shell.CreateShortcut($atalho1)
        $lnk.TargetPath = "powershell.exe"
        $lnk.Arguments = "-ExecutionPolicy Bypass -File `"$scriptDir\Limpeza_Semanal.ps1`""
        $lnk.IconLocation = "imageres.dll,51"
        $lnk.Save()
        Exibir-Mensagem "Atalho 'Limpar' criado." "OK"
    }

    # Atalho Otimizar
    if (Test-Path $atalho2) {
        Exibir-Mensagem "O atalho 'Otimizar' ja existe. Substituir? [S/N]" "AVISO"
        $resp = Read-Host "  > "
        if ($resp -eq "S" -or $resp -eq "s") {
            $shell = New-Object -ComObject WScript.Shell
            $lnk = $shell.CreateShortcut($atalho2)
            $lnk.TargetPath = "powershell.exe"
            $lnk.Arguments = "-ExecutionPolicy Bypass -File `"$scriptDir\Otimizar.ps1`""
            $lnk.IconLocation = "imageres.dll,109"
            $lnk.Save()
            Exibir-Mensagem "Atalho 'Otimizar' atualizado." "OK"
        }
    } else {
        $shell = New-Object -ComObject WScript.Shell
        $lnk = $shell.CreateShortcut($atalho2)
        $lnk.TargetPath = "powershell.exe"
        $lnk.Arguments = "-ExecutionPolicy Bypass -File `"$scriptDir\Otimizar.ps1`""
        $lnk.IconLocation = "imageres.dll,109"
        $lnk.Save()
        Exibir-Mensagem "Atalho 'Otimizar' criado." "OK"
    }

    Pausa
}

# --- [4] ATUALIZACOES ---
function Menu-Update {
    Exibir-Cabecalho
    Exibir-Mensagem "Verificando repositorio..." "INFO"
    try {
        $remote = (Invoke-WebRequest -Uri $urlVersion -UseBasicParsing -TimeoutSec 10).Content.Trim()
        $local = "0.0.0"
        if (Test-Path "$scriptDir\version.txt") { $local = (Get-Content "$scriptDir\version.txt").Trim() }
        
        if ($remote -eq $local) { 
            Exibir-Mensagem "Sistema atualizado (Local: $local | Remoto: $remote)." "OK" 
        }
        else {
            Exibir-Mensagem "Nova versao disponivel: $remote (Sua versao: $local)" "AVISO"
            $r = Read-Host "  > Baixar e atualizar todos os componentes? [S/N]"
            if ($r -eq "S" -or $r -eq "s") {
                $files = @("Guardiao_Processos.ps1", "Limpeza_Semanal.ps1", "Otimizar.ps1", "Painel_Soberano.ps1", "version.txt", "Painel_Soberano.bat")
                $count = 0
                foreach ($f in $files) {
                    $count++
                    Mostrar-Progresso $count $files.Count "Baixando $f"
                    Invoke-WebRequest -Uri "$urlBase/$f" -OutFile "$scriptDir\$f" -UseBasicParsing
                }
                Write-Host ""
                Exibir-Mensagem "Atualizacao concluida com sucesso!" "OK"
                Exibir-Mensagem "Reinicie o painel para aplicar as mudancas." "AVISO"
            }
        }
    } catch { 
        Exibir-Mensagem "Erro de conexao ou repositorio nao encontrado." "ERRO" 
    }
    Pausa
}

# VERIFICAR ADMIN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Clear-Host
    Write-Host "  [!] ERRO: Este painel precisa de privilegios de Administrador." -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

# LOOP PRINCIPAL
while ($true) {
    Exibir-Cabecalho
    Write-Host "  +-- MENU PRINCIPAL -------------------------------------------+" -ForegroundColor Cyan
    $opcoes = @(
        "[1] Limpar                 executar limpeza manual ",
        "[2] Otimizar               preparar PC para a VM   ",
        "[3] Atalhos                criar atalhos no desktop",
        "[4] Atualizacoes           checar versao remota    ",
        "[0] Sair                   encerrar aplicacao      "
    )
    foreach ($o in $opcoes) {
        Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
        Write-Host $o.Substring(0,3) -NoNewline -ForegroundColor Cyan
        Write-Host $o.Substring(3,24) -NoNewline -ForegroundColor White
        Write-Host $o.Substring(27).PadRight(28) -NoNewline -ForegroundColor DarkGray
        Write-Host " |" -ForegroundColor DarkGray
    }
    Write-Host "  +-------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    $opt = Read-Host "  > Selecione uma opcao"
    
    if ($opt -eq "1") { Menu-Limpeza }
    elseif ($opt -eq "2") { Menu-Otimizar }
    elseif ($opt -eq "3") { Menu-Atalhos }
    elseif ($opt -eq "4") { Menu-Update }
    elseif ($opt -eq "0") { exit }
}
