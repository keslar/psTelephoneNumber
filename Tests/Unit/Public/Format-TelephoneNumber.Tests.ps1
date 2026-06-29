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
    . $ProjectRoot/Source/Public/New-TelephoneNumber.ps1
    . $ProjectRoot/Source/Public/Format-TelephoneNumber.ps1
}

Describe "Format-TelephoneNumber cmdlet" {
    BeforeAll {
        $PhoneNumber = New-TelephoneNumber -Number "+14125551234"
    }

    Context "E164 format (default)" {
        It "1.1 Should return E164 format by default" {
            $result = Format-TelephoneNumber -InputObject $PhoneNumber
            $result | Should -Be '+14125551234'
        }
        It "1.2 Should return E164 format explicitly" {
            $result = Format-TelephoneNumber -InputObject $PhoneNumber -Format E164
            $result | Should -Be '+14125551234'
        }
    }

    Context "RFC3966 format" {
        It "2.1 Should return RFC3966 format" {
            $result = Format-TelephoneNumber -InputObject $PhoneNumber -Format RFC3966
            $result | Should -Be 'tel:+1-412-5551234'
        }
    }

    Context "Dialable format" {
        It "3.1 Should return Dialable format" {
            $result = Format-TelephoneNumber -InputObject $PhoneNumber -Format Dialable
            $result | Should -Be '+14125551234'
        }
    }

    Context "Pipeline input" {
        It "4.1 Should accept pipeline input" {
            $result = $PhoneNumber | Format-TelephoneNumber -Format RFC3966
            $result | Should -Be 'tel:+1-412-5551234'
        }
    }
}