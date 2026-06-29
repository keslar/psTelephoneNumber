<#
.SYNOPSIS
    Returns all supported telephone number country codes.

.DESCRIPTION
    Retrieves all country code definitions currently available from the
    CountryCode class data source.

.OUTPUTS
    System.Object[]

.EXAMPLE
    Get-TelephoneNumberAllCountryCodes

    Returns all configured country code records.
#>
function Get-TelephoneNumberAllCountryCodes {
    [CmdletBinding()]
    [OutputType([CountryCode])]
    param ()

    return [CountryCode]::GetAllCountryCodes()
}
