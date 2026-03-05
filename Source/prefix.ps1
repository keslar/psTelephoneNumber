# requires -version <powershell version>
# requires -Modules <ModuleList>
# -- remove space before requires statement and replace version and ModuleList
<#
    .SYNOPSIS

    A powershell module to validate and manipulate telephone numbers

    .DESCRIPTION

    .NOTES
        Version:    {{MODULE_VERSION}}
        Author(s):  [. Keslar <crk4@pitt.edu>
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