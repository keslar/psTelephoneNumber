if ((Get-Module Pester).Version.Major -lt 5) { Write-Warning "This test file requires Pester v5 or later. Skipping."; return }

BeforeAll {
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\")).Path

    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"

    . $ProjectRoot/source/prefix.ps1
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
    . $ProjectRoot/source/Public/Get-TelephoneNumberCountryCode.ps1
}

Describe "Public cmdlet - Get-TelephoneNumberCountryCode" {
    Context "1 Cmdlet behavior" {
        It "1.1 Should not throw for a valid US phone number" {
            { Get-TelephoneNumberCountryCode -TelephoneNumber "+1 (412) 123-4567" } | Should -Not -Throw
        }
        It "1.2 Should return a CountryCode object" {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber "+1 (412) 123-4567"
            $result.GetType().Name | Should -Be "CountryCode"
        }
        It "1.3 Should return the correct country for a US number" {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber "+1 (412) 123-4567"
            $result.ISO3 | Should -Be "USA"
        }
        It "1.4 Should return the correct country for a UK number" {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber "+44 20 7946 0123"
            $result.ISO3 | Should -Be "GBR"
        }
    }
}
