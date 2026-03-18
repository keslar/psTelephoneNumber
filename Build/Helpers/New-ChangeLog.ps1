<#
.SYNOPSIS
    Generates a changelog based on commit messages since the last tag and updates the CHANGELOG.md file

.DESCRIPTION
    This function creates a new entry in the CHANGELOG.md file for the specified version, listing all features and fixes introduced since the last tag.

.PARAMETER Version
    The version string for which to generate the changelog entry.
#>
function New-Changelog {
    param(
        [string]$Version
    )
    
    if (-not (Test-Path $Script:ChangelogPath)) { 
        New-Item -ItemType File -Path $Script:ChangelogPath -Force | Out-Null 
    }
    
    try { 
        $lastTag = git describe --tags --abbrev=0 
    } catch { 
        $lastTag = "" 
    }

    $commits = git log "$lastTag..HEAD" --pretty=format:"%s"
    $features = $commits | Where-Object { $_ -match "^feat" }
    $fixes = $commits | Where-Object { $_ -match "^fix" }
    $log = @()
    $log += "## $Version"
    $log += ""

    if ($features) { 
        $log += "### Added"
        $features | ForEach-Object { 
            $log += "- $_" 
        }
        $log += "" 
    }

    if ($fixes) { 
        $log += "### Fixed"
        $fixes | ForEach-Object { 
            $log += "- $_" 
        }
        $log += "" 
    }
    $existing = Get-Content $Script:ChangelogPath
    ($log + $existing) | Set-Content $Script:ChangelogPath
    Write-Host "CHANGELOG.md updated" -ForegroundColor Green
}