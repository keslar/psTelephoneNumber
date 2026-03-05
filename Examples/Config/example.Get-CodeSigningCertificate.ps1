function Get-CodeSigningCertificate {
    [CmdletBinding()]
    param (
        [switch]$AllowSelfSigned,
        [string]$SubjectName
    )

    # Get the code signing certificate from the CurrentUser store
    $certs = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert | Where-Object { $_.FriendlyName -eq "$(whoami /upn)" }
    if ($SubjectName) {
        $certs = $certs | Where-Object { $_.Subject -like "*CN=$SubjectName*" }
    }

    if ($AllowSelfSigned) {
        $cert = $certs | Select-Object -First 1
    } else {
        $cert = $certs | Where-Object { -not $_.Verify() } | Select-Object -First 1
    }


    if ($null -eq $cert) {
        Write-Error "No code signing certificate found with subject name '$SubjectName'."
        return $null
    }

    return $cert
}