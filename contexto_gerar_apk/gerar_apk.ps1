# ==============================================================================
# Script de Compilacao do APK do ASA Connect
# ==============================================================================

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   ASA CONNECT - GERADOR AUTOMATICO DE APK          " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

$CurrentDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Detectar pasta do Flutter
$MobileDirs = @(
    (Join-Path $CurrentDir "..\src\mobile"),
    (Join-Path $CurrentDir "..\app"),
    (Join-Path $CurrentDir "..\mobile")
)

$TargetMobileDir = $null
foreach ($dir in $MobileDirs) {
    if (Test-Path (Join-Path $dir "pubspec.yaml")) {
        $TargetMobileDir = (Resolve-Path $dir).Path
        break
    }
}

if (-not $TargetMobileDir) {
    Write-Host "`n[ERRO] Nao foi possivel localizar automaticamente a pasta do app Flutter com pubspec.yaml." -ForegroundColor Red
    $TargetMobileDir = Read-Host "Por favor, digite o caminho completo da pasta 'src/mobile' ou 'app'"
    if (-not (Test-Path (Join-Path $TargetMobileDir "pubspec.yaml"))) {
        Write-Host "[ERRO] Pasta invalida. Abortando." -ForegroundColor Red
        Exit 1
    }
}

Write-Host "`nPasta do projeto Flutter detectada:" -ForegroundColor Yellow
Write-Host "-> $TargetMobileDir" -ForegroundColor White

Push-Location $TargetMobileDir

Write-Host "`n1. Verificando dependencias (flutter pub get)..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[AVISO] flutter pub get retornou codigo diferente de 0. Verifique sua conexao." -ForegroundColor Yellow
}

Write-Host "`n2. Selecione o tipo de APK desejado:" -ForegroundColor Cyan
Write-Host "[1] Release (Recomendado - otimizado e menor tamanho)"
Write-Host "[2] Debug (Rapido para testes)"
$Choice = Read-Host "Digite 1 ou 2 (Padrao: 1)"

$BuildType = "release"
if ($Choice -eq "2") {
    $BuildType = "debug"
}

Write-Host "`n3. Iniciando compilacao do APK ($BuildType)... Aguarde alguns instantes..." -ForegroundColor Cyan
if ($BuildType -eq "release") {
    flutter build apk --release
} else {
    flutter build apk --debug
}

if ($LASTEXITCODE -eq 0) {
    $ApkPath = Join-Path $TargetMobileDir "build\app\outputs\flutter-apk\app-$BuildType.apk"
    if (Test-Path $ApkPath) {
        $DestPath = Join-Path $CurrentDir "asa-connect-$BuildType.apk"
        Copy-Item -Path $ApkPath -Destination $DestPath -Force
        Write-Host "`n====================================================" -ForegroundColor Green
        Write-Host "   APK GERADO COM SUCESSO!                          " -ForegroundColor Green
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host "O arquivo pronto foi copiado para:" -ForegroundColor White
        Write-Host "-> $DestPath" -ForegroundColor Yellow
    } else {
        Write-Host "[SUCESSO] Build concluido, mas o arquivo nao foi encontrado no caminho padrao: $ApkPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n[ERRO] A compilacao falhou. Verifique se o Android SDK esta configurado com 'flutter doctor -v'." -ForegroundColor Red
}

Pop-Location
Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
