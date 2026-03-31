<#
.SYNOPSIS
    Creates a TelephoneNumber object from an input string.

.DESCRIPTION
    Performs basic validation on the supplied number string and returns a new
    TelephoneNumber object when the value is in a supported format.

.PARAMETER Number
    The telephone number string to convert into a TelephoneNumber object.

.OUTPUTS
    TelephoneNumber

.EXAMPLE
    New-TelephoneNumber -Number '+1 (212) 123-4567'

    Creates a TelephoneNumber object from the supplied input string.
#>
function New-TelephoneNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Number
    )
    # Validate the telephone number format (basic validation)
    if ($Number -notmatch '^\+?[0-9\s\-\(\)]+$') {
        throw "Invalid telephone number format. Please provide a valid number."
    }
    return [TelephoneNumber]::new($Number)
}       