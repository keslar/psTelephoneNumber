BeforeAll {
    $ProjectRoot = (Resolve-Path -Literal (Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\")).Path

    $env:TELEPHONE_NUMBER_DATA_DIR = Join-Path -Path $ProjectRoot -ChildPath "Data"

    . $ProjectRoot/source/prefix.ps1
    . $ProjectRoot/source/Classes/CountryCode.ps1
    . $ProjectRoot/source/Classes/NationalDestinationCode.ps1
    . $ProjectRoot/source/Classes/SubscriberNumber.ps1
    . $ProjectRoot/source/Classes/TelephoneNumber.ps1
    . $ProjectRoot/source/Public/Get-TelephoneNumberSubscriberNumber.ps1
}

# Note: Get-TelephoneNumberSubscriberNumber.ps1 currently defines Get-TelephoneNumberNationalDestinationCode
# (appears to be a copy-paste issue in the source). Tests exercise the function as defined in the file.
Describe "Public cmdlet - Get-TelephoneNumberSubscriberNumber (file)" {
    Context "1 Cmdlet behavior" {
        It "1.1 Should not throw for a valid phone number" {
            { Get-TelephoneNumberNationalDestinationCode -TelephoneNumber "+1 (412) 123-4567" } | Should -Not -Throw
        }
        It "1.2 Should return a NationalDestinationCode object" {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber "+1 (412) 123-4567"
            $result.GetType().Name | Should -Be "NationalDestinationCode"
        }
        It "1.3 Should return the correct NDC for area code 412" {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber "+1 (412) 123-4567"
            $result.Code | Should -Be "412"
        }
    }
}
