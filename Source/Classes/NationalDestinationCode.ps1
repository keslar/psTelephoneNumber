#using module "G:\20 - Projects\TelephoneNumber\Source\Classes\CountryCode.ps1"
<#
.SYNOPSIS
    Represents a national destination code within a telecommunications system.

.DESCRIPTION

#>

class NationalDestinationCode {
    [string]$Code                   # The national destination code (NDC) or area code.
    [string]$ISO3       # The country code associated with this NDC.    
    [string]$Description            # A description of the NDC, such as the city or region it serves.
    [string]$Region                 # The specific region or city associated with the NDC, if applicable.
    [bool]$IsGeographic             # Indicates whether the NDC is geographic (true) or non-geographic (false).
    [string]$NumberType             # The type of number associated with the NDC (e.g., "geographic", "mobile", "toll-free", etc.).
    ##############################################
    ################ Constructors ################
    # Constructor for NationalDestinationCode with required parameters
    NationalDestinationCode ([string]$ISO3, [string]$code, [string]$description) {
        if ([string]::IsNullOrWhiteSpace($ISO3)) {
            throw [System.ArgumentException]::new("CountryCode cannot be null.")
        } 
        if ([string]::IsNullOrWhiteSpace($code)) {
            throw [System.ArgumentException]::new("Code cannot be null or empty.")
        }
        if ([string]::IsNullOrWhiteSpace($description)) {
            throw [System.ArgumentException]::new("Description cannot be null or empty.")
        }

        $this.ISO3 = $ISO3
        $CountryCode = [CountryCode]::FindByISO($ISO3)  | Select-Object -First 1
        if ($null -eq $CountryCode) {
            throw [System.ArgumentException]::new("Country code with ISO3 '$ISO3' not found.")
        }
        $this.Code = $code
        $this.Description = $description
        $this.Region = $null
        $this.IsGeographic = $false
        $this.NumberType = "unknown"
    }
    # Constructor for NationalDestinationCode with all parameters
    NationalDestinationCode ([string]$ISO3, [string]$code, [string]$description, [string]$region, [bool]$isGeographic, [string]$numberType) {
        if ([string]::IsNullOrWhiteSpace($ISO3)) {
            throw [System.ArgumentException]::new("CountryCode cannot be null.")
        }
        if ([string]::IsNullOrWhiteSpace($code)) {
            throw [System.ArgumentException]::new("Code cannot be null or empty.")
        }
        if ([string]::IsNullOrWhiteSpace($description)) {
            throw [System.ArgumentException]::new("Description cannot be null or empty.")
        }   
        
        $this.ISO3 = $ISO3

        $CountryCode = [CountryCode]::FindByISO($ISO3) | Select-Object -First 1
        if ($null -eq $CountryCode) {
            throw [System.ArgumentException]::new("Country code with ISO3 '$ISO3' not found.")
        }
        $this.Code = $code
        $this.Description = $description
        $this.Region = $region
        $this.IsGeographic = $isGeographic
        if ([string]::IsNullOrWhiteSpace($numberType)) {
            if ($isGeographic) {
                $this.NumberType = "geographic"
            } else {
                $this.NumberType = "unknown"
            }
        } else {
            $this.NumberType = $numberType
        }
        if (($isGeographic) -and ($this.NumberType -ne "geographic")) {
            throw [System.ArgumentException]::new("NumberType must be 'geographic' when IsGeographic is true.")
        } 
        if ((-not $isGeographic) -and ($this.NumberType -eq "geographic")) {
            throw [System.ArgumentException]::new("NumberType must not be 'geographic' when IsGeographic is false.")
        } 
    }
    ###############################################
    ################ Methods ######################
    # Check if a phone number starts with this NDC, ignoring any non-digit characters
    [bool] MatchesNumber([string]$phoneNumber) {
        $cleanNumber = $phoneNumber -replace '[^0-9+]', ''
        $countryCode = [CountryCode]::FindByISO($this.ISO3) | Select-Object -First 1
        $startsWidth = "+$($countryCode.NumericCode)$($this.Code)"
        return $cleanNumber.StartsWith($startsWidth)
    }
    # Override ToString for better display
    [string] ToString() {
        $countryCode = [CountryCode]::FindByISO($this.ISO3) | Select-Object -First 1
        return "$($this.Code) : $($countryCode.CountryName) ($($countryCode.Code)) - $($this.Description)"
    }
    ###############################################
    ############# Static Methods ##################
    static [void] ClearCache() {
        $script:cacheTelephoneNumberNationalDestinationCodes = $null
    }

    static [void] SetDataDirectory([string]$directory) {
        if (-not (Test-Path -Path $directory -PathType Container)) {
            throw [System.IO.DirectoryNotFoundException]::new("The specified directory does not exist: $directory")
        }
        $script:cacheTelephoneNumberDataDirectory = $directory
        [NationalDestinationCode]::ClearCache()
    }
    # Get a list of all national destination codes
    static [object[]] GetAllNationalDestinationCodes() {
        # Check if the cache is already populated
        if ($null -ne $script:cacheTelephoneNumberNationalDestinationCodes) {
            return $script:cacheTelephoneNumberNationalDestinationCodes
        }  

        #$script:cacheTelephoneNumberNationalDestinationCodes = @()
        $NDCs = New-Object System.Collections.ArrayList

        # Load data into the list
        try {
            $NationalDestinationCodeData = Import-Csv -Path (Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath NationalDestinationCodes.csv)
        } catch {
            throw [System.IO.FileNotFoundException]::new("NationalDestinationCodes.csv not found in data directory: $($script:cacheTelephoneNumberDataDirectory)")
        }

        foreach ($row in $NationalDestinationCodeData) {
            $NDC = [NationalDestinationCode]::new($row.ISO3, $row.Code, $row.Description, $row.Region, [bool]::Parse($row.IsGeographic), $row.NumberType)
            $NDCs.Add($NDC) | Out-Null
        }
        $script:cacheTelephoneNumberNationalDestinationCodes = $NDCs.ToArray()
        return $script:cacheTelephoneNumberNationalDestinationCodes
    }

    # Get all National Destination Codes for a Country
    static [object[]]  GetAllNationalDestinationCodeForCountry([object]$CountryCode) {
        if ( $CountryCode.GetType().Name -eq "String") {
            $cc = [CountryCode]::FindByISO($CountryCode)[0]
            if ($null -eq $cc) {
                throw [System.ArgumentException]::new("Country code with ISO3 '$CountryCode' not found.")
            }
        } else {
            if (($CountryCode.GetType().Name -ne "CountryCode") -or ($CountryCode.GetType().Name -ne "CountryCode")) {
                throw [System.ArgumentException]::new("CountryCode must be a string (ISO3) or a CountryCode object.")
            }
            $cc = $CountryCode[0]
        }
        
        return ( [NationalDestinationCode]::GetAllNationalDestinationCodes() | Where-Object { $_.ISO3 -eq $cc.ISO3 } )
    }
    static [NationalDestinationCode] FindByCode([string]$ISO, [string]$Code) {
        $countryCode = [CountryCode]::FindByISO($ISO)
        return [NationalDestinationCode]::GetAllNationalDestinationCodes() | Where-Object { ($_.ISO3 -eq $countryCode.ISO3) -and ($_.Code -eq $Code) }
    }
    static [NationalDestinationCode] FindByCode([int]$numericCode, [string]$Code) {
        $countryCodes = [CountryCode]::FindByCode($numericCode)
        
        foreach ($country in $countryCodes) {
            $destinationCode = [NationalDestinationCode]::GetAllNationalDestinationCodes() | Where-Object { ($_.ISO3 -eq $country.ISO3) -and ($_.Code -eq $Code) }
            if ( $null -ne $destinationCode ) {
                return $destinationCode
            }
        }
        return $null
    }
    static [bool] isValidCode( [string]$ISO3, [string]$Code ) {
        try {
            return (([NationalDestinationCode]::GetAllNationalDestinationCodeForCountry( $ISO3 ) | Where-Object { $_.Code -eq $Code }).Count -gt 0)
        } catch {
            return $false
        }
        # return (([NationalDestinationCode]::GetAllNationalDestinationCodeForCountry( $ISO3 ) | Where-Object { $_.Code -eq $Code }).Count -gt 0)
    }
}

