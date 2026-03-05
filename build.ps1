<#
.SYNOPSIS
    Convenience wrapper around the InvokeBuild pipeline for the EmailAddress module.

.DESCRIPTION
    Delegates all build logic to .build.ps1 via Invoke-Build. This wrapper exists
    so that callers using the original build.ps1 interface continue to work without
    change. All build logic lives in .build.ps1 — do not add logic here.

.PARAMETER SemVer
    Semantic version to stamp on the build. Passed through to .build.ps1.
    If omitted, version is resolved automatically via version.txt, git tags,
    GitVersion, or manifest auto-increment.

.PARAMETER Test
    When specified, runs the full test suite (unit + integration) after building.
    Maps to the Test task in .build.ps1.

.PARAMETER Publish
    When specified, publishes the built module to the PowerShell Gallery after
    a successful build and test run. Requires PS_GALLERY_KEY to be set.
    Maps to the Publish task in .build.ps1.

.PARAMETER Clean
    When specified, wipes the Build/ output directory before building.
    Maps to the Clean task in .build.ps1.

.EXAMPLE
    # Build only
    ./build.ps1

.EXAMPLE
    # Build and test
    ./build.ps1 -Test

.EXAMPLE
    # Clean, build, test, and publish
    ./build.ps1 -Clean -Test -Publish

.EXAMPLE
    # Build a specific version
    ./build.ps1 -SemVer '1.0.0'
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$SemVer,
    [switch]$Clean,
    [switch]$Test,
    [switch]$Publish
)

# Resolve which InvokeBuild tasks to run based on the switches provided
$tasks = [System.Collections.Generic.List[string]]::new()

if ($Clean) { $tasks.Add('Clean') }

# Always build
$tasks.Add('Build')

if ($Test) { $tasks.Add('Test') }
if ($Publish) { $tasks.Add('Publish') }

# Pass -SemVer through to .build.ps1 only when explicitly provided,
# so .build.ps1's own version resolution runs when it is omitted.
$ibParams = @{
    Task = $tasks.ToArray()
    File = Join-Path $PSScriptRoot '.build.ps1'
}
if ($SemVer) { $ibParams.SemVer = $SemVer }

Invoke-Build @ibParams
