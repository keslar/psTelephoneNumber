<#
.SYNOPSIS
    Pushes the current commit and a new tag to the remote repository.   

.DESCRIPTION
    This function takes a version string, constructs the corresponding tag name, and pushes both the current commit and the specified tag to the remote repository. It uses standard git commands to perform these operations.

.PARAMETER Version
    The version string to use for the git tag. The function will prepend "v" to
    the version to create the tag name (e.g., "v1.0.0").

.EXAMPLE
    Push-GitRelease -Version "1.0.0"

    This command will push the current commit and the git tag named "v1.0.0" to the remote repository.
    
.NOTES
    This function assumes that git is installed and available in the system's PATH.
    It also assumes that the current directory is a git repository and that there are
    changes to push. Make sure to handle any potential errors that may arise from
    these assumptions in a production environment.
    
#>
function Push-GitRelease { 
    param(
        [string]$Version
    ) 
    $tag = "v$Version"
    git push
    git push origin $tag
    Write-Host "Pushed commit and tag $tag" -ForegroundColor Cyan 
}