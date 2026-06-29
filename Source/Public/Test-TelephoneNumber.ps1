<#
.SYNOPSIS
    Validates a telephone number.

.DESCRIPTION
    Validates a telephone number string and returns a ValidationStatus
    indicating the result. Unlike New-TelephoneNumber which throws on
    invalid input, this cmdlet returns a structured result.

.PARAMETER Number
    The telephone number string to validate.

.OUTPUTS
    ValidationStatus

.EXAMPLE
    Test-TelephoneNumber -Number "+1 (412) 555-1234"

    Returns Valid for a valid US number.

.EXAMPLE
    Test-TelephoneNumber -Number "invalid"

    Returns InvalidFormat for an invalid number.
#>
function Test-TelephoneNumber {
    [CmdletBinding()]
    [OutputType([ValidationStatus])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Number
    )

    process {
        try {
            $phone = [TelephoneNumber]::new($Number)
            return $phone.Validate()
        } catch {
            return [ValidationStatus]::InvalidFormat
        }
    }
}