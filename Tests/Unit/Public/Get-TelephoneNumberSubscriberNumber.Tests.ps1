BeforeAll {
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..")).Path

    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"

    . $ProjectRoot/source/prefix.ps1
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
    . $ProjectRoot/source/Public/Get-TelephoneNumberSubscriberNumber.ps1
}

Describe "Public cmdlet - Get-TelephoneNumberSubscriberNumber" {
    Context "1 Cmdlet behavior" {
        It "1.1 Should not throw for a valid phone number" {
            { Get-TelephoneNumberSubscriberNumber -TelephoneNumber "+1 (412) 123-4567" } | Should -Not -Throw
        }
        It "1.2 Should return a SubscriberNumber object" {
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber "+1 (412) 123-4567"
            $result.GetType().Name | Should -Be "SubscriberNumber"
        }
        It "1.3 Should return the correct subscriber number for area code 412" {
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber "+1 (412) 123-4567"
            $result.Value | Should -Be "1234567"
        }
    }
}
