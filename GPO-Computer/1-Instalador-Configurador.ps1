# =========================================================================
# SCRIPT 1: INSTALADOR, CONFIGURADOR E EXTRATOR DE ID (GPO DE COMPUTADOR - BOOT)
# =========================================================================

# --- [ BLOCO DE CONFIGURAÇÃO - ALTERE AQUI ] ---
$PastaRedeInstalador = "\\SERVIDOR\Compartilhamento\Instalador"
$ServidorRustDesk    = "remote.seudominio.com.br"
$ChavePublica        = "SUA_CHAVE_PUBLICA_AQUI"
$SenhaFixaAcesso     = "SuaSenhaForte@123"
# -----------------------------------------------

$ExePath = "C:\Program Files\RustDesk\rustdesk.exe"
$TempInstaller = "C:\Windows\Temp\Instalador_RustDesk.exe"
$CaminhoDestinoID = "C:\ProgramData\RustDeskID.txt"

# 1. LIMPEZA DE CACHE E INSTALAÇÃO
if (Test-Path $ExePath) {
    Stop-Service -Name "RustDesk" -Force -ErrorAction SilentlyContinue
    $PathData = "C:\ProgramData\RustDesk"
    $PathSys  = "C:\Windows\System32\config\systemprofile\AppData\Roaming\RustDesk"
    
    if (Test-Path "$PathData\config") { Remove-Item -Path "$PathData\config\*" -Force -Recurse -ErrorAction SilentlyContinue }
    if (Test-Path "$PathSys\config")  { Remove-Item -Path "$PathSys\config\*" -Force -Recurse -ErrorAction SilentlyContinue }
    Start-Service -Name "RustDesk" -ErrorAction SilentlyContinue
} else {
    try {
        $Executavel = Get-ChildItem -LiteralPath $PastaRedeInstalador -Filter "*.exe" | Select-Object -First 1
        if ($Executavel) {
            Copy-Item -LiteralPath $Executavel.FullName -Destination $TempInstaller -Force
            Start-Process -FilePath $TempInstaller -ArgumentList "--silent-install" -Wait -WindowStyle Hidden
            Start-Sleep -Seconds 5
            Remove-Item -Path $TempInstaller -Force
        }
    } catch {
        $_.Exception.Message | Out-File -FilePath "C:\ProgramData\erro_rustdesk_install.txt" -Force
    }
}

# 2. INJEÇÃO DE CONFIGURAÇÕES E EXPORTAÇÃO DE ID
if (Test-Path $ExePath) {
    try {
        # Configura Servidor e Chave
        $ConfigArgs = "--config host=$ServidorRustDesk,key=$ChavePublica"
        Start-Process -FilePath $ExePath -ArgumentList $ConfigArgs -Wait -WindowStyle Hidden
        
        # Configura Senha Fixa
        & $ExePath --password $SenhaFixaAcesso
        Start-Sleep -Seconds 3

        # Exporta ID limpo para o C:\ProgramData
        $RawID = & $ExePath --get-id 2>$null
        if ($RawID) {
            $CleanID = $RawID.Trim()
            [System.IO.File]::WriteAllText($CaminhoDestinoID, $CleanID, [System.Text.Encoding]::UTF8)
        }
    } catch {
        $_.Exception.Message | Out-File -FilePath "C:\ProgramData\erro_rustdesk_config.txt" -Force
    }
}
