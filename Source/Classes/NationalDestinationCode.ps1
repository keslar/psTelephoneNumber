<#
.SYNOPSIS
    Represents a national destination code within a telecommunications system.

.DESCRIPTION
    The NationalDestinationCode class encapsulates the national destination
    code portion of a telephone number, sometimes referred to as an area code
    or destination code. It stores metadata about the code and provides methods
    to match numbers, retrieve destination-code data, and validate codes for a
    given country.

.PROPERTIES
    Code: The national destination code (NDC) or area code.
    ISO3: The ISO 3166-1 alpha-3 code for the associated country.
    Description: A description of the NDC, such as the city or service area.
    Region: The region or locality associated with the NDC, when available.
    IsGeographic: Indicates whether the NDC is geographic.
    NumberType: The type of number associated with the NDC.

.METHODS
    MatchesNumber(phoneNumber): Checks whether a phone number starts with this
        country code and national destination code.
    ToString(): Returns a display-friendly representation of the NDC.
    ClearCache(): Clears the cached national destination code data.
    SetDataDirectory(directory): Sets the data directory used to load NDC data.
    GetAllNationalDestinationCodes(): Returns all known national destination
        codes from the data source.
    GetAllNationalDestinationCodeForCountry(CountryCode): Returns all national
        destination codes for a given country.
    FindByCode(ISO, Code): Finds a national destination code by ISO3 code and
        destination code.
    FindByCode(numericCode, Code): Finds a national destination code by
        numeric country code and destination code.
    isValidCode(ISO3, Code): Returns true when the specified code exists for
        the given country.

.EXAMPLE
    $ndc = [NationalDestinationCode]::new('USA', '412', 'Pittsburgh')
    $ndc.ToString()

    Creates a national destination code and returns its display string.

.EXAMPLE
    [NationalDestinationCode]::FindByCode('USA', '412')

    Returns the matching national destination code for the given country and
    code, if one exists.

.NOTES
    National destination code data is loaded from NationalDestinationCodes.csv
    in the configured data directory and cached for reuse.

#>

class NationalDestinationCode {
    [string]$Code                   # The national destination code (NDC) or area code.
    [string]$ISO3                   # The country code associated with this NDC.
    [string]$Description            # A description of the NDC, such as the city or region it serves.
    [string]$Region                 # The specific region or city associated with the NDC, if applicable.
    [bool]$IsGeographic             # Indicates whether the NDC is geographic (true) or non-geographic (false).
    [string]$NumberType             # The type of number associated with the NDC (e.g., "geographic", "mobile", "toll-free", etc.).

    ##############################################
    ################ Constructors ################

    # Constructor for NationalDestinationCode with required parameters
    NationalDestinationCode ([string]$ISO3, [string]$Code, [string]$Description) {
        if ([string]::IsNullOrWhiteSpace($ISO3)) {
            throw [System.ArgumentException]::new('CountryCode cannot be null.')
        }
        if ([string]::IsNullOrWhiteSpace($Code)) {
            throw [System.ArgumentException]::new('Code cannot be null or empty.')
        }
        if ([string]::IsNullOrWhiteSpace($Description)) {
            throw [System.ArgumentException]::new('Description cannot be null or empty.')
        }

        $this.ISO3 = $ISO3
        $CountryCodeResult = [CountryCode]::FindByISO($ISO3)
        if ($null -eq $CountryCodeResult) {
            throw [System.ArgumentException]::new("Country code with ISO3 '$ISO3' not found.")
        }
        $this.Code = $Code
        $this.Description = $Description
        $this.Region = $null
        $this.IsGeographic = $false
        $this.NumberType = 'unknown'
    }

    # Constructor for NationalDestinationCode with all parameters
    NationalDestinationCode ([string]$ISO3, [string]$Code, [string]$Description, [string]$Region, [bool]$IsGeographic, [string]$NumberType) {
        if ([string]::IsNullOrWhiteSpace($ISO3)) {
            throw [System.ArgumentException]::new('CountryCode cannot be null.')
        }
        if ([string]::IsNullOrWhiteSpace($Code)) {
            throw [System.ArgumentException]::new('Code cannot be null or empty.')
        }
        if ([string]::IsNullOrWhiteSpace($Description)) {
            throw [System.ArgumentException]::new('Description cannot be null or empty.')
        }

        $this.ISO3 = $ISO3

        $CountryCodeResult = [CountryCode]::FindByISO($ISO3)
        if ($null -eq $CountryCodeResult) {
            throw [System.ArgumentException]::new("Country code with ISO3 '$ISO3' not found.")
        }
        $this.Code = $Code
        $this.Description = $Description
        $this.Region = $Region
        $this.IsGeographic = $IsGeographic
        if ([string]::IsNullOrWhiteSpace($NumberType)) {
            if ($IsGeographic) {
                $this.NumberType = 'geographic'
            } else {
                $this.NumberType = 'unknown'
            }
        } else {
            $this.NumberType = $NumberType
        }
        if (($IsGeographic) -and ($this.NumberType -ne 'geographic')) {
            throw [System.ArgumentException]::new("NumberType must be 'geographic' when IsGeographic is true.")
        }
        if ((-not $IsGeographic) -and ($this.NumberType -eq 'geographic')) {
            throw [System.ArgumentException]::new("NumberType must not be 'geographic' when IsGeographic is false.")
        }
    }

    ###############################################
    ################ Methods ######################

    # Check if a phone number starts with this NDC, ignoring any non-digit characters
    [bool] MatchesNumber([string]$PhoneNumber) {
        $CleanNumber = $PhoneNumber -replace '[^0-9+]', ''
        $CountryCodeResult = [CountryCode]::FindByISO($this.ISO3)
        $StartsWith = "+$($CountryCodeResult.NumericCode)$($this.Code)"
        return $CleanNumber.StartsWith($StartsWith)
    }

    # Override ToString for better display
    [string] ToString() {
        $CountryCodeResult = [CountryCode]::FindByISO($this.ISO3)
        return "$($this.Code) : $($CountryCodeResult.CountryName) ($($CountryCodeResult.Code)) - $($this.Description)"
    }

    ###############################################
    ############# Static Methods ##################

    static [void] ClearCache() {
        $script:cacheTelephoneNumberNationalDestinationCodes = $null
    }

    # NOTE: Only clears the NationalDestinationCode cache. This is intentional -- each class
    # manages its own data directory independently so tests can validate cache
    # isolation per data type without cross-contamination.
    static [void] SetDataDirectory([string]$Directory) {
        if (-not (Test-Path -Path $Directory -PathType Container)) {
            throw [System.IO.DirectoryNotFoundException]::new("The specified directory does not exist: $Directory")
        }
        $script:cacheTelephoneNumberDataDirectory = $Directory
        [NationalDestinationCode]::ClearCache()
    }

    # Get a list of all national destination codes
    static [object[]] GetAllNationalDestinationCodes() {
        if ($null -ne $script:cacheTelephoneNumberNationalDestinationCodes) {
            return $script:cacheTelephoneNumberNationalDestinationCodes
        }

        $NationalDestinationCodes = [System.Collections.Generic.List[NationalDestinationCode]]::new()

        try {
            $NationalDestinationCodeData = Import-Csv -Path (Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath 'NationalDestinationCodes.csv')
        } catch {
            throw [System.IO.FileNotFoundException]::new('NationalDestinationCodes.csv not found in data directory.')
        }

        foreach ($Row in $NationalDestinationCodeData) {
            $Ndc = [NationalDestinationCode]::new($Row.ISO3, $Row.Code, $Row.Description, $Row.Region, [bool]::Parse($Row.IsGeographic), $Row.NumberType)
            $NationalDestinationCodes.Add($Ndc)
        }
        $script:cacheTelephoneNumberNationalDestinationCodes = $NationalDestinationCodes.ToArray()
        return $script:cacheTelephoneNumberNationalDestinationCodes
    }

    # Get all National Destination Codes for a Country
    static [object[]] GetAllNationalDestinationCodeForCountry([object]$CountryCodeInput) {
        if ($CountryCodeInput.GetType().Name -eq 'String') {
            $CountryCodeItem = [CountryCode]::FindByISO($CountryCodeInput)
            if ($null -eq $CountryCodeItem) {
                throw [System.ArgumentException]::new("Country code with ISO3 '$CountryCodeInput' not found.")
            }
        } else {
            if ($CountryCodeInput.GetType().Name -ne 'CountryCode') {
                throw [System.ArgumentException]::new('CountryCode must be a string (ISO3) or a CountryCode object.')
            }
            $CountryCodeItem = $CountryCodeInput
        }

        $NationalDestinationCodes = @([NationalDestinationCode]::GetAllNationalDestinationCodes() | Where-Object { $_.ISO3 -eq $CountryCodeItem.ISO3 })
        return $NationalDestinationCodes
    }

    static [NationalDestinationCode] FindByCode([string]$ISO, [string]$Code) {
        $CountryCodeResult = [CountryCode]::FindByISO($ISO)
        if ($null -eq $CountryCodeResult) {
            return $null
        }
        return [NationalDestinationCode]::GetAllNationalDestinationCodes() | Where-Object { ($_.ISO3 -eq $CountryCodeResult.ISO3) -and ($_.Code -eq $Code) }
    }

    static [NationalDestinationCode] FindByCode([int]$NumericCode, [string]$Code) {
        $CountryCodes = [CountryCode]::FindByCode($NumericCode)

        foreach ($Country in $CountryCodes) {
            $DestinationCode = [NationalDestinationCode]::GetAllNationalDestinationCodes() | Where-Object { ($_.ISO3 -eq $Country.ISO3) -and ($_.Code -eq $Code) }
            if ($null -ne $DestinationCode) {
                return $DestinationCode
            }
        }
        return $null
    }

    static [bool] isValidCode([string]$ISO3, [string]$Code) {
        try {
            $MatchingCodes = @([NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($ISO3) | Where-Object { $_.Code -eq $Code })
            return $MatchingCodes.Count -gt 0
        } catch {
            Write-Verbose "isValidCode check failed for ISO3='$ISO3', Code='$Code': $_"
            return $false
        }
    }
}
