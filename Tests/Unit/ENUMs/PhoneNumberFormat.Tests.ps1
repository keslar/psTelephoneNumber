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
}

Describe "PhoneNumberFormat ENUM" {
    Context "ENUM values" {
        It "1.1 E164 should have value 1" {
            [PhoneNumberFormat]::E164.value__ | Should -Be 1
        }
        It "1.2 National should have value 2" {
            [PhoneNumberFormat]::National.value__ | Should -Be 2
        }
        It "1.3 RFC3966 should have value 3" {
            [PhoneNumberFormat]::RFC3966.value__ | Should -Be 3
        }
        It "1.4 Dialable should have value 4" {
            [PhoneNumberFormat]::Dialable.value__ | Should -Be 4
        }
    }
}

Describe "ValidationStatus ENUM" {
    Context "ENUM values" {
        It "2.1 Valid should have value 0" {
            [ValidationStatus]::Valid.value__ | Should -Be 0
        }
        It "2.2 InvalidCountryCode should have value 1" {
            [ValidationStatus]::InvalidCountryCode.value__ | Should -Be 1
        }
        It "2.3 InvalidNDC should have value 2" {
            [ValidationStatus]::InvalidNDC.value__ | Should -Be 2
        }
        It "2.4 InvalidSubscriberNumber should have value 3" {
            [ValidationStatus]::InvalidSubscriberNumber.value__ | Should -Be 3
        }
        It "2.5 InvalidFormat should have value 4" {
            [ValidationStatus]::InvalidFormat.value__ | Should -Be 4
        }
        It "2.6 Incomplete should have value 5" {
            [ValidationStatus]::Incomplete.value__ | Should -Be 5
        }
    }
}

Describe "PhoneNumberType ENUM" {
    Context "ENUM values" {
        It "3.1 Unknown should have value 0" {
            [PhoneNumberType]::Unknown.value__ | Should -Be 0
        }
        It "3.2 Landline should have value 1" {
            [PhoneNumberType]::Landline.value__ | Should -Be 1
        }
        It "3.3 Mobile should have value 2" {
            [PhoneNumberType]::Mobile.value__ | Should -Be 2
        }
        It "3.4 VoIP should have value 3" {
            [PhoneNumberType]::VoIP.value__ | Should -Be 3
        }
        It "3.5 TollFree should have value 4" {
            [PhoneNumberType]::TollFree.value__ | Should -Be 4
        }
        It "3.6 Premium should have value 5" {
            [PhoneNumberType]::Premium.value__ | Should -Be 5
        }
    }
}

Describe "TelephoneNumber.Format() method" {
    BeforeAll {
        $PhoneNumber = [TelephoneNumber]::new('+14125551234')
    }

    Context "E164 format" {
        It "4.1 Should return E164 format" {
            $PhoneNumber.Format([PhoneNumberFormat]::E164) | Should -Be '+14125551234'
        }
    }

    Context "RFC3966 format" {
        It "4.2 Should return RFC3966 format" {
            $PhoneNumber.Format([PhoneNumberFormat]::RFC3966) | Should -Be 'tel:+1-412-5551234'
        }
    }

    Context "Dialable format" {
        It "4.3 Should return Dialable format" {
            $PhoneNumber.Format([PhoneNumberFormat]::Dialable) | Should -Be '+14125551234'
        }
    }
}

Describe "TelephoneNumber.Validate() method" {
    Context "Valid number" {
        It "5.1 Should return Valid for valid number" {
            $PhoneNumber = [TelephoneNumber]::new('+14125551234')
            $PhoneNumber.Validate() | Should -Be ([ValidationStatus]::Valid)
        }
    }

    Context "Invalid number" {
        It "5.2 Should return InvalidFormat for number without country code" {
            { [TelephoneNumber]::Parse('5551234') } | Should -Throw
        }
    }
}
