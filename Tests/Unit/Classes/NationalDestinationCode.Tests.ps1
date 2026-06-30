if ((Get-Module Pester).Version.Major -lt 5) { Write-Warning "This test file requires Pester v5 or later. Skipping."; return }

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
    . $ProjectRoot/Source/Classes/NationalDestinationCode.ps1

    # Create a sample CountryCode object for testing
    #$countryCodeUS = [CountryCode]::new("United States", "+1", "US", "USA", 1)
}

Describe "NationalDestinationCode Class" {
    Context "1 Constructor Tests" {
        Context "1.1 Validation Tests - Required Parameters - CountryCode, Code, Description" {
            It "1.1.1 should throw an error when CountryCode is null" {
                { [NationalDestinationCode]::new($null, "212", "New York City") } | Should -Throw "CountryCode cannot be null."
            }
            It "1.1.2 should throw an error when Code is null or empty" {
                { [NationalDestinationCode]::new("USA", $null, "New York City") } | Should -Throw "Code cannot be null or empty."
                { [NationalDestinationCode]::new("USA", "", "New York City") } | Should -Throw "Code cannot be null or empty."
            }
            It "1.1.3 should throw an error when Description is null or empty" {
                { [NationalDestinationCode]::new("USA", "212", $null) } | Should -Throw "Description cannot be null or empty."
                { [NationalDestinationCode]::new("USA", "212", "") } | Should -Throw "Description cannot be null or empty."
            }
            It "1.1.4 should create an instance with required parameters only" {
                { $ndc = [NationalDestinationCode]::new("USA", "212", "New York City") } | Should -Not -Throw
                #$ndc.CountryCode | Should -Be $countryCodeUS
                #$ndc.Code | Should -Be "212"
                #$ndc.Description | Should -Be "New York City"
                #$ndc.Region | Should -Be $null
                #$ndc.IsGeographic | Should -Be $false
                #$ndc.NumberType | Should -Be "unknown"
            }
        }
        Context "1.1a Invalid ISO3" {
            It "1.1a.1 Should throw when ISO3 is not found in 3-param constructor" {
                { [NationalDestinationCode]::new("ZZZ", "123", "Test") } | Should -Throw "Country code with ISO3 'ZZZ' not found."
            }
            It "1.1a.2 Should throw when ISO3 is not found in 6-param constructor" {
                { [NationalDestinationCode]::new("ZZZ", "123", "Test", "Region", $true, "geographic") } | Should -Throw "Country code with ISO3 'ZZZ' not found."
            }
        }
        Context "1.2 Validation Tests - All Parameters - CountryCode, Code, Description, Optional Parameters - Region, IsGeographic, NumberType" {
            It "1.2.1 should create an instance with all parameters" {
                { $ndc = [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "geographic") } | Should -Not -Throw
                $ndc = [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "geographic")
                $ndc.ISO3 | Should -Be "USA"
                $ndc.Code | Should -Be "212"
                $ndc.Description | Should -Be "New York City"
                $ndc.Region | Should -Be "New York"
                $ndc.IsGeographic | Should -Be $true
                $ndc.NumberType | Should -Be "geographic"
            }
            It "1.2.2 should throw an error when CountryCode is null" {
                { [NationalDestinationCode]::new($null, "212", "New York City", "New York", $true, "geographic") } | Should -Throw "CountryCode cannot be null."
            }
            It "1.2.3 should throw an error when Code is null or empty" {
                { [NationalDestinationCode]::new("USA", $null, "New York City", "New York", $true, "geographic") } | Should -Throw "Code cannot be null or empty."
                { [NationalDestinationCode]::new("USA", "", "New York City", "New York", $true, "geographic") } | Should -Throw "Code cannot be null or empty."
            }
            It "1.2.4 should throw an error when Description is null or empty" {
                { [NationalDestinationCode]::new("USA", "212", $null, "New York", $true, "geographic") } | Should -Throw "Description cannot be null or empty."
                { [NationalDestinationCode]::new("USA", "212", "", "New York", $true, "geographic") } | Should -Throw "Description cannot be null or empty."
            }
            It "1.2.5 should not throw an error when Region is null or empty" {
                $ndc1 = [NationalDestinationCode]::new("USA", "212", "New York City", $null, $true, "geographic")
                $ndc1.Region | Should -Be ""
            
                $ndc2 = [NationalDestinationCode]::new("USA", "212", "New York City", "", $true, "geographic")
                $ndc2.Region | Should -Be ""
            }
            It "1.2.6 should not throw an error when IsGeographic is true or false" {
                { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "geographic") } | Should -Not -Throw
                { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $false, "mobile") } | Should -Not -Throw
            }
            It "1.2.7 should not throw an error when IsGeographic is true and NumberType is geographic" {
                { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "geographic") } | Should -Not -Throw
            }
            It "1.2.8 should throw an error when IsGeographic is true and NumberType is not geographic" {
                { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "mobile") } | Should -Throw "NumberType must be 'geographic' when IsGeographic is true."
            }
            It "1.2.9 should throw an error when IsGeographic is false and NumberType is geographic" {
                { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $false, "geographic") } | Should -Throw "NumberType must not be 'geographic' when IsGeographic is false."
            }
            It "1.2.10 should not throw an error when IsGeographic is false and NumberType is not geographic" {
                { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $false, "mobile") } | Should -Not -Throw
            }   
        }
    }
    Context "2 Property Tests" {
        It "2.1 should have the correct properties and values" {
            $ndc = [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "geographic")
            $ndc.ISO3 | Should -Be "USA"
            $ndc.Code | Should -Be "212"
            $ndc.Description | Should -Be "New York City"
            $ndc.Region | Should -Be "New York"
            $ndc.IsGeographic | Should -Be $true
            $ndc.NumberType | Should -Be "geographic"
        }
        It "2.2 should have default values for optional properties" {
            $ndc = [NationalDestinationCode]::new("USA", "212", "New York City")
            $ndc.Region | Should -BeNullOrEmpty
            $ndc.IsGeographic | Should -Be $false
            $ndc.NumberType | Should -Be "unknown"
        }   
        It "2.3 should allow properties to be set and retrieved" {
            $ndc = [NationalDestinationCode]::new("USA", "212", "New York City")
            $ndc.Region = "New York"
            $ndc.IsGeographic = $true
            $ndc.NumberType = "geographic"
            $ndc.Region | Should -Be "New York"
            $ndc.IsGeographic | Should -Be $true
            $ndc.NumberType | Should -Be "geographic"
        }
        It "2.4 should not allow properties to be set to invalid values" {
            { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $false, "geographic") } | Should -Throw "NumberType must not be 'geographic' when IsGeographic is false."
            { [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "mobile") } | Should -Throw "NumberType must be 'geographic' when IsGeographic is true."
        }   
    }

    Context "3 Method Tests" {
        BeforeEach {
            [NationalDestinationCode]::ClearCache()
        }

        Context "3.1 Method Tests - ToString" {
            It "3.1.1 ToString should return the correct format - Required Parameters - CountryCode, Code, Description" {
                $ndc = [NationalDestinationCode]::new("USA", "212", "New York City")
                $ndc.ToString() | Should -Be "212 : United States (+1) - New York City"
            }
            It "3.1.2 ToString should return the correct format - All Parameters - CountryCode, Code, Description, Optional Parameters - Region, IsGeographic, NumberType" {
                $ndc = [NationalDestinationCode]::new("USA", "212", "New York City", "New York", $true, "geographic")
                $ndc.ToString() | Should -Be "212 : United States (+1) - New York City"
            }
        }
        Context "3.2 Method Tests - GetAllNationalCodes" {
            BeforeEach {
                # Clear the cache before testing
                [NationalDestinationCode]::ClearCache()
            }

            It "3.2.1 Should not throw an error" {
                { $codes = [NationalDestinationCode]::GetAllNationalDestinationCodes() } | Should -Not -Throw

            }
            It "3.2.2 Should return a list of NationalDestinationCode objects" {
                $codes = [NationalDestinationCode]::GetAllNationalDestinationCodes()
                $codes.GetType().Name | Should -Be "NationalDestinationCode[]"
                foreach ($code in $codes) {
                    $code.GetType().Name | Should -Be "NationalDestinationCode"
                }
            }
            It "3.2.3 Should return the same number of codes as are in the CSV file" {
                $codes = [NationalDestinationCode]::GetAllNationalDestinationCodes()
                $filePath = Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath "NationalDestinationCodes.csv"
                $csvData = Import-Csv -Path $filePath
                $csvData.Count | Should -Be $codes.Count
            }   
        }
        Context "3.2a Method Tests - GetAllNationalDestinationCodeForCountry invalid type" {
            It "3.2a.1 Should throw for non-string, non-CountryCode input" {
                { [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry(123) } | Should -Throw "CountryCode must be a string (ISO3) or a CountryCode object."
            }
        }
        Context "3.3 Method Tests - GetAllNationalDestinationCodeForCountry([ContryCode])" {
            BeforeEach {
                # Clear the cache before testing
                [CountryCode]::ClearCache()
                [NationalDestinationCode]::ClearCache()
            }
            # Test with null CountryCode 
            It "3.3.1 Should throw an error if CountryCode is empty" {
                $countryCode = [CountryCode]::new()
                { [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($null) } | Should -Throw "You cannot call a method on a null-valued expression."
            }
            #    # Test with a Valid CountryCode  (country code exist)
            It "3.3.2 Should return a list of NationalDestinationCode objects for a valid CountryCode" {
                $countryCode = ([CountryCode]::FindByISO("USA"))[0]
                $countryCode | Should -Not -BeNullOrEmpty
                { $codes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($countryCode) } | Should -Not -Throw
                $codes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($countryCode)
                $codes | Should -Not -BeNullOrEmpty
                foreach ($code in $codes) {
                    $code.GetType().Name | Should -Be "NationalDestinationCode"
                    $code.ISO3 | Should -Be "USA"
                }
            }
            #    # Test with an inValid CountryCode (country code does not exist)
            It "3.3.3 Should return no NationalDestinationCodes for an invalid CountryCode" {
                $countryCode = [CountryCode]::new("Invalid Country", "+999", "INV", "INV", 999)
                #{ $codes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($countryCode) } | Should -Throw "CountryCode must be a string (ISO3) or a CountryCode object."
                $codes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry($countryCode)
                $codes.Count | Should -Be 0
            }
        }
        Context "3.4 Method Tests - GetAllNationalDestinationCodeForCountryByISO([string]$ISO)" {
            BeforeEach {
                # Clear the cache before testing
                $script:cacheTelephoneNumberNationalDestinationCodes = $null
            }
            It "3.4.1 Should return a list of NationalDestinationCode objects for a valid ISO code" {
                { $codes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry("USA") } | Should -Not -Throw
                $codes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry("USA")
                $codes | Should -Not -BeNullOrEmpty
                foreach ($code in $codes) {
                    $code.GetType().Name | Should -Be "NationalDestinationCode"
                    $code.ISO3 | Should -Be "USA"
                }
            }
            It "3.4.2 Should throw an error for an invalid ISO code" {
                { $codes = [NationalDestinationCode]::GetAllNationalDestinationCodeForCountry("INV") } | Should -Throw "Country code with ISO3 'INV' not found."
            }
        }
        Context "3.5 Method Tests - FindByCode([string]$ISO3, [string]$Code)" {
            BeforeEach {
                # Clear the cache before testing
                $script:cacheTelephoneNumberNationalDestinationCodes = $null
            }
            It "3.5.1 Should return a NationalDestinationCode object for a valid ISO and Code" {
                { $code = [NationalDestinationCode]::FindByCode("USA", "212") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode("USA", "212")
                $code.GetType().Name | Should -Be "NationalDestinationCode"
                $code.ISO3 | Should -Be "USA"
                $code.Code | Should -Be "212"
                
            }
            It "3.5.2 Should return null for an invalid ISO code or Code" {
                { $code = [NationalDestinationCode]::FindByCode("USA", "999") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode("USA", "999")
                $code | Should -BeNull
                { $code = [NationalDestinationCode]::FindByCode("US", "999") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode("US", "999")
                $code | Should -BeNull
                { $code = [NationalDestinationCode]::FindByCode("INV", "212") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode("INV", "212")
                $code | Should -BeNull
            }
        }
        Context "3.6 Method Tests - FindByCode([int]$numericCode, [string]$Code)" {
            BeforeAll {
                # Clear the cache before testing
                $script:cacheTelephoneNumberNationalDestinationCodes = $null
            }
            It "3.6.1 Should return a NationalDestinationCode object for a valid numeric country code and destination code" {
                { $code = [NationalDestinationCode]::FindByCode(1, "212") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode(1, "212")
                #$code.GetType().Name | Should -Be "NationalDestinationCode"
                $code.ISO3 | Should -Be "USA"
                $code.Code | Should -Be "212"
            }
            It "3.6.2 Should return a NationalDestinationCode object for a valid numeric country code and destination code - even if the country code is shared by multiple territories" {
                { $code = [NationalDestinationCode]::FindByCode(1, "684") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode(1, "684")
                #$code.GetType().Name | Should -Be "NationalDestinationCode"
                $code.ISO3 | Should -Be "ASM"
                $code.Code | Should -Be "684"
            }
            It "3.6.3 Should not return a NationalDestinationCode object for a valid numeric country code and invalid destination code" {
                { $code = [NationalDestinationCode]::FindByCode(1, "911") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode(1, "911")
                $code | Should -BeNull
            }
            It "3.6.4 Should return null for an invalid numeric country code or Code" {
                { $code = [NationalDestinationCode]::FindByCode(0, "999") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode(0, "999")
                $code | Should -BeNull
            
                { $code = [NationalDestinationCode]::FindByCode(999, "212") } | Should -Not -Throw
                $code = [NationalDestinationCode]::FindByCode(999, "212")
                $code | Should -BeNull
            }
        }
        Context "3.7 Method Tests - isValidCode([string]$ISO3, [string]$Code)" {
            BeforeAll {
                # Clear the cache before testing
                $script:cacheTelephoneNumberNationalDestinationCodes = $null
            }
            It "3.7.1 Should return true for a valid ISO and Code" {
                { $isValid = [NationalDestinationCode]::isValidCode("USA", "212") } | Should -Not -Throw
                $isValid = [NationalDestinationCode]::isValidCode("USA", "212")
                $isValid | Should -Be $true
            }
            It "3.7.2 Should return false for an invalid ISO code or Code" {
                { $isValid = [NationalDestinationCode]::isValidCode("USA", "999") } | Should -Not -Throw
                $isValid = [NationalDestinationCode]::isValidCode("USA", "999")
                $isValid | Should -Be $false
            
                { $isValid = [NationalDestinationCode]::isValidCode("INV", "212") } | Should -Not -Throw
                $isValid = [NationalDestinationCode]::isValidCode("INV", "212")
                $isValid | Should -Be $false
            }
        }
        Context "3.8 Method Tests - MatchesNumber([string]$phoneNumber)" {
            BeforeAll {
                # Clear the cache before testing
                $script:cacheTelephoneNumberNationalDestinationCodes = $null
            }
            It "3.8.1 Should return true for a phone number that starts with the country code and NDC" {
                $ndc = [NationalDestinationCode]::FindByCode("USA", "212")
                { $matches = $ndc.MatchesNumber("+12125551234") } | Should -Not -Throw
                $matches = $ndc.MatchesNumber("+12125551234")
                $matches | Should -Be $true
            }
            It "3.8.2 Should return false for a phone number that does not start with the country code and NDC" {
                $ndc = [NationalDestinationCode]::FindByCode("USA", "212")
                { $matches = $ndc.MatchesNumber("+13125551234") } | Should -Not -Throw
                $matches = $ndc.MatchesNumber("+13125551234")
                $matches | Should -Be $false
            }
            It "3.8.3 Should return true for a phone number for territories that share the same country code and NDC" {
                $ndc = [NationalDestinationCode]::FindByCode("ASM", "684")
                { $matches = $ndc.MatchesNumber("+16845551234") } | Should -Not -Throw
                $matches = $ndc.MatchesNumber("+16845551234")
                $matches | Should -Be $true
            }
        }   
    }
    Context "4 Static Methods" {
        Context "4.1 ClearCache" {
            BeforeAll {
                $savedDataDirectory = $script:cacheTelephoneNumberDataDirectory
            }
            BeforeEach {
                # Manually reset the data directory and cache before each test to ensure independence
                $script:cacheTelephoneNumberDataDirectory = $savedDataDirectory
                $script:cacheTelephoneNumberNationalDestinationCodes = $null
            }
            It "4.1.1 Should clear the cache of national destination codes" {
                # Make sure is initally empty
                $script:cacheTelephoneNumberNationalDestinationCodes | Should -BeNull
                # Populate the cache first
                $codes = [NationalDestinationCode]::GetAllNationalDestinationCodes()
                $script:cacheTelephoneNumberNationalDestinationCodes | Should -Not -BeNullOrEmpty
                # Clear the cache
                [NationalDestinationCode]::ClearCache()
                $script:cacheTelephoneNumberNationalDestinationCodes | Should -BeNull
            }
        }
    }
    Context "4.2 SetDataDirectory" {
        BeforeAll {
            $savedDataDirectory = $script:cacheTelephoneNumberDataDirectory
        }
        BeforeEach {
            # Manually reset the data directory and cache before each test to ensure independence
            $script:cacheTelephoneNumberDataDirectory = $savedDataDirectory
        }
        It "4.2.1 Should change the data directory when setting DataDirectory" {
            $newDir = (Split-Path -Path (Get-Location) -Parent)
            [NationalDestinationCode]::SetDataDirectory($newDir)
            $script:cacheTelephoneNumberDataDirectory | Should -Be (Split-Path -Path (Get-Location) -Parent)
            # Restore original value after test
            [NationalDestinationCode]::SetDataDirectory($savedDataDirectory)
        }
        It "4.2.2 Should throw when directory does not exist" {
            { [NationalDestinationCode]::SetDataDirectory("C:\NonExistentPath_XYZZY") } | Should -Throw
        }
    }
}
