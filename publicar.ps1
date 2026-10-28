# publicar.ps1
# Publica el Proyecto Integrador en GitHub.
# Requisitos: Git instalado y una cuenta de GitHub con acceso al repositorio NeruTrash.
# Uso: clic derecho > "Ejecutar con PowerShell", o desde una terminal:
#      powershell -ExecutionPolicy Bypass -File .\publicar.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$repo = "https://github.com/NeruTrash/base-datos-integrador-veterinaria.git"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Git no esta instalado. Instalalo con:" -ForegroundColor Yellow
    Write-Host "  winget install --id Git.Git -e --source winget" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path ".git")) {
    git init | Out-Null
    git branch -M main
}

git add .
git -c user.name="NeruTrash" -c user.email="NeruTrash@users.noreply.github.com" commit -m "Proyecto integrador Base de Datos I - sistema de gestion veterinaria" 2>$null

if (-not (git remote | Select-String -Quiet "^origin$")) {
    git remote add origin $repo
} else {
    git remote set-url origin $repo
}

git push -u origin main

Write-Host ""
Write-Host "Listo. Verifica el contenido en:" -ForegroundColor Green
Write-Host "  https://github.com/NeruTrash/base-datos-integrador-veterinaria" -ForegroundColor Green
