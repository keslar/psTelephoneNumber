if ((Get-Module Pester).Version.Major -lt 5) { Write-Warning "This test file requires Pester v5 or later. Skipping."; return }

# We dot-source the file directly for Unit Testing 
# or use Import-Module if testing the module as a whole.
BeforeAll {
    # Find the project root by going up three levels from the current script directory
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    # Set the data directory to the project Data folder for testing
    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"
    
    #################################################################################
    # Dot-source the necessary files for testing
    #################################################################################
    # Dot-source the prefix file to set up the environment and variables
    . $ProjectRoot/Source/prefix.ps1

    # Dot-source the CountryCode class file to make it available for testing
    . $ProjectRoot/Source/Classes/CountryCode.ps1
}

Describe "CountryCode Class" {
    Context "1 Constructor Tests" {
        It "1.1 Should create an instance with country name and code" {
            $countryCode = [CountryCode]::new("United States", "+1")
            $countryCode.CountryName | Should -Be "United States"
            $countryCode.Code | Should -Be "+1"
            $countryCode.ISO2 | Should -BeNullOrEmpty
            $countryCode.ISO3 | Should -BeNullOrEmpty
            $countryCode.NumericCode | Should -Be 0
        }
        It "1.2 Should create an instance with all properties" {
            $countryCode = [CountryCode]::new("United States", "+1", "US", "USA", 840)
            $countryCode.CountryName | Should -Be "United States"
            $countryCode.Code | Should -Be "+1"
            $countryCode.ISO2 | Should -Be "US"
            $countryCode.ISO3 | Should -Be "USA"
            $countryCode.NumericCode | Should -Be 840
        }
        It "1.3 Should create an empty object" {
            $countryCode = [CountryCode]::new()
            $countryCode.CountryName | Should -BeNullOrEmpty
            $countryCode.Code | Should -BeNullOrEmpty
            $countryCode.ISO2 | Should -BeNullOrEmpty
            $countryCode.ISO3 | Should -BeNullOrEmpty
            $countryCode.NumericCode | Should -Be -1
        }
        It "1.4 Should throw when ISO2 is null in full constructor" {
            { [CountryCode]::new("United States", "+1", $null, "USA", 840) } |
                Should -Throw "ISO2 cannot be null or empty."
        }

        It "1.5 Should throw when ISO3 is null in full constructor" {
            { [CountryCode]::new("United States", "+1", "US", $null, 840) } |
                Should -Throw "ISO3 cannot be null or empty."
        }

        It "1.6 Should throw when NumericCode is zero in full constructor" {
            { [CountryCode]::new("United States", "+1", "US", "USA", 0) } |
                Should -Throw "NumericCode must be a positive integer."
        }

        It "1.7 Should throw when NumericCode is negative in full constructor" {
            { [CountryCode]::new("United States", "+1", "US", "USA", -5) } |
                Should -Throw "NumericCode must be a positive integer."
        }

        It "1.8 Should throw when CountryName is whitespace (2-param constructor)" {
            { [CountryCode]::new("   ", "+1") } | Should -Throw
        }

        It "1.9 Should throw when Code is whitespace (2-param constructor)" {
            { [CountryCode]::new("United States", "   ") } | Should -Throw
        }
    }
    
    Context "2 Property Tests" {
        It "2.1 Should allow setting and getting properties" {
            $countryCode = [CountryCode]::new("United States", "+1")
            $countryCode.ISO2 = "US"
            $countryCode.ISO3 = "USA"
            $countryCode.NumericCode = 840

            $countryCode.CountryName | Should -Be "United States"
            $countryCode.Code | Should -Be "+1"
            $countryCode.ISO2 | Should -Be "US"
            $countryCode.ISO3 | Should -Be "USA"
            $countryCode.NumericCode | Should -Be 840
        }   

        Context "2.2 Validation Tests" {
            It "2.2.1 Should handle invalid input gracefully" {
                { [CountryCode]::new($null, "+1") } | Should -Throw
                { [CountryCode]::new("United States", $null) } | Should -Throw
                { [CountryCode]::new("United States", "+1", $null, "USA", 840) } | Should -Throw
            }
        }
    }   
    Context "3 Static Property Tests" {
        Context "3.1 Data Path and Caching Tests" {
            BeforeAll {
                # Ensure we start with a clean cache for testing
                $savedDataDirectory = $script:cacheTelephoneNumberDataDirectory
            }
            BeforeEach {
                # Reset the data directory and cache before each test to ensure independence
                $script:cacheTelephoneNumberDataDirectory = $savedDataDirectory
                # Clear cache before each test to ensure independence
                $script:cacheTelephoneNumberCountryCodes = $null
            }
            It "3.1.1 Should change the data directory when setting DataDirectory" {
                $saved = $script:cacheTelephoneNumberDataDirectory
                $newDir = (Split-Path -Path (Get-Location) -Parent)
                [CountryCode]::SetDataDirectory($newDir)
                $script:cacheTelephoneNumberDataDirectory | Should -Be (Split-Path -Path (Get-Location) -Parent)
                # Restore original value after test
                [CountryCode]::SetDataDirectory($saved)
            }
            It "3.1.2 Should cache country codes correctly" {
                $script:cacheTelephoneNumberCountryCodes = $null
                $codes = [CountryCode]::GetAllCountryCodes()
                $script:cacheTelephoneNumberCountryCodes | Should -Not -BeNullOrEmpty
                #{ $codes.Code } | Should -Be $script:cacheTelephoneNumberCountryCodes.Count
            }
            It "3.1.3 Should return the same cached list on subsequent calls" {
                $script:cacheTelephoneNumberCountryCodes = $null
                $firstCall = [CountryCode]::GetAllCountryCodes()
                $secondCall = [CountryCode]::GetAllCountryCodes()
                $thirdCall = [CountryCode]::GetAllCountryCodes()
                [object]::ReferenceEquals($firstCall, $secondCall) | Should -Be $true
                [object]::ReferenceEquals($secondCall, $thirdCall) | Should -Be $true
            }

        }
        
    }
    Context "4 Method Tests" {
        Context "4.1 Method Tests - GetNumericCodeOnly()" {
            # GetNumericCodeOnly method tests would go here if implemented
            It "4.1.1 Should return numeric code only as a string" {
                $countryCode = [CountryCode]::new("United States", "+1", "US", "USA", 840)
                $countryCode.GetNumericCodeOnly() | Should -Be "1"
            }
        }
        Context "4.2 Method Tests - FormatNumber()" {
            It "4.2.1 Should format number correctly" {
                $PhoneNumber = "1234567890"
                $countryCode = [CountryCode]::new("United States", "+1")
                $formattedNumber = $countryCode.FormatNumber($PhoneNumber)
                $formattedNumber | Should -Be "+11234567890"
                # FormatNumber method tests would go here if implemented
            }
        }
        Context "4.3 Method Tests - MatchesNumber()" {
            It "4.3.1 Should match the country code number correctly - no subcode" {
                $countryCode = [CountryCode]::new("United States", "+1", "US", "USA", 840)
                $countryCode.MatchesNumber("+14125551212") | Should -Be $true
            }
            It "4.3.2 Should not match the country code number correctly - no subcode" {
                $countryCode = [CountryCode]::new("United States", "+1", "US", "USA", 840)
                $countryCode.MatchesNumber("+444125551212") | Should -Be $false
            }

            It "4.3.3 Should match the country code number correctly - with subcode" {
                $countryCode = [CountryCode]::new("Antigua and Barbuda", "+1-268", "AG", "ATG", 1)
                $countryCode.MatchesNumber("+12681234567") | Should -Be $true
            }

            It "4.3.4 Should not match the country code number correctly - with subcode" {
                $countryCode = [CountryCode]::new("Antigua and Barbuda", "+1-268", "AG", "ATG", 1)
                $countryCode.MatchesNumber("+14125551212") | Should -Be $false
            }
        }
        Context "4.4 Method Tests - GetAllCountryCodes()" {
            BeforeAll {
                $script:cacheTelephoneNumberCountryCodes = $null
                $codes = [CountryCode]::GetAllCountryCodes()
            }

            It "4.4.1 Throws FileNotFoundException when CountryCodes.csv is missing" {
                $script:cacheTelephoneNumberCountryCodes = $null
                $originalDir = $script:cacheTelephoneNumberDataDirectory
                $script:cacheTelephoneNumberDataDirectory = "C:\NonExistentPath_XYZZY"
                try {
                    { [CountryCode]::GetAllCountryCodes() } | Should -Throw
                } finally {
                    $script:cacheTelephoneNumberDataDirectory = $originalDir
                    $script:cacheTelephoneNumberCountryCodes = $null
                }
            }

            #
            It "4.4.2 Should return a non-empty list of country codes" {
                $codes | Should -Not -BeNullOrEmpty
                $codes.Count | Should -BeGreaterThan 0
            }   

            # Assuming we have a known number of country codes, e.g., 241
            It "4.4.3 Should return the expected number of country codes" {
                $expectedCount = 241
                $csvFilePath = Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath "CountryCodes.csv"
                try {
                    $csvData = Import-Csv -Path $csvFilePath
                } catch {
                    throw [System.IO.FileNotFoundException]::new("CountryCodes.csv not found in data directory: $($script:cacheTelephoneNumberDataDirectory)")
                }
                $expectedCount = $csvData.Count
                # Assuming we have a known number of country codes, e.g., 250
                $codes.Count | Should -Be $expectedCount
            }
            

            # The entries should be of type CountryCode
            It "4.4.4 Should contain objects of type CountryCode" {
                $codes[0].GetType().Name | Should -Be "CountryCode"
            }

            # All country codes should have a non-empty country name
            It "4.4.5 Should have no entries with empty country names" {
                $codes | Where-Object { [string]::IsNullOrWhiteSpace($_.CountryName) } |
                    Should -BeNullOrEmpty
            }

            # All country codes should have a non-empty code
            It "4.4.6 Should have no entries with empty codes" {
                $codes | Where-Object { [string]::IsNullOrWhiteSpace($_.Code) } |
                    Should -BeNullOrEmpty
            }

            # All country codes should start with a + sign
            It "4.4.7 Should have all codes starting with +" {
                $codes | Where-Object { -not $_.Code.StartsWith('+') } |
                    Should -BeNullOrEmpty
            }

            # Spot check a few known countries to ensure they are included and have correct properties
            It "4.4.8 Should contain United States with correct properties" {
                $us = $codes | Where-Object { $_.ISO2 -eq 'US' }
                $us.CountryName | Should -Be "United States"
                $us.Code | Should -Be "+1"
                $us.ISO3 | Should -Be "USA"
                $us.NumericCode | Should -Be 1
            }

            It "4.4.9 Should contain United Kingdom with correct properties" {
                $uk = $codes | Where-Object { $_.ISO2 -eq 'GB' }
                $uk.CountryName | Should -Be "United Kingdom"
                $uk.Code | Should -Be "+44"
            }

            It "4.4.10 Should return cached list on second call (same object reference)" {
                $first = [CountryCode]::GetAllCountryCodes()
                $second = [CountryCode]::GetAllCountryCodes()
                [object]::ReferenceEquals($first, $second) | Should -Be $true
            }
        }

        Context "4.5 Method Tests - FindByCode([string]$code)" {
            It "4.5.1 Should return a country code object for a valid country code" {
                $countryCode = [CountryCode]::FindByCode("+228")
                # test return type
                $countryCode | Should -Not -BeNull
                $countryCode -is [system.Collections.IEnumerable] | Should -Be $true
                $countryCode.Count | Should -Be 1
                # test properties of the returned object
                $countryCode.CountryName | Should -Be @('Togo')
                $countryCode.Code | Should -Be "+228"
                $countryCode.ISO2 | Should -Be "TG"
                $countryCode.ISO3 | Should -Be "TGO"
                $countryCode.NumericCode | Should -Be 228
            }

            It "4.5.2 Should return the correct country code(s) for a valid country code with multiple countries sharing the same code" {
                $countryCode = [CountryCode]::FindByCode("+1")
                # test return type
                $countryCode | Should -Not -BeNull
                $countryCode -is [system.Collections.IEnumerable] | Should -Be $true    
                $countryCode.Count | Should -Be 2
                # test properties of the returned objects
                $countryCode.CountryName | Should -Contain 'Canada'
                $countryCode.CountryName | Should -Contain 'United States'
            }

            It "4.5.3 Should return null for an invalid country code" {
                $invalidCountryCode = [CountryCode]::FindByCode("+999")
                # test return type
                $invalidCountryCode | Should -BeNull  
            }

            It "4.5.4 Should return empty for unknown code without plus" {
                $result = [CountryCode]::FindByCode("9999")
                $result | Should -BeNullOrEmpty
            }

            It "4.5.5 Should return results for numeric code 44 (UK)" {
                $result = [CountryCode]::FindByCode(44)
                $result | Should -Not -BeNullOrEmpty
                $result.ISO2.Contains("GB") | Should -Be $true
            }

        }
        Context "4.6 Method Tests - FindByCode([int]$numericcode)" {
            It "4.6.1 Should return no country codes with an invalid numericcode" {
                $invalidCountryCode = [CountryCode]::FindByCode(999)
                $invalidCountryCode | Should -BeNull  
            }
            It "4.6.2 Should return a single country codes with an valid numericcode" {
                $code = [CountryCode]::FindByCode(678)
                $code.Count |  Should -Be 1
            }
            It "4.6.3 Should return multiple country codes with an valid numericcode" {
                $code = [CountryCode]::FindByCode(1)
                $code.Count |  Should -BeGreaterThan 1
            }
        }
        Context "4.7 Method Tests - FindByISO([string]$iso)" {
            It "4.7.1 Should return a country code object for a valid 2 character ISO code" {
                $countryCode = [CountryCode]::FindByISO("US")
                # test return type
                $countryCode | Should -Not -BeNull
                $countryCode -is [system.Collections.IEnumerable] | Should -Be $true
                $countryCode.Count | Should -Be 1
                # test properties of the returned object
                $countryCode.CountryName | Should -Be @('United States')
                $countryCode.Code | Should -Be "+1"
                $countryCode.ISO2 | Should -Be "US"
                $countryCode.ISO3 | Should -Be "USA"
                $countryCode.NumericCode | Should -Be 1
            }

            It "4.7.2 Should return a country code object for a valid 3 character ISO code" {
                $countryCode = [CountryCode]::FindByISO("USA")
                # test return type
                $countryCode | Should -Not -BeNull
                $countryCode -is [system.Collections.IEnumerable] | Should -Be $true
                $countryCode.Count | Should -Be 1
                # test properties of the returned object
                $countryCode.CountryName | Should -Be @('United States')
                $countryCode.Code | Should -Be "+1"
                $countryCode.ISO2 | Should -Be "US"
                $countryCode.ISO3 | Should -Be "USA"
                $countryCode.NumericCode | Should -Be 1
            }

            It "4.7.3 Should return null for an invalid ISO code" {
                $invalidCountryCode = [CountryCode]::FindByISO("ZZ")
                # test return type
                $invalidCountryCode | Should -BeNull

            }

            It "4.7.4 Should throw an exception for an ISO code that is not 2 or 3 characters long" {
                { [CountryCode]::FindByISO("U") }  | Should -Throw 'ISO code must be either 2 or 3 characters long.'
                { [CountryCode]::FindByISO("USAA") }  | Should -Throw 'ISO code must be either 2 or 3 characters long.'
            }
            
            It "4.7.5 Should return null for a 3-character ISO code that is not found" {
                $result = [CountryCode]::FindByISO("ZZZ")
                $result | Should -BeNullOrEmpty
            }
        }

        Context "4.9 Full constructor validation" {
            It "4.9.1 Should throw when CountryName is null in full constructor" {
                { [CountryCode]::new($null, "+1", "US", "USA", 840) } | Should -Throw "CountryName cannot be null or empty."
            }
            It "4.9.2 Should throw when Code is null in full constructor" {
                { [CountryCode]::new("United States", $null, "US", "USA", 840) } | Should -Throw "Code cannot be null or empty."
            }
        }
        Context "4.10 SetDataDirectory validation" {
            It "4.10.1 Should throw when directory does not exist" {
                { [CountryCode]::SetDataDirectory("C:\NonExistentPath_XYZZY") } | Should -Throw
            }
        }
        Context "4.8 Method Tests - FindByName([string]$name)" {
            It "4.8.1 Should return a country code object for a valid country name" {
                $countryCode = [CountryCode]::FindByName("United States")
                # test return type
                $countryCode | Should -Not -BeNull
                $countryCode -is [system.Collections.IEnumerable] | Should -Be $true
                $countryCode.Count | Should -Be 1
                # test properties of the returned object
                $countryCode.CountryName | Should -Be @('United States')
                $countryCode.Code | Should -Be "+1"
                $countryCode.ISO2 | Should -Be "US"
                $countryCode.ISO3 | Should -Be "USA"
                $countryCode.NumericCode | Should -Be 1
            }

            It "4.8.2 Should return null for an invalid country name" {
                $invalidCountryCode = [CountryCode]::FindByName("Narnia")
                # test return type
                $invalidCountryCode | Should -BeNull  
            }

            It "4.8.3 Should return null for completely unknown name" {
                $result = [CountryCode]::FindByName("Atlantis")
                $result | Should -BeNullOrEmpty
            }

            It "4.8.4 Should return multiple results for partial match 'United'" {
                $result = [CountryCode]::FindByName("United")
                $result.Count | Should -BeGreaterThan 1
            }
        }
        Context "4.8.5 Method Tests - ToString()" {
            It "4.8.5.1 Should return a string representation of the object" {
                $countryCode = [CountryCode]::new("United States", "+1", "US", "USA", 840)
                $countryCode.ToString() | Should -Be "United States: +1"
            }
        }   

    }
}
