<#
.SYNOPSIS
    Root wrapper for the Invoke-Build pipeline in build/.build.ps1
#>

[CmdletBinding()]
param(
    [string[]]$Task,
    [string]$SemVer,
    [ValidateSet("major", "minor", "patch")]
    [string]$VersionBump,
    [switch]$Clean,
    [switch]$Test,
    [switch]$TestIntegration,
    [switch]$TestUnit,
    [switch]$Analyze,
    [switch]$Publish,
    [switch]$PushTag,
    [switch]$Release
)

$buildFile = Join-Path $PSScriptRoot 'build/.build.ps1'

if (-not (Test-Path $buildFile)) {
    throw "Build script not found: $buildFile"
}

$tasksToRun = [System.Collections.Generic.List[string]]::new()

if ($Task -and $Task.Count -gt 0) {
    $Task | ForEach-Object { $tasksToRun.Add($_) }
} elseif ($Release) {
    $tasksToRun.Add("Release")
} else {
    if ($Clean) { $tasksToRun.Add("Clean") }
    $tasksToRun.Add("Build")
    if ($Test) { $tasksToRun.Add("TestUnit") }
    if ($Publish) { $tasksToRun.Add("Publish") }
}

$ibParams = @{
    Task = $tasksToRun.ToArray()
    File = $buildFile
}

if ($SemVer) { $ibParams.SemVer = $SemVer }
if ($VersionBump) { $ibParams.VersionBump = $VersionBump }
if ($PushTag) { $ibParams.PushTag = $true }

Write-Host ""
Write-Host "Running Invoke-Build tasks: $($tasksToRun -join ', ')" -ForegroundColor Cyan
Write-Host ""

Invoke-Build @ibParams