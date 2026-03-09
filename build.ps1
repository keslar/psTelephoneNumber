<#
.SYNOPSIS
    Root wrapper for the Invoke-Build pipeline in Build/.build.ps1

.DESCRIPTION
    Provides a friendly interface to the Invoke-Build pipeline. Use
    -Task for granular control, convenience switches for common
    workflows, or -Release for the full pipeline.

.PARAMETER Task
    One or more specific Invoke-Build tasks to run directly.
    Bypasses all convenience switch logic.
    Valid tasks: Clean, Analyze, TestUnit, Version, Build, Sign,
                 TestIntegration, Changelog, Tag, Publish, Release

.PARAMETER SemVer
    Manually set the next version (e.g. '1.2.3'). Overrides automatic
    version detection from git tags and commit messages.

.PARAMETER VersionBump
    Force a specific bump type: major, minor, or patch.
    Ignored if -SemVer is provided.

.PARAMETER Clean
    Add the Clean task before whatever else is running.

.PARAMETER Analyze
    Run static code analysis only.

.PARAMETER TestUnit
    Run unit tests only (includes Analyze).

.PARAMETER TestIntegration
    Run integration tests only (includes Build and Sign).

.PARAMETER Publish
    Add the Publish task to the pipeline.

.PARAMETER PushTag
    When tagging a release, also push the tag to the remote repository.

.PARAMETER Release
    Run the full release pipeline:
    Clean → Version → Build → Sign → TestIntegration → Changelog → Tag → Publish

.PARAMETER WhatIf
    Show which tasks would run without executing them.

.EXAMPLE
    .\build.ps1
    Default build: Version → Build → Sign → TestIntegration

.EXAMPLE
    .\build.ps1 -Release -PushTag
    Full release pipeline, pushing the tag to remote when complete.

.EXAMPLE
    .\build.ps1 -Release -VersionBump minor -PushTag
    Full release pipeline, forcing a minor version bump.

.EXAMPLE
    .\build.ps1 -Release -SemVer 1.0.0 -PushTag
    Full release pipeline, pinning the version to 1.0.0.

.EXAMPLE
    .\build.ps1 -Task Version, Build
    Run specific tasks only.

.EXAMPLE
    .\build.ps1 -TestUnit
    Run static analysis and unit tests only.

.EXAMPLE
    .\build.ps1 -Clean -TestUnit
    Clean first, then run static analysis and unit tests.

.EXAMPLE
    .\build.ps1 -WhatIf
    Show what tasks would run without executing them.

.NOTES
    Requires InvokeBuild and ModuleBuilder modules.
    Publishing requires the PSGALLERY_KEY environment variable to be set.
    Signing requires a valid code signing certificate in Cert:\CurrentUser\My.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$Task,

    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$SemVer,

    [ValidateSet('major', 'minor', 'patch')]
    [string]$VersionBump,

    [switch]$Clean,
    [switch]$Analyze,
    [switch]$TestUnit,
    [switch]$TestIntegration,
    [switch]$Publish,
    [switch]$PushTag,
    [switch]$Release
)

if (($SemVer -or $VersionBump) -and -not $Release -and -not ($Task -and $Task.Count -gt 0)) {
    Write-Warning "-SemVer and -VersionBump have no effect without -Release or -Task. Did you mean: .\build.ps1 -Release -SemVer $SemVer"
}

###############################################################################
# Resolve build file
###############################################################################
$buildFile = Join-Path $PSScriptRoot 'Build/.build.ps1'
if (-not (Test-Path $buildFile)) {
    throw "Build script not found at: $buildFile"
}

###############################################################################
# Determine tasks to run
###############################################################################
$tasksToRun = [System.Collections.Generic.List[string]]::new()

if ($Task -and $Task.Count -gt 0) {
    # Explicit task list — pass through directly, ignore all switches
    $Task | ForEach-Object { $tasksToRun.Add($_) }

} elseif ($Release) {
    $tasksToRun.Add('Release')

} elseif ($Analyze) {
    if ($Clean) { $tasksToRun.Add('Clean') }
    $tasksToRun.Add('Analyze')

} elseif ($TestUnit) {
    if ($Clean) { $tasksToRun.Add('Clean') }
    $tasksToRun.Add('TestUnit')

} elseif ($TestIntegration) {
    if ($Clean) { $tasksToRun.Add('Clean') }
    $tasksToRun.Add('TestIntegration')

} else {
    # Default: version, build, sign, integration test
    if ($Clean) { $tasksToRun.Add('Clean') }
    $tasksToRun.Add('Version')
    $tasksToRun.Add('Build')
    $tasksToRun.Add('Sign')
    $tasksToRun.Add('TestIntegration')
    if ($Publish) { $tasksToRun.Add('Publish') }
}

$ibParams = @{
    Task = $tasksToRun.ToArray()
    File = $buildFile
}

# Invoke-Build passes these through as named parameters to .build.ps1's param() block
if ($SemVer) { $ibParams['SemVer'] = $SemVer }
if ($VersionBump) { $ibParams['VersionBump'] = $VersionBump }
if ($PushTag) { $ibParams['PushTag'] = $true }

###############################################################################
# Execute
###############################################################################
Write-Host ''
Write-Host "Tasks : $($tasksToRun -join ' → ')" -ForegroundColor Cyan
if ($SemVer) { Write-Host "SemVer      : $SemVer"      -ForegroundColor DarkCyan }
if ($VersionBump) { Write-Host "VersionBump : $VersionBump" -ForegroundColor DarkCyan }
if ($PushTag) { Write-Host "PushTag     : true"         -ForegroundColor DarkCyan }
Write-Host ''

if ($PSCmdlet.ShouldProcess($buildFile, "Invoke-Build $($tasksToRun -join ', ')")) {
    Invoke-Build @ibParams
}
