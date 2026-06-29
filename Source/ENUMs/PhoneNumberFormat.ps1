<#
.SYNOPSIS
    Defines the format styles for displaying telephone numbers.

.DESCRIPTION
    Specifies how a telephone number should be formatted for display,
    including international, national, and URI standards.

.EXAMPLE
    [PhoneNumberFormat]::E164

    Returns the E164 format enum value.
#>
enum PhoneNumberFormat {
    E164        = 1
    National    = 2
    RFC3966    = 3
    Dialable   = 4
}