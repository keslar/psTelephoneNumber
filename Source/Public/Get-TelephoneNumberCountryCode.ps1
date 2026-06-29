<#
.SYNOPSIS
    Returns the country code for a telephone number.

.DESCRIPTION
    Parses the supplied telephone number and returns the matching CountryCode
    object.

.PARAMETER TelephoneNumber
    The telephone number to inspect.

.OUTPUTS
    CountryCode

.EXAMPLE
    Get-TelephoneNumberCountryCode -TelephoneNumber '+14125551234'

    Returns the country code object associated with the supplied telephone
    number.
#>
function Get-TelephoneNumberCountryCode {
    [CmdletBinding()]
    [OutputType([CountryCode])]
    param (
        [Parameter(Mandatory)]
        [string]$TelephoneNumber
    )
    $PhoneNumber = [TelephoneNumber]::new($TelephoneNumber)
    if (-not $PhoneNumber.Value) {
        throw 'Invalid telephone number format. Please provide a valid number.'
    }
    return $PhoneNumber.GetCountryCode()
}
