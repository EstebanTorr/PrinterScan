$ErrorActionPreference = "Continue"

Clear-Host
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "    IDENTIFICADOR DE IMPRESORAS - ACCESO DESDE CELULAR    " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# Detener procesos previos si existen
Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 1. Iniciar servidor local en el puerto 8080
$serverScript = Join-Path $PSScriptRoot "servidor.ps1"
$serverJob = Start-Job -FilePath $serverScript -ArgumentList 8080

Write-Host "[1/2] Servidor local iniciado correctamente." -ForegroundColor Green
Write-Host "[2/2] Generando enlace HTTPS seguro para el celular..." -ForegroundColor Yellow

$logFile = Join-Path $PSScriptRoot "tunnel.log"
if (Test-Path $logFile) { Remove-Item $logFile -Force }

$cloudflared = Join-Path $PSScriptRoot "cloudflared.exe"
$tunnelProc = Start-Process -FilePath $cloudflared -ArgumentList "--logfile `"$logFile`" tunnel --url http://127.0.0.1:8080" -PassThru -WindowStyle Hidden

$url = $null
$timeout = 0

while (-not $url -and $timeout -lt 30) {
    Start-Sleep -Seconds 1
    $timeout++
    if (Test-Path $logFile) {
        $content = Get-Content $logFile -Raw -ErrorAction SilentlyContinue
        if ($content -match "(https://[a-zA-Z0-9-]+\.trycloudflare\.com)") {
            $url = $matches[1]
            break
        }
    }
}

if ($url) {
    Set-Content -Path (Join-Path $PSScriptRoot "ENLACE_CELULAR.txt") -Value $url

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host " LISTO! ABRE ESTE ENLACE EN EL NAVEGADOR DE TU CELULAR:   " -ForegroundColor Yellow
    Write-Host ""
    Write-Host "    $url" -ForegroundColor Magenta
    Write-Host ""
    Write-Host " (Tiene HTTPS, por lo que la camara funcionara de inmediato)" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tip: Puedes copiar el enlace y enviartelo por WhatsApp Web para abrirlo directo en tu celular." -ForegroundColor White
    Write-Host ""
    Write-Host "El enlace tambien se guardo en el archivo: ENLACE_CELULAR.txt" -ForegroundColor Gray
    Write-Host ""
    Write-Host ">> Manten esta ventana ABIERTA mientras uses la pagina en tu celular <<" -ForegroundColor Red
    Write-Host "   (Para salir, simplemente cierra esta ventana)" -ForegroundColor Gray

    # Mantener vivo
    while (-not $tunnelProc.HasExited) {
        Start-Sleep -Seconds 5
    }
} else {
    Write-Host ""
    Write-Host "No se pudo obtener el enlace en el tiempo esperado." -ForegroundColor Red
    Write-Host "Revisa tu conexion a internet o el archivo tunnel.log." -ForegroundColor Red
}

Stop-Job $serverJob -ErrorAction SilentlyContinue
Remove-Job $serverJob -ErrorAction SilentlyContinue
Stop-Process -Id $tunnelProc.Id -Force -ErrorAction SilentlyContinue
