function New-TelephoneNumber {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Number
    )
    # Validate the telephone number format (basic validation)
    if ($Number -notmatch '^\+?[0-9\s\-\(\)]+$') {
        throw "Invalid telephone number format. Please provide a valid number."
    }
    return [TelephoneNumber]::new($Number)
}       