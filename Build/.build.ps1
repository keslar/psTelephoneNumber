<#
.SYNOPSIS
    Modular PowerShell module build pipeline using Invoke-Build

.DESCRIPTION
    This script defines a set of tasks for building, testing,
    versioning, and releasing a PowerShell module. It uses
    Invoke-Build to orchestrate the tasks and supports both
    granular task execution and a full release pipeline.

.PARAMETER SemVer
    Manually specify the next semantic version to set in the module
    manifest. If not provided, the script will determine the next
    version based on commit messages.

.PARAMETER VersionBump
    Specify the type of version bump (major, minor, patch) to apply
    when determining the next version. Ignored if SemVer is provided.

.PARAMETER PushTag
    When creating a git tag for the new version, also push the tag to
    the remote repository.

.EXAMPLE
    .\build.ps1 -Release

    Runs the full release pipeline: Clean → Version → Build → Sign →
    TestIntegration → Changelog → Tag → Publish.

.EXAMPLE
    .\build.ps1 -Task Version, Build

    Runs only the specified tasks.

.NOTES
    - Signing requires a valid code signing certificate in Cert:\CurrentUser\My
    - Publishing requires $env:PSGALLERY_KEY to be set
    - Commit messages should follow Conventional Commits for automatic
      version bumping (feat:, fix:, BREAKING CHANGE)
#>
# param() MUST be first in the file - Invoke-Build passes these as named
# parameters when calling the build file, same as any other script.
param(
    [string]$SemVer,
    [string]$VersionBump,   # major | minor | patch - validated in Version task
    [switch]$PushTag
)


###############################################################################
# Setup
###############################################################################
Import-Module InvokeBuild   -ErrorAction Stop
Import-Module ModuleBuilder -ErrorAction Stop

###############################################################################
# Script Variables
###############################################################################
$Script:ProjectRoot = Split-Path -Path $PSScriptRoot -Parent
$Script:SourcePath = Join-Path  -Path $Script:ProjectRoot -ChildPath 'Source'
$Script:ModuleName = Split-Path -Path $Script:ProjectRoot -Leaf
#$Script:ModuleName = (Get-ChildItem -Path $Script:SourcePath -Filter '*.psd1' |
#        Select-Object -First 1).BaseName
$Script:ManifestPath = Join-Path  -Path $Script:SourcePath  -ChildPath "$($Script:ModuleName).psd1"
$Script:OutputPath = Join-Path  -Path $Script:ProjectRoot -ChildPath 'Output'
$Script:TestsPath = Join-Path  -Path $Script:ProjectRoot -ChildPath 'Tests'
$Script:ChangelogPath = Join-Path  -Path $Script:ProjectRoot -ChildPath 'CHANGELOG.md'
$Script:AnalyzerSettings = Join-Path  -Path $Script:ProjectRoot -ChildPath 'PSScriptAnalyzerSettings.ps1'
$Script:Repository = 'PittDigital'
$Script:CoverageThreshold = 90

# Store params as $Script: so task scriptblocks can access them
$Script:SemVer = $SemVer
$Script:VersionBump = $VersionBump
$Script:PushTag = $PushTag

# Set by Version task, consumed by Build, Sign, Tag, Changelog, Publish
$Script:ResolvedVersion = $null

# Set by Build task, consumed by Sign, TestIntegration, Publish
$Script:BuiltModuleBase = $null
$Script:BuiltVersion = $null

###############################################################################
# Helper Functions
###############################################################################
$helpersPath = Join-Path -Path $PSScriptRoot -ChildPath 'Helpers'
if (Test-Path $helpersPath) {
    Get-ChildItem -Path $helpersPath -Filter '*.ps1' | ForEach-Object {
        . $_.FullName
    }
}

###############################################################################
# Tasks
###############################################################################

#------------------------------------------------------------------------------
# Default task - runs when no specific task is provided
#------------------------------------------------------------------------------
task . Clean, Version, Build, Sign, TestIntegration, {
    Write-Build Green "Build complete! Version $($Script:ResolvedVersion) is ready."
}

#------------------------------------------------------------------------------
# Clean - remove all build output
#------------------------------------------------------------------------------
task Clean {
    Write-Build Cyan 'Cleaning previous build outputs...'
    if (Test-Path $Script:OutputPath) {
        Remove-Item $Script:OutputPath -Recurse -Force
        Write-Build Green '  Clean complete.'
    } else {
        Write-Build DarkGray '  No previous build outputs found, skipping.'
    }
    New-Item -ItemType Directory -Path $Script:OutputPath | Out-Null
}

#------------------------------------------------------------------------------
# Analyze - static code analysis via PSScriptAnalyzer
#------------------------------------------------------------------------------
task Analyze {
    Write-Build Cyan 'Running PSScriptAnalyzer...'

    $analyzeParams = @{
        Path        = $Script:SourcePath
        Settings    = $Script:AnalyzerSettings
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
    }

    $findings = Invoke-ScriptAnalyzer @analyzeParams | Where-Object { $_.Severity -ne 'Information' }

    if ($findings) {
        $errors = @($findings | Where-Object Severity -EQ 'Error')
        $warnings = @($findings | Where-Object Severity -EQ 'Warning')

        foreach ($finding in $findings) {
            $color = if ($finding.Severity -eq 'Error') { 'Red' } else { 'Yellow' }
            Write-Build $color "  [$($finding.Severity)] $($finding.RuleName)"
            Write-Build $color "    $($finding.ScriptName) line $($finding.Line): $($finding.Message)"
        }

        Write-Build White "  Errors: $($errors.Count)   Warnings: $($warnings.Count)"

        if ($errors.Count -gt 0) {
            throw "PSScriptAnalyzer found $($errors.Count) error(s). Fix before building."
        }
    } else {
        Write-Build Green '  No issues found.'
    }
}

#------------------------------------------------------------------------------
# TestUnit - run Pester unit tests with code coverage
#------------------------------------------------------------------------------
task TestUnit Analyze, {
    Write-Build Cyan 'Running Pester unit tests...'

    # Capture variables before crossing the process boundary
    $testsPath = $Script:TestsPath
    $sourcePath = $Script:SourcePath
    $threshold = $Script:CoverageThreshold

    pwsh -WorkingDirectory $Script:ProjectRoot -NoProfile -NonInteractive -Command {
        param($TestsPath, $SourcePath, $CoverageThreshold)

        Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

        $pesterConfig = New-PesterConfiguration
        $pesterConfig.Run.Path = Join-Path $TestsPath 'Unit'
        $pesterConfig.Run.PassThru = $true
        $pesterConfig.Output.Verbosity = 'Normal'
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = 'JUnitXml'
        $pesterConfig.TestResult.OutputPath = Join-Path $TestsPath 'Results/TestResults-Unit.xml'
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = @("$SourcePath/**/*.ps1")
        $pesterConfig.CodeCoverage.OutputPath = Join-Path $TestsPath 'Results/Coverage-Unit.xml'
        $pesterConfig.CodeCoverage.CoveragePercentTarget = $CoverageThreshold
        Write-Warning "  Writing results to $($pesterConfig.TestResult.OutputPath) and $($pesterConfig.CodeCoverage.OutputPath) - these will be overwritten on each run of the TestUnit task."
        $results = Invoke-Pester -Configuration $pesterConfig

        Write-Host "  Passed: $($results.PassedCount)   Failed: $($results.FailedCount)   Skipped: $($results.SkippedCount)"

        if ($results.FailedCount -gt 0) {
            throw "Unit tests: $($results.FailedCount) test(s) failed."
        }

        $coverage = [math]::Round($results.CodeCoverage.CoveragePercent, 1)
        if ($coverage -lt $CoverageThreshold) {
            throw "Code coverage $coverage% is below the $CoverageThreshold% threshold."
        }

        Write-Host "  All unit tests passed. Coverage: $coverage%"

    } -args $testsPath, $sourcePath, $threshold

    if ($LASTEXITCODE -ne 0) {
        throw 'Unit test task failed — see output above.'
    }
}

#------------------------------------------------------------------------------
# Version - determine and set the next module version
#------------------------------------------------------------------------------
task Version {
    Write-Build Cyan 'Determining next version...'

    # Git tag is the source of truth; fall back to manifest if no tags exist
    try {
        $lastTag = git describe --tags --abbrev=0 2>$null
    } catch {
        $lastTag = $null
    }

    if ($lastTag) {
        $current = $lastTag.TrimStart('v')
        Write-Build Cyan "  Current version (git tag)  : $current"
    } else {
        $current = Get-ManifestVersion
        Write-Build Yellow "  No git tag found, using manifest version: $current"
    }

    # Manual SemVer override takes highest priority
    if ($Script:SemVer) {
        $next = $Script:SemVer
        Write-Build Yellow "  Version override (manual)  : $next"
    } else {
        if ($Script:VersionBump) {
            $bump = $Script:VersionBump
            Write-Build Cyan "  Version bump (parameter)   : $bump"
        } else {
            $bump = Determine-VersionBumpFromCommits -LastTag $lastTag
            Write-Build Cyan "  Version bump (commits)     : $bump"
        }
        $next = Get-NextSemVer -CurrentVersion $current -Bump $bump
    }

    Write-Build Green "  Next version: $current → $next"
    Set-ManifestVersion -Version $next
    $Script:ResolvedVersion = $next
}

#------------------------------------------------------------------------------
# Build - compile source into a single .psm1 via ModuleBuilder
#------------------------------------------------------------------------------
task Build TestUnit, {
    Write-Build Cyan 'Building module...'

    # If Version task did not run, fall back to manifest version
    if (-not $Script:ResolvedVersion) {
        $Script:ResolvedVersion = Get-ManifestVersion
        Write-Build Yellow "  No resolved version found, using manifest version: $($Script:ResolvedVersion)"
    }

    Write-Build Cyan "  Source         : $($Script:SourcePath)"
    Write-Build Cyan "  Output         : $($Script:OutputPath)"
    Write-Build Cyan "  Manifest       : $($Script:ManifestPath)"
    Write-Build Cyan "  Module Name    : $($Script:ModuleName)"
    Write-Build Cyan "  Module Version : $($Script:ResolvedVersion)"

    $buildParams = @{
        SourcePath      = $Script:SourcePath
        OutputDirectory = $Script:OutputPath
        SemVer          = $Script:ResolvedVersion
    }

    $module = Build-Module @buildParams -Passthru

    # Stamp {{BUILD_DATE}} and {{MODULE_VERSION}} placeholders in the built .psm1
    $psm1Path = Join-Path $module.ModuleBase "$($module.Name).psm1"
    if (Test-Path $psm1Path) {
        $buildDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $content = Get-Content $psm1Path -Raw
        $content = $content -replace '\{\{BUILD_DATE\}\}', $buildDate
        $content = $content -replace '\{\{MODULE_VERSION\}\}', $Script:ResolvedVersion
        Set-Content -Path $psm1Path -Value $content -NoNewline
        Write-Build DarkCyan "  Stamped version $($Script:ResolvedVersion) and build date $buildDate"
    }

    Write-Build Green "  Built: $($module.Name) $($module.Version) → $($module.ModuleBase)"

    # Persist for downstream tasks
    $Script:BuiltModuleBase = $module.ModuleBase
    $Script:BuiltVersion = $module.Version
}

#------------------------------------------------------------------------------
# Sign - digitally sign the built .psm1 and .psd1
#------------------------------------------------------------------------------
task Sign Build, {
    Write-Build Cyan 'Signing built module...'

    # Skip signing if not running on Windows locally, since Set-AuthenticodeSignature is Windows-only and code signing is typically only needed for local development and PSGallery publishing (which requires a Windows-signed package).
    if (-not $IsWindows -or $env:CI) {
        Write-Build Yellow '  Skipping signing (not running on Windows or running in CI environment).'
        return
    }
    # Select the most recently expiring valid code signing certificate
    $cert = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert |
        Where-Object { $_.NotAfter -gt (Get-Date) } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1

    if (-not $cert) {
        throw 'No valid code signing certificate found in Cert:\CurrentUser\My'
    }

    # Detect whether this is a self-signed certificate:
    # A self-signed cert has the same Subject and Issuer, and its chain
    # cannot be verified against a trusted root - so Set-AuthenticodeSignature
    # will return UnknownError instead of Valid. We allow that status for
    # self-signed certs but still catch real failures (HashMismatch, NotSigned, etc.)
    $isSelfSigned = $cert.Subject -eq $cert.Issuer
    $validStatuses = if ($isSelfSigned) { @('Valid', 'UnknownError') } else { @('Valid') }

    if ($isSelfSigned) {
        Write-Build Yellow '  Self-signed certificate detected - UnknownError status will be accepted.'
    }

    Write-Build DarkCyan "  Certificate  : $($cert.Subject)"
    Write-Build DarkCyan "  Thumbprint   : $($cert.Thumbprint)"
    Write-Build DarkCyan "  Expires      : $($cert.NotAfter.ToString('yyyy-MM-dd'))"
    Write-Build DarkCyan "  Self-Signed  : $isSelfSigned"

    # Only use a timestamp server for CA-issued certs - self-signed certs
    # will cause the timestamp request to fail or be ignored anyway.
    $signParams = @{
        Certificate = $cert
    }
    if (-not $isSelfSigned) {
        $signParams['TimestampServer'] = 'http://timestamp.sectigo.com'
    }

    $filesToSign = @(
        Join-Path $Script:BuiltModuleBase "$($Script:ModuleName).psm1"
        Join-Path $Script:BuiltModuleBase "$($Script:ModuleName).psd1"
    )

    foreach ($file in $filesToSign) {
        if (-not (Test-Path $file)) {
            Write-Build Yellow "  Skipping (not found): $file"
            continue
        }

        $result = Set-AuthenticodeSignature -FilePath $file @signParams

        if ($result.Status -notin $validStatuses) {
            throw "Signing failed for $(Split-Path $file -Leaf): [$($result.Status)] $($result.StatusMessage)"
        }

        $statusLabel = if ($result.Status -eq 'UnknownError') { 'Signed (self-signed, chain unverified)' } else { $result.Status }
        Write-Build Green "  Signed: $(Split-Path $file -Leaf) [$statusLabel]"
    }
}

#------------------------------------------------------------------------------
# TestIntegration - run Pester integration tests against the built/signed module
#------------------------------------------------------------------------------
task TestIntegration Sign, {
    Write-Build Cyan 'Running Pester integration tests...'

    $integrationPath = Join-Path -Path $Script:TestsPath -ChildPath 'Integration'
    if (-not (Test-Path $integrationPath) -or
        -not (Get-ChildItem -Path $integrationPath -Filter '*.Tests.ps1' -Recurse)) {
        Write-Build Yellow '  No integration tests found, skipping.'
        return
    }

    # Capture variables before crossing the process boundary
    $testsPath = $Script:TestsPath
    $moduleName = $Script:ModuleName
    $psd1Path = Join-Path $Script:BuiltModuleBase "$($Script:ModuleName).psd1"
    
    pwsh -WorkingDirectory $Script:ProjectRoot -NoProfile -NonInteractive -Command {
        param($TestsPath, $ModuleName, $Psd1Path)

        Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

        # Ensure we are testing the built/signed output, not the source
        if (Get-Module -Name $ModuleName) {
            Remove-Module -Name $ModuleName -Force
        }
        Import-Module $Psd1Path -Force

        $pesterConfig = New-PesterConfiguration
        # Run Settings
        $pesterConfig.Run.Path = Join-Path $TestsPath 'Integration'
        $pesterConfig.Run.PassThru = $true
        # Output Settings
        $pesterConfig.Output.Verbosity = 'Normal'
        # Test Result Settings
        $pesterConfig.TestResult.Enabled = $true
        $pesterConfig.TestResult.OutputFormat = 'JUnitXml'
        $pesterConfig.TestResult.OutputPath = Join-Path $TestsPath 'Results/TestResults-Integration.xml'

        #$results = Invoke-Pester -Configuration $pesterConfig -Data @{ ModulePath = $Psd1Path}
        $results = Invoke-Pester -Configuration $pesterConfig

        Write-Host "  Passed: $($results.PassedCount)   Failed: $($results.FailedCount)   Skipped: $($results.SkippedCount)"

        if ($results.FailedCount -gt 0) {
            throw "Integration tests: $($results.FailedCount) test(s) failed."
        }

        Write-Host '  All integration tests passed.'
        exit 0
    } -args $testsPath, $moduleName, $psd1Path

    if ($LASTEXITCODE -ne 0) {
        throw 'Integration test task failed — see output above.'
    }
}

#------------------------------------------------------------------------------
# Changelog - update CHANGELOG.md with commits since last tag
#------------------------------------------------------------------------------
task Changelog Version, {
    Write-Build Cyan 'Updating changelog...'
    New-Changelog -Version $Script:ResolvedVersion
    Write-Build Green '  Changelog updated.'
}

#------------------------------------------------------------------------------
# Tag - commit manifest change and create git tag
#------------------------------------------------------------------------------
task Tag Version, {
    Write-Build Cyan "Tagging release v$($Script:ResolvedVersion)..."
    New-GitTag -Version $Script:ResolvedVersion
    if ($Script:PushTag) {
        Write-Build Cyan '  Pushing tag to remote...'
        Push-GitRelease -Version $Script:ResolvedVersion
    }
    Write-Build Green "  Tagged: v$($Script:ResolvedVersion)"
}

#------------------------------------------------------------------------------
# Publish - publish the module to the configured repository
#
# For PSGallery:        set $env:PSGALLERY_KEY to your NuGet API key
# For private repos:    register the repo first with Register-PSRepository,
#                       then set $env:PSGALLERY_KEY to its API key (if required),
#                       or leave it unset if the repo uses credential-free auth
#                       (e.g. a local file share or internal NuGet feed that
#                       trusts the current user).
#------------------------------------------------------------------------------
task Publish {
    Write-Build Cyan "Publishing $($Script:ModuleName) $($Script:BuiltVersion) to '$($Script:Repository)'..."

    # Verify the repository is registered
    if (-not (Get-PSRepository -Name $Script:Repository -ErrorAction SilentlyContinue)) {
        throw "Repository '$($Script:Repository)' is not registered. Run Register-PSRepository first."
    }

    $publishPath = Join-Path $Script:OutputPath $Script:ModuleName |
        Join-Path -ChildPath $Script:BuiltVersion

    if (-not (Test-Path $publishPath)) {
        throw "Publish path not found: $($publishPath) - run the Build task first."
    }

    $publishParams = @{
        Path       = $publishPath
        Repository = $Script:Repository
    }

    # NuGetApiKey is optional - private repos using credential-based or
    # anonymous auth (e.g. internal NuGet feeds, local file shares) don't need it.
    if ($env:PSGALLERY_KEY) {
        $publishParams['NuGetApiKey'] = $env:PSGALLERY_KEY
    } else {
        #Write-Build Yellow "  PSGALLERY_KEY not set - publishing without API key."
    }

    Publish-Module @publishParams
    Write-Build Green "  Published: $($Script:ModuleName) $($Script:BuiltVersion) → $($Script:Repository)"
}

#------------------------------------------------------------------------------
# Release - full release pipeline
#------------------------------------------------------------------------------
task Release Clean, Version, Build, Sign, TestIntegration, Changelog, Tag, Publish, {
    Write-Build Green "Release pipeline complete! Version $($Script:ResolvedVersion) published to $($Script:Repository)."
}
