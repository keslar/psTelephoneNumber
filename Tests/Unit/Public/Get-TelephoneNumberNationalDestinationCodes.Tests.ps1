BeforeAll {
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"

    . $ProjectRoot/source/prefix.ps1
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
    . $ProjectRoot/source/Public/Get-TelephoneNumberNationalDestinationCodes.ps1
}

Describe "Public cmdlet - Get-TelephoneNumberNationalDestinationCodes (ByISO/ByCode)" {
    Context "1 ByISO parameter set" {
        It "1.1 Should not throw for a valid ISO3 code" {
            { Get-TelephoneNumberNationalDestinationCodes -ISO "USA" } | Should -Not -Throw
        }
        It "1.2 Should return NationalDestinationCode objects for USA" {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO "USA"
            $result | Should -Not -BeNullOrEmpty
        }
        It "1.3 Results should be NationalDestinationCode objects" {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO "USA"
            $result[0].GetType().Name | Should -Be "NationalDestinationCode"
        }
        It "1.4 Should include known US area code 412" {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO "USA"
            $codes = $result | Select-Object -ExpandProperty Code
            $codes | Should -Contain "412"
        }
    }
    Context "2 ByCode parameter set" {
        It "2.1 Should not throw for a valid country code" {
            { Get-TelephoneNumberNationalDestinationCodes -Code "+1" } | Should -Not -Throw
        }
        It "2.2 Should return results for country code +1" {
            $result = Get-TelephoneNumberNationalDestinationCodes -Code "+1"
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
