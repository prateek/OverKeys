### CI-specific Windows build script
### This script builds the Flutter Windows app and stages files for InnoSetup compilation
### It accepts parameters for flexible CI usage

param(
    [Parameter(Mandatory=$true)]
    [string]$StagingPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$UseFvm = $false
)

Write-Host "🔨 Building Flutter Windows application..." -ForegroundColor Cyan

# Navigate to project root (scripts/ci -> scripts -> project root)
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
Set-Location $projectRoot

# Determine Flutter command
$flutterCmd = if ($UseFvm) { "fvm flutter" } else { "flutter" }

# Clean and build
Write-Host "🧹 Cleaning previous build..." -ForegroundColor Yellow
& $flutterCmd clean

Write-Host "📦 Getting dependencies..." -ForegroundColor Yellow
& $flutterCmd pub get

Write-Host "🏗️ Building Windows release..." -ForegroundColor Yellow
& $flutterCmd build windows

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Flutter build failed with exit code $LASTEXITCODE" -ForegroundColor Red
    exit $LASTEXITCODE
}

# Stage files for InnoSetup
Write-Host "📁 Staging files to $StagingPath..." -ForegroundColor Yellow

Remove-Item $StagingPath -Force -Recurse -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $StagingPath | Out-Null

# Verify build output exists
$buildPath = Join-Path $projectRoot "build\windows\x64\runner\Release"
if (-not (Test-Path $buildPath)) {
    Write-Host "❌ Build output folder does not exist: $buildPath" -ForegroundColor Red
    exit 1
}

Write-Host "📂 Build output found at: $buildPath" -ForegroundColor Green

# Use absolute paths from project root
Copy-Item -Path "$buildPath\*" -Destination $StagingPath -Recurse
Copy-Item -Path (Join-Path $projectRoot "assets\images\app_icon.ico") -Destination $StagingPath
Copy-Item -Path (Join-Path $projectRoot "LICENSE") -Destination $StagingPath
Copy-Item -Path (Join-Path $projectRoot "scripts\x64\*.dll") -Destination $StagingPath

Write-Host "✅ Build completed successfully!" -ForegroundColor Green
Write-Host "📂 Files staged at: $StagingPath" -ForegroundColor Green
