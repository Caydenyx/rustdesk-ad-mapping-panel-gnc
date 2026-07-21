# 🖥️ RustDesk AD Mapping & Live Status Dashboard (v1.0)

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Open Source](https://img.shields.io/badge/RustDesk-Open%20Source-orange.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blueviolet.svg)
![Active Directory](https://img.shields.io/badge/Active%20Directory-GPO-0078D4.svg)

Solução corporativa *Open Source* para **instalação, configuração centralizada, inventário dinâmico e monitoramento de status em tempo real (ICMP)** da ferramenta de suporte remoto **RustDesk** integrada ao **Active Directory (AD)**.

---

## 🚀 Sobre o Projeto & Desafio Resolvido

Em ambientes corporativos com múltiplos turnos e estações de trabalho compartilhadas por diversos usuários (como emissoras de TV, rádios, centrais de atendimento e ilhas de edição), rastrear **qual ID do RustDesk pertence a qual máquina e usuário ativo** é um grande gargalo operacional.

### 💡 Como esta automação resolve o problema:
1. **Implantação Silenciosa via Boot (GPO):** Instala o RustDesk, limpa caches antigos, aplica a chave/servidor privado do seu RustDesk Server, define a senha administrativa fixa e exporta o ID local de forma limpa.
2. **Coleta Multi-usuário via Logon (GPO):** Associa o ID do RustDesk ao usuário logado no momento e captura a Unidade Organizacional (OU/Setor) diretamente do AD, registrando histórico completo de revezamento.
3. **Painel Web Interativo com Ping em Tempo Real:** Um script no servidor processa os dados, valida a disponibilidade de rede (*Live ICMP Ping*) e compila um painel HTML moderno com busca dinâmica, filtros por setor e conexão em 1 clique via protocolo nativo (`rustdesk://`).

---

## 🏗️ Arquitetura da Solução

```text
  [ Estação de Trabalho ]
           │
           ├─► (Boot da Máquina / GPO Startup)
           │     └─► Run: 1-Instalador-Configurador.ps1
           │           ├─ Instala/Atualiza RustDesk
           │           ├─ Configura Server Privado + Senha Fixa
           │           └─ Salva ID em C:\ProgramData\RustDeskID.txt
           │
           └─► (Logon do Usuário / GPO Logon)
                 └─► Run: 2-Coletor-Dados.ps1
                       ├─ Captura: Computador + Usuário + Setor (OU) + ID Local
                       └─ Grava arquivo: \\SERVIDOR\Compartilhamento\Dados\PC_USUARIO.txt

  [ Servidor Central (Windows Server) ]
           │
           ├─► (Task Scheduler - A cada 15 Minutos)
           │     └─► Run: 3-Gerador-Painel.ps1
           │           ├─ Lê todos os arquivos .txt da pasta \Dados
           │           ├─ Executa teste de conectividade (Ping ICMP) em tempo real
           │           └─ Compila o arquivo estático painel.html
           │
           └─► [ 🌐 Painel Web de TI ] ──► (Dispara acesso via rustdesk://[ID])
```

---

## 📂 Estrutura do Repositório

```text
rustdesk-ad-mapping-panel/
│
├── 📜 README.md                            # Documentação completa do projeto
│
├── 📂 GPO-Computer/
│   └── 📜 1-Instalador-Configurador.ps1    # Script de Boot (Instalação + Server + ID)
│
├── 📂 GPO-User/
│   └── 📜 2-Coletor-Dados.ps1              # Script de Logon (Mapeamento AD + SMB)
│
└── 📂 Servidor/
    ├── 📜 3-Gerador-Painel.ps1             # Script Gerador (Ping + HTML Engine)
    └── 📜 Task-Painel.xml                  # Template de importação para o Task Scheduler
```

---

## 🛠️ Guia de Implantação Passo a Passo

### 1️⃣ Pré-requisitos & Permissões da Pasta de Rede
Crie uma pasta compartilhada na sua rede (ex: `\\SERVIDOR\Compartilhamento\`) com duas subpastas:
* `\Instalador` — Armazene o executável oficial do RustDesk.
* `\Dados` — Local onde os registros `.txt` dos clientes serão salvos.

> 🔒 **Permissões de Compartilhamento/NTFS na pasta `\Dados`:**
> * **Domain Computers (Computadores do Domínio):** Leitura.
> * **Domain Users (Usuários do Domínio):** Modificar / Gravidade (Escrita).

---

### 2️⃣ Configurar a GPO de Computador (Boot / Startup)
Este script garante a instalação do programa e a configuração da máquina antes mesmo do usuário fazer login.

1. Abra o **Group Policy Management console (`gpmc.msc`)**.
2. Crie ou edite uma GPO vinculada à OU das suas máquinas.
3. Navegue até:  
   `Configuração do Computador` ➔ `Políticas` ➔ `Configurações do Windows` ➔ `Scripts (Inicialização/Encerramento)` ➔ `Inicialização (Startup)`.
4. Adicione o script `1-Instalador-Configurador.ps1`.
5. **Ajuste as Variáveis** no topo do script:
   ```powershell
   $PastaRedeInstalador = "\\SEU-SERVIDOR\SHARE\Instalador"
   $ServidorRustDesk    = "remote.seudominio.com"
   $ChavePublica        = "SUA_CHAVE_PUBLICA_AQUI"
   $SenhaFixaAcesso     = "SuaSenhaForte@123"
   ```

---

### 3️⃣ Configurar a GPO de Usuário (Logon)
Este script roda no contexto do usuário que acabou de logar, capturando a conta corporativa e o setor (OU) no AD.

1. Na mesma GPO (ou em uma GPO vinculada à OU de Usuários), navegue até:  
   `Configuração do Usuário` ➔ `Políticas` ➔ `Configurações do Windows` ➔ `Scripts (Logon/Logoff)` ➔ `Logon`.
2. Adicione o script `2-Coletor-Dados.ps1` com o parâmetro de execução `-ExecutionPolicy Bypass`.
3. **Ajuste a Variável** no topo do script:
   ```powershell
   $PastaDadosRede = "\\SEU-SERVIDOR\SHARE\Dados"
   ```

---

### 4️⃣ Configurar o Gerador de Painel no Servidor
O gerador compila os dados coletados e valida o status online/offline das estações.

1. Salve o script `3-Gerador-Painel.ps1` em uma pasta no seu servidor.
2. Edite os caminhos de origem e destino no script:
   ```powershell
   $PastaDados  = "\\SEU-SERVIDOR\SHARE\Dados"
   $CaminhoHtml = "\\SEU-SERVIDOR\SHARE\painel.html"
   ```
3. Abra o **Agendador de Tarefas (*Task Scheduler*)** do Windows Server.
4. Clique em **Importar Tarefa...** e selecione o arquivo `Task-Painel.xml`.
5. Altere o usuário de execução da tarefa para uma conta com privilégios de leitura na rede e marque a opção **"Executar com privilégios máximos"**.

---

## 🖥️ Funcionalidades do Dashboard Web

- 🟢 **Indicador de Status (ICMP Ping):** Bolinha verde (*Online*) se a máquina responde ao ping na rede local; vermelha (*Offline*) se estiver desligada.
- 🔍 **Busca Global Instantânea:** Campo de texto livre para buscar simultaneamente por nome da máquina, nome do usuário, setor ou ID.
- 📁 **Filtro por Departamento / Setor:** Dropdown populado automaticamente de acordo com as OUs do Active Directory.
- ⚡ **Acesso em 1 Clique (`rustdesk://`):** Botão "Conectar" aciona a protocolo personalizado do RustDesk, abrindo a sessão remota no app local do técnico sem precisar digitar o ID manualmente.

---

## 🗺️ Roadmap de Evolução (v2.0)

A próxima fase deste projeto contempla a evolução da arquitetura para um modelo moderno de microsserviços:

- [ ] **Backend em Python (FastAPI):** API REST assíncrona para leitura de arquivos e ping concorrente em alta performance.
- [ ] **Frontend Moderno em React + Tailwind CSS:** Interface responsiva em Dark Mode com gráficos de uso por departamento.
- [ ] **WebSockets / Server-Sent Events:** Atualização de status de conectividade em tempo real sem reload do HTML.
- [ ] **Bot de Alertas:** Integração com Webhooks (Microsoft Teams / WhatsApp) para notificar sobre novas máquinas conectadas.

---

## 👨‍💻 Autor

**Thiago Soutelo**  
*Infrastructure Analyst | Observability | Cloud & DevOps*  
📍 Manaus, AM — Brasil  
🔗 [LinkedIn](https://linkedin.com/in/thiagosoutelo) | [GitHub](https://github.com/Caydenyx) | 📧 soutelothiago@gmail.com
