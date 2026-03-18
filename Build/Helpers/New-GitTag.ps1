<#
.SYNOPSIS
    Creates a new git tag for the specified version and commits the changes

.DESCRIPTION
    This function takes a version string, creates a git tag in the format "v{Version}", 
    and commits any changes with a message indicating the release. It uses standard 
    git commands to add changes, commit them, and create the tag.

.PARAMETER Version
    The version string to use for the git tag. The function will prepend "v" to
    the version to create the tag name (e.g., "v1.0.0").

.EXAMPLE
    New-GitTag -Version "1.0.0"

    This command will create a git tag named "v1.0.0" and commit any changes with the message "Release v1.0.0".

.NOTES
    This function assumes that git is installed and available in the system's PATH. 
    It also assumes that the current directory is a git repository and that there are 
    changes to commit. Make sure to handle any potential errors that may arise from 
    these assumptions in a production environment.

#>
function New-GitTag {
    param([string]$Version)
    $tag = "v$Version"

    # Stage only tracked files — respects .gitignore
    git add -u

    # Only commit if there are staged changes
    $status = git status --porcelain
    if ($status) {
        git commit -m "Release $tag"
    } else {
        Write-Host "  No changes to commit for $tag" -ForegroundColor DarkGray
    }

    # Only create tag if it doesn't already exist
    $existing = git tag --list $tag
    if ($existing) {
        Write-Host "  Tag $tag already exists, skipping." -ForegroundColor Yellow
    } else {
        git tag -a $tag -m "Release $tag"
        Write-Host "  Git tag $tag created" -ForegroundColor Cyan
    }
}