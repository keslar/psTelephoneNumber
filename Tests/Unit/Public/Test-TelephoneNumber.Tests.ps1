if ((Get-Module Pester).Version.Major -lt 5) { Write-Warning "This test file requires Pester v5 or later. Skipping."; return }

BeforeAll {
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path
    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"

    . $ProjectRoot/Source/prefix.ps1
    . $ProjectRoot/Source/ENUMs/PhoneNumberFormat.ps1
    . $ProjectRoot/Source/ENUMs/ValidationStatus.ps1
    . $ProjectRoot/Source/ENUMs/PhoneNumberType.ps1
    . $ProjectRoot/Source/Classes/CountryCode.ps1
    . $ProjectRoot/Source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/Source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/Source/Classes/TelephoneNumber.ps1
    . $ProjectRoot/Source/Public/Test-TelephoneNumber.ps1
}

Describe "Test-TelephoneNumber cmdlet" {
    Context "Valid numbers" {
        It "1.1 Should return Valid for valid US number" {
            $result = Test-TelephoneNumber -Number "+14125551234"
            $result | Should -Be ([ValidationStatus]::Valid)
        }
        It "1.2 Should return Valid for valid UK number" {
            $result = Test-TelephoneNumber -Number "+442071234567"
            $result | Should -Be ([ValidationStatus]::Valid)
        }
    }

    Context "Invalid numbers" {
        It "2.1 Should return InvalidFormat for non-numeric input" {
            $result = Test-TelephoneNumber -Number "invalid"
            $result | Should -Be ([ValidationStatus]::InvalidFormat)
        }
        It "2.2 Should return InvalidFormat for symbols only" {
            $result = Test-TelephoneNumber -Number "!@#$%"
            $result | Should -Be ([ValidationStatus]::InvalidFormat)
        }
    }

    Context "Pipeline input" {
        It "3.1 Should accept pipeline input" {
            $result = "+14125551234" | Test-TelephoneNumber
            $result | Should -Be ([ValidationStatus]::Valid)
        }
    }
}
