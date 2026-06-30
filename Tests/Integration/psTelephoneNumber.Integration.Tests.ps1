<#
.SYNOPSIS
    Integration tests for the TelephoneNumber module.

.DESCRIPTION
    These tests validate the full module pipeline end-to-end — importing
    the built/signed module and exercising all public cmdlets against the
    real data files. They test realistic phone number scenarios across
    multiple countries and verify that cmdlets interact correctly with
    each other.

    Unlike unit tests, these do NOT dot-source source files. They rely
    entirely on the built module being importable and functional.
#>

BeforeAll {
    # Resolve the built module — walk up from Tests/Integration to project root
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $ModuleName  = Split-Path $ProjectRoot -Leaf

    # Find the highest version built in Output/
    $OutputPath  = Join-Path $ProjectRoot 'Output' $ModuleName
    $BuiltVersion = Get-ChildItem -Path $OutputPath -Directory |
        Sort-Object { [version]$_.Name } -Descending |
        Select-Object -First 1

    if (-not $BuiltVersion) {
        throw "No built module found in $OutputPath — run the Build task first."
    }

    $ManifestPath = Join-Path $BuiltVersion.FullName "$ModuleName.psd1"

    # Remove any previously loaded version and import the built module
    if (Get-Module -Name $ModuleName) {
        Remove-Module -Name $ModuleName -Force
    }
    Import-Module $ManifestPath -Force

    # Convenience — phone numbers used across multiple tests
    $Script:US_NYC          = '+12121234567'       # USA, New York City (NDC 212)
    $Script:US_DC           = '+12025551234'       # USA, Washington DC (NDC 202)
    $Script:US_FORMATTED    = '+1 (212) 123-4567'  # USA with formatting
    $Script:UK_LONDON       = '+442071234567'       # UK, London (NDC 20)
    $Script:UK_MOBILE       = '+447451234567'       # UK, Mobile (NDC 745)
    $Script:DE_BERLIN       = '+493012345678'       # Germany, Berlin (NDC 30)
    $Script:DE_HAMBURG      = '+494012345678'       # Germany, Hamburg (NDC 40)
    $Script:CA_TORONTO      = '+14165551234'        # Canada, Toronto (NDC 416)
}

AfterAll {
    $ModuleName = Split-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path -Leaf
    Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
}

###############################################################################
Describe 'Module Import' {
###############################################################################
    It 'Module imports successfully' {
        $ModuleName = Split-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path -Leaf
        Get-Module -Name $ModuleName | Should -Not -BeNullOrEmpty
    }

    It 'All expected public cmdlets are exported' {
        $ModuleName = Split-Path (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path -Leaf
        $commands = Get-Command -Module $ModuleName | Select-Object -ExpandProperty Name
        $commands | Should -Contain 'New-TelephoneNumber'
        $commands | Should -Contain 'Get-TelephoneNumberCountryCode'
        $commands | Should -Contain 'Get-TelephoneNumberNationalDestinationCode'
        $commands | Should -Contain 'Get-TelephoneNumberNationalDestinationCodes'
        $commands | Should -Contain 'Get-TelephoneNumberSubscriberNumber'
        $commands | Should -Contain 'Get-TelephoneNumberAllCountryCodes'
    }
}

###############################################################################
Describe 'New-TelephoneNumber' {
###############################################################################
    Context 'Valid numbers' {
        It 'Accepts a clean E.164 US number' {
            { New-TelephoneNumber -Number $Script:US_NYC } | Should -Not -Throw
        }

        It 'Returns a TelephoneNumber object' {
            $result = New-TelephoneNumber -Number $Script:US_NYC
            $result.GetType().Name | Should -Be 'TelephoneNumber'
        }

        It 'Strips formatting and stores clean E.164 value' {
            $result = New-TelephoneNumber -Number $Script:US_FORMATTED
            $result.Value | Should -Be $Script:US_NYC
        }

        It 'Accepts a UK number' {
            { New-TelephoneNumber -Number $Script:UK_LONDON } | Should -Not -Throw
        }

        It 'Accepts a German number' {
            { New-TelephoneNumber -Number $Script:DE_BERLIN } | Should -Not -Throw
        }

        It 'Accepts a Canadian number' {
            { New-TelephoneNumber -Number $Script:CA_TORONTO } | Should -Not -Throw
        }

        It 'Stores the value starting with a plus sign' {
            $result = New-TelephoneNumber -Number $Script:UK_LONDON
            $result.Value | Should -Match '^\+'
        }

        It 'ToString returns the same value as .Value' {
            $result = New-TelephoneNumber -Number $Script:US_NYC
            $result.ToString() | Should -Be $result.Value
        }
    }

    Context 'Invalid numbers' {
        It 'Throws for alphabetic input' {
            { New-TelephoneNumber -Number 'abc-def-ghij' } | Should -Throw
        }

        It 'Throws for a number with no valid country code' {
            { New-TelephoneNumber -Number '+999999999999' } | Should -Throw
        }

        It 'Throws for an empty string' {
            { New-TelephoneNumber -Number '' } | Should -Throw
        }

        It 'Throws for special characters only' {
            { New-TelephoneNumber -Number '!@#$%^&*' } | Should -Throw
        }

        It 'Throws for a number with a valid country code but no valid NDC' {
            { New-TelephoneNumber -Number '+10000000000' } | Should -Throw
        }
    }
}

###############################################################################
Describe 'Get-TelephoneNumberCountryCode' {
###############################################################################
    Context 'US numbers' {
        It 'Returns a CountryCode object' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_NYC
            $result.GetType().Name | Should -Be 'CountryCode'
        }

        It 'Returns country code +1 for a US number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_NYC
            $result.Code | Should -Be '+1'
        }

        It 'Returns ISO2 US for a US number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_NYC
            $result.ISO2 | Should -Be 'US'
        }

        It 'Returns ISO3 USA for a US number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_NYC
            $result.ISO3 | Should -Be 'USA'
        }
    }

    Context 'UK numbers' {
        It 'Returns country code +44 for a UK number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:UK_LONDON
            $result.Code | Should -Be '+44'
        }

        It 'Returns ISO3 GBR for a UK number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:UK_LONDON
            $result.ISO3 | Should -Be 'GBR'
        }
    }

    Context 'German numbers' {
        It 'Returns country code +49 for a German number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:DE_BERLIN
            $result.Code | Should -Be '+49'
        }

        It 'Returns ISO3 DEU for a German number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:DE_BERLIN
            $result.ISO3 | Should -Be 'DEU'
        }
    }

    Context 'Canada — shared +1 country code with US' {
        It 'Returns country code +1 for a Canadian number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:CA_TORONTO
            $result.Code | Should -Be '+1'
        }

        It 'Resolves Canada (not USA) for a Toronto number' {
            $result = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:CA_TORONTO
            $result.ISO3 | Should -Be 'CAN'
        }
    }

    Context 'Invalid input' {
        It 'Throws for a number with no valid country code' {
            { Get-TelephoneNumberCountryCode -TelephoneNumber '+999999999999' } | Should -Throw
        }
    }
}

###############################################################################
Describe 'Get-TelephoneNumberNationalDestinationCode' {
###############################################################################
    Context 'US numbers' {
        It 'Returns a NationalDestinationCode object' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_NYC
            $result.GetType().Name | Should -Be 'NationalDestinationCode'
        }

        It 'Returns NDC 212 for a New York City number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_NYC
            $result.Code | Should -Be '212'
        }

        It 'Returns NDC 202 for a Washington DC number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_DC
            $result.Code | Should -Be '202'
        }

        It 'Returns ISO3 USA for a US NDC' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_NYC
            $result.ISO3 | Should -Be 'USA'
        }

        It 'Returns IsGeographic true for a US geographic number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_NYC
            $result.IsGeographic | Should -Be $true
        }
    }

    Context 'UK numbers' {
        It 'Returns NDC 20 for a London number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:UK_LONDON
            $result.Code | Should -Be '20'
        }

        It 'Returns IsGeographic true for London' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:UK_LONDON
            $result.IsGeographic | Should -Be $true
        }

        It 'Returns IsGeographic false for a UK mobile number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:UK_MOBILE
            $result.IsGeographic | Should -Be $false
        }

        It 'Returns NumberType mobile for a UK mobile number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:UK_MOBILE
            $result.NumberType | Should -Be 'mobile'
        }
    }

    Context 'German numbers' {
        It 'Returns NDC 30 for a Berlin number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:DE_BERLIN
            $result.Code | Should -Be '30'
        }

        It 'Returns NDC 40 for a Hamburg number' {
            $result = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:DE_HAMBURG
            $result.Code | Should -Be '40'
        }
    }

    Context 'Invalid input' {
        It 'Throws for an invalid telephone number' {
            { Get-TelephoneNumberNationalDestinationCode -TelephoneNumber '+999999999999' } | Should -Throw
        }
    }
}

###############################################################################
Describe 'Get-TelephoneNumberSubscriberNumber' {
###############################################################################
    Context 'US numbers' {
        It 'Returns a SubscriberNumber object' {
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:US_NYC
            $result.GetType().Name | Should -Be 'SubscriberNumber'
        }

        It 'Returns the correct subscriber digits for a US number' {
            # +1 (212) 123-4567 → CC=+1, NDC=212, SN=1234567
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:US_NYC
            $result.Value | Should -Be '1234567'
        }

        It 'Returns the correct subscriber digits for a DC number' {
            # +1 202 555-1234 → CC=+1, NDC=202, SN=5551234
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:US_DC
            $result.Value | Should -Be '5551234'
        }

        It 'ToString returns the subscriber number value' {
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:US_NYC
            $result.ToString() | Should -Be $result.Value
        }
    }

    Context 'UK numbers' {
        It 'Returns the correct subscriber digits for a London number' {
            # +44 20 7123 4567 → CC=+44, NDC=20, SN=71234567
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:UK_LONDON
            $result.Value | Should -Be '71234567'
        }
    }

    Context 'German numbers' {
        It 'Returns the correct subscriber digits for a Berlin number' {
            # +49 30 1234 5678 → CC=+49, NDC=30, SN=12345678
            $result = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:DE_BERLIN
            $result.Value | Should -Be '12345678'
        }
    }

    Context 'Invalid input' {
        It 'Throws for an invalid telephone number' {
            { Get-TelephoneNumberSubscriberNumber -TelephoneNumber '+999999999999' } | Should -Throw
        }
    }
}

###############################################################################
Describe 'Get-TelephoneNumberNationalDestinationCodes' {
###############################################################################
    Context 'By ISO code' {
        It 'Returns results for a valid ISO2 code' {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO 'US'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns results for a valid ISO3 code' {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO 'USA'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns NationalDestinationCode objects' {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO 'USA'
            $result[0].GetType().Name | Should -Be 'NationalDestinationCode'
        }

        It 'Returns multiple NDCs for USA' {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO 'USA'
            $result.Count | Should -BeGreaterThan 1
        }

        It 'All returned NDCs have ISO3 USA' {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO 'USA'
            $result | ForEach-Object { $_.ISO3 | Should -Be 'USA' }
        }

        It 'Returns NDCs for UK by ISO2' {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO 'GB'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns NDCs for Germany by ISO3' {
            $result = Get-TelephoneNumberNationalDestinationCodes -ISO 'DEU'
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'By dialing code' {
        It 'Returns results for country code +1' {
            $result = Get-TelephoneNumberNationalDestinationCodes -Code '+1'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns results for country code +44' {
            $result = Get-TelephoneNumberNationalDestinationCodes -Code '+44'
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Returns NationalDestinationCode objects when querying by code' {
            $result = Get-TelephoneNumberNationalDestinationCodes -Code '+49'
            $result[0].GetType().Name | Should -Be 'NationalDestinationCode'
        }
    }
}

###############################################################################
Describe 'Get-TelephoneNumberAllCountryCodes' {
###############################################################################
    It 'Returns a non-empty list' {
        $result = Get-TelephoneNumberAllCountryCodes
        $result | Should -Not -BeNullOrEmpty
    }

    It 'Returns CountryCode objects' {
        $result = Get-TelephoneNumberAllCountryCodes
        $result[0].GetType().Name | Should -Be 'CountryCode'
    }

    It 'Returns more than 100 country codes' {
        $result = Get-TelephoneNumberAllCountryCodes
        $result.Count | Should -BeGreaterThan 100
    }

    It 'Contains a country code for the US' {
        $result = Get-TelephoneNumberAllCountryCodes
        $result | Where-Object { $_.ISO2 -eq 'US' } | Should -Not -BeNullOrEmpty
    }

    It 'Contains a country code for the UK' {
        $result = Get-TelephoneNumberAllCountryCodes
        $result | Where-Object { $_.ISO2 -eq 'GB' } | Should -Not -BeNullOrEmpty
    }

    It 'All entries have a Code starting with +' {
        $result = Get-TelephoneNumberAllCountryCodes
        $result | ForEach-Object { $_.Code | Should -Match '^\+' }
    }
}

###############################################################################
Describe 'End-to-end pipeline' {
###############################################################################
    Context 'Decompose and recompose a US number' {
        BeforeAll {
            $Script:E2E_Number = New-TelephoneNumber -Number $Script:US_NYC
            $Script:E2E_CC     = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_NYC
            $Script:E2E_NDC    = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_NYC
            $Script:E2E_SN     = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:US_NYC
        }

        It 'Reassembling CC + NDC + SN reproduces the original number' {
            $reassembled = "$($Script:E2E_CC.Code)$($Script:E2E_NDC.Code)$($Script:E2E_SN.Value)"
            $reassembled | Should -Be $Script:US_NYC
        }

        It 'TelephoneNumber.Value matches the original cleaned number' {
            $Script:E2E_Number.Value | Should -Be $Script:US_NYC
        }

        It 'Country code object matches the number via MatchesNumber' {
            $Script:E2E_CC.MatchesNumber($Script:US_NYC) | Should -Be $true
        }

        It 'NDC object matches the number via MatchesNumber' {
            $Script:E2E_NDC.MatchesNumber($Script:US_NYC) | Should -Be $true
        }
    }

    Context 'Decompose and recompose a UK number' {
        BeforeAll {
            $Script:E2E_UK_CC  = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:UK_LONDON
            $Script:E2E_UK_NDC = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:UK_LONDON
            $Script:E2E_UK_SN  = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:UK_LONDON
        }

        It 'Reassembling CC + NDC + SN reproduces the original UK number' {
            $reassembled = "$($Script:E2E_UK_CC.Code)$($Script:E2E_UK_NDC.Code)$($Script:E2E_UK_SN.Value)"
            $reassembled | Should -Be $Script:UK_LONDON
        }
    }

    Context 'Formatted input produces same result as clean input' {
        It 'Formatted US number parses to same CC as clean number' {
            $fromFormatted = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_FORMATTED
            $fromClean     = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_NYC
            $fromFormatted.Code | Should -Be $fromClean.Code
        }

        It 'Formatted US number parses to same NDC as clean number' {
            $fromFormatted = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_FORMATTED
            $fromClean     = Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $Script:US_NYC
            $fromFormatted.Code | Should -Be $fromClean.Code
        }

        It 'Formatted US number parses to same subscriber number as clean number' {
            $fromFormatted = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:US_FORMATTED
            $fromClean     = Get-TelephoneNumberSubscriberNumber -TelephoneNumber $Script:US_NYC
            $fromFormatted.Value | Should -Be $fromClean.Value
        }
    }

    Context 'GetAllCountryCodes result is consistent with country code lookup' {
        It 'Country code returned for US number exists in GetAllCountryCodes' {
            $cc     = Get-TelephoneNumberCountryCode -TelephoneNumber $Script:US_NYC
            $allCCs = Get-TelephoneNumberAllCountryCodes
            $allCCs | Where-Object { $_.ISO3 -eq $cc.ISO3 } | Should -Not -BeNullOrEmpty
        }
    }
}
