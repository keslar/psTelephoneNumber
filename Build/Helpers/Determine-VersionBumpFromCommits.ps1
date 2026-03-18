<#
.SYNOPSIS
    Determines the type of version bump (major, minor, patch) based on commit messages since the last tag

.DESCRIPTION
    This function analyzes commit messages to determine the appropriate version bump type.

.PARAMETER LastTag
    The last git tag to compare against.

.EXAMPLE
    Determine-VersionBumpFromCommits -LastTag "v1.0.0"
#>
function Determine-VersionBumpFromCommits {
    param(
        [string]$LastTag
    )
    $commits = git log "$LastTag..HEAD" --pretty=format:"%s"
    if (-not $commits) { 
        return "patch" 
    }
    $major = $false
    $minor = $false
    foreach ($c in $commits) {
        if (($c -match "BREAKING CHANGE") -or ($c -match "feat!?:")) { 
            $major = $true 
        } elseif ($c -match "^feat") { 
            $minor = $true 
        }
    }
    if ($major) { 
        return "major" 
    } elseif ($minor) { 
        return "minor" 
    } else {
        return "patch"
    }
}
