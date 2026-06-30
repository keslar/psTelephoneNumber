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
    [OutputType([TelephoneNumber])]
    param (
        [Parameter(Mandatory)]
        [string]$Number
    )
    return [TelephoneNumber]::new($Number)
}
