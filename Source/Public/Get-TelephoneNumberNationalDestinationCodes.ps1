<#
.SYNOPSIS
    Returns national destination codes for a country.

.DESCRIPTION
    Retrieves all NationalDestinationCode objects associated with a country,
    using either an ISO code or a country calling code.

.PARAMETER ISO
    The ISO country code used to find matching national destination codes.

.PARAMETER CallingCode
    The country calling code used to find matching national destination codes.

.OUTPUTS
    System.Object[]

.EXAMPLE
    Get-TelephoneNumberNationalDestinationCodes -ISO 'USA'

    Returns all national destination codes for the specified ISO country code.

.EXAMPLE
    Get-TelephoneNumberNationalDestinationCodes -CallingCode '+1'

    Returns all national destination codes for countries that use the supplied
    calling code.
#>
function Get-TelephoneNumberNationalDestinationCodes {
    [CmdletBinding()]
    [OutputType([NationalDestinationCode])]
    param (
        [Parameter(ParameterSetName = 'ByISO', Mandatory)]
        [string]$ISO,
        [Parameter(ParameterSetName = 'ByCode', Mandatory)]
        [string]$CallingCode
    )
    $CountryCodes = if ($ISO) {
        @([CountryCode]::FindByISO($ISO))
    } else {
        [CountryCode]::FindByCode($CallingCode)
    }

    $NationalDestinationCodes = [System.Collections.Generic.List[NationalDestinationCode]]::new()
    foreach ($CodeEntry in $CountryCodes) {
        $NdcList = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CodeEntry)
        foreach ($NdcEntry in $NdcList) {
            $NationalDestinationCodes.Add($NdcEntry)
        }
    }
    return $NationalDestinationCodes
}
