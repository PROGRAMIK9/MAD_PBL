param(
  [string]$FlutterPath = 'C:\src\flutter\bin\flutter.bat',
  [string]$ProjectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'

Set-Location $ProjectPath
& $FlutterPath build windows --release

$releaseDir = Join-Path $ProjectPath 'build\windows\x64\runner\Release'
$installerDir = Join-Path $ProjectPath 'build\windows\installer'
New-Item -ItemType Directory -Force -Path $installerDir | Out-Null

$zipPath = Join-Path $installerDir 'offline_mesh_app-windows-portable.zip'
if (Test-Path $zipPath) {
  Remove-Item $zipPath -Force
}

Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $zipPath -Force
Write-Host "Created portable Windows installer package: $zipPath"

$issPath = Join-Path $ProjectPath 'windows\installer\offline_mesh_app.iss'
if (Test-Path $issPath) {
  Write-Host 'Inno Setup script ready at windows\\installer\\offline_mesh_app.iss'
}
