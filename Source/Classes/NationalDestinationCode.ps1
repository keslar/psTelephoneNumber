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
# SIG # Begin signature block
# MIIFjAYJKoZIhvcNAQcCoIIFfTCCBXkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC0xTuPIku9d3dG
# 0gfIxMpX7Pae7o/n4i2BT1UEIqJimKCCAwQwggMAMIIB6KADAgECAhBQ0l1avYtc
# qk1MO0ndTe6CMA0GCSqGSIb3DQEBCwUAMBgxFjAUBgNVBAMMDWNyazRAcGl0dC5l
# ZHUwHhcNMjYwMzA0MTkwMTQxWhcNMjkwMzA0MTkxMTQyWjAYMRYwFAYDVQQDDA1j
# cms0QHBpdHQuZWR1MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxYDu
# v/8i2MXm5/Fhte2iKfWxaL2lx3MgsveHCpe5SssfRcObL4rXPj6/AOYhEelKDYsf
# st6aLsrrbFlDJW3vWtPyvBqg5DYYFne9b091goNma2zEUMrTKP7R4kXquYECqz5D
# aTE0RDdfBYUK2Mp0Sp3HmNRDIy5c/BJkJOAWJ+lCEz4CIa9ZvvTCOaW313PJQdNK
# G9Rg+8Jt623mbaLGq+/piJnpi/WpU4Mj+YLrzuVDvc5W91xZwXXz5Cuin3L3cWJL
# 8wpoHKsNGN4oviQuxk+uDVAoQmkYrp9ZESAWn8L0fdK6er8HngtHJzyfjU2HAj5T
# +adkKU57BkvKADxIlQIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwHQYDVR0OBBYEFEXH/JQt+ou5xhJYKHzsru0ABDxcMA0GCSqG
# SIb3DQEBCwUAA4IBAQBWJBa0O7aQ/C32GHJQZO/Q1p0S3osshvdPqxgEqFPBDa4i
# PYb3rYugIsFp8jqXYg7SO6gcPcpPizuYFGN6eK/sJppRr5NZfDJxn+MYo8M6pmZE
# mN7rLu+lQfLdQy3cJ0m7flCPM+VJ+o58cSukqgUpUlC5Ih5JRh2PG6ngdCVtn7c4
# /56/maq34FnUJhRoDh30okln4GFLFkABSUutz7c+V38Z5hFBtEEu7YKm0JNUXxPv
# w7MYfCFGswHGwMlrhOD6CgXp6svr9wjyw9uAv0IKACRaZDc9gYFjbVefLKWtLUUz
# i83o8+2qTmHTrd0jZ3zvR/0UYGazvGvVvf7gzoOxMYIB3jCCAdoCAQEwLDAYMRYw
# FAYDVQQDDA1jcms0QHBpdHQuZWR1AhBQ0l1avYtcqk1MO0ndTe6CMA0GCWCGSAFl
# AwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkD
# MQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJ
# KoZIhvcNAQkEMSIEIGdfLHCOEsc/va0sH7nfusKyN03I5CKUw/3vyLdMfvdBMA0G
# CSqGSIb3DQEBAQUABIIBAKBAoDg7VM8qg9RCW4yxojJregBmaoHkbVDwa7YZZEdm
# tjgIzFlMS9aRYBwA1KrByZV7xGxr9LLNio4kogoKQC/xMRiII2K5fSjNUHk6WRqn
# QxYBkw1i8FdHerAvdoky2n86lRCTHC5D5uI0/TQR7UoRzw/1wD6CXtFzSh7lifDK
# 3laxyyxO+PVrLkRACjiExILZGubf1AyLbGp4468QUY+hXIaYkD0wd42zCO4KZ49U
# y/Ja2zkvSXU/RCyOhizStNvc+GuZfp/tcZ0PDiT+kP0TsjN6loHlX0B0wJYj51+6
# UFNbuhmNnmofTtigOgWrGtf2gHe1BikDXgkx/5Zb2FE=
# SIG # End signature block
