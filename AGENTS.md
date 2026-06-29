# psTelephoneNumber

PowerShell module for telephone number parsing, validation, and manipulation.

## Architecture

- **`Source/`** is multi-file source. `ModuleBuilder` compiles it into a single `.psm1` + `.psd1` in `Output/`.
- **`Source/build.psd1`** is the ModuleBuilder config (not the build pipeline).
- **`Source/prefix.ps1`** is prepended to the compiled `.psm1`. It sets `$script:cacheTelephoneNumberDataDirectory` from `$env:TELEPHONE_NUMBER_DATA_DIR` (fallback: `Data/` next to module).
- **`Source/ENUMs/`** → `Classes/` → `Private/` → `Public/` load order matters.
- **`Source/Private/`** is empty in source — private functions go here if needed.

## Build Commands

All from repo root. Wrapper `build.ps1` delegates to `Build/.build.ps1` (Invoke-Build).

```powershell
.\build.ps1                            # Version → Build → Sign → TestIntegration
.\build.ps1 -TestUnit                  # Analyze → TestUnit (includes Analyze)
.\build.ps1 -TestIntegration           # Build → Sign → TestIntegration
.\build.ps1 -Task Clean, Analyze       # Run any specific task(s)
.\build.ps1 -Release -VersionBump minor  # Full pipeline with bump
.\build.ps1 -Release -SemVer 1.2.3     # Full pipeline with explicit version
.\build.ps1 -WhatIf                    # Dry-run
```

Task dependency chain: `TestUnit` depends on `Analyze`, `Build` depends on `TestUnit`, `Sign` depends on `Build`, `TestIntegration` depends on `Sign`.

## Testing

- **Pester 5** required. 90% code coverage threshold enforced.
- **Unit tests** (`Tests/Unit/`): dot-source source files, do not import module. Each `.Tests.ps1` sets `$env:TELEPHONE_NUMBER_DATA_DIR` to `Data/` and dot-sources `prefix.ps1` + relevant Classes + the function under test.
- **Integration tests** (`Tests/Integration/`): import built module from `Output/<Module>/<version>/`.
- Test results written to `Tests/Results/TestResults-*.xml`.

## CI

- Ubuntu (pwsh) + Windows (PS 5.1) via GitHub Actions.
- Pipeline: Analyze → Build → TestUnit → TestIntegration.
- Release workflow runs on Windows, triggered by git tags (`v*.*.*`).
- CI always skips code signing (`$env:CI` check in Sign task).
- Local testing with `act`: use `.actrc` config (runs Ubuntu in Docker, Windows as `-self-hosted`).

## Key Quirks

- **`$env:PSGALLERY_KEY`** (no underscore) is what `Build/.build.ps1` checks for publish. The release workflow sets **`PS_GALLERY_KEY`** (with underscore) — this is a known mismatch unless the build script is updated to check both.
- **Code signing**: only runs on local Windows (skipped in CI). Needs a valid cert in `Cert:\CurrentUser\My`. Self-signed certs accepted with relaxed status check.
- **Shared +1 country code**: NDC is used to disambiguate US (NDC 200‑999) vs Canada vs Caribbean.
- Commit messages should follow Conventional Commits for automatic version bumping: `feat:`, `fix:`, `BREAKING CHANGE`.

## Publishing

- Repository: `PittDigital` (must be registered with `Register-PSRepository`).
- `$env:PSGALLERY_KEY` set for NuGet API key (optional for private repos).
