$sourceDirectories = @('ENUMs', 'Classes', 'Public', 'Private')

if (Test-Path -Path '.\.prefix.ps1') {
    . .\.prefix.ps1
}

foreach ( $dir in $sourceDirectories) { 
    $path = Join-Path -Path $PSScriptRoot -ChildPath $dir 
    if (Test-Path -Path $path) { 
        Get-ChildItem -Path $path -Filter "*.ps1" | ForEach-Object { 
            . $_.FullName 
        } 
    } else { 
        Write-Warning "Source directory not found: $path" 
    } 
}   

if (Test-Path -Path '.\.suffix.ps1') {
    . .\.suffix.ps1
}