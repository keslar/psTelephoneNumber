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
    CountryCode([string]$countryName, [string]$code) {
        if ([string]::IsNullOrWhiteSpace($countryName)) {
            throw [System.ArgumentException]::new("CountryName cannot be null or empty.")
        }
        if ([string]::IsNullOrWhiteSpace($code)) {
            throw [System.ArgumentException]::new("Code cannot be null or empty.")
        }
        $this.CountryName = $countryName
        $this.Code = $code
    }
    # Constructor with all properties
    CountryCode([string]$countryName, [string]$code, [string]$iso2, [string]$iso3, [int]$numericCode) {
        if ([string]::IsNullOrWhiteSpace($countryName)) {
            throw [System.ArgumentException]::new("CountryName cannot be null or empty.")
        }
        if ([string]::IsNullOrWhiteSpace($code)) {
            throw [System.ArgumentException]::new("Code cannot be null or empty.")
        }
        if ([string]::IsNullOrWhiteSpace($iso2)) {
            throw [System.ArgumentException]::new("ISO2 cannot be null or empty.")
        }
        if ([string]::IsNullOrWhiteSpace($iso3)) {
            throw [System.ArgumentException]::new("ISO3 cannot be null or empty.")
        }
        if ($numericCode -le 0) {
            throw [System.ArgumentException]::new("NumericCode must be a positive integer.")
        }

        $this.CountryName = $countryName
        $this.Code = $code
        $this.ISO2 = $iso2
        $this.ISO3 = $iso3
        $this.NumericCode = $numericCode
    }
    ###############################################
    ################ Methods ######################
    # Get the code without the plus sign
    [string] GetNumericCodeOnly() {
        return $this.Code.TrimStart('+')
    }
    # Format a phone number with this country code
    [string] FormatNumber([string]$nationalNumber) {
        $cleanNumber = $nationalNumber -replace '[^0-9]', ''
        $cleanCode = $this.Code -replace '[^0-9+]', ''
        return "$cleanCode$cleanNumber"
    }
    # Check if a phone number starts with this country code, ignoring subcodes,must start with+ sign and country code, but can have additional digits after the country code
    [bool] MatchesNumber([string]$phoneNumber) {
        $cleanNumber = $phoneNumber -replace '[^0-9+]', ''
        return $cleanNumber.StartsWith(($this.Code -replace '[^0-9+]', ''))
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

    # NOTE: Only clears the CountryCode cache. This is intentional — each class
    # manages its own data directory independently so tests can validate cache
    # isolation per data type without cross-contamination.
    static [void] SetDataDirectory([string]$directory) {
        if (-not (Test-Path -Path $directory -PathType Container)) {
            throw [System.IO.DirectoryNotFoundException]::new("The specified directory does not exist: $directory")
        }
        $script:cacheTelephoneNumberDataDirectory = $directory
        [CountryCode]::ClearCache()
    }

    # Get a list of all country codes  
    static [object[]] GetAllCountryCodes() {  
        if ($null -ne $script:cacheTelephoneNumberCountryCodes) {
            return $script:cacheTelephoneNumberCountryCodes
        }
        $script:cacheTelephoneNumberCountryCodes = @()
        # Load data into the list
        try {
            $CountryCodesData = Import-Csv -Path (Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath CountryCodes.csv)
        } catch {
            throw [System.IO.FileNotFoundException]::new("CountryCodes.csv not found in data directory: $($script:cacheTelephoneNumberDataDirectory)")
        }
        
        if ($null -eq $CountryCodesData) {
            throw [System.Exception]::new("Failed to load country codes data from CSV.")
        }
        
        foreach ( $Country in $CountryCodesData ) {
            $script:cacheTelephoneNumberCountryCodes += [CountryCode]::new($Country.CountryName, $Country.Code, $Country.ISO2, $Country.ISO3, [int]$Country.NumericCode)
        }
        return $script:cacheTelephoneNumberCountryCodes
    }
    # Find a country code by its code (e.g., +1), returns a list of matching CountryCode objects
    # This accounts for cases where multiple countries share the same code (e.g., +1 for US, Canada, etc.)
    static [object[]] FindByCode([string]$code) {
        $cleanCode = $code.TrimStart('+')
        $codes = [CountryCode]::GetAllCountryCodes()
        $Countries = @()
        foreach ($countryCode in $codes) {
            if ($countryCode.Code.TrimStart('+') -eq $cleanCode) {
                $Countries += $countryCode
            }
        }
        return $Countries
    }
    # Find a country code by its code (e.g., +1), returns a list of matching CountryCode objects
    # This accounts for cases where multiple countries share the same code (e.g., +1 for US, Canada, etc.)
    static [object[]] FindByCode([int]$numericCode) {
        $codes = [CountryCode]::GetAllCountryCodes()
        $Countries = @()
        foreach ($countryCode in $codes) {
            if ($countryCode.NumericCode -eq $numericCode) {
                $Countries += $countryCode
            }
        }
        return $Countries
    }
    # Find a country code by its ISO code (either ISO2 or ISO3), returns the a list of matching CountryCode object or null if not found
    # This accounts for cases where multiple countries share the same code (e.g., +1 for US, Canada, etc.)
    static [object[]] FindByISO([string]$iso) {
        if ($iso.Length -ne 2 -and $iso.Length -ne 3) {
            throw [System.ArgumentException]::new("ISO code must be either 2 or 3 characters long.")
        }
        $codes = [CountryCode]::GetAllCountryCodes()
        $Countries = @()
        foreach ($countryCode in $codes) {
            if ($countryCode.ISO2 -eq $iso -or $countryCode.ISO3 -eq $iso) {
                $Countries += $countryCode
            }
        }
        return $Countries
    }
    # Find a country code by its name, returns a list of matching CountryCode objects
    # This accounts for cases where multiple countries share similar names
    static [object[]] FindByName([string]$name) {
        $codes = [CountryCode]::GetAllCountryCodes()
        $Countries = @()
        foreach ($countryCode in $codes) {
            if ($countryCode.CountryName -like "*$name*") {
                $Countries += $countryCode
            }
        }
        return $Countries   
    }
}