# Creates the Play upload key for "Kac Gun Oldu?" and android/key.properties.
#
# Run once, from the project root, in PowerShell:
#     powershell -ExecutionPolicy Bypass -File tool\create_upload_key.ps1
#
# You choose the password; it is written only to android\key.properties, which
# is git-ignored, as is the .jks file. KEEP BOTH SAFE AND BACKED UP (a password
# manager, an encrypted drive): every future update of the app must be signed
# with this same key. With Play App Signing Google holds the real app signing
# key, and a lost upload key can be reset through Play Console support - but
# that takes days.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$keystoreDir = Join-Path $env:USERPROFILE 'keys'
$keystore = Join-Path $keystoreDir 'kacgunoldu-upload.jks'
$props = Join-Path $root 'android\key.properties'

if (Test-Path $keystore) { throw "A key already exists at $keystore - not overwriting it." }

$keytool = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
if (-not (Test-Path $keytool)) { $keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' }
if (-not (Test-Path $keytool)) { throw 'keytool not found. Install Android Studio or set JAVA_HOME.' }

$secure = Read-Host 'Choose a keystore password (min. 6 characters)' -AsSecureString
$confirm = Read-Host 'Repeat the password' -AsSecureString
$pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
$pw2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($confirm))
if ($pw -ne $pw2) { throw 'The passwords do not match.' }
if ($pw.Length -lt 6) { throw 'The password must be at least 6 characters.' }

$name = Read-Host 'Your name or company, as it should appear in the certificate (e.g. EMA Labs)'

New-Item -ItemType Directory -Force $keystoreDir | Out-Null
& $keytool -genkeypair -v -keystore $keystore -storetype JKS -keyalg RSA -keysize 2048 `
    -validity 10000 -alias upload -storepass $pw -keypass $pw -dname "CN=$name, C=TR"
if ($LASTEXITCODE -ne 0) { throw 'keytool failed.' }

$storeFile = $keystore -replace '\', '/'
@"
storePassword=$pw
keyPassword=$pw
keyAlias=upload
storeFile=$storeFile
"@ | Set-Content -Encoding ascii $props

Write-Host ''
Write-Host "Upload key:     $keystore"
Write-Host "Signing config: $props"
Write-Host 'Back BOTH up now. Then build the bundle with:  flutter build appbundle --release'
