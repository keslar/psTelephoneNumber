<#
.SYNOPSIS
    Represents the validation result for a telephone number.

.DESCRIPTION
    Indicates whether a telephone number passed validation and, if not,
    what specific validation failure occurred.

.EXAMPLE
    [ValidationStatus]::Valid

    Returns the Valid enum value.
#>
enum ValidationStatus {
    Valid                   = 0
    InvalidCountryCode      = 1
    InvalidNDC            = 2
    InvalidSubscriberNumber = 3
    InvalidFormat         = 4
    Incomplete           = 5
}