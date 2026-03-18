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

    # Dot-source the class files to make them available for testing
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
    # Dot-source the New-TelephoneNumber function file to make it available for testing
    . $ProjectRoot/source/Public/New-TelephoneNumber.ps1
}

Describe "Public cmdlet - New-gTelephoneNumber" {
    Context "Test cmdlet behavior" {
        It "1.1 Not throw an exception for a valid phone number" {
            { New-TelephoneNumber -Number "+1 (212) 123-4567" } | Should -Not -Throw
        }
        It "1.2 Should output a TelephoneNumber object for a valid phone number" {
            $phoneNumber = New-TelephoneNumber -Number "+1 (212) 123-4567"
            $phoneNumber.GetType().Name | Should -Be "TelephoneNumber"
        }
        It "1.3 Create a TelephoneNumber object with the correct value for a valid phone number" {
            $phoneNumber = New-TelephoneNumber -Number "+1 (212) 123-4567"
            $phoneNumber.Value | Should -Be "+12121234567"
        }
        It "1.1 Should throw for a number with invalid characters only" {
            { New-TelephoneNumber -Number "abc-def-ghij" } | Should -Throw
        }
        It "1.2 Should throw for an empty-ish number with only symbols" {
            { New-TelephoneNumber -Number "!@#$%" } | Should -Throw
        }
    }
}