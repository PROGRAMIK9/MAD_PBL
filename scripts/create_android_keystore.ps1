param(
  [Parameter(Mandatory = $false)]
  [string]$KeystorePath = (Join-Path $PSScriptRoot '..\android\app\upload-keystore.jks'),

  [Parameter(Mandatory = $false)]
  [string]$KeyAlias = 'offline_mesh_app',

  [Parameter(Mandatory = $false)]
  [string]$StorePassword,

  [Parameter(Mandatory = $false)]
  [string]$KeyPassword,

  [Parameter(Mandatory = $false)]
  [string]$ValidityDays = '10000'
)

$ErrorActionPreference = 'Stop'

function Read-SecretText {
  param([string]$Prompt)

  $secure = Read-Host -Prompt $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  }
  finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

if (-not $StorePassword) {
  $StorePassword = Read-SecretText -Prompt 'Enter keystore password'
}

if (-not $KeyPassword) {
  $KeyPassword = Read-SecretText -Prompt 'Enter key password'
}

$keystoreDir = Split-Path -Parent $KeystorePath
New-Item -ItemType Directory -Force -Path $keystoreDir | Out-Null

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
  throw 'keytool was not found in PATH. Install a JDK or Android Studio first.'
}

& $keytool.Path `
  -genkeypair `
  -v `
  -keystore $KeystorePath `
  -alias $KeyAlias `
  -keyalg RSA `
  -keysize 2048 `
  -validity $ValidityDays `
  -storepass $StorePassword `
  -keypass $KeyPassword `
  -dname 'CN=Offline Mesh, OU=Mobile, O=Offline Mesh, L=Unknown, S=Unknown, C=US'

$propertiesPath = Join-Path $PSScriptRoot '..\android\key.properties'
@"
storePassword=$StorePassword
keyPassword=$KeyPassword
keyAlias=$KeyAlias
storeFile=app/upload-keystore.jks
"@ | Set-Content -Path $propertiesPath -Encoding ASCII

Write-Host "Created keystore: $KeystorePath"
Write-Host "Wrote Android signing config: $propertiesPath"
Write-Host 'Do not commit the generated .jks or key.properties files.'
