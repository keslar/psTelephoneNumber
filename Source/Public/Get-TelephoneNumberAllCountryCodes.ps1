function Get-TelephoneNumberAllCountryCodes {
    [CmdletBinding()]
    param ()
    return [CountryCode]::GetAllCountryCodes()
}