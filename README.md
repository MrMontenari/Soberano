# Soberano

### Núcleo da Sentinela (Automação de Controle do Windows)

---

## 📌 Visão Geral

O **Projeto Soberano** transforma o Windows em um sistema **controlado, previsível e silencioso**.

No centro dessa estratégia está a **Sentinela**, composta por 3 scripts principais:

* `Guardiao_Processos.ps1` → vigilância ativa
* `Limpeza_Semanal.ps1` → manutenção automática
* `Otimizar.ps1` → preparação sob demanda

E um orquestrador:

* `Painel_Soberano.ps1` → interface e controle central

---

## 🧠 Arquitetura do Sistema

```
                ┌────────────────────┐
                │  Painel Soberano   │
                │ (Interface / TUI)  │
                └─────────┬──────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Guardião    │  │   Limpeza    │  │   Otimizar   │
│ (Tempo real) │  │  (Semanal)   │  │ (Sob demanda)│
└──────────────┘  └──────────────┘  └──────────────┘
```

---
## 🎛️ Painel Soberano (`Painel_Soberano.ps1`)

O painel é o **centro de comando**.

### Funções principais:

* Instalar / reinstalar sistema
* Verificar status completo
* Ativar/desativar serviços
* Executar limpeza manual
* Atualizar via GitHub

### Características:

* Interface TUI (Terminal UI)
* Monitoramento em tempo real (CPU, RAM, uptime)
* Sistema de update automático via repositório
* Integração total com os scripts

---

# 🧿 Guardião de Processos (`Guardiao_Processos.ps1`)

## 📌 Função

Vigilância em tempo real do sistema.

## ⚙️ Como funciona

Usa o evento do Windows:

👉 Windows Management Instrumentation
👉 Evento: `Win32_ProcessStartTrace`

Ou seja:

> O Windows avisa quando um processo nasce — e o Guardião elimina instantaneamente.

---

## 🧠 Lógica

* Não faz loop
* Não consome CPU constantemente
* Atua **no nascimento do processo**

---

## 🔥 O que ele faz

* Mata processos indesejados imediatamente
* Bloqueia telemetria e apps invasivos
* Monitora o sistema em tempo real
* Mantém o firewall ativo (watchdog)

---

## 🛡️ Recursos principais

### ✔️ Eliminação instantânea

Processos são mortos antes de:

* abrir interface
* consumir RAM relevante
* enviar dados

---

### ✔️ Watchdog de firewall

Verifica se o firewall (ex: Simplewall) está ativo.

Se não estiver:
→ reinicia automaticamente

---

### ✔️ Auto-recuperação

Se o script cair:
→ o Agendador reinicia automaticamente

---

### ✔️ Logs

Local:

```
C:\Soberania\Logs\
```

Exemplo:

```
[ELIMINADO] msedge.exe - morto no nascimento
[ALERTA] firewall inativo - reiniciado
```

---

## ⚠️ Nível de controle

Roda como:

* `SYSTEM`
* `RunLevel: Highest`

👉 Controle total da máquina

---

# 🧹 Limpeza Semanal (`Limpeza_Semanal.ps1`)

## 📌 Função

Manutenção automática e persistência das configurações.

---

## ⏱️ Execução

* 1x por semana (domingo, 03:00)
* Ou manual via painel

---

## 🧠 O que resolve

Problema crítico:

> O Windows tenta reverter suas alterações com o tempo.

---

## 🔧 O que o script faz

### 1. Reforça configurações

* Re-desativa serviços
* Impede reativação de telemetria

---

### 2. Limpeza de sistema

Remove:

* arquivos temporários
* cache
* logs inúteis
* restos de update

---

### 3. Limpeza inteligente

* Ignora diretórios pequenos (<1MB)
* Evita processamento desnecessário

---

### 4. Execução silenciosa

Utiliza ferramentas nativas do Windows

---

## 📊 Resultado

* Liberação de espaço
* Redução de uso de disco
* Sistema mais leve
* Persistência da “soberania”

---

## 📝 Logs

```
C:\Soberania\Logs\limpeza_*.log
```

---

# ⚡ Otimizar (`Otimizar.ps1`)

## 📌 Função

Preparar o sistema para performance máxima sob demanda.

---

## 🎯 Quando usar

Antes de:

* abrir VM
* jogar
* tarefas pesadas

---

## 🧠 Estratégia

Ao invés de bloquear alguns processos:

> Ele permite poucos — e elimina todo o resto.

(Allowlist)

---

## 🔥 O que ele faz

### 1. Ativa modo desempenho

Altera plano de energia

---

### 2. Mata processos

Tudo que não for essencial:

* navegadores
* apps em background
* serviços desnecessários

---

### 3. Para serviços pesados

Ex:

* indexação
* otimizações automáticas
* processos de disco

---

### 4. Libera memória

Usa:

👉 `EmptyWorkingSet`

→ força processos a devolver RAM não utilizada

---

### 5. Gera relatório

Mostra:

* RAM antes/depois
* CPU atual
* processos mortos

---

## ⚠️ Atenção

Antes de rodar:

* Salve tudo
* Feche programas importantes

👉 Ele não pede permissão — ele executa

---

## 🟢 Resultado esperado

* RAM liberada
* CPU estável
* Sistema pronto para carga máxima

---

# 🔗 Integração entre os scripts

| Script   | Papel        | Quando atua |
| -------- | ------------ | ----------- |
| Guardião | Defesa ativa | Tempo real  |
| Limpeza  | Manutenção   | Semanal     |
| Otimizar | Performance  | Manual      |
| Painel   | Controle     | Sempre      |

---

# 🧠 Filosofia do Projeto

> “Não é sobre otimizar o Windows.
> É sobre controlar o comportamento dele.”

---

# ⚠️ Aviso de responsabilidade

Este projeto:

* altera comportamento do sistema
* executa com privilégios elevados
* cria tarefas automáticas

👉 Indicado para usuários que entendem o que estão executando

---

# 🚀 Próximos passos (evolução do projeto)

* Empacotamento em `.exe` (ex: PS2EXE)
* Interface gráfica (GUI)
* Sistema modular de plugins
* Dashboard com métricas

---
