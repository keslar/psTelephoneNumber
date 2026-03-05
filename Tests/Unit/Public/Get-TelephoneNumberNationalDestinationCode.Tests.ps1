BeforeAll {
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\")).Path

    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"

    . $ProjectRoot/source/prefix.ps1
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
    . $ProjectRoot/source/Public/Get-TelephoneNumberNationalDestinationCode.ps1
}

Describe "Public cmdlet - Get-TelephoneNumberNationalDestinationCode (ByTelephoneNumber)" {
    Context "1 Cmdlet behavior" {
        It "1.1 Should not throw for a valid phone number" {
            { Get-TelephoneNumberNationalDestinationCode -TelephoneNumber "+1 (412) 123-4567" } | Should -Not -Throw
        }
        It "1.2 Should return a NationalDestinationCode object" {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber "+1 (412) 123-4567"
            $result.GetType().Name | Should -Be "NationalDestinationCode"
        }
        It "1.3 Should return the correct NDC for a US number" {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber "+1 (412) 123-4567"
            $result.Code | Should -Be "412"
        }
        It "1.4 Should return the correct NDC for a different US area code" {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber "+1 (212) 123-4567"
            $result.Code | Should -Be "212"
        }
    }
}
