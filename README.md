# psTelephoneNumber

PowerShell module for parsing, validating, and manipulating telephone numbers.

## Features

- Parse and validate international telephone numbers (E.164 format)
- Extract country codes, national destination codes (NDC), and subscriber numbers
- Validate numbers against ITU standards
- Support for US and international number formats

## Requirements

- PowerShell 5.1 or PowerShell 7+

## Installation

```powershell
# From a registered PowerShell repository
Install-Module -Name psTelephoneNumber

# From source
git clone https://github.com/keslar/psTelephoneNumber.git
cd psTelephoneNumber
.\build.ps1 -Release
```

## Quick Start

```powershell
# Create a telephone number object
$phone = New-TelephoneNumber -Number "+1 (212) 555-0123"
$phone.Value                                                          # Returns: +12125550123

# Validate a number
Test-TelephoneNumber -Number "+1 (212) 555-0123"                      # Returns: Valid

# Format for display
$phone | Format-TelephoneNumber -Format RFC3966                       # Returns: tel:+1-212-555-0123

# Extract components
Get-TelephoneNumberCountryCode            -TelephoneNumber $phone.Value  # Returns: CountryCode object (USA, +1)
Get-TelephoneNumberNationalDestinationCode -TelephoneNumber $phone.Value  # Returns: NationalDestinationCode object (212)
Get-TelephoneNumberSubscriberNumber        -TelephoneNumber $phone.Value  # Returns: SubscriberNumber object (5550123)
```

## Cmdlets

| Cmdlet | Description |
|--------|-------------|
| `New-TelephoneNumber` | Create a TelephoneNumber object from a string |
| `Test-TelephoneNumber` | Validate a telephone number string |
| `Format-TelephoneNumber` | Format a TelephoneNumber object for display |
| `Get-TelephoneNumberCountryCode` | Extract the country code from a number |
| `Get-TelephoneNumberNationalDestinationCode` | Get the NDC (area code) for a number |
| `Get-TelephoneNumberNationalDestinationCodes` | List all NDCs for a country |
| `Get-TelephoneNumberSubscriberNumber` | Get the subscriber number (local number) |
| `Get-TelephoneNumberAllCountryCodes` | List all supported country codes |

## Data Sources

The module uses CSV data files in the `Data/` directory:
- `CountryCodes.csv` - Country dialing codes
- `NationalDestinationCodes.csv` - Area/city codes by country
- `SubscriberNumberFormats.csv` - Local number formats

## Building

```powershell
# Install dependencies
Install-Module -Name InvokeBuild, Pester, PSScriptAnalyzer -Scope CurrentUser -Force

# Build and test
.\build.ps1
```

## License

See [LICENSE.md](LICENSE.md)