# יוצר מפתח חתימה מקומי לחנות (לא להעלות ל-git)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$ktCandidates = @(
  "$env:JAVA_HOME\bin\keytool.exe",
  "C:\Program Files\Eclipse Adoptium\jdk-17.0.20.8-hotspot\bin\keytool.exe",
  "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
)
$kt = $ktCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $kt) { throw "keytool not found. Install JDK 17 first." }

New-Item -ItemType Directory -Force -Path "$root\keystore" | Out-Null
$jks = "$root\keystore\anchor-night-upload.jks"
if (Test-Path $jks) {
  Write-Host "Keystore already exists: $jks"
  exit 0
}

$pass = Read-Host "Enter keystore password (save it securely)"
& $kt -genkeypair -v `
  -keystore $jks `
  -keyalg RSA -keysize 2048 -validity 10000 `
  -alias anchor_night `
  -storepass $pass -keypass $pass `
  -dname "CN=AnchorNight, OU=Mobile, O=AnchorNight, L=TelAviv, S=Israel, C=IL"

@"
storePassword=$pass
keyPassword=$pass
keyAlias=anchor_night
storeFile=../../keystore/anchor-night-upload.jks
"@ | Set-Content "$root\android\key.properties" -Encoding ASCII

Write-Host "Created:"
Write-Host " - $jks"
Write-Host " - $root\android\key.properties"
Write-Host "Keep the password safe. Do not commit these files."
