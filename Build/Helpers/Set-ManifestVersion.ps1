<#
.SYNOPSIS
    Updates the module manifest with a new version.

.DESCRIPTION
    This function takes a version string as input and updates the module manifest file with the new version using the Update-ModuleManifest cmdlet. It retrieves the path to the manifest file using the Get-ManifestPath function.

.PARAMETER Version
    The new version string to set in the module manifest. This should be in a valid semantic versioning format (e.g., 1.0.0).

.OUTPUTS
    None. This function performs an update operation on the module manifest file and outputs a confirmation message to the console.

.EXAMPLE
    Set-ManifestVersion -Version "1.2.3"
    This command updates the module manifest to version 1.2.3 and outputs a confirmation message.

.NOTES
    Ensure that the version string provided is valid and that the module manifest file exists at the expected
    location. This function relies on the Get-ManifestPath function to locate the manifest file, so it should be defined and accessible in the same context.

#>
function Set-ManifestVersion { 
    param(
        [string]$Version
    ) 
    # Update the ModuleVersion field
    Update-ModuleManifest -Path ($Script:ManifestPath) -ModuleVersion $Version

    # Update the IconUri version tag in the manifest (e.g. .../v1.0.0/... -> .../v1.2.3/...)
    $content = Get-Content -Path $Script:ManifestPath -Raw
    $updated = $content -replace '(https://raw\.githubusercontent\.com/keslar/psTelephoneNumber/)v[\d]+\.[\d]+\.[\d]+(/.+)', "`${1}v$Version`${2}"
    if ($updated -ne $content) {
        Set-Content -Path $Script:ManifestPath -Value $updated -NoNewline
        Write-Host "  IconUri version tag updated to v$Version" -ForegroundColor Green
    }

    Write-Host "Module manifest updated to version $Version" -ForegroundColor Green 
}
