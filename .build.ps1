<#
.SYNOPSIS
    InvokeBuild script for the EmailAddress module.

.DESCRIPTION
    Defines build tasks for the EmailAddress module using InvokeBuild.
    Tasks cover the full pipeline: clean, analyze, build, test, and publish.

.NOTES
    Author(s):  [.Keslar <crk4@pitt.edu>
    Requires:   InvokeBuild, ModuleBuilder, Pester, PSScriptAnalyzer
                Install via: Resolve-Dependency (RequiredModules.psd1)

.EXAMPLE
    # Run the default task (Analyze → Build → Test)
    Invoke-Build

.EXAMPLE
    # Clean, then run the full pipeline
    Invoke-Build Clean, Analyze, Build, Test

.EXAMPLE
    # Build and run only unit tests
    Invoke-Build Build, TestUnit

.EXAMPLE
    # Full release pipeline: clean, analyze, build, test, publish
    Invoke-Build Release
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    # Semantic version to stamp on the build. If omitted, resolved automatically
    # via version.txt, git tags, GitVersion, or manifest auto-increment (in that order).
    [string]$SemVer,

    # NuGet API key for PowerShell Gallery publication.
    # Defaults to the PS_GALLERY_KEY environment variable.
    [string]$GalleryApiKey = $env:PS_GALLERY_KEY
)

###############################################################################
## Script-level constants
###############################################################################
$Script:ProjectRoot = $BuildRoot
$Script:ModuleName = Split-Path -Path $Script:ProjectRoot -Leaf
$Script:SourcePath = Join-Path -Path $Script:ProjectRoot -ChildPath 'Source'
$Script:BuildOutput = Join-Path -Path $Script:ProjectRoot -ChildPath 'Build'
$Script:TestsPath = Join-Path -Path $Script:ProjectRoot -ChildPath 'Tests'
$Script:UnitTestsPath = Join-Path -Path $Script:TestsPath   -ChildPath 'Unit'
$Script:IntTestsPath = Join-Path -Path $Script:TestsPath   -ChildPath 'Integration'
$Script:AnalyzerSettings = Join-Path -Path $Script:ProjectRoot -ChildPath 'PSScriptAnalyzerSettings.ps1'
$Script:ConfigPath = Join-Path -Path $Script:ProjectRoot -ChildPath 'Config'
$Script:Repository = "PSGallery" # default repository, can be overridden by LocalRepo.ps1 in the Config directory if present

$Script:Repository = "PittITPSModules"
##
$Script:AllowSelfSignedCerts = $false

###############################################################################
## Local Configuration overides
###############################################################################
# Local Repository Connections or use PSGallery by default if no Config/LocalRepo.ps1 is found. This allows the build script to work out-of-the-box without any required configuration, while still supporting connection to the Pitt Teams module repository for devs who have access to it and want to use it for faster module installation during development.
if ( Test-Path -Path (Join-Path -Path $Script:ProjectRoot -ChildPath 'LocalRepo.ps1') ) {
    # Import repository connection setup functions from Config/LocalRepo.ps1
    #todo: think through what functions this file should expose and whether it should be split into multiple files if it grows much larger. For now it just has functions for connecting to the Pitt Teams module repository, but we may want to add other repo-related functions in the future (e.g. for connecting to an internal Artifactory instance or something like that).
    . "$Script:ConfigPath/LocalRepo.ps1"
} else {
    #todo: add repo functions for connecting to the PSGallery if we want/need them, but for now we'll just rely on the fact that PSGallery is the default repo and skip any setup if no Config directory is found. This will allow the build script to work out-of-the-box without any required configuration, while still supporting connection to the Pitt Teams module repository for devs who have access to it and want to use it for faster module installation during development. 
    # Use PSGallery as the default repository if no Config directory is found
    #Write-Build Yellow "No LocalRepo.ps1 in Config directory found at $($Script:ConfigPath). Using default repository connection settings (PSGallery)."
    $Script:Repository = 'PSGallery'
}

###############################################################################
## Version resolution — shared by Build and any task that needs the version
###############################################################################
if ($SemVer) {
    $Script:SemwareVersion = $SemVer
}

function Get-BuildVersion {
    <#
    .SYNOPSIS
        Resolves the semantic version for this build using a priority chain.
    #>
    $version = '0.0.0'
    
    #Write-Build Cyan 'Resolving build version...'
    # Was a SemVer passed?
    
    if ( $null -ne $script:SemVersion ) {
        # Use SemVer passed to the script
        #Write-Build DarkCyan "  Version source: CLI ($script:SemVersion)"
        return $script:SemVersion
    } 

    # Is there a version.txt in the ProjectRoot directory
    #Write-Build Cyan '  No version passed via CLI. Checking for version.txt...'
    #Write-Build Cyan "  Looking for version.txt in $($script:ProjectRoot)..."
    $versionFile = Join-Path -Path $script:ProjectRoot -ChildPath "version.txt"
    if ( Test-Path -Path $versionFile ) {
        # Read version from version.txt file
        $version = (Get-Content version.txt | Where-Object { ($_.trim().length -gt 0) -and (-not $_.Trim().StartsWith("#")) } | Select-Object -First 1)
        return $version
    }

    # Let's try to get the version from git
    $gitDir = Join-Path -Path $script:ProjectRoot -ChildPath ".git"
    if ( (Test-Path -Path $gitDir -PathType Container) -and (Get-Command "git" -ErrorAction SilentlyContinue)) {
        if (Get-Command "gitversion" -ErrorAction SilentlyContinue) {
            # Get version using gitversion
            $version = (gitversion | ConvertFrom-Json).FullSemVer
            #Write-Build DarkCyan "  Version source: GitVersion ($version)"
            return $version
        } else {
            # gitversion not installed, let's get it from git tags
            $tag = git describe --tags --abbrev=0 2>$null
            if ($tag) {
                $version = $tag.TrimStart('v')
                #Write-Build DarkCyan "  Version source: git tag ($version)"
                return $version
            }
        }
    }
    
    # fallback plan, read the manifest and autoincrement the version 
    $manifestPath = Join-Path -Path $Script:SourcePath -ChildPath "$($Script:ModuleName).psd1"
    $manifest = Import-PowerShellDataFile $manifestPath
    $current = [version]$manifest.ModuleVersion
    $version = '{0}.{1}.{2}' -f $current.Major, $current.Minor, ($current.Build + 1)
    #Write-Build Yellow "  Version source: manifest auto-increment ($v)"
    return $version
}


###############################################################################
## Tasks
###############################################################################

# Default task — run when Invoke-Build is called with no task name
task . Analyze, Build, Sign, TestUnit

#------------------------------------------------------------------------------
# Clean — remove all build output
#------------------------------------------------------------------------------
task Clean {
    Write-Build Cyan 'Cleaning build output...'
    $moduleOutput = Join-Path $Script:BuildOutput $Script:ModuleName
    if (Test-Path $moduleOutput) {
        Remove-Item -Path $moduleOutput -Recurse -Force
        Write-Build Green "  Removed: $moduleOutput"
    } else {
        Write-Build DarkGray '  Nothing to clean.'
    }
}

#------------------------------------------------------------------------------
# Analyze — run PSScriptAnalyzer against all source files
#------------------------------------------------------------------------------
task Analyze {
    Write-Build Cyan 'Running PSScriptAnalyzer...'

    $analyzeParams = @{
        Path        = $Script:SourcePath
        Settings    = $Script:AnalyzerSettings
        Recurse     = $true
        ErrorAction = 'SilentlyContinue'
    }

    $findings = Invoke-ScriptAnalyzer @analyzeParams  | Where-Object { $_.Severity -ne 'Information' }


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
# SignedBuild — build the module and sign the output with a code signing certificate
#------------------------------------------------------------------------------
task Sign Build, {
    Write-Build Cyan 'Signing built module...'

    if (Test-Path -Path (Join-Path $Script:ConfigPath -ChildPath "Get-CodeSigningCertificate.ps1")) {
        #Write-Build Green "Importing code signing certificate retrieval function from $($Script:ConfigPath)/Get-CodeSigningCertificate.ps1)"
        . (Join-Path $Script:ConfigPath -ChildPath "Get-CodeSigningCertificate.ps1")
    } else {
        function Get-CodeSigningCertificate {
            param (
                [switch]$AllowSelfSigned
            )
            $codeSigningCerts = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.NotAfter -gt (Get-Date) }
            if ( $AllowSelfSigned ) {
                return $codeSigningCerts | Select-Object -First 1
            } else {
                return $codeSigningCerts | Where-Object { -not $_.Verify() } | Select-Object -First 1
            }
        }
    }

    if (-not $Script:BuiltModuleBase) {
        throw 'BuiltModuleBase is not set. Run the Build task first.'
    }

    $timestampServer = "http://timestamp.digicert.com"

    if ($Script:AllowSelfSignedCerts) {
        $cert = Get-CodeSigningCertificate -AllowSelfSigned
    } else {
        $cert = Get-CodeSigningCertificate
    }
    
    if ($cert) {
        foreach ( $moduleFile in (Get-ChildItem -Path $Script:BuiltModuleBase -Include *.psd1, *.psm1 -Recurse) ) {
            #Write-Build Green "  Signing: $($moduleFile.FullName) with certificate: $($cert.Subject)"
            #$results = Set-AuthenticodeSignature -FilePath $moduleFile.FullName -Certificate $cert -TimestampServer $timestampServer -HashAlgorithm SHA256
            #Write-Build Green "  Signed module with certificate: $($cert.Subject)"    
        }
        
    } else {
        Write-Build Yellow "  No code signing certificate configured. Skipping signing."
    }

}
#------------------------------------------------------------------------------
# Build — compile source into a single .psm1 via ModuleBuilder
#------------------------------------------------------------------------------
task Build {
    Write-Build Cyan 'Building module...'

    $version = Get-BuildVersion
    #Write-Build DarkCyan "  Resolved version: [$version]"

    $buildParams = @{
        SourcePath      = $Script:SourcePath
        OutputDirectory = $Script:BuildOutput
        SemVer          = $version.Replace('-', '.')
    }

    $module = Build-Module @buildParams -Passthru
    
    # Stamp {{BUILD_DATE}} and {{MODULE_VERSION}} placeholders in the built .psm1
    $psm1Path = Join-Path $module.ModuleBase "$($module.Name).psm1"
    if (Test-Path $psm1Path) {
        $buildDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $content = Get-Content $psm1Path -Raw
        $contentUpdated = $false
    
        if ($content -match '\{\{BUILD_DATE\}\}') {
            $content = $content -replace '\{\{BUILD_DATE\}\}', $buildDate
            $contentUpdated = $true
        }
    
        if ($content -match '\{\{MODULE_VERSION\}\}') {
            $content = $content -replace '\{\{MODULE_VERSION\}\}', $version
            $contentUpdated = $true
        }
    
        if ($contentUpdated) {
            Set-Content -Path $psm1Path -Value $content -NoNewline
            Write-Build DarkCyan "  Stamped version $version and build date $buildDate"
        }
    }
    
    Write-Build Green "  Built: $($module.Name) $($module.Version) → $($module.ModuleBase)"
    
    # Persist the resolved module base path for downstream tasks
    $Script:BuiltModuleBase = $module.ModuleBase
    $Script:BuiltVersion = $module.Version   
}

#------------------------------------------------------------------------------
# TestUnit — run unit tests against dot-sourced source files (no Import-Module)
#------------------------------------------------------------------------------
task TestUnit {
    Write-Build Cyan 'Running unit tests...'

    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    $config = New-PesterConfiguration
    $config.Run.Path = $Script:UnitTestsPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Normal'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = 'JUnitXml'
    $config.TestResult.OutputPath = Join-Path $Script:TestsPath 'Results/TestResults-Unit.xml'
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        "$($Script:SourcePath)/**/*.ps1"
    )
    $config.CodeCoverage.OutputPath = Join-Path $Script:TestsPath 'Results/Coverage-Unit.xml'
    # $config.CodeCoverage.Threshold = 90

    $results = Invoke-Pester -Configuration $config

    Write-Build White "  Passed: $($results.PassedCount)   Failed: $($results.FailedCount)   Skipped: $($results.SkippedCount)"

    if ($results.FailedCount -gt 0) {
        throw "Unit tests: $($results.FailedCount) test(s) failed."
    }

    if ($results.CodeCoverage.CoveragePercent -lt 90) {
        throw "Code coverage $([math]::Round($results.CodeCoverage.CoveragePercent, 1))% is below the 90% threshold."
    }

    Write-Build Green "  All unit tests passed. Coverage: $([math]::Round($results.CodeCoverage.CoveragePercent, 1))%"
}

#------------------------------------------------------------------------------
# TestIntegration — run integration tests against the *built* module output
#------------------------------------------------------------------------------
task TestIntegration Sign, Build, {
    Write-Build Cyan 'Running integration tests...'

    if (-not $Script:BuiltModuleBase) {
        throw 'BuiltModuleBase is not set. Run the Build task first.'
    }

    if (-not (Test-Path $Script:IntTestsPath)) {
        Write-Build Yellow '  No integration tests found — skipping.'
        return
    }

    # Integration tests import the built module, not dot-sourced source files
    $env:EMAILADDRESS_BUILT_MODULE = $Script:BuiltModuleBase

    $config = New-PesterConfiguration
    $config.Run.Path = $Script:IntTestsPath
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Normal'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputFormat = 'JUnitXml'
    $config.TestResult.OutputPath = Join-Path $Script:ProjectRoot 'TestResults-Integration.xml'

    $results = Invoke-Pester -Configuration $config

    Write-Build White "  Passed: $($results.PassedCount)   Failed: $($results.FailedCount)   Skipped: $($results.SkippedCount)"

    if ($results.FailedCount -gt 0) {
        throw "Integration tests: $($results.FailedCount) test(s) failed."
    }

    Write-Build Green '  All integration tests passed.'
}

#------------------------------------------------------------------------------
# Test — run both unit and integration test suites
#------------------------------------------------------------------------------
task Test TestUnit, TestIntegration

#------------------------------------------------------------------------------
# Publish — publish the built module to the PowerShell Gallery
#------------------------------------------------------------------------------
task Publish Build, Test, {
    # Register Repository if needed (e.g. if using the Pitt Teams repo during development)
    if ( $Script:Repository -eq 'PittTeams' ) {
        Write-Build Cyan "Registering Pitt Teams repository for publication..."
        Register-PittTeamsRepository -Name PittITPSModules -URI \\pittitteams.file.core.windows.net\psmodules -Trusted
    }

    Write-Build Cyan 'Publishing to PowerShell Gallery...'

    if (-not $Script:BuiltModuleBase) {
        throw 'BuiltModuleBase is not set. Run the Build task first.'
    }

    if ([string]::IsNullOrWhiteSpace($GalleryApiKey)) {
        throw 'No Gallery API key. Pass -GalleryApiKey or set the PS_GALLERY_KEY environment variable.'
    }

    if ( $Script:Repository -eq 'PSGallery' ) {
        Publish-Module -Path $Script:BuiltModuleBase -NuGetApiKey $GalleryApiKey
        Write-Build Green "  Published $Script:ModuleName $Script:BuiltVersion to the PowerShell Gallery."
    } else {
        Write-Build Yellow "  Repository is set to $Script:Repository. Skipping publication to PowerShell Gallery."
        Publish-PSResource -Path $BuiltModuleBase -Repository $Script:Repository # -NuGetApiKey $GalleryApiKey
        Write-Build Green "  Published $Script:ModuleName $Script:BuiltVersion to repository $Script:Repository."
    }
}

#------------------------------------------------------------------------------
# Release — full pipeline: clean, analyze, build, test, publish
#------------------------------------------------------------------------------
task Release Clean, Analyze, Build, Sign, Test, Publish
