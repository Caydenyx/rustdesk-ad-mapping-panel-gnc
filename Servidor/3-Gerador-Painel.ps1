# =========================================================================
# SCRIPT 3: GERADOR DO PAINEL WEB DO RUSTDESK (COM DARK MODE & PING)
# =========================================================================

# --- [ BLOCO DE CONFIGURAÇÃO - ALTERE AQUI ] ---
$PastaDados   = "\\SEU-SERVIDOR\SHARE\Dados"
$CaminhoHtml  = "\\SEU-SERVIDOR\SHARE\painel.html"
$TituloPainel = "Painel de Controle - RustDesk AD"
# -----------------------------------------------

# Cabeçalho do HTML com CSS Suportando Modo Claro e Escuro
$HtmlHeader = @"
<!DOCTYPE html>
<html lang="pt-BR" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>$TituloPainel</title>
    <style>
        :root[data-theme="dark"] {
            --bg-body: #0f172a;
            --bg-card: #1e293b;
            --text-main: #f8fafc;
            --text-muted: #94a3b8;
            --border-color: #334155;
            --th-bg: #1e3a8a;
            --th-text: #ffffff;
            --row-hover: #334155;
            --input-bg: #0f172a;
        }

        :root[data-theme="light"] {
            --bg-body: #f4f6f9;
            --bg-card: #ffffff;
            --text-main: #333333;
            --text-muted: #4b5563;
            --border-color: #cbd5e1;
            --th-bg: #1e3a8a;
            --th-text: #ffffff;
            --row-hover: #f1f5f9;
            --input-bg: #ffffff;
        }

        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: var(--bg-body); color: var(--text-main); margin: 20px; transition: background-color 0.3s, color 0.3s; }
        
        .header-container { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--th-bg); padding-bottom: 10px; margin-bottom: 15px; }
        h1 { color: var(--text-main); margin: 0; font-size: 24px; }
        
        .theme-toggle-btn { background: var(--bg-card); color: var(--text-main); border: 1px solid var(--border-color); padding: 8px 14px; border-radius: 6px; cursor: pointer; font-weight: 600; transition: 0.2s; }
        .theme-toggle-btn:hover { border-color: #2563eb; }

        .painel-controles { display: flex; flex-wrap: wrap; gap: 15px; align-items: center; justify-content: space-between; margin-bottom: 20px; padding: 15px; background: var(--bg-card); border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); border: 1px solid var(--border-color); }
        .info-status { font-size: 14px; color: var(--text-muted); }
        .filtros-box { display: flex; gap: 10px; flex-wrap: wrap; }
        .input-busca, .select-filtro { padding: 8px 12px; background-color: var(--input-bg); color: var(--text-main); border: 1px solid var(--border-color); border-radius: 6px; font-size: 14px; outline: none; transition: border-color 0.2s; }
        .input-busca:focus, .select-filtro:focus { border-color: #2563eb; }
        .input-busca { width: 260px; }

        table { width: 100%; border-collapse: collapse; background: var(--bg-card); border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.1); border: 1px solid var(--border-color); }
        th { background-color: var(--th-bg); color: var(--th-text); padding: 12px 15px; text-align: left; font-weight: 600; }
        td { padding: 10px 15px; border-bottom: 1px solid var(--border-color); font-size: 14px; color: var(--text-main); }
        tr:hover { background-color: var(--row-hover); }

        .status-badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
        .status-ok { background-color: #065f46; color: #d1fae5; }
        .status-wait { background-color: #92400e; color: #fef3c7; }
        .btn-conectar { background-color: #2563eb; color: white; padding: 6px 12px; text-decoration: none; border-radius: 4px; font-size: 13px; font-weight: 500; display: inline-block; transition: background-color 0.2s; }
        .btn-conectar:hover { background-color: #1d4ed8; }
        .linha-oculta { display: none !important; }

        .dot { height: 10px; width: 10px; border-radius: 50%; display: inline-block; margin-right: 8px; vertical-align: middle; }
        .dot-online { background-color: #22c55e; box-shadow: 0 0 6px #22c55e; }
        .dot-offline { background-color: #ef4444; opacity: 0.8; }
    </style>
</head>
<body>
    <div class="header-container">
        <h1>$TituloPainel</h1>
        <button class="theme-toggle-btn" id="btnTheme" onclick="alternarTema()">☀️ Modo Claro</button>
    </div>

    <div class="painel-controles">
        <div class="info-status">
            <strong>Exibindo:</strong> <span id="lblTotal">{TOTAL_MAQUINAS}</span> | 
            <strong>Sincronização:</strong> {DATA_AGORA}
        </div>
        <div class="filtros-box">
            <input type="text" id="txtBusca" class="input-busca" placeholder="🔍 Buscar PC, Usuário ou ID..." onkeyup="filtrarTabela()">
            <select id="selSetor" class="select-filtro" onchange="filtrarTabela()">
                <option value="">📁 Todos os Setores</option>
                {OPCOES_SETORES}
            </select>
        </div>
    </div>

    <table id="tabelaRustDesk">
        <thead>
            <tr>
                <th>Computador</th>
                <th>Usuário</th>
                <th>Setor / OU</th>
                <th>ID RustDesk</th>
                <th>Última Sincronização</th>
                <th>Ação</th>
            </tr>
        </thead>
        <tbody>
"@

$HtmlLines = ""
$TotalComputadores = 0
$SetoresEncontrados = [System.Collections.Generic.HashSet[string]]::new()

if (Test-Path -LiteralPath $PastaDados) {
    $Arquivos = Get-ChildItem -LiteralPath $PastaDados -Filter "*.txt"
    $TotalComputadores = $Arquivos.Count

    foreach ($Arq in $Arquivos) {
        $Conteudo = Get-Content -LiteralPath $Arq.FullName -Raw -Encoding UTF8
        if (-not [string]::IsNullOrWhiteSpace($Conteudo)) {
            $Campos = $Conteudo.Split(";")
            if ($Campos.Count -ge 5) {
                $Comp    = $Campos[0].Trim()
                $User    = $Campos[1].Trim()
                $Setor   = $Campos[2].Trim()
                $ID      = $Campos[3].Trim()
                $Sinc    = $Campos[4].Trim()

                if (-not [string]::IsNullOrWhiteSpace($Setor)) {
                    [void]$SetoresEncontrados.Add($Setor)
                }

                # -------------------------------------------------------------
                # VALIDAÇÃO DE PING (Verifica se a máquina está ligada na rede)
                # -------------------------------------------------------------
                $IsOnline = Test-Connection -ComputerName $Comp -Count 1 -Quiet -ErrorAction SilentlyContinue
                
                if ($IsOnline) {
                    $DotClass = "dot-online"
                    $StatusTooltip = "Máquina Ligada na Rede"
                } else {
                    $DotClass = "dot-offline"
                    $StatusTooltip = "Máquina Desligada ou Sem Rede"
                }

                if ($ID -eq "Aguardando_Sincronizacao" -or [string]::IsNullOrEmpty($ID)) {
                    $BadgeClass = "status-wait"
                    $ID_Exibir = "Aguardando Sincronização"
                    $AcaoBotao = "<td><span style='color: #9ca3af;'>Aguardando</span></td>"
                } else {
                    $BadgeClass = "status-ok"
                    $ID_Exibir = $ID
                    $AcaoBotao = "<td><a class='btn-conectar' href='rustdesk://$ID'>Conectar</a></td>"
                }

                $HtmlLines += @"
            <tr data-computador="$Comp" data-usuario="$User" data-setor="$Setor" data-id="$ID_Exibir">
                <td><span class="dot $DotClass" title="$StatusTooltip"></span><strong>$Comp</strong></td>
                <td>$User</td>
                <td>$Setor</td>
                <td><span class="status-badge $BadgeClass">$ID_Exibir</span></td>
                <td>$Sinc</td>
                $AcaoBotao
            </tr>
"@
            }
        }
    }
}

$OpcoesSetoresHtml = ""
foreach ($S in ($SetoresEncontrados | Sort-Object)) {
    $OpcoesSetoresHtml += "<option value=""$S"">$S</option>`n"
}

$HtmlFooter = @"
        </tbody>
    </table>

    <script>
        function filtrarTabela() {
            const busca = document.getElementById('txtBusca').value.toLowerCase().trim();
            const setorSel = document.getElementById('selSetor').value.toLowerCase().trim();
            const linhas = document.querySelectorAll('#tabelaRustDesk tbody tr');
            let visiveis = 0;

            linhas.forEach(linha => {
                const comp = (linha.getAttribute('data-computador') || '').toLowerCase();
                const user = (linha.getAttribute('data-usuario') || '').toLowerCase();
                const setor = (linha.getAttribute('data-setor') || '').toLowerCase();
                const id = (linha.getAttribute('data-id') || '').toLowerCase();

                const bateuBusca = !busca || comp.includes(busca) || user.includes(busca) || id.includes(busca) || setor.includes(busca);
                const bateuSetor = !setorSel || setor === setorSel;

                if (bateuBusca && bateuSetor) {
                    linha.classList.remove('linha-oculta');
                    visiveis++;
                } else {
                    linha.classList.add('linha-oculta');
                }
            });

            document.getElementById('lblTotal').innerText = visiveis + " de " + linhas.length + " registro(s)";
        }

        // Lógica de Alternância de Tema (Modo Escuro / Claro)
        function aplicarTema(tema) {
            document.documentElement.setAttribute('data-theme', tema);
            const btn = document.getElementById('btnTheme');
            if (tema === 'dark') {
                btn.innerHTML = '☀️ Modo Claro';
            } else {
                btn.innerHTML = '🌙 Modo Escuro';
            }
            localStorage.setItem('temaPainelRustDesk', tema);
        }

        function alternarTema() {
            const temaAtual = document.documentElement.getAttribute('data-theme');
            const novoTema = temaAtual === 'dark' ? 'light' : 'dark';
            aplicarTema(novoTema);
        }

        // Carrega o tema salvo ao abrir a página (Padrão: Dark)
        (function() {
            const temaSalvo = localStorage.getItem('temaPainelRustDesk') || 'dark';
            aplicarTema(temaSalvo);
        })();
    </script>
</body>
</html>
"@

$DataAtual = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
$HtmlHeader = $HtmlHeader.Replace("{TOTAL_MAQUINAS}", $TotalComputadores.ToString())
$HtmlHeader = $HtmlHeader.Replace("{DATA_AGORA}", $DataAtual)
$HtmlHeader = $HtmlHeader.Replace("{OPCOES_SETORES}", $OpcoesSetoresHtml)

$HtmlCompleto = $HtmlHeader + $HtmlLines + $HtmlFooter

[System.IO.File]::WriteAllText($CaminhoHtml, $HtmlCompleto, [System.Text.Encoding]::UTF8)

Write-Host "Painel atualizado com sucesso em: $CaminhoHtml" -ForegroundColor Green
