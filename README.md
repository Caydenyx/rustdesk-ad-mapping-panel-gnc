# 🖥️ RustDesk AD Mapping & Live Status Dashboard (v1.0)

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Open Source](https://img.shields.io/badge/RustDesk-Open%20Source-orange.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blueviolet.svg)

Solução automatizada para mapeamento dinâmico de IDs da ferramenta **Open Source RustDesk**, integrando contas do **Active Directory (AD)** e gerando um painel web interativo com checagem de status de rede em tempo real (**ICMP Ping**).

---

## 🚀 Sobre o Projeto & Desafio Resolvido

O **RustDesk** é uma das melhores alternativas *Open Source* e *Self-Hosted* para suporte remoto corporativo. Contudo, em ambientes enterprise com trocas frequentes de turnos e múltiplos usuários compartilhando as mesmas estações de trabalho (como em ilhas de edição, emissoras de TV, rádios e operação), rastrear **qual ID do RustDesk pertence a qual computador e usuário ativo** pode ser um grande gargalo operacional.

### 💡 A Solução (v1.0):
Esta automação elimina a necessidade de planilhas manuais ou consultas individuais, implementando:
1. **Coleta Automática via GPO:** Toda vez que um colaborador faz logon no domínio, um script em PowerShell coleta as credenciais da sessão, a OU/Setor e o ID do RustDesk local, registrando em um repositório centralizado.
2. **Dashboard Web Interativo:** Um script no servidor processa os registros, executa testes de conectividade (*Ping*) em tempo real e compila um painel HTML moderno com busca instantânea e disparo direto do cliente remoto em 1 clique (`rustdesk://`).

---

## 🏗️ Arquitetura da Solução

```text
 [ Computador do Usuário ]
           │
           ▼ (Logon do Usuário via GPO)
 [ Script: Coletar-RustDesk.ps1 ] 
           │
           ▼ (Grava registro .txt)
 [ Repositório Central / Share de Dados ] 
           │
           ▼ (Execução Periódica / Task Scheduler)
 [ Script Servidor: Gerar-Painel.ps1 ] ──► (Validação ICMP / Ping em Tempo Real)
           │
           ▼ (Gera HTML Dinâmico)
 [ 🌐 Painel Web da Equipe de TI ] ──► (Conectar via rustdesk://ID)
```

---

## 🔍 Funcionalidades & Destaques

- 🔓 **100% Open Source Architecture:** Baseado na infraestrutura do RustDesk sem custo de licenciamento.
- 👥 **Mapeamento Multi-usuário:** Preserva o histórico de todos os colaboradores que utilizam a mesma máquina, garantindo auditabilidade.
- 🟢 **Status em Tempo Real (Live Ping):** Indicador visual (*Online* / *Offline*) atualizado automaticamente a cada ciclo do gerador.
- 🔍 **Busca & Filtros Dinâmicos:** Filtro instantâneo em JavaScript por Nome da Máquina, Usuário, ID ou Setor/OU.
- ⚡ **Acesso em 1 Clique:** Integração nativa com a URI Protocol (`rustdesk://[ID]`), disparando o acesso remoto direto no aplicativo do técnico.
- 🗂️ **Zero Banco de Dados (v1.0):** Arquitetura ultraleve baseada em arquivos e execução nativa em PowerShell.

---

## 💻 Tech Stack

| Categoria | Tecnologia |
| :--- | :--- |
| **Acesso Remoto** | RustDesk (Open Source Remote Desktop) |
| **Automação & Scripting** | PowerShell 5.1+ / Active Directory Module |
| **Gerenciamento de Política** | Group Policy Objects (GPO) |
| **Frontend / Dashboard** | HTML5, CSS3 Moderno, JavaScript (Vanilla) |
| **Protocolos de Rede** | ICMP (Ping), SMB/CIFS, Custom URI Scheme (`rustdesk://`) |

---

## 🛠️ Estrutura do Repositório

```text
rustdesk-ad-mapping-panel/
│
├── 📜 README.md
├── 📂 gpo/
│   └── 📜 Coletar-RustDesk.ps1     # Script executado no logon do usuário (GPO)
└── 📂 server/
    └── 📜 Gerar-Painel.ps1         # Script do servidor (Ping + Gerador HTML)
```

---

## 🗺️ Evolução e Roadmap (v2.0)

Como esta é a **primeira versão (v1.0)** em formato de scripts operacionais, a próxima fase do projeto prevê a migração para uma arquitetura moderna de microsserviços:

- [ ] **Backend em Python (FastAPI):** Substituição do gerador estático por uma API REST em Python.
- [ ] **Frontend em React + Tailwind CSS:** Interface em modo escuro (*Dark Glossy*) com gráficos de uso por departamento.
- [ ] **WebSockets / Server-Sent Events:** Atualização do status de ping em tempo real sem necessidade de re-renderizar o arquivo HTML.
- [ ] **Notificações Automáticas:** Bot de integração com WPP para alertas de novas máquinas na rede.

---

## 👨‍💻 Autor

**Thiago Soutelo**  
*Infrastructure Analyst | Observability | Cloud & DevOps*  
📍 Manaus, AM — Brasil  
🔗 [LinkedIn](https://linkedin.com/in/thiagosoutelo) | [GitHub](https://github.com/Caydenyx) | 📧 soutelothiago@gmail.com
