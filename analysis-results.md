1. **Critical: built module cannot be imported**
- `[Build\TelephoneNumber\0.0.2\TelephoneNumber.psm1](G:\20 - Projects\TelephoneNumber\Build\TelephoneNumber\0.0.2\TelephoneNumber.psm1)` contains code after a signed-script block from the concatenated `NationalDestinationCode` file. PowerShell reports `Executable script code found in signature block` when importing.
- This is a release blocker: consumers cannot `Import-Module` the built artifact.

2. **High: public command surface is broken by function name collisions**
- `[Get-TelephoneNumberNationalDestinationCode.ps1:1](G:\20 - Projects\TelephoneNumber\Source\Public\Get-TelephoneNumberNationalDestinationCode.ps1:1)`, `[Get-TelephoneNumberNationalDestinationCodes.ps1:1](G:\20 - Projects\TelephoneNumber\Source\Public\Get-TelephoneNumberNationalDestinationCodes.ps1:1)`, and `[Get-TelephoneNumberSubscriberNumber.ps1:1](G:\20 - Projects\TelephoneNumber\Source\Public\Get-TelephoneNumberSubscriberNumber.ps1:1)` all define `Get-TelephoneNumberNationalDestinationCode`.
- In module load order, later definitions overwrite earlier ones, so intended commands are missing/miswired.

3. **High: subscriber cmdlet implementation is incorrect**
- `[Get-TelephoneNumberSubscriberNumber.ps1:1](G:\20 - Projects\TelephoneNumber\Source\Public\Get-TelephoneNumberSubscriberNumber.ps1:1)` defines the wrong function and returns `GetNationalDestinationCode()` (NDC), not a subscriber number.
- This is a logic/API mismatch.

4. **Medium: source manifest points to non-existent root module**
- `[TelephoneNumber.psd1:12](G:\20 - Projects\TelephoneNumber\Source\TelephoneNumber.psd1:12)` references `.\TelephoneNumber.psm1`, but `Source\TelephoneNumber.psm1` does not exist.
- Importing the source manifest fails.

5. **Medium: data directory handling is inconsistent**
- `[SubscriberNumber.ps1:63](G:\20 - Projects\TelephoneNumber\Source\Classes\SubscriberNumber.ps1:63)` reads from `$env:TELEPHONE_NUMBER_DATA_DIR`, while other classes use `$script:cacheTelephoneNumberDataDirectory`.
- `SetDataDirectory()` changes in other classes won’t affect subscriber formats, causing inconsistent runtime behavior.

6. **Low (style/maintainability): naming and export hygiene**
- Typo in filename: `[Get-TelephponeNumberCountryCode.ps1](G:\20 - Projects\TelephoneNumber\Source\Public\Get-TelephponeNumberCountryCode.ps1)`.
- Source manifest still uses wildcard exports (`Functions/Cmdlets/Aliases/Variables = '*'`) at `[TelephoneNumber.psd1:72](G:\20 - Projects\TelephoneNumber\Source\TelephoneNumber.psd1:72)`, `[TelephoneNumber.psd1:75](G:\20 - Projects\TelephoneNumber\Source\TelephoneNumber.psd1:75)`, `[TelephoneNumber.psd1:81](G:\20 - Projects\TelephoneNumber\Source\TelephoneNumber.psd1:81)`.

Checks run:
- `Invoke-Pester`: **142 passed, 0 failed**.
- `Invoke-ScriptAnalyzer` on repo: **62 findings** (2 error, 41 warning, 19 info).  
- Source-only analyzer findings are mostly `TypeNotFound` parse-time infos due class load order (`using module` commented out), not syntax errors.
- Tests currently mask API issues because they dot-source files and intentionally call the wrong function names (see `[Get-TelephoneNumberSubscriberNumber.Tests.ps1:14](G:\20 - Projects\TelephoneNumber\Tests\Unit\Public\Get-TelephoneNumberSubscriberNumber.Tests.ps1:14)`).
