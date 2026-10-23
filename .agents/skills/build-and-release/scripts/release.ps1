<#
.SYNOPSIS
    Create GitHub Release, upload artifacts, and publish to Backblaze B2 for VocabFlip.

.DESCRIPTION
    - Read GITHUB_TOKEN from ../../alpha-studio-backend/.env (or .env.release / env)
    - Build Windows ZIP + Android APK + Web bundle (unless -SkipBuild)
    - Push current branch, create git tag and push to origin
    - Create/update GitHub Release via REST API and upload APK + Windows ZIP
    - Upload APK + Windows ZIP + version.json to Backblaze B2 (serves both in-app updater and /studio/vocab)

.PARAMETER Version
    Version/tag string (e.g. "v1.2.5" or "1.2.5").

.PARAMETER Title
    Release title on GitHub (default: "VocabFlip v<version>").

.PARAMETER Notes
    Release notes (string or path to file).

.PARAMETER Targets
    Comma-separated build targets passed to build.ps1 (default: "windows,android,web").

.PARAMETER Prerelease
    Mark release as prerelease; skip the stable B2 channel.

.PARAMETER Draft
    Create release as draft; skip the stable B2 channel.

.PARAMETER SkipBuild
    Skip build step and use existing artifacts in build/release/.

.PARAMETER SkipB2
    Skip the Backblaze B2 upload step (GitHub Release only).
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$Title = "",

    [string]$Notes = "",

    [string]$Targets = "windows,android,web",

    [switch]$Prerelease,

    [switch]$Draft,

    [switch]$SkipBuild,

    [switch]$SkipB2
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

function Read-EnvMap {
    param([string[]]$CandidatePaths)
    $Map = @{}
    foreach ($Path in $CandidatePaths) {
        if ($Path -and (Test-Path $Path -PathType Leaf)) {
            Get-Content $Path | ForEach-Object {
                if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
                    $Key = $Matches[1]
                    $Val = $Matches[2].Trim('"').Trim("'")
                    if ($Val) {
                        $Map[$Key] = $Val
                    }
                }
            }
        }
    }
    return $Map
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

$TagVersion = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
$SemVer = $Version -replace '^v', ''

# --- Read GITHUB_TOKEN ---

Write-Step "Reading GITHUB_TOKEN"

$BackendEnv = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot "..\..\alpha-studio-backend\.env"))
$ReleaseEnv = Join-Path $ProjectRoot ".env.release"
$LocalEnv   = Join-Path $ProjectRoot ".env"

$EnvVars = Read-EnvMap -CandidatePaths @($LocalEnv, $BackendEnv, $ReleaseEnv)
$Token = if ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $EnvVars['GITHUB_TOKEN'] }

if (-not $Token) {
    Write-Err "Could not find GITHUB_TOKEN in ../../alpha-studio-backend/.env, .env.release, or environment."
    Write-Host "WARNING: Do NOT put GITHUB_TOKEN in tools/vocabflip/.env because pubspec.yaml bundles .env into the app!" -ForegroundColor Red
    exit 1
}

Write-Success "GITHUB_TOKEN loaded"

# --- Detect repo ---

$RemoteUrl = git remote get-url origin 2>$null
if (-not $RemoteUrl) {
    Write-Err "Could not find git remote origin"
    exit 1
}

if ($RemoteUrl -match 'github\.com[:/]([^/]+)/([^/.]+?)(?:\.git)?$') {
    $Owner = $Matches[1]
    $Repo = $Matches[2]
} else {
    Write-Err "Could not parse owner/repo from remote URL: $RemoteUrl"
    exit 1
}

Write-Host "Repository: $Owner/$Repo"
Write-Host "Tag       : $TagVersion"

# --- Defaults ---

if (-not $Title) {
    $Title = "VocabFlip $TagVersion"
}

if ($Notes -and (Test-Path $Notes -PathType Leaf)) {
    $Notes = Get-Content $Notes -Raw -Encoding UTF8
} elseif (-not $Notes) {
    $Notes = ""
}

# --- Build (if needed) ---

$ReleaseDir = Join-Path $ProjectRoot "build\release"

if (-not $SkipBuild) {
    Write-Step "Running build script"
    $BuildScript = Join-Path $PSScriptRoot "build.ps1"
    & $BuildScript -Version $SemVer -Targets $Targets
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Build failed!"
        exit 1
    }
}

# --- Verify artifacts ---

Write-Step "Checking artifacts"

if (-not (Test-Path $ReleaseDir)) {
    Write-Err "Directory build/release/ does not exist. Run build first!"
    exit 1
}

$Artifacts = Get-ChildItem $ReleaseDir -File
if ($Artifacts.Count -eq 0) {
    Write-Err "No artifacts found in build/release/"
    exit 1
}

Write-Host "Artifacts to upload:" -ForegroundColor Yellow
foreach ($f in $Artifacts) {
    $Size = [math]::Round($f.Length / 1MB, 2)
    Write-Host "  - $($f.Name)  ($Size MB)"
}

# --- Push current branch to origin ---

Write-Step "Pushing current branch to origin"

$CurrentBranch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
if ($CurrentBranch -and $CurrentBranch -ne "HEAD") {
    Write-Host "Pushing branch '$CurrentBranch' to origin..."
    git push origin $CurrentBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Push branch $CurrentBranch failed!"
        exit 1
    }
    Write-Success "Branch '$CurrentBranch' pushed to origin"
} else {
    Write-Host "Detached HEAD or could not detect branch name, skipping branch push."
}

# --- Create git tag ---

Write-Step "Creating git tag: $TagVersion"

$ExistingTag = git tag -l $TagVersion 2>$null
if ($ExistingTag) {
    Write-Host "Tag $TagVersion already exists, skipping tag creation."
} else {
    git tag -a $TagVersion -m "Release $TagVersion"
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Creating git tag failed!"
        exit 1
    }
    Write-Success "Tag $TagVersion created"
}

# --- Push tag ---

Write-Step "Pushing tag to origin"

git push origin $TagVersion
if ($LASTEXITCODE -ne 0) {
    Write-Err "Push tag failed!"
    exit 1
}
Write-Success "Tag pushed"

# --- Create or Get GitHub Release ---

Write-Step "Creating or updating GitHub Release"

$Headers = @{
    "Authorization"        = "Bearer $Token"
    "Accept"               = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$ReleaseId = $null
$HtmlUrl = $null
$ExistingAssets = @()
$ExistingRelease = $null

$GetReleaseUrl = "https://api.github.com/repos/$Owner/$Repo/releases/tags/$TagVersion"
try {
    $ExistingRelease = Invoke-RestMethod -Uri $GetReleaseUrl -Method GET -Headers $Headers
    $ReleaseId = $ExistingRelease.id
    $HtmlUrl = $ExistingRelease.html_url
    $ExistingAssets = $ExistingRelease.assets
    Write-Host "Found existing release $TagVersion (ID: $ReleaseId)" -ForegroundColor Yellow

    if ($Notes) {
        $PatchBody = @{
            body = $Notes
        } | ConvertTo-Json -Depth 3
        Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/releases/$ReleaseId" -Method PATCH -Headers $Headers -Body $PatchBody -ContentType "application/json; charset=utf-8" | Out-Null
        Write-Success "Updated release notes"
    }
} catch {
    $ReleaseBody = @{
        tag_name               = $TagVersion
        name                   = $Title
        body                   = $Notes
        draft                  = [bool]$Draft
        prerelease             = [bool]$Prerelease
        generate_release_notes = $false
    } | ConvertTo-Json -Depth 3

    $ApiUrl = "https://api.github.com/repos/$Owner/$Repo/releases"

    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Method POST -Headers $Headers `
            -Body $ReleaseBody -ContentType "application/json; charset=utf-8"
        $ReleaseId = $Response.id
        $HtmlUrl = $Response.html_url
        Write-Success "Release created: $HtmlUrl"
    } catch {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $ErrorBody = $_.ErrorDetails.Message
        Write-Err "GitHub API error ($StatusCode): $ErrorBody"
        exit 1
    }
}

# --- Upload assets to GitHub Release ---

Write-Step "Uploading artifacts to GitHub Release"

$UploadUrlBase = "https://uploads.github.com/repos/$Owner/$Repo/releases/$ReleaseId/assets"

foreach ($Artifact in $Artifacts) {
    $FileName = $Artifact.Name
    $FilePath = $Artifact.FullName
    $FileSize = [math]::Round($Artifact.Length / 1MB, 2)

    if ($ExistingAssets) {
        foreach ($Asset in $ExistingAssets) {
            if ($Asset.name -eq $FileName) {
                Write-Host "Deleting old asset: $FileName (ID: $($Asset.id))..." -NoNewline
                try {
                    Invoke-RestMethod -Uri "https://api.github.com/repos/$Owner/$Repo/releases/assets/$($Asset.id)" -Method DELETE -Headers $Headers
                    Write-Host " [OK]" -ForegroundColor Green
                } catch {
                    Write-Host " [FAILED]" -ForegroundColor Red
                }
            }
        }
    }

    Write-Host "Uploading: $FileName ($FileSize MB)..." -NoNewline

    $ContentType = switch -Regex ($FileName) {
        '\.apk$'  { "application/vnd.android.package-archive" }
        '\.zip$'  { "application/zip" }
        '\.exe$'  { "application/x-msdownload" }
        default   { "application/octet-stream" }
    }

    $UploadUrl = "$UploadUrlBase`?name=$([Uri]::EscapeDataString($FileName))"

    try {
        $FileBytes = [System.IO.File]::ReadAllBytes($FilePath)
        $UploadResponse = Invoke-RestMethod -Uri $UploadUrl -Method POST -Headers $Headers `
            -Body $FileBytes -ContentType $ContentType
        Write-Host " [OK]" -ForegroundColor Green
        Write-Host "  -> $($UploadResponse.browser_download_url)"
    } catch {
        $StatusCode = $_.Exception.Response.StatusCode.Value__
        $ErrorBody = $_.ErrorDetails.Message
        Write-Host " [FAILED]" -ForegroundColor Red
        Write-Err "Upload failed ($StatusCode): $ErrorBody"
    }
}

# --- Upload to Backblaze B2 (in-app updater + /studio/vocab web download link) ---

$B2Ok = $false

if ($SkipB2 -or $Draft -or $Prerelease -or $ExistingRelease.draft -or $ExistingRelease.prerelease) {
    Write-Host ""
    Write-Host "[SKIP] B2 stable channel unchanged: -SkipB2 or draft/prerelease (requested or existing on GitHub)." -ForegroundColor Yellow
} else {
    Write-Step "Uploading to Backblaze B2"

    $WinZip = $Artifacts | Where-Object { $_.Name -like "*windows*.zip" } | Select-Object -First 1
    $ApkFile = $Artifacts | Where-Object { $_.Name -like "*.apk" } | Select-Object -First 1

    $UploadScript = Join-Path $PSScriptRoot "upload-b2.ps1"
    $B2Params = @{
        Version    = $SemVer
        Title      = $Title
        Notes      = $Notes
        ReleaseUrl = $HtmlUrl
    }
    if ($WinZip)  { $B2Params['ZipPath'] = $WinZip.FullName }
    if ($ApkFile) { $B2Params['ApkPath'] = $ApkFile.FullName }

    & $UploadScript @B2Params
    if ($LASTEXITCODE -eq 0) {
        $B2Ok = $true
    } else {
        Write-Err "B2 upload failed. GitHub Release is already published - rerun the B2 upload alone with:"
        Write-Host "  powershell -ExecutionPolicy Bypass -File `".agents\skills\build-and-release\scripts\upload-b2.ps1`" -Version `"$SemVer`"" -ForegroundColor Yellow
    }
}

# --- Done ---

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " Release completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "GitHub Release : $HtmlUrl" -ForegroundColor Yellow
Write-Host "Tag            : $TagVersion"
if ($B2Ok) {
    Write-Host "Studio page    : https://giaiphapsangtao.com/studio/vocab" -ForegroundColor Yellow
}
Write-Host "Web bundle     : alpha-studio/public/vocab (commit & push in alpha-studio repo to deploy web)" -ForegroundColor Yellow
Write-Host ""

Write-Host "Artifacts:" -ForegroundColor Yellow
foreach ($f in $Artifacts) {
    $Size = [math]::Round($f.Length / 1MB, 2)
    Write-Host "  - $($f.Name)  ($Size MB)"
}
