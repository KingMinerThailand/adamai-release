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

$NodeMajor = if ($env:ADAMAI_NODE_MAJOR) { $env:ADAMAI_NODE_MAJOR } else { "24" }
$NodeHome = if ($env:ADAMAI_NODE_HOME) { $env:ADAMAI_NODE_HOME } else { Join-Path $HOME ".adamai/node-v$NodeMajor" }

function Get-NodeMajor {
  try {
    $v = node -p "Number(process.versions.node.split('.')[0])" 2>$null
    return [int]$v
  } catch {
    return 0
  }
}

function Test-WorkingNode {
  return ((Get-Command node -ErrorAction SilentlyContinue) -and
          (Get-Command npm -ErrorAction SilentlyContinue) -and
          ((Get-NodeMajor) -ge 18))
}

function Add-NodePath {
  if (-not ($env:PATH -split ';' | Where-Object { $_ -eq $NodeHome })) {
    $env:PATH = "$NodeHome;$env:PATH"
  }
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if (-not $userPath) { $userPath = "" }
  if (-not ($userPath -split ';' | Where-Object { $_ -eq $NodeHome })) {
    $newPath = if ($userPath) { "$NodeHome;$userPath" } else { $NodeHome }
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Added Node.js to the user PATH."
  }
}

function Install-PortableNode {
  $archRaw = $env:PROCESSOR_ARCHITECTURE
  if (-not $archRaw -and $IsMacOS) { $archRaw = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() }
  switch -Regex ($archRaw) {
    "ARM64|Arm64" { $arch = "arm64"; break }
    "AMD64|x64|X64" { $arch = "x64"; break }
    default { throw "Unsupported CPU for automatic Node.js install: $archRaw" }
  }

  Write-Host "Node.js 18+ was not found. Installing portable Node.js $NodeMajor LTS for AdamAI..."
  $sumsUrl = "https://nodejs.org/dist/latest-v${NodeMajor}.x/SHASUMS256.txt"
  $sums = (Invoke-WebRequest -Uri $sumsUrl).Content -split "`n"
  $line = $sums | Where-Object { $_ -match "node-v[\d.]+-win-$arch\.zip$" } | Select-Object -First 1
  if (-not $line) {
    throw "Could not find Node.js $NodeMajor LTS binary for win-$arch."
  }
  $parts = $line.Trim() -split "\s+"
  $expected = $parts[0].ToLowerInvariant()
  $fileName = $parts[1]
  $zipUrl = "https://nodejs.org/dist/latest-v${NodeMajor}.x/$fileName"
  $tmpNode = Join-Path ([System.IO.Path]::GetTempPath()) ("adamai-node-" + [System.Guid]::NewGuid())
  $zip = Join-Path $tmpNode $fileName
  $extract = Join-Path $tmpNode "extract"

  New-Item -ItemType Directory -Force -Path $tmpNode, $extract | Out-Null
  try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zip
    $actual = (Get-FileHash -Algorithm SHA256 $zip).Hash.ToLowerInvariant()
    if ($actual -ne $expected) {
      throw "Node.js download checksum mismatch."
    }

    if (Test-Path $NodeHome) {
      Remove-Item $NodeHome -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path $NodeHome | Out-Null
    Expand-Archive -Path $zip -DestinationPath $extract -Force
    $inner = Get-ChildItem $extract -Directory | Select-Object -First 1
    if (-not $inner) {
      throw "Node.js archive did not contain a runtime folder."
    }
    Copy-Item -Path (Join-Path $inner.FullName "*") -Destination $NodeHome -Recurse -Force
    Add-NodePath
    Write-Host "Installed $(node -v) at $NodeHome"
  } finally {
    if (Test-Path $tmpNode) {
      Remove-Item $tmpNode -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
}

function Ensure-Node {
  if (Test-WorkingNode) {
    Write-Host "Using Node.js $(node -v) and npm $(npm -v)"
    return
  }
  Install-PortableNode
  if (-not (Test-WorkingNode)) {
    throw "Node.js install did not produce a working node/npm command."
  }
}

Ensure-Node

foreach ($cmd in @("tar")) {
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
if (Test-Path $NodeHome) {
  Write-Host "Node path:  $NodeHome"
}
Write-Host "Open Hub:   http://127.0.0.1:3200"
if ($InstallProfile -eq "automation") {
  Write-Host "Open n8n:   http://127.0.0.1:5678 or http://127.0.0.1:3200/n8n"
}
