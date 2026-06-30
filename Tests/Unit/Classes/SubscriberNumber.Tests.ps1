if ((Get-Module Pester).Version.Major -lt 5) { Write-Warning "This test file requires Pester v5 or later. Skipping."; return }

# We dot-source the file directly for Unit Testing
# or use Import-Module if testing the module as a whole.
BeforeAll {
    # Find the project root by going up three levels from the current script directory
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    #################################################################################
    # Dot-source the necessary files for testing
    #################################################################################
    # Dot-source the prefix file to set up the environment and variables
    . $ProjectRoot/Source/prefix.ps1

    # Set the data directory to the project Data folder for testing
    $script:cacheTelephoneNumberDataDirectory = Join-Path -Path $ProjectRoot -ChildPath "Data"

    # Dot-source the CountryCode class file to make it available for testing
    . $ProjectRoot/Source/Classes/CountryCode.ps1
    . $ProjectRoot/Source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/Source/Classes/SubscriberNumber.ps1
}

Describe "SubscriberNumber Class" {
    Context "1 Constructor Tests" {
        Context "1.1 Default Constructor" {
            It "Should create an instance with a null value" {
                $subscriberNumber = [SubscriberNumber]::new()
                $subscriberNumber.Value | Should -BeNullOrEmpty
            }
        }
        Context "1.2 Parameterized Constructor" {
            It "Should create an instance with the provided value" {
                $number = "1234567890"
                $subscriberNumber = [SubscriberNumber]::new($number)
                $subscriberNumber.Value | Should -Be $number
            }
        }
        Context "1.3 Parameterized Constructor with ISO3" {
            It "Should create an instance with the provided value and validate it for a valid number and ISO3" {
                $number = "5551212"
                { [SubscriberNumber]::new($number, "USA") } | Should -Not -Throw
                $subscriberNumber = [SubscriberNumber]::new($number, "USA")
                $subscriberNumber.Value | Should -Be $number
            }
            It "Should throw an exception for an invalid number format for the given ISO3" {
                $number = "123"
                { [SubscriberNumber]::new($number, "USA") } | Should -Throw "Invalid subscriber number format for country code: USA"
            }
        }
    }
    Context "2 Method Tests" {
        Context "2.1 ToString Method" {
            It "Should return the value as a string" {
                $number = "1234567890"
                $subscriberNumber = [SubscriberNumber]::new($number)
                $subscriberNumber.ToString() | Should -Be $number
            }
        }
        Context "2.2 IsValid Method" {
            It "Should return true for a valid subscriber number format ISO3 = USA and number = 5551212" {
                $number = "5551212"
                $subscriberNumber = [SubscriberNumber]::new($number)
                $subscriberNumber.IsValid("USA") | Should -BeTrue
            }
            It "Should return false for an invalid subscriber number format ISO3 = ATA and number = 55512" {
                $number = "55512"
                $subscriberNumber = [SubscriberNumber]::new($number)
                $subscriberNumber.IsValid("ATA") | Should -BeFalse
            }
        }
    }
    Context "3 Static Method Tests" {
        Context "3.1 ClearCache Method" {
            BeforeAll {
                # Ensure the cache is populated
                $script:cacheTelephoneNumberSubscriberNumberFormats = $null
                $null = [SubscriberNumber]::GetSubscriberNumberFormats()
            }
            It "3.1.1 Should clear the cached formats" {
                $script:cacheTelephoneNumberSubscriberNumberFormats | Should -Not -BeNullOrEmpty
                [SubscriberNumber]::ClearCache()
                $script:cacheTelephoneNumberSubscriberNumberFormats | Should -BeNullOrEmpty
            }
        }
        Context "3.2 SetDataDirectory Method" {
            BeforeAll {
                $savedDataDirectory = $script:cacheTelephoneNumberDataDirectory
            }
            AfterAll {
                $script:cacheTelephoneNumberDataDirectory = $savedDataDirectory
            }
            It "3.2.1 Should throw when directory does not exist" {
                { [SubscriberNumber]::SetDataDirectory("C:\NonExistentPath_XYZZY") } | Should -Throw
            }
            It "3.2.2 Should update data directory and clear cache when valid directory is set" {
                $script:cacheTelephoneNumberSubscriberNumberFormats = $null
                $null = [SubscriberNumber]::GetSubscriberNumberFormats()
                $script:cacheTelephoneNumberSubscriberNumberFormats | Should -Not -BeNullOrEmpty
                $newDir = (Split-Path -Path (Get-Location) -Parent)
                [SubscriberNumber]::SetDataDirectory($newDir)
                $script:cacheTelephoneNumberSubscriberNumberFormats | Should -BeNullOrEmpty
                $script:cacheTelephoneNumberDataDirectory | Should -Be $newDir
                # Restore
                [SubscriberNumber]::SetDataDirectory($savedDataDirectory)
            }
        }
        Context "3.3 GetSubscriberNumberFormatForCountryCode Method" {
            It "3.3.1 Should throw for invalid country code" {
                { [SubscriberNumber]::GetSubscriberNumberFormatForCountryCode("ZZZ") } | Should -Throw "No subscriber number format found for country code: ZZZ"
            }
        }
        Context "3.4 GetSubscriberNumberFormats Method" {
            BeforeAll {
                # Clear the cache to ensure we are testing the file loading logic
                $script:cacheTelephoneNumberSubscriberNumberFormats = $null
            }
            It "Should throw an exception if the data file is missing" {
                # Temporarily rename the data file to simulate it being missing
                $dataFile = Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath "SubscriberNumberFormats.csv"
                $tempFile = "$dataFile.bak"
                Rename-Item -Path $dataFile -NewName $tempFile
                try {
                    { [SubscriberNumber]::GetSubscriberNumberFormats() } | Should -Throw "Subscriber number formats data file not found at path: $dataFile"
                } finally {
                    # Restore the original file
                    Rename-Item -Path $tempFile -NewName "SubscriberNumberFormats.csv"
                }
            }
            It "Should return a list of subscriber number formats" {
                $formats = [SubscriberNumber]::GetSubscriberNumberFormats()
                $formats | Should -Not -BeNullOrEmpty
                $formats.GetType().Name | Should -Be "Object[]"
            }
            It "Should cache the formats after the first call" {
                # Call the method once to populate the cache
                $formats1 = [SubscriberNumber]::GetSubscriberNumberFormats()
                # Call the method again to test if it uses the cache
                $formats2 = [SubscriberNumber]::GetSubscriberNumberFormats()
                # The second call should return the same object from the cache
                $formats1 | Should -Be $formats2
            }
            It "Should return the same number of rows as are in the CSV file" {
                $dataFile = Join-Path -Path $script:cacheTelephoneNumberDataDirectory -ChildPath "SubscriberNumberFormats.csv"
                $csvData = Import-Csv -Path $dataFile
                $formats = [SubscriberNumber]::GetSubscriberNumberFormats()
                $formats.Count | Should -Be $csvData.Count
            }
        }
    }
}
