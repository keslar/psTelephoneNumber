<#
.SYNOPSIS
    Determines the next semantic version based on the current version 
    and the type of bump (major, minor, patch).

.DESCRIPTION
    This function takes the current version and a specified bump type 
    to calculate the next semantic version. It uses the .NET [version] 
    type to parse the current version and then constructs the new version 
    string based on the bump type.

.PARAMETER CurrentVersion
    The current version string in semantic versioning format (e.g., 1.0.0).

.PARAMETER Bump
    The type of version bump to apply. This can be "major", "minor", or 
    "patch". The default is "patch".

.OUTPUTS
    A string representing the next semantic version based on the current 
    version and the specified bump type.   

.EXAMPLE
    Get-NextSemVer -CurrentVersion "1.2.3" -Bump "minor"
    This command will return "1.3.0" as the next semantic version.

.NOTES
    Ensure that the CurrentVersion parameter is in a valid semantic 
    versioning format. The function relies on the .NET [version] type for 
    parsing, so it should be compatible with standard version formats.    

#>
function Get-NextSemVer {
    param(
        [string]$CurrentVersion, 
        [ValidateSet("major", "minor", "patch")]
        $Bump = "patch"
    )
    
    $v = [version]$CurrentVersion
    switch ($Bump) {
        "major" { 
            return "{0}.{1}.{2}" -f ($v.Major + 1), 0, 0 
        }
        "minor" { 
            return "{0}.{1}.{2}" -f $v.Major, ($v.Minor + 1), 0 
        }
        "patch" { 
            return "{0}.{1}.{2}" -f $v.Major, $v.Minor, ($v.Build + 1) 
        }
    }
}
