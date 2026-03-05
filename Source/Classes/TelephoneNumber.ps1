#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\CountryCode.ps1"
#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\NationalDestinationCode.ps1"
#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\SubscriberNumber.ps1"

<#
.SYNOPSIS
    Represents a subscriber number within a telecommunications system.
.DESCRIPTION
    The SubscriberNumber class encapsulates the subscriber number portion of a telephone number, which is the part that follows the country code and national destination code. It provides properties to store the subscriber number value and methods to validate it based on the formats defined for different country codes.
#>

class TelephoneNumber {
    [AllowNull()]
    [string]$Value
    TelephoneNumber() {
        $this.Value = $null
    }
    TelephoneNumber([string]$value) {
        if ([string]::IsNullOrWhiteSpace($value)) {
            throw [System.ArgumentException]::new("Value cannot be null or empty.")
        }
        $this.Value = [TelephoneNumber]::Parse($value)
    }
    ###############################################
    ################ Methods ######################
    #TODO: Add methods to return formated versions of the phone number, such as E.164 format, national format, etc. Also add methods to return the country code, national destination code, and subscriber number as separate objects.
    # Override ToString for better display    
    [string] ToString() {
        return $this.Value
    }
    # GetCountryCode extracts the country code from the phone number and returns the corresponding CountryCode object
    [CountryCode] GetCountryCode() {
        $cleanNumber = $this.Value -replace '[^0-9+]', ''
        $countryCodes = [CountryCode]::GetAllCountryCodes()
        $cc = $null
        $CountryCodesFound = @()
        foreach ($countryCode in $countryCodes) {
            if ($countryCode.MatchesNumber($cleanNumber)) {
                $CountryCodesFound += $countryCode
            }
        }
        if ($CountryCodesFound.Count -eq 0) {
            throw [System.ArgumentException]::new("No matching country code found for phone number: $($this.Value). Unable to determine country code.")
        } elseif ($CountryCodesFound.Count -gt 1) {
            # Write-Warning "Multiple country codes found for phone number: $($this.Value)."
            foreach ($CountryCode in $CountryCodesFound) {
                #Write-Warning "  Checking Country code: $($CountryCode.Code), ISO3: $($CountryCode.ISO3)"
                $NationalDestinationCodes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCode.ISO3)
                $NationalDestinationCode = $null
                $cc = $CountryCode
                $ccCode = $CountryCode.Code
                foreach ($ndc in $NationalDestinationCodes) {
                    # Write-Warning "Checking NDC: $($ndc.Code) for country code: $($CountryCode.Code)"
                    $ndcCode = $ndc.Code
                    if ($cleanNumber.StartsWith("$ccCode$ndcCode")) {
                        $NationalDestinationCode = $ndc
                        break
                    }
                }
                if ($null -ne $NationalDestinationCode) {
                    # Write-Warning "Found matching country code: $($CountryCode.Code) and national destination code: $($NationalDestinationCode.Code) for phone number: $($this.Value)."
                    break
                }
            }
        } else {
            $cc = $CountryCodesFound[0]
        }
        return $cc
    }
    # GetNationalDestinationCode extracts the national destination code from the phone number and returns the corresponding NationalDestinationCode object 
    [NationalDestinationCode] GetNationalDestinationCode() {
        $cleanNumber = $this.Value -replace '[^0-9+]', ''
        $countryCode = $this.GetCountryCode()
        if ($null -eq $countryCode) {
            throw [System.ArgumentException]::new("Unable to determine country code for phone number: $($this.Value). Cannot determine national destination code without a valid country code.")
        }

        $ndcs = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($countryCode.ISO3)
        foreach ($ndc in $ndcs) {
            if ($ndc.MatchesNumber($cleanNumber)) {
                return $ndc
            }
        }
        throw [System.ArgumentException]::new("Unable to determine national destination code for phone number: $($this.Value).")
    }
    # GetSubscriberNumber extracts the subscriber number from the phone number and returns a SubscriberNumber object
    [SubscriberNumber] GetSubscriberNumber() {
        $cleanNumber = $this.Value -replace '[^0-9+]', ''
        $countryCode = $this.GetCountryCode()
        if ($null -eq $countryCode) {
            throw [System.ArgumentException]::new("Unable to determine country code for phone number: $($this.Value). Cannot determine subscriber number without a valid country code.")
        }
        $ndc = $this.GetNationalDestinationCode()
        if ($null -eq $ndc) {
            throw [System.ArgumentException]::new("Unable to determine national destination code for phone number: $($this.Value). Cannot determine subscriber number without a valid national destination code.")
        }
        # Assuming the subscriber number is the remaining digits after removing the country code and national destination code
        $subscriberNumber = [SubscriberNumber]::new($cleanNumber.Substring($countryCode.Code.Length + $ndc.Code.Length), $countryCode.ISO3)
        return $subscriberNumber
    }

    ###############################################
    ############# Static Methods ##################
    # Parse takes a phone number string and returns a cleaned and validated version of the phone number in international format (starting with a plus sign followed by the country code and national destination code)    
    static [string] Parse([string]$number) {
        # Remove all non-digit and non-plus characters
        $PhoneNumber = $number -replace '[^0-9+]', ''
        # Ensure the phone number starts with a plus sign for international format
        if ( -not ($PhoneNumber.StartsWith('+') ) ) {
            $PhoneNumber = $PhoneNumber.Insert(0, '+')
        }
        # Ensure the phone number begins with a valid country code
        $CountryCodes = [CountryCode]::GetAllCountryCodes()
        $FoundCountryCodes = @()
        foreach ($CountryCode in $CountryCodes) {
            if ($PhoneNumber.StartsWith($CountryCode.Code)) {
                $FoundCountryCodes += $CountryCode
            }
        }
        if ($FoundCountryCodes.Count -eq 0) {
            throw [System.ArgumentException]::new("Invalid phone number format. Must start with a valid country code.")
        }
    
        # Ensure the phone number contains a national destination code
        $cc = $null
        $ndc = $null
        foreach ($CountryCode in $FoundCountryCodes) {
            $NDCS = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCode.ISO3)
            foreach ($NationDestinationCode in $NDCS) {
                #"$($NationDestinationCode.Code, $CountryCode.Code.Length)"
                $CCplusNDC = "$($CountryCode.Code)$($NationDestinationCode.Code)"
                if ($PhoneNumber.StartsWith($CCplusNDC)) {
                    $cc = $CountryCode
                    $ndc = $NationDestinationCode
                    break
                }
            }
            if ($null -ne $ndc) {
                break
            }
        }
    
        if (($null -eq $ndc) -or ($null -eq $cc)) {
            throw [System.ArgumentException]::new("Invalid phone number format. Must contain a valid country code and national destination code.")
        }
        # Ensure the phone number contains a valid subscriber number
        #TODO: This is a bit of a hack to get the subscriber number for validation. It assumes the subscriber number is the remaining digits after removing the country code and national destination code. This may not be accurate for all phone number formats and should be improved in the future.
        $SubscriberNumber = [SubscriberNumber]::new($PhoneNumber.Substring($cc.Code.Length + $ndc.Code.Length), $cc.ISO3)
        if ($null -eq $SubscriberNumber) {
            throw [System.ArgumentException]::new("Invalid phone number format. Must contain a valid subscriber number.")
        }
    
        # return the cleaned and validated phone number
        return $PhoneNumber
    }
}