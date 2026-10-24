[CmdletBinding()]
param(
  [ValidateSet("start", "status", "logs", "stop")]
  [string]$Action = "start"
)

$ErrorActionPreference = "Stop"
$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$EnvFile = Join-Path $Root ".env.dz-smart-seller"
$ExampleFile = Join-Path $Root ".env.dz-smart-seller.example"
$BaseCompose = Join-Path $Root "docker-compose.yaml"
$Overlay = Join-Path $Root "docker-compose.dz-smart-seller.yml"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  throw "Docker was not found. Install Docker Desktop and start it, then run this script again."
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
  throw "Docker Engine is not running. Start Docker Desktop, wait until it is ready, then retry."
}

if (-not (Test-Path $ExampleFile)) { throw "Missing environment template: $ExampleFile" }
if (-not (Test-Path $BaseCompose)) { throw "Missing base Compose file: $BaseCompose" }
if (-not (Test-Path $Overlay)) { throw "Missing integration Compose file: $Overlay" }

if (-not (Test-Path $EnvFile)) {
  $Content = Get-Content -Raw -Path $ExampleFile
  $Evaluator = [System.Text.RegularExpressions.MatchEvaluator]{
    param($Match)
    [Convert]::ToHexString([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
  }
  $Content = [regex]::Replace($Content, "REPLACE_WITH_RANDOM_HEX_SECRET", $Evaluator)
  [System.IO.File]::WriteAllText(
    $EnvFile,
    $Content,
    (New-Object System.Text.UTF8Encoding($false))
  )
  Write-Host "Created private .env.dz-smart-seller with unique secrets."
  Write-Host "Keep this file private. It is excluded from Git."
}

$Compose = @(
  "compose",
  "--env-file", $EnvFile,
  "-f", $BaseCompose,
  "-f", $Overlay
)

Push-Location $Root
try {
  switch ($Action) {
    "start" {
      & docker @Compose config --quiet
      if ($LASTEXITCODE -ne 0) { throw "Compose validation failed; services were not started." }

      Write-Host "Starting DZ Smart Seller services. First run may take several minutes to download images."
      & docker @Compose up -d
      if ($LASTEXITCODE -ne 0) { throw "Docker Compose could not start all services. Check logs with: .\integrations\launch-dz-smart-seller.ps1 logs" }

      Write-Host ""
      Write-Host "Service status:"
      & docker @Compose ps
      Write-Host ""
      Write-Host "Portal:    http://localhost:3000"
      Write-Host "Postmill:  http://localhost:4007"
      Write-Host "OpenPost:  http://localhost:8080"
      Write-Host ""
      Write-Host "Facebook posting is not configured until you add your Meta app credentials and complete the setup guide."
      Write-Host "Guide: docs\DZ-SMART-SELLER-INTEGRATION.md"
    }
    "status" {
      & docker @Compose ps
      if ($LASTEXITCODE -ne 0) { throw "Could not read Compose status. Check that the environment file exists." }
      foreach ($Url in @("http://localhost:3000", "http://localhost:4007", "http://localhost:8080/api/v1/ready")) {
        try {
          $Response = Invoke-WebRequest -Uri $Url -TimeoutSec 4 -UseBasicParsing
          Write-Host "OK  $Url ($($Response.StatusCode))"
        } catch {
          Write-Host "WAIT $Url — not responding yet"
        }
      }
    }
    "logs" {
      & docker @Compose logs --tail=100 -f
    }
    "stop" {
      & docker @Compose down
      if ($LASTEXITCODE -ne 0) { throw "Could not stop the Compose stack." }
      Write-Host "Services stopped. Persistent data volumes were kept."
    }
  }
} finally {
  Pop-Location
}
