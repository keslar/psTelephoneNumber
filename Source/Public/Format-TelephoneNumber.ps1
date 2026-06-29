<#
.SYNOPSIS
    Formats a telephone number for display.

.DESCRIPTION
    Formats a TelephoneNumber object according to the specified format.
    Supported formats: E164, National, RFC3966, Dialable.

.PARAMETER TelephoneNumber
    The TelephoneNumber object to format.

.PARAMETER Format
    The desired output format. Default is E164.

.OUTPUTS
    string

.EXAMPLE
    $phone = New-TelephoneNumber -Number "+14125551234"
    $phone | Format-TelephoneNumber -Format National

    Returns: (412) 555-1234

.EXAMPLE
    Format-TelephoneNumber -InputObject $phone -Format RFC3966

    Returns: tel:+1-412-555-1234
#>
function Format-TelephoneNumber {
    [CmdletBinding(DefaultParameterSetName = 'Pipeline')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ParameterSetName = 'Pipeline')]
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'InputObject')]
        [TelephoneNumber]$InputObject,

        [Parameter()]
        [ValidateSet('E164', 'National', 'RFC3966', 'Dialable')]
        [PhoneNumberFormat]$Format = 'E164'
    )

    process {
        return $InputObject.Format($Format)
    }
}
