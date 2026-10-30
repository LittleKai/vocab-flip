<#
.SYNOPSIS
    Upload VocabFlip Windows ZIP + Android APK + version.json to Backblaze B2 (alpha-studio bucket).

.DESCRIPTION
    Both the Studio web page (giaiphapsangtao.com/studio/vocab via GET /api/vocab/releases/latest)
    and VocabFlip's in-app updater (UpdateProvider -> UpdateApi) read:
      https://cdn.giaiphapsangtao.com/file/alpha-studio/vocabflip-app/version.json

    Uploads:
      vocabflip-app/releases/vocabflip-v<version>.apk
      vocabflip-app/releases/vocabflip-windows-v<version>.zip
      vocabflip-app/version.json

    Also cleans up older release binaries on B2, keeping the 3 newest versions.

.PARAMETER Version
    Version/tag string (e.g. "v1.2.5" or "1.2.5").

.PARAMETER ZipPath
    Windows ZIP to upload. Default: build/release/vocabflip-windows-v<version>.zip

.PARAMETER ApkPath
    Android APK to upload. Default: build/release/vocabflip-v<version>.apk

.PARAMETER Title
    Release title stored in version.json (default: "VocabFlip v<version>").

.PARAMETER Notes
    Release notes (string or path to a file) stored in version.json.

.PARAMETER ReleaseUrl
    GitHub release html_url stored in version.json.

.PARAMETER PublishedAt
    ISO-8601 publish timestamp. Default: now (UTC).
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$ZipPath = "",

    [string]$ApkPath = "",

    [string]$Title = "",

    [string]$Notes = "",

    [string]$ReleaseUrl = "",

    [string]$PublishedAt = ""
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Invoke-RestMethod is ~10x faster without the progress bar

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

$SemVer = $Version -replace '^v', ''
$TagVersion = if ($Version.StartsWith('v')) { $Version } else { "v$Version" }
$ReleaseDir = Join-Path $ProjectRoot "build\release"

if (-not $ZipPath) {
    $CandidateZip = Join-Path $ReleaseDir "vocabflip-windows-v$SemVer.zip"
    if (Test-Path $CandidateZip -PathType Leaf) {
        $ZipPath = $CandidateZip
    } elseif (Test-Path $ReleaseDir) {
        $FoundZip = Get-ChildItem $ReleaseDir -Filter "*windows*.zip" -File | Select-Object -First 1
        if ($FoundZip) { $ZipPath = $FoundZip.FullName }
    }
}

if (-not $ApkPath) {
    $CandidateApk = Join-Path $ReleaseDir "vocabflip-v$SemVer.apk"
    if (Test-Path $CandidateApk -PathType Leaf) {
        $ApkPath = $CandidateApk
    } elseif (Test-Path $ReleaseDir) {
        $FoundApk = Get-ChildItem $ReleaseDir -Filter "*.apk" -File | Select-Object -First 1
        if ($FoundApk) { $ApkPath = $FoundApk.FullName }
    }
}

$HasZip = $ZipPath -and (Test-Path $ZipPath -PathType Leaf)
$HasApk = $ApkPath -and (Test-Path $ApkPath -PathType Leaf)

if ((-not $HasZip) -and (-not $HasApk)) {
    Write-Err "Neither Windows ZIP nor Android APK found in $ReleaseDir"
    exit 1
}

if (-not $Title) { $Title = "VocabFlip $TagVersion" }
if ($Notes -and (Test-Path $Notes -PathType Leaf)) {
    $Notes = Get-Content $Notes -Raw -Encoding UTF8
}
if (-not $PublishedAt) {
    $PublishedAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

# --- Read B2 config (prefer alpha-studio-backend/.env so secrets never enter bundled vocabflip/.env) ---

Write-Step "Reading B2 config"

$BackendEnv = [System.IO.Path]::GetFullPath((Join-Path $ProjectRoot "..\..\alpha-studio-backend\.env"))
$ReleaseEnv = Join-Path $ProjectRoot ".env.release"

$EnvVars = Read-EnvMap -CandidatePaths @($BackendEnv, $ReleaseEnv)

$KeyId      = if ($env:B2_ACCESS_KEY_ID)     { $env:B2_ACCESS_KEY_ID }     else { $EnvVars['B2_ACCESS_KEY_ID'] }
$AppKey     = if ($env:B2_SECRET_ACCESS_KEY) { $env:B2_SECRET_ACCESS_KEY } else { $EnvVars['B2_SECRET_ACCESS_KEY'] }
$BucketName = if ($env:B2_BUCKET_NAME)       { $env:B2_BUCKET_NAME }       else { $EnvVars['B2_BUCKET_NAME'] }
$CdnBase    = if ($env:CDN_BASE_URL)         { $env:CDN_BASE_URL }         else { $EnvVars['CDN_BASE_URL'] }

$Missing = @()
if (-not $KeyId)      { $Missing += 'B2_ACCESS_KEY_ID' }
if (-not $AppKey)     { $Missing += 'B2_SECRET_ACCESS_KEY' }
if (-not $BucketName) { $Missing += 'B2_BUCKET_NAME' }
if (-not $CdnBase)    { $Missing += 'CDN_BASE_URL' }

if ($Missing.Count -gt 0) {
    Write-Err ("Missing B2 credentials: " + ($Missing -join ', '))
    Write-Host ""
    Write-Host "Ensure these variables exist in ../../alpha-studio-backend/.env (or .env.release):" -ForegroundColor Yellow
    Write-Host "  B2_ACCESS_KEY_ID=<b2 keyID>"
    Write-Host "  B2_SECRET_ACCESS_KEY=<b2 applicationKey>"
    Write-Host "  B2_BUCKET_NAME=alpha-studio"
    Write-Host "  CDN_BASE_URL=https://cdn.giaiphapsangtao.com/file/alpha-studio"
    Write-Host "WARNING: Do NOT put B2 secrets in tools/vocabflip/.env because pubspec.yaml bundles .env into the app!" -ForegroundColor Red
    exit 1
}

$CdnBase = $CdnBase.TrimEnd('/')
Write-Success "Bucket: $BucketName - CDN: $CdnBase"

# --- Authorize ---

Write-Step "Authorizing with Backblaze B2"

$BasicAuth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${KeyId}:${AppKey}"))
try {
    $Auth = Invoke-RestMethod -Uri "https://api.backblazeb2.com/b2api/v3/b2_authorize_account" `
        -Headers @{ Authorization = "Basic $BasicAuth" }
} catch {
    Write-Err "B2 authorize failed: $($_.Exception.Message)"
    exit 1
}

$ApiUrl   = $Auth.apiInfo.storageApi.apiUrl
$BucketId = $Auth.apiInfo.storageApi.bucketId

if (-not $BucketId) {
    $ListUrl = "$ApiUrl/b2api/v3/b2_list_buckets?accountId=$($Auth.accountId)&bucketName=$BucketName"
    $Buckets = Invoke-RestMethod -Uri $ListUrl -Headers @{ Authorization = $Auth.authorizationToken }
    $BucketId = ($Buckets.buckets | Select-Object -First 1).bucketId
}

if (-not $BucketId) {
    Write-Err "Could not resolve bucketId for bucket '$BucketName'"
    exit 1
}

Write-Success "Authorized (bucketId: $BucketId)"

# --- Upload helper ---

function Invoke-B2Upload {
    param(
        [string]$Key,
        [string]$FilePath,
        [byte[]]$Bytes,
        [string]$ContentType
    )

    $UploadInfo = Invoke-RestMethod -Uri "$ApiUrl/b2api/v3/b2_get_upload_url" -Method POST `
        -Headers @{ Authorization = $Auth.authorizationToken } `
        -Body (@{ bucketId = $BucketId } | ConvertTo-Json) -ContentType "application/json"

    if ($FilePath) {
        $Sha1 = (Get-FileHash -Path $FilePath -Algorithm SHA1).Hash.ToLower()
    } else {
        $Sha1Provider = [Security.Cryptography.SHA1]::Create()
        $Sha1 = ($Sha1Provider.ComputeHash($Bytes) | ForEach-Object { $_.ToString('x2') }) -join ''
    }

    $EncodedKey = ($Key.Split('/') | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/'

    $Headers = @{
        Authorization       = $UploadInfo.authorizationToken
        'X-Bz-File-Name'    = $EncodedKey
        'X-Bz-Content-Sha1' = $Sha1
    }

    if ($FilePath) {
        return Invoke-RestMethod -Uri $UploadInfo.uploadUrl -Method POST -Headers $Headers `
            -ContentType $ContentType -InFile $FilePath
    }
    return Invoke-RestMethod -Uri $UploadInfo.uploadUrl -Method POST -Headers $Headers `
        -ContentType $ContentType -Body $Bytes
}

$AssetsList = @()
$ApkUrl = ""
$ZipUrl = ""

# --- Upload Android APK ---

if ($HasApk) {
    $ApkItem   = Get-Item $ApkPath
    $ApkName   = "vocabflip-v$SemVer.apk"
    $ApkKey    = "vocabflip-app/releases/$ApkName"
    $ApkSizeMb = [math]::Round($ApkItem.Length / 1MB, 2)

    Write-Step "Uploading $ApkName ($ApkSizeMb MB) to B2"

    if ($ApkItem.Length -gt 200MB) {
        Write-Err "APK is larger than 200MB - b2_upload_file single-part upload is not suitable."
        exit 1
    }

    try {
        Invoke-B2Upload -Key $ApkKey -FilePath $ApkItem.FullName -ContentType "application/vnd.android.package-archive" | Out-Null
    } catch {
        Write-Err "APK upload failed: $($_.Exception.Message)"
        exit 1
    }

    $ApkUrl = "$CdnBase/$ApkKey"
    Write-Success "APK -> $ApkUrl"

    $AssetsList += [ordered]@{
        name                 = $ApkName
        browser_download_url = $ApkUrl
        size                 = $ApkItem.Length
        content_type         = "application/vnd.android.package-archive"
    }
}

# --- Upload Windows ZIP ---

if ($HasZip) {
    $ZipItem   = Get-Item $ZipPath
    $ZipName   = "vocabflip-windows-v$SemVer.zip"
    $ZipKey    = "vocabflip-app/releases/$ZipName"
    $ZipSizeMb = [math]::Round($ZipItem.Length / 1MB, 2)

    Write-Step "Uploading $ZipName ($ZipSizeMb MB) to B2"

    if ($ZipItem.Length -gt 200MB) {
        Write-Err "ZIP is larger than 200MB - b2_upload_file single-part upload is not suitable."
        exit 1
    }

    try {
        Invoke-B2Upload -Key $ZipKey -FilePath $ZipItem.FullName -ContentType "application/zip" | Out-Null
    } catch {
        Write-Err "ZIP upload failed: $($_.Exception.Message)"
        exit 1
    }

    $ZipUrl = "$CdnBase/$ZipKey"
    Write-Success "ZIP -> $ZipUrl"

    $AssetsList += [ordered]@{
        name                 = $ZipName
        browser_download_url = $ZipUrl
        size                 = $ZipItem.Length
        content_type         = "application/zip"
    }
}

# --- Upload version.json ---

Write-Step "Uploading vocabflip-app/version.json"

$Manifest = [ordered]@{
    tag_name     = $TagVersion
    version      = $SemVer
    name         = $Title
    body         = $Notes
    html_url     = $ReleaseUrl
    published_at = $PublishedAt
    assets       = $AssetsList
}

$ManifestJson  = $Manifest | ConvertTo-Json -Depth 5
$ManifestBytes = [Text.Encoding]::UTF8.GetBytes($ManifestJson)

try {
    Invoke-B2Upload -Key "vocabflip-app/version.json" -Bytes $ManifestBytes -ContentType "application/json" | Out-Null
} catch {
    Write-Err "version.json upload failed: $($_.Exception.Message)"
    exit 1
}

$ManifestUrl = "$CdnBase/vocabflip-app/version.json"
Write-Success "version.json -> $ManifestUrl"

# --- Cleanup old releases on B2 (keep 3 newest versions) ---

Write-Step "Cleaning up old VocabFlip releases on B2 (keeping 3 newest versions)"

try {
    $ListFilesBody = @{
        bucketId     = $BucketId
        prefix       = "vocabflip-app/releases/"
        maxFileCount = 1000
    } | ConvertTo-Json

    $ListRes = Invoke-RestMethod -Uri "$ApiUrl/b2api/v3/b2_list_file_names" -Method POST `
        -Headers @{ Authorization = $Auth.authorizationToken } `
        -Body $ListFilesBody -ContentType "application/json"

    $MatchedFiles = @()
    foreach ($f in $ListRes.files) {
        if ($f.fileName -match '^vocabflip-app/releases/vocabflip-(?:windows-)?v(\d+\.\d+\.\d+)\.(?:apk|zip)$') {
            $MatchedFiles += [PSCustomObject]@{
                fileName = $f.fileName
                fileId   = $f.fileId
                version  = [Version]$Matches[1]
            }
        }
    }

    $UniqueVersions = $MatchedFiles | Select-Object -ExpandProperty version -Unique | Sort-Object
    if ($UniqueVersions.Count -gt 3) {
        $KeepVersions = $UniqueVersions | Select-Object -Last 3
        $ToDelete = $MatchedFiles | Where-Object { $KeepVersions -notcontains $_.version }
        foreach ($item in $ToDelete) {
            $DelBody = @{
                fileName = $item.fileName
                fileId   = $item.fileId
            } | ConvertTo-Json
            Invoke-RestMethod -Uri "$ApiUrl/b2api/v3/b2_delete_file_version" -Method POST `
                -Headers @{ Authorization = $Auth.authorizationToken } `
                -Body $DelBody -ContentType "application/json" | Out-Null
            Write-Host "  Deleted old B2 file: $($item.fileName)"
        }
        Write-Success "Deleted $($ToDelete.Count) old release file(s)"
    } else {
        Write-Host "3 or fewer versions found on B2. No cleanup needed."
    }
} catch {
    Write-Host "[WARN] B2 retention cleanup skipped: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- Done ---

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " B2 upload completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
if ($ApkUrl) { Write-Host "Android APK    : $ApkUrl" -ForegroundColor Yellow }
if ($ZipUrl) { Write-Host "Windows ZIP    : $ZipUrl" -ForegroundColor Yellow }
Write-Host "Manifest       : $ManifestUrl" -ForegroundColor Yellow
Write-Host "Studio page    : https://giaiphapsangtao.com/studio/vocab"
Write-Host ""

exit 0
