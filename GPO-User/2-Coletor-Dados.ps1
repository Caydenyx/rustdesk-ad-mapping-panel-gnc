# =========================================================================
# SCRIPT 2: COLETOR DE DADOS INTEGRADO (GPO DE USUÁRIO - LOGON)
# =========================================================================

# --- [ BLOCO DE CONFIGURAÇÃO - ALTERE AQUI ] ---
$PastaDadosRede = "\\SERVIDOR\Compartilhamento\Dados"
# -----------------------------------------------

$Computador = $env:COMPUTERNAME
$UsuarioLogado = $env:USERNAME

# 1. Captura a OU (Setor) do usuário logado do AD
$DN = whoami /fqdn
$Setor = "Desconhecido"
if ($DN -match "OU=([^,]+)") {
    $Setor = $matches[1]
}

# 2. Resgata o ID gerado pelo Script de Computador
$CaminhoID = "C:\ProgramData\RustDeskID.txt"
$ID_RustDesk = ""

if (Test-Path $CaminhoID) {
    $Conteudo = Get-Content $CaminhoID -Raw
    if ($Conteudo) { $ID_RustDesk = $Conteudo.Trim() }
}

if ([string]::IsNullOrEmpty($ID_RustDesk) -or $ID_RustDesk -eq "Aguardando_Sincronizacao") {
    $RustDeskExe = "C:\Program Files\RustDesk\rustdesk.exe"
    if (Test-Path $RustDeskExe) {
        $RawID = & $RustDeskExe --get-id 2>$null
        if ($RawID) { $ID_RustDesk = $RawID.Trim() }
    }
}

if ([string]::IsNullOrEmpty($ID_RustDesk)) {
    $ID_RustDesk = "Aguardando_Sincronizacao"
}

$DataHora = Get-Date -Format "dd/MM/yyyy HH:mm"

# 3. Salva no formato COMPUTADOR_USUARIO para lidar com revezamento
$LinhaDados = "$Computador;$UsuarioLogado;$Setor;$ID_RustDesk;$DataHora"
$ArquivoDestino = "$PastaDadosRede\${Computador}_${UsuarioLogado}.txt"

try {
    # Testa se o caminho da rede existe antes de gravar
    if (-not (Test-Path $PastaDadosRede)) { New-Item -ItemType Directory -Force -Path $PastaDadosRede | Out-Null }
    [System.IO.File]::WriteAllText($ArquivoDestino, $LinhaDados, [System.Text.Encoding]::UTF8)
} catch {
    $LinhaDados | Out-File -LiteralPath $ArquivoDestino -Encoding UTF8 -Force
}
