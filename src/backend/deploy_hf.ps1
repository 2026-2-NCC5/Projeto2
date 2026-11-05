param(
    [Parameter(Mandatory=$false)]
    [string]$Username,
    [Parameter(Mandatory=$false)]
    [string]$SpaceName = "asaconnect-api"
)

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   DEPLOY DO BACKEND ASA CONNECT+ NO HUGGING FACE   " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan

if (-not $Username) {
    $Username = Read-Host "Digite o seu nome de usuário no Hugging Face"
}

if (-not $Username) {
    Write-Host "Nome de usuário obrigatório!" -ForegroundColor Red
    exit 1
}

$apiDir = "$PSScriptRoot"
Set-Location $apiDir

if (-not (Test-Path ".git")) {
    Write-Host "Inicializando repositório Git na pasta api..." -ForegroundColor Green
    git init -b main
}

git add .
git commit -m "Deploy ASA Connect+ API com RAG e Docker" -q

$remoteUrl = "https://huggingface.co/spaces/$Username/$SpaceName"
Write-Host "Configurando remote para: $remoteUrl" -ForegroundColor Green

git remote remove hf 2>$null
git remote add hf $remoteUrl

Write-Host "Enviando código para o Hugging Face Spaces..." -ForegroundColor Cyan
Write-Host "DICA: Se pedir senha, utilize o seu 'Access Token' (Role: Write) gerado em huggingface.co/settings/tokens" -ForegroundColor Yellow

git push --force hf main

Write-Host "`n====================================================" -ForegroundColor Green
Write-Host "Deploy enviado com sucesso para o Hugging Face!" -ForegroundColor Green
Write-Host "1. Acompanhe a inicialização em: $remoteUrl" -ForegroundColor Cyan
Write-Host "2. A URL oficial da sua API será:" -ForegroundColor Yellow
Write-Host "   https://$Username-$SpaceName.hf.space/api/v1" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Green
