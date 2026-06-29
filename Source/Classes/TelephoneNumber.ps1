<#
.SYNOPSIS
    Represents a full telephone number within a telecommunications system.

.DESCRIPTION
    The TelephoneNumber class encapsulates a complete telephone number value in
    international format. It provides methods to parse and normalize a phone
    number string, determine the associated country code and national
    destination code, and extract the subscriber number portion.

.PROPERTIES
    Value: The normalized telephone number value.

.METHODS
    ToString(): Returns the normalized telephone number as a string.
    Format(format): Returns the number formatted according to the specified format.
    GetCountryCode(): Returns the CountryCode object associated with the phone
        number.
    GetNationalDestinationCode(): Returns the NationalDestinationCode object
        associated with the phone number.
    GetSubscriberNumber(): Returns the SubscriberNumber object associated with
        the phone number.
    Validate(): Returns a ValidationStatus indicating the validation result.
    Parse(number): Cleans, validates, and normalizes a phone number string.

.EXAMPLE
    $number = [TelephoneNumber]::new('+14125551234')
    $number.ToString()

    Creates a telephone number object and returns its normalized value.

.EXAMPLE
    $number = [TelephoneNumber]::new('+14125551234')
    $number.GetCountryCode()

    Returns the country code object that matches the telephone number.

.EXAMPLE
    [TelephoneNumber]::Parse('(412) 555-1234')

    Cleans and normalizes the supplied phone number into international format.

.NOTES
    Telephone number parsing depends on the configured country code, national
    destination code, and subscriber number data sources.
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
    # Override ToString for better display
    [string] ToString() {
        return $this.Value
    }
    # Format returns the telephone number in the specified format
    [string] Format([PhoneNumberFormat]$format) {
        if ($format -eq [PhoneNumberFormat]::E164 -or $format -eq [PhoneNumberFormat]::Dialable) {
            return $this.Value
        }
        if ($format -eq [PhoneNumberFormat]::National) {
            $cc = $this.GetCountryCode()
            $ndc = $this.GetNationalDestinationCode()
            $subscriber = $this.GetSubscriberNumber()
            if ($cc.ISO2 -eq 'US' -and $subscriber.Value.Length -ge 7) {
                return "({0}) {1}-{2}" -f $ndc.Code, $subscriber.Value.Substring(0, 3), $subscriber.Value.Substring(3)
            }
            return $this.Value
        }
        if ($format -eq [PhoneNumberFormat]::RFC3966) {
            $cc = $this.GetCountryCode()
            $ndc = $this.GetNationalDestinationCode()
            $subscriber = $this.GetSubscriberNumber()
            return "tel:{0}-{1}-{2}" -f $cc.Code, $ndc.Code, $subscriber.Value
        }
        return $this.Value
    }
    # Validate returns a ValidationStatus indicating the validation result
    [ValidationStatus] Validate() {
        try {
            $null = $this.GetCountryCode()
            $null = $this.GetNationalDestinationCode()
            $null = $this.GetSubscriberNumber()
            return [ValidationStatus]::Valid
        } catch {
            if ($_ -match "Invalid phone number format") {
                return [ValidationStatus]::InvalidFormat
            }
            if ($_ -match "country code") {
                return [ValidationStatus]::InvalidCountryCode
            }
            if ($_ -match "national destination code") {
                return [ValidationStatus]::InvalidNDC
            }
            if ($_ -match "subscriber number") {
                return [ValidationStatus]::InvalidSubscriberNumber
            }
            return [ValidationStatus]::Incomplete
        }
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
            $ndcFound = $false
            foreach ($CountryCode in $CountryCodesFound) {
                $NationalDestinationCodes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCode.ISO3)
                $NationalDestinationCode = $null
                $cc = $CountryCode
                $ccCode = $CountryCode.Code
                foreach ($ndc in $NationalDestinationCodes) {
                    $ndcCode = $ndc.Code
                    if ($cleanNumber.StartsWith("$ccCode$ndcCode")) {
                        $NationalDestinationCode = $ndc
                        $ndcFound = $true
                        break
                    }
                }
                if ($ndcFound) {
                    break
                }
            }
            if (-not $ndcFound) {
                throw [System.ArgumentException]::new("No matching country code found for phone number: $($this.Value). Unable to determine country code.")
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