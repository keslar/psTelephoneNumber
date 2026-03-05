#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\CountryCode.ps1"
#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\NationalDestinationCode.ps1"
$script:cacheTelephoneNumberSubscriberNumberFormats = $null
<#
.SYNOPSIS
    Represents a subscriber number within a telecommunications system.
.DESCRIPTION
    The SubscriberNumber class encapsulates the subscriber number portion of a telephone number, which is the part that follows the country code and national destination code. It provides properties to store the subscriber number value and methods to validate it based on the formats defined for different country codes.
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
    # Get the formats for subscriber numbers from the data file
    static [object[]] GetSubscriberNumberFormats () {
        if ($null -eq $script:cacheTelephoneNumberSubscriberNumberFormats) {
            $dataFile = Join-Path -Path $env:TELEPHONE_NUMBER_DATA_DIR -ChildPath "SubscriberNumberFormats.csv"
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

