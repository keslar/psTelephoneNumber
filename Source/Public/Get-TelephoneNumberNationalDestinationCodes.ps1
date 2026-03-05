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
