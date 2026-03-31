<#
.SYNOPSIS
    Returns national destination codes for a country.

.DESCRIPTION
    Retrieves all NationalDestinationCode objects associated with a country,
    using either an ISO code or a country calling code.

.PARAMETER ISO
    The ISO country code used to find matching national destination codes.

.PARAMETER Code
    The country calling code used to find matching national destination codes.

.OUTPUTS
    System.Object[]

.EXAMPLE
    Get-TelephoneNumberNationalDestinationCodes -ISO 'USA'

    Returns all national destination codes for the specified ISO country code.

.EXAMPLE
    Get-TelephoneNumberNationalDestinationCodes -Code '+1'

    Returns all national destination codes for countries that use the supplied
    calling code.
#>
function Get-TelephoneNumberNationalDestinationCodes {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = "ByISO", Mandatory = $true)]
        [string]$ISO,
        [Parameter(ParameterSetName = "ByCode", Mandatory = $true)]
        [string]$Code
    )
    if ($ISO) {
        $CountryCodes = [CountryCode]::FindByISO($ISO)
    } else {
        $CountryCodes = [CountryCode]::FindByCode($Code)
    }

    $NationalDestinationCodes = @()
    foreach ($CountryCode in $CountryCodes) {
        $NDCs = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCode)
        $NationalDestinationCodes += $NDCs
    }
    return $NationalDestinationCodes
}
