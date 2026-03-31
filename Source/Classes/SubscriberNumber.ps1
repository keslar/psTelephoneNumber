#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\CountryCode.ps1"
#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\NationalDestinationCode.ps1"
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
    SubscriberNumber( [string]$number ) {
        $this.Value = $number
    }
    SubscriberNumber( [string]$number, [string]$ISO3 ) {
        $this.Value = $number
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
    # isValid checks if the subscriber number is valid based on the formats for the country code
    [bool] IsValid ( [string]$iso ) {
        try {
            $format = [SubscriberNumber]::GetSubscriberNumberFormatForCountryCode($iso)
            $numberToValidate = $this.Value -replace "\D", "" # Remove non-digit characters for validation
            # Get the min and max length for NDC
            $ndcs = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry( ([CountryCode]::FindByISO($iso))[0] )
            $maxNDCLength = 1
            $minNDCLength = 100
            foreach ($ndc in $ndcs) {
                if ($ndc.Code.Length -gt $maxNDCLength) {
                    $maxNDCLength = $ndc.Code.Length
                }
                if ($ndc.Code.Length -lt $minNDCLength) {
                    $minNDCLength = $ndc.Code.Length
                }
            }
            $minLength = [int]$format.Min - $maxNDCLength
            $maxLength = [int]$format.Max - $minNDCLength
            # Check of the length of the subscriber number is within the valid range for the country code
            $lengthCheck = ($numberToValidate.Length -ge $minLength) -and ($numberToValidate.Length -le $maxLength)
            return $lengthCheck
        } catch {
            throw $_
        }
    }


    ###############################################
    ############# Static Methods ##################
    static [void] ClearCache() {
        $script:cacheTelephoneNumberSubscriberNumberFormats = $null
    }

    static [void] SetDataDirectory([string]$directory) {
        if (-not (Test-Path -Path $directory -PathType Container)) {
            throw [System.IO.DirectoryNotFoundException]::new("The specified directory does not exist: $directory")
        }
        $script:cacheTelephoneNumberDataDirectory = $directory
        [SubscriberNumber]::ClearCache()
    }

    # Get the formats for subscriber numbers from the data file
    static [object[]] GetSubscriberNumberFormats () {
        if ($null -eq $script:cacheTelephoneNumberSubscriberNumberFormats) {
            $dataFile = Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath "SubscriberNumberFormats.csv"
            if (Test-Path -Path $dataFile) {
                $script:cacheTelephoneNumberSubscriberNumberFormats = Import-Csv -Path $dataFile
            } else {
                throw [System.IO.FileNotFoundException]::new("Subscriber number formats data file not found at path: $dataFile")
            }
        }
        return $script:cacheTelephoneNumberSubscriberNumberFormats
    }
    # Get the format for a specific country code
    static [object] GetSubscriberNumberFormatForCountryCode ( [string]$countryCode ) {
        $formats = [SubscriberNumber]::GetSubscriberNumberFormats()
        $format = $formats | Where-Object { $_.ISO3 -eq $countryCode }
        if ($null -ne $format) {
            return $format
        } else {
            throw [System.ArgumentException]::new("No subscriber number format found for country code: $countryCode")
        }
    }
}

