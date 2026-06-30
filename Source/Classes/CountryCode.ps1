$script:cacheTelephoneNumberCountryCodes = $null

<#
.SYNOPSIS
    Represents a country code with various properties and methods for handling international phone numbers.

.DESCRIPTION
    The CountryCode class encapsulates information about a country's international dialing code, ISO codes, and
    numeric code. It provides methods to format phone numbers, check for matches, and retrieve country code information.

.PROPERTIES
    CountryName: The name of the country.
    Code: The international dialing code (e.g., +1, +44).
    ISO2: The ISO 3166-1 alpha-2 code (e.g., US, GB).
    ISO3: The ISO 3166-1 alpha-3 code (e.g., USA, GBR).
    NumericCode: The numeric country code.

.METHODS
    GetNumericCodeOnly(): Returns the country code without the plus sign.
    FormatNumber(nationalNumber): Formats a national phone number with this country code.
    MatchesNumber(phoneNumber): Checks if a given phone number starts with this country code.
    ToString(): Returns a string representation of the country code.
    GetAllCountryCodes(): Static method that returns a list of all country codes.
    FindByCode(code): Static method that finds and returns a list of CountryCode objects matching the given code.
    FindByISO(iso): Static method that finds and returns a CountryCode object matching the given ISO code (either ISO2 or ISO3).

.EXAMPLE
    $countryCode = [CountryCode]::new("United States", "+1", "US", "USA", 1)
    Write-Output $countryCode.FormatNumber("555-1234")
    # Output: +15551234

.EXAMPLE
    $countryCode = [CountryCode]::new("United States", "+1", "US", "USA", 1)
    Write-Output $countryCode.MatchesNumber("+15551234")
    # Output: True

.EXAMPLE
    $allCodes = [CountryCode]::GetAllCountryCodes()
    $usCode = [CountryCode]::FindByISO("US")
    Write-Output $usCode
    # Output: United States: +1

.NOTES

#>
class CountryCode {
    [string]$CountryName        # Name of the country
    [string]$Code               # Country code (e.g., +1, +44)
    [string]$ISO2               # ISO 3166-1 alpha-2 code (e.g., US, GB)
    [string]$ISO3               # ISO 3166-1 alpha-3 code (e.g., USA, GBR)
    [int]$NumericCode           # Numeric country code

    ##############################################
    ################ Constructors ################

    # Constructor with no parameters
    CountryCode() {
        $this.CountryName = $null
        $this.Code = $null
        $this.ISO2 = $null
        $this.ISO3 = $null
        $this.NumericCode = -1
    }

    # Constructor with country name and code
    CountryCode([string]$CountryName, [string]$Code) {
        if ([string]::IsNullOrWhiteSpace($CountryName)) {
            throw [System.ArgumentException]::new('CountryName cannot be null or empty.')
        }
        if ([string]::IsNullOrWhiteSpace($Code)) {
            throw [System.ArgumentException]::new('Code cannot be null or empty.')
        }
        $this.CountryName = $CountryName
        $this.Code = $Code
    }

    # Constructor with all properties
    CountryCode([string]$CountryName, [string]$Code, [string]$Iso2, [string]$Iso3, [int]$NumericCode) {
        if ([string]::IsNullOrWhiteSpace($CountryName)) {
            throw [System.ArgumentException]::new('CountryName cannot be null or empty.')
        }
        if ([string]::IsNullOrWhiteSpace($Code)) {
            throw [System.ArgumentException]::new('Code cannot be null or empty.')
        }
        if ([string]::IsNullOrWhiteSpace($Iso2)) {
            throw [System.ArgumentException]::new('ISO2 cannot be null or empty.')
        }
        if ([string]::IsNullOrWhiteSpace($Iso3)) {
            throw [System.ArgumentException]::new('ISO3 cannot be null or empty.')
        }
        if ($NumericCode -le 0) {
            throw [System.ArgumentException]::new('NumericCode must be a positive integer.')
        }

        $this.CountryName = $CountryName
        $this.Code = $Code
        $this.ISO2 = $Iso2
        $this.ISO3 = $Iso3
        $this.NumericCode = $NumericCode
    }

    ###############################################
    ################ Methods ######################

    # Get the code without the plus sign
    [string] GetNumericCodeOnly() {
        return $this.Code.TrimStart('+')
    }

    # Format a phone number with this country code
    [string] FormatNumber([string]$NationalNumber) {
        $CleanNumber = $NationalNumber -replace '[^0-9]', ''
        $CleanCode = $this.Code -replace '[^0-9+]', ''
        return "$CleanCode$CleanNumber"
    }

    # Check if a phone number starts with this country code, ignoring subcodes, must start with+ sign and country code, but can have additional digits after the country code
    [bool] MatchesNumber([string]$PhoneNumber) {
        $CleanNumber = $PhoneNumber -replace '[^0-9+]', ''
        return $CleanNumber.StartsWith(($this.Code -replace '[^0-9+]', ''))
    }

    # Override ToString for better display
    [string] ToString() {
        return "$($this.CountryName): $($this.Code)"
    }

    #################################################
    ################# Static Methods ################

    static [void] ClearCache() {
        $script:cacheTelephoneNumberCountryCodes = $null
    }

    # NOTE: Only clears the CountryCode cache. This is intentional -- each class
    # manages its own data directory independently so tests can validate cache
    # isolation per data type without cross-contamination.
    static [void] SetDataDirectory([string]$Directory) {
        if (-not (Test-Path -Path $Directory -PathType Container)) {
            throw [System.IO.DirectoryNotFoundException]::new("The specified directory does not exist: $Directory")
        }
        $script:cacheTelephoneNumberDataDirectory = $Directory
        [CountryCode]::ClearCache()
    }

    # Get a list of all country codes
    static [object[]] GetAllCountryCodes() {
        if ($null -ne $script:cacheTelephoneNumberCountryCodes) {
            return $script:cacheTelephoneNumberCountryCodes
        }
        $script:cacheTelephoneNumberCountryCodes = @()
        try {
            $CountryCodesData = Import-Csv -Path (Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath 'CountryCodes.csv')
        } catch {
            throw [System.IO.FileNotFoundException]::new('CountryCodes.csv not found in data directory.')
        }

        if ($null -eq $CountryCodesData) {
            throw [System.Exception]::new('Failed to load country codes data from CSV.')
        }

        foreach ($Row in $CountryCodesData) {
            $script:cacheTelephoneNumberCountryCodes += [CountryCode]::new($Row.CountryName, $Row.Code, $Row.ISO2, $Row.ISO3, [int]$Row.NumericCode)
        }
        return $script:cacheTelephoneNumberCountryCodes
    }

    # Find a country code by its code (e.g., +1), returns a list of matching CountryCode objects
    static [object[]] FindByCode([string]$Code) {
        $CleanCode = $Code.TrimStart('+')
        $Codes = [CountryCode]::GetAllCountryCodes()
        $Results = [System.Collections.Generic.List[CountryCode]]::new()
        foreach ($CodeEntry in $Codes) {
            if ($CodeEntry.Code.TrimStart('+') -eq $CleanCode) {
                $Results.Add($CodeEntry)
            }
        }
        if ($Results.Count -eq 0) { return @() }
        return $Results.ToArray()
    }

    # Find a country code by its numeric code (e.g., 1), returns a list of matching CountryCode objects
    static [object[]] FindByCode([int]$NumericCode) {
        $Codes = [CountryCode]::GetAllCountryCodes()
        $Results = [System.Collections.Generic.List[CountryCode]]::new()
        foreach ($CodeEntry in $Codes) {
            if ($CodeEntry.NumericCode -eq $NumericCode) {
                $Results.Add($CodeEntry)
            }
        }
        if ($Results.Count -eq 0) { return @() }
        return $Results.ToArray()
    }

    # Find a country code by its ISO code (either ISO2 or ISO3), returns a list of matching CountryCode objects
    static [object[]] FindByISO([string]$ISO) {
        if ($ISO.Length -ne 2 -and $ISO.Length -ne 3) {
            throw [System.ArgumentException]::new('ISO code must be either 2 or 3 characters long.')
        }
        $Codes = [CountryCode]::GetAllCountryCodes()
        $Results = [System.Collections.Generic.List[CountryCode]]::new()
        foreach ($CodeEntry in $Codes) {
            if ($CodeEntry.ISO2 -eq $ISO -or $CodeEntry.ISO3 -eq $ISO) {
                $Results.Add($CodeEntry)
            }
        }
        if ($Results.Count -eq 0) { return @() }
        return $Results.ToArray()
    }

    # Find a country code by its name, returns a list of matching CountryCode objects
    static [object[]] FindByName([string]$Name) {
        $Codes = [CountryCode]::GetAllCountryCodes()
        $Results = [System.Collections.Generic.List[CountryCode]]::new()
        foreach ($CodeEntry in $Codes) {
            if ($CodeEntry.CountryName -like "*$Name*") {
                $Results.Add($CodeEntry)
            }
        }
        if ($Results.Count -eq 0) { return @() }
        return $Results.ToArray()
    }
}
