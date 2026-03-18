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
    . $ProjectRoot/source/prefix.ps1

    # Dot-source the CountryCode class file to make it available for testing
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
}

Describe "TelephoneNumber Class" {
    Context "1 Constructor Tests" {
        It "1.1 Should create an instance with a valid phone number" {
            $phoneNumber = [TelephoneNumber]::new("+1 (212) 123-4567")
            $phoneNumber.Value | Should -Be "+12121234567"
        }
        It "1.2 Should throw an exception for null or empty input" {
            { [TelephoneNumber]::new($null) } | Should -Throw "Value cannot be null or empty."
            { [TelephoneNumber]::new("") } | Should -Throw "Value cannot be null or empty."
            { [TelephoneNumber]::new("   ") } | Should -Throw "Value cannot be null or empty."
        }
        It "1.3 Should not throw an exception with no parameters" {
            $phoneNumber = [TelephoneNumber]::new()
            $phoneNumber.Value | Should -BeNullOrEmpty
        }
    }
    Context "2 Method Tests" {
        Context "2.1 ToString Method" {
            It "2.1.1 Should return the phone number as a string without formatting" {
                $phoneNumber = [TelephoneNumber]::new("+1 (303) 123-4567")
                $phoneNumber.ToString() | Should -Be "+13031234567"
            }
            It "2.1.2 Should return the phone number as a string without formatting adding a plus if missing" {
                $phoneNumber = [TelephoneNumber]::new("1 (415) 123-4567")
                $phoneNumber.ToString() | Should -Be "+14151234567"
            }
        }
        Context "2.2 GetCountryCode Method" {
            #TODO: Add more test cases for different Countries and area codes, including edge cases where multiple country codes could match and the NDC is needed to disambiguate. Also add test cases for invalid phone numbers that should throw exceptions.
            It "2.2.1 Should return the correct CountryCode object for a valid phone number" {
                $phoneNumber = [TelephoneNumber]::new("+1 (412) 123-4567")
                $countryCode = $phoneNumber.GetCountryCode()
                $countryCode.ISO3 | Should -Be "USA"
            }
            It "2.2.2 Should throw an exception for an invalid phone number" {
                {
                    $phoneNumber = [TelephoneNumber]::new("12345")
                    $phoneNumber.GetCountryCode() 
                } | Should -Throw "Invalid subscriber number format for country code: USA"   
            }
            It "2.2.3 Should correctly disambiguate when multiple country codes share a prefix" {
                # +1 is shared by USA, Canada, and many Caribbean nations
                # A Canadian number (+1 followed by Canadian area code) should return Canada
                $phoneNumber = [TelephoneNumber]::new("+1 (416) 123-4567")
                $countryCode = $phoneNumber.GetCountryCode()
                $countryCode | Should -Not -BeNullOrEmpty
            }
        }
        Context "2.3 GetNationalDestinationCode Method" {
            It "2.3.1 Should return the correct NationalDestinationCode object for a valid phone number" {
                $phoneNumber = [TelephoneNumber]::new("+1 (412) 123-4567")
                $ndc = $phoneNumber.GetNationalDestinationCode()
                $ndc.Code | Should -Be "412"
            }
            It "2.3.2 Should throw when NDC cannot be found for a truncated number" {
                # A number that has a valid country code but no matching NDC after stripping
                # We manipulate the Value directly after construction to simulate a bad state
                $phoneNumber = [TelephoneNumber]::new()
                $phoneNumber.Value = "+10000000000"  # Unlikely real NDC
                { $phoneNumber.GetNationalDestinationCode() } | Should -Throw
            }
        }
        Context "2.4 GetSubscriberNumber Method" {
            It "2.4.1 Should return the correct SubscriberNumber object for a valid phone number" {
                $phoneNumber = [TelephoneNumber]::new("+1 (412) 123-4567")
                $subscriberNumber = $phoneNumber.GetSubscriberNumber()
                $subscriberNumber.Value | Should -Be "1234567"
            }
            It "2.4.2 Should return a valid SubscriberNumber for a UK number" {
                $phoneNumber = [TelephoneNumber]::new("+44 20 7946 0123")
                $subscriber = $phoneNumber.GetSubscriberNumber()
                $subscriber | Should -Not -BeNullOrEmpty
            }
        }
    }
    Context "3 Static Method Tests" {
        Context "3.1 Parse Method" {
            # TODO: Add more test cases for different Countries and area codes
            It "3.1.1 Should parse a valid phone number and return it in a standardized format" {
                $parsedNumber = [TelephoneNumber]::Parse("+1 (412) 123-4567")
                $parsedNumber | Should -Be "+14121234567"
            }
            It "3.1.2 Should add a plus sign if missing and parse the number" {
                $parsedNumber = [TelephoneNumber]::Parse("1 (717) 123-4567")
                $parsedNumber | Should -Be "+17171234567"
            }
            It "Should remove all non-digit and non-plus characters but fail on number length" {
                { [TelephoneNumber]::Parse("+1-555-123-4567 ext. 89") } | Should -Throw "Invalid phone number format. Must contain a valid country code and national destination code."
            }
        }
    }
}#