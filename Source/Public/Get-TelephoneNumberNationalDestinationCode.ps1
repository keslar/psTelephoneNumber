<#
.SYNOPSIS
    Returns the national destination code for a telephone number.

.DESCRIPTION
    Parses the supplied telephone number and returns the matching
    NationalDestinationCode object.

.PARAMETER TelephoneNumber
    The telephone number to inspect.

.OUTPUTS
    NationalDestinationCode

.EXAMPLE
    Get-TelephoneNumberNationalDestinationCode -TelephoneNumber '+14121234567'

    Returns the national destination code object associated with the supplied
    telephone number.
#>
function Get-TelephoneNumberNationalDestinationCode {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = "ByTelephoneNumber", Mandatory = $true)]
        [string]$TelephoneNumber
    )
    $PhoneNumber = [TelephoneNumber]::new($TelephoneNumber)
    if (-not $PhoneNumber.Value) {
        throw "Invalid telephone number format. Please provide a valid number."
    }
    return $PhoneNumber.GetNationalDestinationCode()
}
