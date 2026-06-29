<#
.SYNOPSIS
    Represents the type of telephone service.

.DESCRIPTION
    Indicates the category of telephone service associated with a number,
    such as mobile, landline, or VoIP. Currently unused but
    reserved for future carrier/location detection features.

.EXAMPLE
    [PhoneNumberType]::Mobile

    Returns the Mobile enum value.
#>
enum PhoneNumberType {
    Unknown   = 0
    Landline  = 1
    Mobile    = 2
    VoIP      = 3
    TollFree  = 4
    Premium   = 5
}