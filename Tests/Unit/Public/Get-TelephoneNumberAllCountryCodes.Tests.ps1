BeforeAll {
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\")).Path

    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"

    . $ProjectRoot/source/prefix.ps1
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
    . $ProjectRoot/source/Public/Get-TelephoneNumberAllCountryCodes.ps1
}

Describe "Public cmdlet - Get-TelephoneNumberAllCountryCodes" {
    Context "1 Cmdlet behavior" {
        It "1.1 Should not throw" {
            { Get-TelephoneNumberAllCountryCodes } | Should -Not -Throw
        }
        It "1.2 Should return a non-empty collection" {
            $result = Get-TelephoneNumberAllCountryCodes
            $result | Should -Not -BeNullOrEmpty
        }
        It "1.3 Should return CountryCode objects" {
            $result = Get-TelephoneNumberAllCountryCodes
            $result[0].GetType().Name | Should -Be "CountryCode"
        }
        It "1.4 Should include United States in the result" {
            $result = Get-TelephoneNumberAllCountryCodes
            $usEntry = $result | Where-Object { $_.ISO3 -eq "USA" }
            $usEntry | Should -Not -BeNullOrEmpty
        }
    }
}
