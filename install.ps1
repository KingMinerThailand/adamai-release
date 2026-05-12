param(
  [string]$ReleaseUrl = $env:ADAMAI_RELEASE_URL,
  [string]$ReleaseRepo = $env:ADAMAI_RELEASE_REPO,
  [string]$InstallDir = $env:ADAMAI_INSTALL_DIR,
  [string]$InstallProfile = $env:ADAMAI_INSTALL_PROFILE
)

$ErrorActionPreference = "Stop"

if (-not $ReleaseRepo) {
  $ReleaseRepo = "KingMinerThailand/adamai-release"
}
if (-not $ReleaseUrl) {
  $ReleaseUrl = "https://raw.githubusercontent.com/$ReleaseRepo/main/adamai-local-beta.tgz"
}
if (-not $InstallDir) {
  $InstallDir = Join-Path $HOME "AdamAI"
}
if (-not $InstallProfile) {
  $InstallProfile = "starter"
}

foreach ($cmd in @("node", "npm", "tar")) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Missing dependency: $cmd"
  }
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("adamai-local-beta-" + [System.Guid]::NewGuid() + ".tgz")

Write-Host "AdamAI installer"
Write-Host "Release: $ReleaseUrl"
Write-Host "Repo:    $ReleaseRepo"
Write-Host "Target:  $InstallDir"
Write-Host "Profile: $InstallProfile"
Write-Host ""

Invoke-WebRequest -Uri $ReleaseUrl -OutFile $tmp
tar -xzf $tmp -C $InstallDir --strip-components=1
Remove-Item $tmp -Force

Set-Location $InstallDir
npm run install:local -- --yes --profile=$InstallProfile

Write-Host ""
Write-Host "Running AdamAI doctor..."
npm run doctor
if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "Doctor found issues to review. AdamAI was installed; rerun 'npm run doctor' after fixing prerequisites."
}

Write-Host ""
Write-Host "AdamAI installed."
Write-Host "Start with: cd `"$InstallDir`"; npm run start:local"
Write-Host "Open Hub:   http://127.0.0.1:3200"
if ($InstallProfile -eq "automation") {
  Write-Host "Open n8n:   http://127.0.0.1:5678 or http://127.0.0.1:3200/n8n"
}
