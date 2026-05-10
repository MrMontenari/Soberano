# Projeto Soberano

### Windows domado, Linux no horizonte — simples, reversível, eficaz

> **Para quem é este documento?** Para você, que quer controle real do seu sistema sem depender de scripts que não entende completamente. Cada ferramenta aqui tem uma razão clara — e pode ser desfeita com a mesma facilidade com que foi feita.

---

## O que é este projeto

**Soberania Digital** é o processo de transformar o Windows de um sistema que trabalha _para a Microsoft_ em um sistema que trabalha _para você_.

Por padrão, o Windows faz coisas sem te avisar:

- Envia dados sobre o que você faz para servidores da Microsoft (**telemetria**)
- Instala aplicativos que você nunca pediu (**bloatware**)
- Usa RAM e processador em segundo plano sem motivo útil para você
- Tenta te forçar a criar uma conta online só para usar o PC que você pagou

Neste projeto, você assume o controle com o mínimo de ferramentas necessário. O objetivo não é anonimato — é **privacidade razoável com reversibilidade total**.

### O que este projeto não é

- Não é blindagem completa (isso não existe)
- Não é um conjunto de scripts que você roda sem entender
- Não bloqueia o Windows Update nem a Microsoft Store

---

## Por que simplificar

A versão anterior do projeto tinha mais camadas do que precisava. O Guardião de Processos resolvia um problema que o WinUtil já resolve de forma mais permanente e sem processo rodando continuamente. A Allowlist agressiva do Otimizar quebrava coisas inesperadas. Bloquear o Windows Update quebrou a Store.

A lição: **complexidade sem compreensão é risco, não proteção**.

### Escala de privacidade

Para referência, o que este projeto entrega na prática:

| Nível | Situação |
|-------|----------|
| 0–2 | Windows padrão com conta Microsoft |
| 3–4 | Configurações manuais sem automação |
| **6–7** | **Este projeto — seu alvo** |
| 8–9 | VPN própria, DNS criptografado, Qubes OS |
| 10 | Não existe |

Para um estudante de ADS querendo controle do próprio sistema e um ambiente Linux para estudar, **6–7 é mais do que suficiente** — e mais do que 99% dos profissionais de TI têm no dia a dia.

---

## O mapa

```
HOJE                    EM BREVE               NO FUTURO
─────────────────────────────────────────────────────────
Windows domado    →   Dual Boot           →   Linux puro
+ Linux na VM         30% Windows              Supremacia
                       70% Linux               Linux
  ← VOCÊ ESTÁ AQUI →
```

---

## As ferramentas — o que ficou, o que saiu

### O que ficou

| Ferramenta | Função | Reversível? |
|------------|--------|-------------|
| Instalação limpa | Fundação — sem conta Microsoft, sem bloatware desde o início | N/A (decisão única) |
| WinUtil (Chris Titus) | Desativa telemetria, remove lixo, instala programas limpos | Sim, maioria das opções |
| Simplewall | Controla o que cada programa pode acessar na rede | Sim — desinstalar restaura tudo |
| DNS 1.1.1.1 | Troca o servidor de nomes por um sem rastreamento | Sim — um clique |
| Limpeza Semanal | Faxina automática de disco e reconfirmação de serviços | Sim — desregistrar a tarefa |
| Otimizar | Prepara o PC antes de abrir o Linux na VM | Sim — fechar o terminal reverte |

### O que saiu e por quê

| Removido | Motivo |
|----------|--------|
| Guardião de Processos | Redundante com WinUtil. Causava conflitos com Store e Update. |
| Bloqueio do Windows Update | Quebrou a Microsoft Store. Atualizações de segurança importam. |
| Allowlist agressiva no Otimizar | Encerrava processos sem critério claro. Risco de perda de dados. |

---

## Fase 1 — Instalação limpa

> **Objetivo:** Instalar o Windows desde o início sem dar à Microsoft controle sobre o sistema.

Não conecte rede nem Wi-Fi durante a instalação. Offline, o Windows não consegue obrigar conta Microsoft nem ativar telemetria automaticamente.

### O truque da conta local

Na tela "Vamos conectar você a uma rede":

1. Pressione `Shift + F10` — abre o Prompt de Comando
2. Digite e pressione Enter:

```
OOBE\BYPASSNRO
```

3. O PC reinicia. Na próxima tela, clique **"Eu não tenho internet"** → **"Continuar com a configuração limitada"**
4. Crie seu usuário com nome simples, sem espaços (ex: `seu_nome`)

> **Regra:** nunca coloque espaço em nomes de usuário, pasta ou arquivo. Espaços causam erros em scripts e terminais.

### Telas de privacidade

Responda **Não** para tudo:

| Pergunta | Resposta |
|----------|----------|
| Localização | Não |
| Encontrar meu dispositivo | Não |
| Dados de diagnóstico | Enviar apenas o mínimo |
| Experiências personalizadas | Não |
| ID de publicidade | Não |

---

## Fase 2 — WinUtil (Chris Titus Tech)

> **Objetivo:** Desativar telemetria, remover bloatware e instalar programas de forma limpa — tudo em uma única sessão.

### Como executar

1. Conecte à internet
2. Abra o Terminal como Administrador: `Win + X` → Terminal (Administrador)
3. Cole e pressione Enter:

```powershell
irm christitus.com/win | iex
```

### Na aba Tweaks, ative

**Essential Tweaks:**
- Telemetry — Disable
- Location Tracking — Disable
- Activity History — Disable
- Disk Cleanup
- Hibernation — Disable

**Advanced Tweaks:**
- Background Apps — Disable
- Microsoft Copilot — Disable
- Microsoft Edge — Debloat
- Microsoft OneDrive — Remove
- Unwanted Pre-installed Apps — Remove

**Customize Preferences:**
- File Explorer File Extensions — Show
- Start Menu Bing Search — Desativar
- Mouse Acceleration — Desativar

**Performance Plans:**
- Enable Ultimate Performance Profile

Clique em **Run Tweaks** e aguarde.

### Na aba Install

Instale pelo WinUtil (instala limpo via winget, sem toolbars):

- VirtualBox
- Firefox ou Brave
- Simplewall

> **Por que instalar pelo WinUtil?** Instalações via `winget` são limpas — sem bundleware, sem extensões indesejadas. Atualizações futuras via `winget upgrade --all`.

### Limpeza manual

1. Pressione `Win + R`, digite `appwiz.cpl`, Enter
2. Desinstale: McAfee, ferramentas Lenovo (Vantage, Welcome), Office trial, programas de voz

---

## Fase 3 — Simplewall

> **Objetivo:** Enxergar e controlar o que cada programa do seu PC pode acessar na internet.

O Simplewall não protege contra ataques externos — ele controla o que os programas do **seu próprio computador** podem enviar para fora.

**Como funciona:** toda vez que um programa tenta se conectar, aparece uma notificação. Você decide sim ou não. Essa decisão fica salva.

### Regra de ouro

> Se você não abriu o programa e ele pediu internet → **bloqueie**.

### O que bloquear

| Processo | O que é |
|----------|---------|
| `svchost.exe` | "Faz-tudo" da Microsoft |
| `msedge.exe` | Navegador Edge |
| `msmpeng.exe` | Antivírus Defender |
| `lsass.exe` | Processo de autenticação |
| `MusNotification.exe` | Notificações de update |

### O que permitir

| Processo | O que é |
|----------|---------|
| Seu navegador (Firefox/Brave) | Você instalou |
| VirtualBox | Você instalou |
| `winget` / PowerShell | Durante instalações que você iniciou |

---

## Fase 4 — DNS privado

> **Objetivo:** Trocar o servidor DNS por um sem rastreamento por anunciantes.

Antes de qualquer conexão, o PC pergunta a um servidor DNS "qual é o IP desse site?". Por padrão, esse servidor é do seu provedor ou da Microsoft. Trocar por Cloudflare resolve isso.

### Como trocar

1. `Win + R` → `ncpa.cpl` → Enter
2. Botão direito na conexão ativa → Propriedades
3. Clique em **Protocolo TCP/IPv4** → Propriedades
4. Marque **"Usar os seguintes endereços de servidor DNS"**
5. Preencha:
   - DNS preferencial: `1.1.1.1`
   - DNS alternativo: `1.0.0.1`
6. OK em todas as janelas

### Como desfazer

Volte na mesma tela e marque **"Obter endereço dos servidores DNS automaticamente"**.

### Verificar se funcionou

```powershell
Resolve-DnsName google.com
```

Se retornar um endereço IP, está funcionando.

> **Alternativa:** `9.9.9.9` (Quad9) — também sem rastreamento e bloqueia domínios maliciosos conhecidos automaticamente.

---

## Fase 5 — Limpeza Semanal

> **Objetivo:** Manter o disco limpo e reconfirmar serviços desativados automaticamente, sem intervenção manual.

O script roda todo domingo às 03:00. Se o PC estiver desligado nesse horário, roda na próxima vez que ligar.

### O que ele faz

**Reconfirma serviços desligados** — o Windows Update pode reativar serviços que você desativou. A Limpeza verifica toda semana e força de volta para desligado:

| Serviço | Por que é desativado |
|---------|---------------------|
| `DiagTrack` | Telemetria principal |
| `dmwappushservice` | Canal secundário de telemetria |
| `DoSvc` | Usa sua internet para distribuir updates a estranhos |
| `WerSvc` | Envia logs de erro para a Microsoft |
| `lfsvc` | Rastreamento de localização |
| `XblAuthManager` | Autenticação Xbox |

**Limpa pastas temporárias:**

| Pasta | O que acumula |
|-------|--------------|
| `Windows\Temp` | Temporários do sistema |
| `%TEMP%` | Temporários do usuário |
| `Windows\WER` | Relatórios de erro |
| `SoftwareDistribution` | Downloads de atualização antigos |

**Logs em:** `C:\Soberania\Logs\limpeza_AAAA-MM-DD.log`

### Como instalar

1. Coloque `Instalar_Soberania.ps1` e `Limpeza_Semanal.ps1` na pasta `C:\Soberania\`
2. Botão direito em `Instalar_Soberania.ps1` → Executar com PowerShell
3. Confirme como Administrador

### Como verificar

```powershell
Get-ScheduledTask -TaskName "Soberania_Limpeza_Semanal" | Select-Object TaskName, State
```

Deve retornar `Ready` (aguardando o horário agendado — correto).

### Como forçar agora (sem esperar domingo)

```powershell
Start-ScheduledTask -TaskName "Soberania_Limpeza_Semanal"
```

### Como desinstalar

```powershell
Unregister-ScheduledTask -TaskName "Soberania_Limpeza_Semanal" -Confirm:$false
```

---

## Fase 6 — Otimizar

> **Objetivo:** Preparar o PC antes de abrir o Linux na VM — liberar RAM, ativar alto desempenho, parar serviços pesados.

Este script é executado **manualmente**, clicando no atalho na Área de Trabalho antes de abrir o VirtualBox. Ao fechar a janela do script, o PC volta ao estado normal automaticamente.

### O que ele faz

1. Verifica se está rodando como Administrador
2. Ativa o plano de **Alto Desempenho**
3. Para serviços que consomem CPU e disco em segundo plano (SysMain, Indexador de Busca)
4. Libera memória não utilizada ativamente pelos processos em execução (`EmptyWorkingSet`)
5. Exibe relatório: RAM antes/depois, CPU, plano ativo

### Relatório final

| Item | Significa |
|------|-----------|
| `[PLANO]` | Modo turbo ativo |
| `[RAM]` | Memória livre antes e depois — "Ganho" é o que foi devolvido |
| `[CPU]` | Carga média de processamento |

**Semáforo de prontidão:**

| Cor | Significa |
|-----|----------|
| Verde | Sistema pronto para a VM |
| Amarelo | Uso moderado, aceitável |
| Vermelho | Ainda há algo pesado rodando |

> **Atenção:** mantenha a janela do script **minimizada** enquanto usa a VM. Fechar a janela encerra o modo Alto Desempenho e volta para Equilibrado.

### Fluxo de uso diário

```
1. Clique em "Otimizar" na Área de Trabalho
2. Aguarde o relatório verde
3. Abra o VirtualBox e inicie o Zorin OS
4. Trabalhe no Linux normalmente
5. Ao terminar, desligue o Zorin pelo menu interno dele
   (não feche a janela — desligue corretamente)
6. Feche o terminal do Otimizar
```

---

## Windows Update — a estratégia correta

Bloquear completamente o Update quebra a Microsoft Store e impede correções de segurança reais. A estratégia é **controlar quando e o quê**, não bloquear tudo.

### Pausar por 5 semanas (recomendado)

1. Configurações → Windows Update → Opções avançadas
2. Em **Pausar atualizações**, selecione **5 semanas**
3. Renove mensalmente — vire um hábito

Isso dá tempo para a comunidade testar se uma atualização quebra algo antes de você instalar.

### Desativar distribuição peer-to-peer

O Windows usa sua conexão para distribuir updates para outros PCs na internet. Para desativar:

**Configurações → Windows Update → Opções avançadas → Otimização de entrega → desative "Permitir downloads de outros PCs"**

Ou via terminal:

```powershell
sc stop DoSvc
sc config DoSvc start= disabled
```

### Após qualquer atualização grande

1. Force a Limpeza Semanal manualmente:

```powershell
Start-ScheduledTask -TaskName "Soberania_Limpeza_Semanal"
```

2. Verifique se o Simplewall ainda está ativo (ícone verde no canto inferior direito)

---

## Manutenção

### Verificar o que está ativo

```powershell
Get-ScheduledTask -TaskName "Soberania_*" | Select-Object TaskName, State
```

### Onde ficam os logs

| Script | Localização |
|--------|-------------|
| Limpeza Semanal | `C:\Soberania\Logs\limpeza_AAAA-MM-DD.log` |
| Otimizar | Exibe na tela (sem arquivo permanente) |

### Níveis de log

| Nível | Significa |
|-------|----------|
| `[INFO]` | Informação geral |
| `[OK]` | Tudo certo neste ponto |
| `[ACAO]` | O script fez algo |
| `[ALERTA]` | Detectou algo indesejado e agiu |
| `[ERRO]` | Tentou fazer algo e não conseguiu |

---

## Como desfazer tudo

| O que desfazer | Como |
|----------------|------|
| Limpeza Semanal | `Unregister-ScheduledTask -TaskName "Soberania_Limpeza_Semanal" -Confirm:$false` |
| Simplewall | Desinstalar normalmente — tudo volta ao padrão |
| DNS | Propriedades da rede → "Obter DNS automaticamente" |
| Windows Update | Configurações → Windows Update → Retomar atualizações |
| WinUtil (tweaks) | A maioria tem opção "Enable" para reverter na mesma interface |

---

## Dicionário

| Termo | O que significa |
|-------|----------------|
| **Telemetria** | Dados sobre o que você faz enviados automaticamente para a Microsoft |
| **Bloatware** | Programas instalados de fábrica que você nunca pediu |
| **Firewall** | Porteiro que controla quem pode passar pela rede |
| **Simplewall** | Firewall que controla o que os programas do *seu* PC podem acessar |
| **VM (Máquina Virtual)** | Um computador simulado dentro do seu computador |
| **VirtualBox** | O programa que cria e gerencia máquinas virtuais |
| **ISO** | Arquivo de imagem de instalação — como um DVD digital |
| **Zorin OS** | Distribuição Linux com visual parecido com Windows |
| **DNS** | "Lista telefônica" da internet — traduz nomes de sites em IPs |
| **winget** | Gerenciador de pacotes do Windows — instala programas via terminal |
| **Conta local** | Conta de usuário que existe só no seu PC, sem vinculação com a Microsoft |
| **BYPASSNRO** | Comando que permite criar conta local durante a instalação |
| **DoSvc** | Serviço que usa sua internet para distribuir updates a outros PCs |
| **Rolling release** | Distro Linux que recebe atualizações contínuas |
| **Fixed release** | Distro Linux com versões estáveis em intervalos definidos |

---

## O próximo passo

Se você seguiu o documento até aqui, uma coisa importa agora:

> **Abra a VM, abra o terminal do Zorin, e escreva seu primeiro programa em C dentro do Linux.**

```bash
mkdir ~/primeiro_programa
cd ~/primeiro_programa
nano hello.c
```

```c
#include <stdio.h>

int main() {
    printf("Soberania conquistada.\n");
    return 0;
}
```

```bash
gcc hello.c -o hello
./hello
```

O resto vem com o tempo.

---

*Projeto Soberano — versão simplificada.*  
*Desenvolvido com auxílio de IA (Claude). Windows 11. Curso ADS — Fatec Arthur de Azevedo.*  
*Este documento é vivo — atualize conforme o projeto evolui.*
