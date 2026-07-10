$script:cacheTelephoneNumberSubscriberNumberFormats = $null
<#
.SYNOPSIS
    Represents a subscriber number within a telecommunications system.

.DESCRIPTION
    The SubscriberNumber class encapsulates the subscriber number portion of a
    telephone number, which is the part that follows the country code and
    national destination code. It stores the subscriber number value and
    provides methods to validate it against the supported formats for a given
    country.

.PROPERTIES
    Value: The subscriber number portion of the telephone number.

.METHODS
    ToString(): Returns the subscriber number as a string.
    IsValid(iso): Validates the subscriber number against the configured rules
        for the specified ISO country code.
    ClearCache(): Clears the cached subscriber number format data.
    SetDataDirectory(directory): Sets the data directory used to load
        subscriber number format data.
    GetSubscriberNumberFormats(): Returns all subscriber number formats from
        the configured data source.
    GetSubscriberNumberFormatForCountryCode(countryCode): Returns the
        subscriber number format for a specific country.

.EXAMPLE
    $subscriber = [SubscriberNumber]::new('5551234')
    $subscriber.ToString()

    Creates a subscriber number object and returns its string value.

.EXAMPLE
    [SubscriberNumber]::new('5551234', 'USA')

    Creates a subscriber number and validates it against the format rules for
    the specified country.

.NOTES
    Subscriber number formats are loaded from SubscriberNumberFormats.csv in
    the configured data directory and cached for reuse.
#>
class SubscriberNumber {
    [string]$Value
    SubscriberNumber() {
        $this.Value = $null
    }
    SubscriberNumber( [string]$Number ) {
        $this.Value = $Number
    }
    SubscriberNumber( [string]$Number, [string]$ISO3 ) {
        $this.Value = $Number
        if (-not $this.IsValid($ISO3)) {
            throw [System.ArgumentException]::new("Invalid subscriber number format for country code: $ISO3")
        }
    }
    ###############################################
    ################ Methods ######################

    # Override ToString for better display
    [string] ToString() {
        return $this.Value
    }

    # IsValid checks if the subscriber number is valid based on the formats for the country code
    [bool] IsValid ( [string]$ISO ) {
        try {
            $Format = [SubscriberNumber]::GetSubscriberNumberFormatForCountryCode($ISO)
            $NumberToValidate = $this.Value -replace '\D', ''
            $CountryCodeItem = [CountryCode]::FindByISO($ISO)
            if ($null -eq $CountryCodeItem) {
                throw [System.ArgumentException]::new("Country code with ISO '$ISO' not found.")
            }
            $NationalDestinationCodes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCodeItem)
            $MaxNdcLength = 1
            $MinNdcLength = 100
            foreach ($Ndc in $NationalDestinationCodes) {
                if ($Ndc.Code.Length -gt $MaxNdcLength) {
                    $MaxNdcLength = $Ndc.Code.Length
                }
                if ($Ndc.Code.Length -lt $MinNdcLength) {
                    $MinNdcLength = $Ndc.Code.Length
                }
            }
            $MinLength = [int]$Format.Min - $MaxNdcLength
            $MaxLength = [int]$Format.Max - $MinNdcLength
            $LengthCheck = ($NumberToValidate.Length -ge $MinLength) -and ($NumberToValidate.Length -le $MaxLength)
            return $LengthCheck
        } catch {
            throw $_
        }
    }


    ###############################################
    ############# Static Methods ##################

    static [void] ClearCache() {
        $script:cacheTelephoneNumberSubscriberNumberFormats = $null
    }

    # NOTE: Only clears the SubscriberNumber cache. This is intentional -- each class
    # manages its own data directory independently so tests can validate cache
    # isolation per data type without cross-contamination.
    static [void] SetDataDirectory([string]$Directory) {
        if (-not (Test-Path -Path $Directory -PathType Container)) {
            throw [System.IO.DirectoryNotFoundException]::new("The specified directory does not exist: $Directory")
        }
        $script:cacheTelephoneNumberDataDirectory = $Directory
        [SubscriberNumber]::ClearCache()
    }

    # Get the formats for subscriber numbers from the data file
    static [object[]] GetSubscriberNumberFormats () {
        if ($null -eq $script:cacheTelephoneNumberSubscriberNumberFormats) {
            $DataFile = Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath 'SubscriberNumberFormats.csv'
            if (Test-Path -Path $DataFile) {
                $script:cacheTelephoneNumberSubscriberNumberFormats = Import-Csv -Path $DataFile
            } else {
                throw [System.IO.FileNotFoundException]::new("Subscriber number formats data file not found at path: $DataFile")
            }
        }
        return $script:cacheTelephoneNumberSubscriberNumberFormats
    }

    # Get the format for a specific country code
    static [object] GetSubscriberNumberFormatForCountryCode ( [string]$CountryCode ) {
        $Formats = [SubscriberNumber]::GetSubscriberNumberFormats()
        $Format = $Formats | Where-Object { $_.ISO3 -eq $CountryCode }
        if ($null -ne $Format) {
            return $Format
        } else {
            throw [System.ArgumentException]::new("No subscriber number format found for country code: $CountryCode")
        }
    }
}
