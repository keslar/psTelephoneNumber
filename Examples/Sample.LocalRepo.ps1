
$global:cacheSecrets = @{}

function GetVaultValue {
    # example usage: GetVaultValue -SecretName "MySecret" -ForceRefresh
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SecretName,
        [Parameter(Mandatory = $false)]
        [switch]$ForceRefresh
    )
    logDebug -Message "GetVaultValue :: Called for secret $SecretName. ForceRefresh = $ForceRefresh"
    # If not forcing refresh, check cache
    if ( -not $ForceRefresh ) {        
        # new multiple secret cache
        if ( $global:cacheSecrets.ContainsKey( $SecretName ) ) {
            if ( (Get-Date) - $global:cacheSecrets[$SecretName].RetrievedOn -lt (New-TimeSpan -Minutes 15) ) {  
                return $global:cacheSecrets[$SecretName].Value
            }
        }
    }

    $tryCount = 0
    while ( $tryCount -lt 4 ) {
        $tryCount += 1
        try {
            $secretValue = Get-AzKeyVaultSecret -VaultName "PittTeamsVault" -Name $SecretName -AsPlainText -ErrorAction Stop
            # Update cache
            $global:cacheSecrets[$SecretName] = @{
                "Value"       = $secretValue
                "RetrievedOn" = (Get-Date)
            }
            return $secretValue
        } catch {
            Write-Warning "GetVaultValue :: Retrying retrieval of secret $SecretName (Attempt $tryCount of 3)"
        }
    }
    throw "GetVaultValue :: Failed to retrieve secret $SecretName after 3 attempts."
}

function MapModuleRepositoryDrive {
    [CmdletBinding()]
    param(
        [string]$SecretName = "PittTeamsStorageKey"
        [string]$DriveLetter = "M"
    )

    # Check if drive is already mapped
    if (Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue) {
        Write-Build Green "Drive $DriveLetter: is already mapped."
        return
    }

    # Test connectivity to the Azure storage account on port 445 before attempting to map the drive
    $connectTestResult = Test-NetConnection -ComputerName pittitteams.file.core.windows.net -Port 445
    if ($connectTestResult.TcpTestSucceeded) {
        $secretKey = GetVaultValue -SecretName $SecretName 
        # Save the password so the drive will persist on reboot
        cmd.exe /C "cmdkey /add:`"pittitteams.file.core.windows.net`" /user:`"localhost\pittitteams`" /pass:`"$($secretKey)`""
        # Mount the drive
        New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root "\\pittitteams.file.core.windows.net\psmodules" -Persist
    } else {
        Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
    }

}

function ConnectPittTeamsModuleRepository {
    [CmdletBinding()]
    param(
        [string]$StorageAccountName = "pittitteams",
        [string]$SecretName = "PittTeamsStorageKey",
    )
    if ( -not CheckPittTeamsModuleRepositoryConnection) {
        $secretKey = GetVaultValue -SecretName $SecretName
        cmd.exe /C "cmdkey /add:`"pittitteams.file.core.windows.net`" /user:`"localhost\pittitteams`" /pass:`"$($secretKey)`""
    }

    if ( -not CheckPittTeamsModuleRepositoryConnection) {
        throw "Unable to connect to the Pitt Teams module repository at \\pittitteams.file.core.windows.net\psmodules. Check your network connection, ensure port 445 is not blocked, and verify the storage account key is correct."
    }
    
}

function CheckPittTeamsModuleRepositoryConnection {
    [CmdletBinding()]
    param(
        [string]$RepoUrl = "\\pittitteams.file.core.windows.net\psmodules"
    )

    $connectTestResult = Test-NetConnection -ComputerName "pittitteams.file.core.windows.net" -Port 445
    if ($connectTestResult.TcpTestSucceeded) {
        Write-Build Green "Successfully connected to the Pitt Teams module repository at $RepoUrl."
        if (Test-Path $RepoUrl) {
            Write-Build Green "Verified access to the Pitt Teams module repository at $RepoUrl."
            return $true
        } else {
            Write-Warning "Connected to pittitteams.file.core.windows.net on port 445, but unable to access the repository path at $RepoUrl. Check permissions and share settings for the storage account."
        }
    } else {
        Write-Error -Message "Unable to connect to the Pitt Teams module repository at $RepoUrl. Check your network connection and ensure that port 445 is not blocked by your organization or ISP."
    }
    return $false
}
function RegisterPittTeamsModuleRepository {
    param (
        [string]$RepoName = "PittTeamsModules",
        [string]$RepoUrl = "\\pittitteams.file.core.windows.net\psmodules"
    )
    

    if (-not (Get-PSRepository -Name $repoName -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Name $repoName -SourceLocation $repoUrl -InstallationPolicy Trusted
        Write-Build Green "Registered PowerShell repository: $repoName ($repoUrl)"
    } else {
        Write-Build Green "PowerShell repository already registered: $repoName"
    }
}