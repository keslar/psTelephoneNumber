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
    TelephoneNumber([string]$Value) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            throw [System.ArgumentException]::new('Value cannot be null or empty.')
        }
        $this.Value = [TelephoneNumber]::Parse($Value)
    }
    ###############################################
    ################ Methods ######################

    # Override ToString for better display
    [string] ToString() {
        return $this.Value
    }

    # Format returns the telephone number in the specified format
    [string] Format([PhoneNumberFormat]$Format) {
        if ($Format -eq [PhoneNumberFormat]::E164 -or $Format -eq [PhoneNumberFormat]::Dialable) {
            return $this.Value
        }
        if ($Format -eq [PhoneNumberFormat]::National) {
            $CountryCodeItem = $this.GetCountryCode()
            $Ndc = $this.GetNationalDestinationCode()
            $Subscriber = $this.GetSubscriberNumber()
            if ($CountryCodeItem.ISO2 -eq 'US' -and $Subscriber.Value.Length -ge 7) {
                return "({0}) {1}-{2}" -f $Ndc.Code, $Subscriber.Value.Substring(0, 3), $Subscriber.Value.Substring(3)
            }
            return $this.Value
        }
        if ($Format -eq [PhoneNumberFormat]::RFC3966) {
            $CountryCodeItem = $this.GetCountryCode()
            $Ndc = $this.GetNationalDestinationCode()
            $Subscriber = $this.GetSubscriberNumber()
            return "tel:{0}-{1}-{2}" -f $CountryCodeItem.Code, $Ndc.Code, $Subscriber.Value
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
            if ($_ -match 'Invalid phone number format') {
                return [ValidationStatus]::InvalidFormat
            }
            if ($_ -match 'subscriber number') {
                return [ValidationStatus]::InvalidSubscriberNumber
            }
            if ($_ -match 'national destination code') {
                return [ValidationStatus]::InvalidNDC
            }
            if ($_ -match 'country code') {
                return [ValidationStatus]::InvalidCountryCode
            }
            return [ValidationStatus]::Incomplete
        }
    }

    # GetCountryCode extracts the country code from the phone number and returns the corresponding CountryCode object
    [CountryCode] GetCountryCode() {
        $CleanNumber = $this.Value -replace '[^0-9+]', ''
        $CountryCodes = [CountryCode]::GetAllCountryCodes()
        $SelectedCountryCode = $null
        $CountryCodesFound = @()
        foreach ($CountryCodeEntry in $CountryCodes) {
            if ($CountryCodeEntry.MatchesNumber($CleanNumber)) {
                $CountryCodesFound += $CountryCodeEntry
            }
        }
        if ($CountryCodesFound.Count -eq 0) {
            throw [System.ArgumentException]::new("No matching country code found for phone number: $($this.Value). Unable to determine country code.")
        } elseif ($CountryCodesFound.Count -gt 1) {
            $NdcFound = $false
            foreach ($CountryCodeEntry in $CountryCodesFound) {
                $NdcList = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCodeEntry.ISO3)
                $SelectedCountryCode = $CountryCodeEntry
                $CountryCodeCode = $CountryCodeEntry.Code
                foreach ($Ndc in $NdcList) {
                    $NdcCode = $Ndc.Code
                    if ($CleanNumber.StartsWith("$CountryCodeCode$NdcCode")) {
                        $NdcFound = $true
                        break
                    }
                }
                if ($NdcFound) {
                    break
                }
            }
            if (-not $NdcFound) {
                throw [System.ArgumentException]::new("No matching country code found for phone number: $($this.Value). Unable to determine country code.")
            }
        } else {
            $SelectedCountryCode = $CountryCodesFound[0]
        }
        return $SelectedCountryCode
    }

    # GetNationalDestinationCode extracts the national destination code from the phone number and returns the corresponding NationalDestinationCode object
    [NationalDestinationCode] GetNationalDestinationCode() {
        $CleanNumber = $this.Value -replace '[^0-9+]', ''
        $CountryCodeItem = $this.GetCountryCode()
        if ($null -eq $CountryCodeItem) {
            throw [System.ArgumentException]::new("Unable to determine country code for phone number: $($this.Value). Cannot determine national destination code without a valid country code.")
        }

        $NdcList = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCodeItem.ISO3)
        foreach ($Ndc in $NdcList) {
            if ($Ndc.MatchesNumber($CleanNumber)) {
                return $Ndc
            }
        }
        throw [System.ArgumentException]::new("Unable to determine national destination code for phone number: $($this.Value).")
    }

    # GetSubscriberNumber extracts the subscriber number from the phone number and returns a SubscriberNumber object
    [SubscriberNumber] GetSubscriberNumber() {
        $CleanNumber = $this.Value -replace '[^0-9+]', ''
        $CountryCodeItem = $this.GetCountryCode()
        if ($null -eq $CountryCodeItem) {
            throw [System.ArgumentException]::new("Unable to determine country code for phone number: $($this.Value). Cannot determine subscriber number without a valid country code.")
        }
        $Ndc = $this.GetNationalDestinationCode()
        if ($null -eq $Ndc) {
            throw [System.ArgumentException]::new("Unable to determine national destination code for phone number: $($this.Value). Cannot determine subscriber number without a valid national destination code.")
        }
        $SubscriberNumber = [SubscriberNumber]::new($CleanNumber.Substring($CountryCodeItem.Code.Length + $Ndc.Code.Length), $CountryCodeItem.ISO3)
        return $SubscriberNumber
    }

    ###############################################
    ############# Static Methods ##################

    # Parse takes a phone number string and returns a cleaned and validated version of the phone number in international format (starting with a plus sign followed by the country code and national destination code)
    static [string] Parse([string]$Number) {
        $PhoneNumber = $Number -replace '[^0-9+]', ''
        if (-not ($PhoneNumber.StartsWith('+'))) {
            $PhoneNumber = $PhoneNumber.Insert(0, '+')
        }
        $CountryCodes = [CountryCode]::GetAllCountryCodes()
        $FoundCountryCodes = @()
        foreach ($CountryCodeEntry in $CountryCodes) {
            if ($PhoneNumber.StartsWith($CountryCodeEntry.Code)) {
                $FoundCountryCodes += $CountryCodeEntry
            }
        }
        if ($FoundCountryCodes.Count -eq 0) {
            throw [System.ArgumentException]::new('Invalid phone number format. Must start with a valid country code.')
        }

        $SelectedCountryCode = $null
        $SelectedNdc = $null
        foreach ($CountryCodeEntry in $FoundCountryCodes) {
            $NdcList = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($CountryCodeEntry.ISO3)
            foreach ($NdcEntry in $NdcList) {
                $CountryCodePlusNdc = "$($CountryCodeEntry.Code)$($NdcEntry.Code)"
                if ($PhoneNumber.StartsWith($CountryCodePlusNdc)) {
                    $SelectedCountryCode = $CountryCodeEntry
                    $SelectedNdc = $NdcEntry
                    break
                }
            }
            if ($null -ne $SelectedNdc) {
                break
            }
        }

        if (($null -eq $SelectedNdc) -or ($null -eq $SelectedCountryCode)) {
            throw [System.ArgumentException]::new('Invalid phone number format. Must contain a valid country code and national destination code.')
        }

        # TODO(crk4): Improve subscriber number extraction logic. Currently assumes subscriber number
        # is the remaining digits after removing CC and NDC. This may not hold for all numbering plans.
        $null = [SubscriberNumber]::new($PhoneNumber.Substring($SelectedCountryCode.Code.Length + $SelectedNdc.Code.Length), $SelectedCountryCode.ISO3)

        return $PhoneNumber
    }
}
