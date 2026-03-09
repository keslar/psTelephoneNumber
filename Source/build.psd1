@{
    # Path to the module manifest (.psd1) relative to this file
    Path                     = "./TelephoneNumber.psd1"

    # Where to output the built module
    OutputDirectory          = "./build"

    # Version management
    VersionedOutputDirectory = $true          # Creates output/MyModule/1.2.0/

    # Semver — overrides what's in the manifest
    # ModuleVersion = "1.2.0"

    # Prefix/Suffix content added to top/bottom of the merged .psm1
    Prefix                   = "prefix.ps1"                     # File path or inline string
    # Suffix = "suffix.ps1"

    # Control which directories get merged into the .psm1
    # By default, Public/ and Private/ folders are included
    SourceDirectories        = @(
        'ENUMs'
        'Classes'
        'Private'
        'Public'
    )

    # Public functions to export (by default, everything in Public/)
    PublicFilter             = "Public/*.ps1"

    # Copy additional files into the output (not merged into .psm1)
    CopyPaths                = @(
        'en-US'          # Localization
        '../data'           # Data files
        # 'lib/some.dll'
    )

    PrivateData              = @{
        PSData = @{
            Prerelease = ''
            # ... any other PSData keys you have
        }
    }

    # Encoding for the output .psm1
    Encoding                 = 'UTF8'
}
