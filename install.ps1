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
  $ReleaseUrl = "https://github.com/$ReleaseRepo/releases/latest/download/adamai-local-beta.tgz"
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
$growthDir = Join-Path $InstallDir "command-hub/public/data/growth"
if (Test-Path $growthDir) {
  Remove-Item $growthDir -Recurse -Force
}
tar -xzf $tmp -C $InstallDir --strip-components=1
Remove-Item $tmp -Force

Set-Location $InstallDir
npm run install:local -- --yes --profile=$InstallProfile
if ($LASTEXITCODE -ne 0) {
  throw "AdamAI install failed"
}

npm run runtime:protect -- --force
if ($LASTEXITCODE -ne 0) {
  throw "AdamAI runtime protection failed"
}

$trustScript = @'
const crypto = require("crypto");
const fs = require("fs");
const os = require("os");
const path = require("path");

const target = path.resolve(process.cwd());
const manifest = path.join(target, "ADAMAI-RUNTIME-MANIFEST.json");
if (!fs.existsSync(manifest)) process.exit(0);

const sha256File = (file) => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
const id = crypto.createHash("sha256").update(target).digest("hex").slice(0, 24);
const stateFile = path.join(os.homedir(), ".adamai", "installations", `${id}.json`);
fs.mkdirSync(path.dirname(stateFile), { recursive: true });
fs.writeFileSync(stateFile, `${JSON.stringify({
  target,
  manifest: "ADAMAI-RUNTIME-MANIFEST.json",
  manifest_sha256: sha256File(manifest),
  recorded_at: new Date().toISOString(),
  cli_version: "direct-installer",
}, null, 2)}\n`, { mode: 0o600 });
'@

node -e $trustScript
if ($LASTEXITCODE -ne 0) {
  throw "Failed to write AdamAI runtime trust record"
}

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
