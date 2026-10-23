<#
.SYNOPSIS
    Build VocabFlip Windows + Android + Web release.

.DESCRIPTION
    - Update version in pubspec.yaml
    - Build Windows release (ZIP), Android release (APK), and/or Web release
    - Package Windows/Android output into build/release/
    - Copy Web build to ../../alpha-studio/public/vocab

.PARAMETER Version
    Version string (e.g. "1.2.5" or "v1.2.5").

.PARAMETER Targets
    Comma-separated build targets: "windows", "android", "web" (default: "windows,android,web").

.PARAMETER SkipVersionUpdate
    Skip updating version in pubspec.yaml.
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$Targets = "windows,android,web",

    [switch]$SkipVersionUpdate
)

$ErrorActionPreference = "Stop"

# --- Helpers ---

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# --- Resolve paths ---

$ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))

if (-not (Test-Path (Join-Path $ProjectRoot "pubspec.yaml"))) {
    $ProjectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}

if (-not (Test-Path (Join-Path $ProjectRoot "pubspec.yaml"))) {
    $ProjectRoot = Get-Location
}

if (-not (Test-Path (Join-Path $ProjectRoot "pubspec.yaml"))) {
    Write-Err "Could not find pubspec.yaml. Please run script from project root."
    exit 1
}

Set-Location $ProjectRoot

# --- Parse version ---

$SemVer = $Version -replace '^v', ''
$TagVersion = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }

# Parse build number from existing pubspec
$PubspecPath = Join-Path $ProjectRoot "pubspec.yaml"
$PubspecContent = Get-Content $PubspecPath -Raw -Encoding UTF8

if ($PubspecContent -match 'version:\s*(\S+)\+(\d+)') {
    $OldVersion = $Matches[1]
    $OldBuildNumber = [int]$Matches[2]
} else {
    $OldVersion = "0.0.0"
    $OldBuildNumber = 0
}

$NewBuildNumber = $OldBuildNumber + 1

Write-Host "Project root : $ProjectRoot"
Write-Host "Old version  : $OldVersion+$OldBuildNumber"
Write-Host "New version  : $SemVer+$NewBuildNumber"
Write-Host "Tag          : $TagVersion"
Write-Host "Targets      : $Targets"

# --- Update pubspec.yaml ---

if (-not $SkipVersionUpdate) {
    Write-Step "Updating version in pubspec.yaml"

    $NewPubspec = $PubspecContent -replace 'version:\s*\S+\+\d+', "version: $SemVer+$NewBuildNumber"
    Set-Content -Path $PubspecPath -Value $NewPubspec -NoNewline -Encoding UTF8
    Write-Success "pubspec.yaml -> version: $SemVer+$NewBuildNumber"
}

# --- Parse targets ---

$TargetList = $Targets.Split(',') | ForEach-Object { $_.Trim().ToLower() }
$NeedsReleaseDir = ($TargetList -contains "windows") -or ($TargetList -contains "android") -or ($TargetList -contains "apk")

# --- Prepare output dir ---

$ReleaseDir = Join-Path $ProjectRoot "build\release"
if ($NeedsReleaseDir) {
    if (Test-Path $ReleaseDir) {
        Remove-Item $ReleaseDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $ReleaseDir -Force | Out-Null
    Write-Success "Output dir: $ReleaseDir"
}

# --- Build Windows ---

if ($TargetList -contains "windows") {
    Write-Step "Building Windows (release)"

    & cmd /c "flutter build windows --release"
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Flutter build windows failed!"
        exit 1
    }

    $WinBuildDir = Join-Path $ProjectRoot "build\windows\x64\runner\Release"
    if (-not (Test-Path $WinBuildDir)) {
        $WinBuildDir = Join-Path $ProjectRoot "build\windows\runner\Release"
    }

    if (-not (Test-Path $WinBuildDir)) {
        Write-Err "Windows build output not found!"
        exit 1
    }

    # Ten chua 'windows' va ket thuc bang '.zip' de AppVersion.fromJson() va backend nhan dien.
    $ZipDest = Join-Path $ReleaseDir "vocabflip-windows-v$SemVer.zip"
    Write-Step "Compressing Windows -> ZIP"

    Compress-Archive -Path "$WinBuildDir\*" -DestinationPath $ZipDest -Force
    $ZipSize = [math]::Round((Get-Item $ZipDest).Length / 1MB, 2)
    Write-Success "Windows ZIP: $ZipDest ($ZipSize MB)"
}

# --- Build Android ---

if (($TargetList -contains "android") -or ($TargetList -contains "apk")) {
    Write-Step "Building Android (release APK)"

    & cmd /c "flutter build apk --release"
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Flutter build apk failed!"
        exit 1
    }

    $ApkSrc = Join-Path $ProjectRoot "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $ApkSrc)) {
        Write-Err "APK output not found at $ApkSrc"
        exit 1
    }

    # Ten ket thuc bang .apk de AppVersion.fromJson() va backend nhan dien.
    $ApkDest = Join-Path $ReleaseDir "vocabflip-v$SemVer.apk"
    Copy-Item $ApkSrc $ApkDest -Force
    $ApkSize = [math]::Round((Get-Item $ApkDest).Length / 1MB, 2)
    Write-Success "Android APK: $ApkDest ($ApkSize MB)"
}

# --- Build Web ---

if ($TargetList -contains "web") {
    Write-Step "Building Web (release, base-href /vocab/)"

    & cmd /c "flutter build web --release --base-href `"/vocab/`""
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Flutter build web failed!"
        exit 1
    }

    $WebBuildDir = Join-Path $ProjectRoot "build\web"
    if (-not (Test-Path $WebBuildDir)) {
        Write-Err "Web build output not found at $WebBuildDir"
        exit 1
    }

    $FrontendRoot = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot "..\..\alpha-studio"))
    if (Test-Path $FrontendRoot) {
        $PublicVocabDir = Join-Path $FrontendRoot "public\vocab"
        Write-Step "Copying Web build -> $PublicVocabDir"
        if (Test-Path $PublicVocabDir) {
            Remove-Item $PublicVocabDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $PublicVocabDir -Force | Out-Null
        Copy-Item -Path "$WebBuildDir\*" -Destination $PublicVocabDir -Recurse -Force
        Write-Success "Web build copied to: $PublicVocabDir"
    } else {
        Write-Host "[WARN] Frontend repo not found at $FrontendRoot - Web build remains at $WebBuildDir" -ForegroundColor Yellow
    }
}

# --- Summary ---

Write-Step "Build completed!"

if (Test-Path $ReleaseDir) {
    $Artifacts = Get-ChildItem $ReleaseDir -File
    if ($Artifacts.Count -gt 0) {
        Write-Host "Artifacts in build/release/:" -ForegroundColor Yellow
        foreach ($f in $Artifacts) {
            $Size = [math]::Round($f.Length / 1MB, 2)
            Write-Host "  - $($f.Name)  ($Size MB)"
        }
    }
}

if ($TargetList -contains "web") {
    Write-Host "Web bundle:" -ForegroundColor Yellow
    Write-Host "  - alpha-studio/public/vocab (remember to commit & push in alpha-studio repo for Vercel deploy)"
}

Write-Host ""
Write-Host "Next step: run release.ps1 to publish to GitHub Release + Backblaze B2." -ForegroundColor Cyan
