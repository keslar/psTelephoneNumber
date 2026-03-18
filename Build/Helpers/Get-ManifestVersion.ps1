<#
.SYNOPSIS
    Gets the current version from the module manifest.

.DESCRIPTION
    This function reads the module manifest file and returns the current version.

.OUTPUTS
    System.String
#>
function Get-ManifestVersion { 
    (Import-PowerShellDataFile ($Script:ManifestPath)).ModuleVersion 
}
