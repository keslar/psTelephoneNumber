#Requires -Version 5.1

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

<#
    .SYNOPSIS
        A PowerShell module to validate and manipulate telephone numbers

    .DESCRIPTION

    .NOTES
        Version:    {{MODULE_VERSION}}
        Author(s):  Chris Keslar <crk4@pitt.edu>
        Date:       {{BUILD_DATE}}

    .LINK

#>

###############################################################################
## CONSTANTS and Script Variables
$script:cacheTelephoneNumberDataDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Data"
$script:cacheTelephoneNumberCountryCodes = $null
$script:cacheTelephoneNumberNationalDestinationCodes = $null
$script:cacheTelephoneNumberSubscriberNumberFormats = $null

###############################################################################
## Update the data directory if the environment variable is set
if ($env:TELEPHONE_NUMBER_DATA_DIR) {
    $script:cacheTelephoneNumberDataDirectory = $env:TELEPHONE_NUMBER_DATA_DIR
}
