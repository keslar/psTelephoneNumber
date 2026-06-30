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
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Number
    )

    process {
        $CleanNumber = $Number -replace '[^0-9+]', ''
        if (-not $CleanNumber.StartsWith('+')) {
            $CleanNumber = $CleanNumber.Insert(0, '+')
        }
        if ($CleanNumber -eq '+') {
            return [ValidationStatus]::InvalidFormat
        }
        try {
            $Phone = [TelephoneNumber]::new()
            $Phone.Value = $CleanNumber
            return $Phone.Validate()
        } catch {
            return [ValidationStatus]::InvalidFormat
        }
    }
}
