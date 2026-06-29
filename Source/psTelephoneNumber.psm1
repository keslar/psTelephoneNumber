$sourceDirectories = @('ENUMs', 'Classes', 'Public', 'Private')

$prefixPath = Join-Path -Path $PSScriptRoot -ChildPath 'prefix.ps1'
if (Test-Path -Path $prefixPath) {
    . $prefixPath
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

$suffixPath = Join-Path -Path $PSScriptRoot -ChildPath 'suffix.ps1'
if (Test-Path -Path $suffixPath) {
    . $suffixPath
}