<#
.SYNOPSIS
    Returns the subscriber number for a telephone number.

.DESCRIPTION
    Parses the supplied telephone number and returns the matching
    SubscriberNumber object.

.PARAMETER TelephoneNumber
    The telephone number to inspect.

.OUTPUTS
    SubscriberNumber

.EXAMPLE
    Get-TelephoneNumberSubscriberNumber -TelephoneNumber '+14121234567'

    Returns the subscriber number object associated with the supplied
    telephone number.
#>
function Get-TelephoneNumberSubscriberNumber {
    [CmdletBinding()]
    [OutputType([SubscriberNumber])]
    param (
        [Parameter(Mandatory)]
        [string]$TelephoneNumber
    )
    $PhoneNumber = [TelephoneNumber]::new($TelephoneNumber)
    if (-not $PhoneNumber.Value) {
        throw 'Invalid telephone number format. Please provide a valid number.'
    }
    return $PhoneNumber.GetSubscriberNumber()
}
