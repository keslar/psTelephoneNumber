function Get-TelephoneNumberSubscriberNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TelephoneNumber
    )
    $PhoneNumber = [TelephoneNumber]::new($TelephoneNumber)
    if (-not $PhoneNumber.Value) {
        throw "Invalid telephone number format. Please provide a valid number."
    }
    return $PhoneNumber.GetSubscriberNumber()
}
