$ErrorActionPreference = 'Stop'
# Run only the real B2 dispatch block; no credentials, builds, git or network.
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
foreach ($SkillDirectory in @('.agents', '.claude')) {
    $ReleasePath = Join-Path $ProjectRoot "$SkillDirectory/skills/build-and-release/scripts/release.ps1"
    $Tokens = $null
    $ParseErrors = $null
    $Ast = [System.Management.Automation.Language.Parser]::ParseFile($ReleasePath, [ref]$Tokens, [ref]$ParseErrors)
    if ($ParseErrors.Count) { throw $ParseErrors[0] }
    $Dispatch = $Ast.FindAll({
        param($Node)
        $Node -is [System.Management.Automation.Language.IfStatementAst] -and
        $Node.Clauses[0].Item1.Extent.Text -match '\$SkipB2'
    }, $true)
    if ($Dispatch.Count -ne 1) { throw 'Expected one B2 dispatch block' }
    foreach ($Case in @(
        @{ Name = 'stable'; Expected = 1 },
        @{ Name = 'draft'; Draft = $true; Expected = 0 },
        @{ Name = 'prerelease'; Prerelease = $true; Expected = 0 },
        @{ Name = 'explicit skip'; SkipB2 = $true; Expected = 0 },
        @{ Name = 'existing draft'; RemoteDraft = $true; Expected = 0 },
        @{ Name = 'existing prerelease'; RemotePrerelease = $true; Expected = 0 }
    )) {
        & {
            $Draft = [bool]$Case.Draft
            $Prerelease = [bool]$Case.Prerelease
            $SkipB2 = [bool]$Case.SkipB2
            $ExistingRelease = [pscustomobject]@{ draft = [bool]$Case.RemoteDraft; prerelease = [bool]$Case.RemotePrerelease }
            $Artifacts = @()
            $SemVer = '0.0.0-test'
            $Title = 'Offline test'
            $Notes = ''
            $HtmlUrl = 'https://example.test/release'
            $script:Uploads = 0
            function Write-Step {}
            function Write-Host {}
            function Write-Err { throw $args[0] }
            function Join-Path { 'Invoke-FakeB2' }
            function Invoke-FakeB2 {
                param($Version, $Title, $Notes, $ReleaseUrl)
                $script:Uploads++
                $global:LASTEXITCODE = 0
            }
            . ([scriptblock]::Create($Dispatch[0].Extent.Text))
            if ($script:Uploads -ne $Case.Expected) {
                throw "$SkillDirectory/$($Case.Name): expected $($Case.Expected) B2 uploads, got $script:Uploads"
            }
        }
    }
}
Write-Host 'Release channel checks passed (both skill copies, 6 cases each).'
