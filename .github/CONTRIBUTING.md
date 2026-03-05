# Contributing to EmailAddress

Thank you for taking the time to contribute. This document explains how to set up
a development environment, the conventions the project follows, and what the review
process looks like.

## Table of Contents

- [Contributing to EmailAddress](#contributing-to-emailaddress)
  - [Table of Contents](#table-of-contents)
  - [Code of Conduct](#code-of-conduct)
  - [Ways to Contribute](#ways-to-contribute)
  - [Before You Start](#before-you-start)
  - [Development Setup](#development-setup)
    - [Prerequisites](#prerequisites)
    - [1. Fork and clone the repository](#1-fork-and-clone-the-repository)
    - [2. Install build dependencies](#2-install-build-dependencies)
    - [3. Verify the setup](#3-verify-the-setup)
  - [Project Structure](#project-structure)
  - [Making Changes](#making-changes)
    - [Adding a new public cmdlet](#adding-a-new-public-cmdlet)
    - [Adding a new private helper](#adding-a-new-private-helper)
    - [Modifying the EmailAddress class](#modifying-the-emailaddress-class)
  - [Tests](#tests)
    - [Running tests](#running-tests)
    - [Test file conventions](#test-file-conventions)
    - [What the CI checks](#what-the-ci-checks)
  - [Code Style](#code-style)
    - [PSScriptAnalyzer](#psscriptanalyzer)
  - [Submitting a Pull Request](#submitting-a-pull-request)
    - [Pull request checklist](#pull-request-checklist)
  - [What to Expect](#what-to-expect)

---

## Code of Conduct

This project follows a standard code of conduct. Please be respectful in all
interactions — issues, pull requests, and discussions. See
[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for details.

---

## Ways to Contribute

- **Bug reports** — if something behaves unexpectedly, open an issue using the
  bug report template
- **Feature requests** — if you have an idea for a new capability, open an issue
  using the feature request template to discuss it before writing any code
- **Bug fixes** — pick up an open issue labeled `bug` and submit a pull request
- **Documentation** — corrections, clarifications, and additional examples are
  always welcome
- **Tests** — additional test cases that improve coverage or document edge cases

If you are planning to work on something non-trivial, open an issue first so we
can discuss the approach before you invest the time.

---

## Before You Start

- Check [open issues](https://github.com/keslar/psEmailAddress/issues) to see if
  the problem or feature is already being tracked
- Check [open pull requests](https://github.com/keslar/psEmailAddress/pulls) to
  see if someone else is already working on it
- For significant changes, comment on the issue to let others know you are working
  on it

---

## Development Setup

### Prerequisites

- PowerShell 5.1 or PowerShell 7+
- Git

### 1. Fork and clone the repository

```powershell
git clone https://github.com/<your-username>/psEmailAddress.git
cd psEmailAddress
```

### 2. Install build dependencies

The project uses `InvokeBuild` as its task runner. All other required modules are
declared in `RequiredModules.psd1`. Install them with:

```powershell
# Install InvokeBuild first (the bootstrapper for everything else)
Install-Module -Name InvokeBuild -MinimumVersion 5.10.4 -Scope CurrentUser

# Install all remaining build dependencies
$modules = Import-PowerShellDataFile .\RequiredModules.psd1
foreach ($name in $modules.Keys) {
    $minVersion = ($modules[$name] -replace '^[\[\(]([^,]+),.+$', '$1').Trim()
    Install-Module -Name $name -MinimumVersion $minVersion -Scope CurrentUser -Force
}
```

The required modules are:

| Module            | Purpose                              |
|-------------------|--------------------------------------|
| `InvokeBuild`     | Task runner (`Invoke-Build`)         |
| `ModuleBuilder`   | Compiles source into a `.psm1`       |
| `Pester`          | Test framework                       |
| `PSScriptAnalyzer`| Static analysis / linting            |
| `Configuration`   | Required by `ModuleBuilder`          |
| `Metadata`        | Required by `ModuleBuilder`          |
| `PowerShellGet`   | Module publishing                    |

### 3. Verify the setup

Run the default build task, which runs analysis, builds the module, and runs the
unit tests:

```powershell
Invoke-Build
```

A clean run should produce no PSScriptAnalyzer errors and no failing tests.

---

## Project Structure

```
psEmailAddress/
├── Source/                         # All source files — edit these, not Build/
│   ├── Classes/
│   │   └── EmailAddress.ps1        # The EmailAddress class
│   ├── Public/                     # Exported cmdlets (one file per cmdlet)
│   │   ├── Compare-EmailAddress.ps1
│   │   ├── ConvertTo-EmailAddress.ps1
│   │   ├── ConvertTo-NormalizedEmailAddress.ps1
│   │   ├── Format-EmailAddress.ps1
│   │   ├── Get-EmailAddress.ps1
│   │   ├── New-EmailAddress.ps1
│   │   ├── Set-EmailAddress.ps1
│   │   └── Test-EmailAddress.ps1
│   ├── Private/                    # Internal helpers (not exported)
│   │   └── Resolve-EmailAddressInput.ps1
│   ├── ENUMs/                      # Enum definitions (currently empty)
│   ├── prefix.ps1                  # Prepended to the compiled .psm1
│   ├── suffix.ps1                  # Appended to the compiled .psm1
│   └── EmailAddress.psd1           # Module manifest
├── Tests/
│   ├── Unit/                       # Unit tests (dot-source source files directly)
│   │   ├── Classes/
│   │   │   └── EmailAddress.Tests.ps1
│   │   ├── Public/                 # One .Tests.ps1 file per public cmdlet
│   │   └── Private/
│   └── Integration/                # Integration tests (import the built module)
│       └── EmailAddress.Integration.Tests.ps1
├── Docs/
│   └── help/
│       └── en-US/
│           └── about_EmailAddress.help.txt
├── Build/                          # Build output — do not edit, do not commit
├── .build.ps1                      # InvokeBuild task definitions
├── RequiredModules.psd1            # Build tool dependencies
├── PSScriptAnalyzerSettings.ps1    # Linting rules
└── version.txt                     # Current version string
```

**Important:** Never edit files under `Build/`. That directory is generated output.
All changes go in `Source/` and `Tests/`.

---

## Making Changes

### Adding a new public cmdlet

1. Create `Source/Public/YourVerb-EmailAddress.ps1` — use an existing cmdlet as a
   template for structure and style
2. Add the function name to `FunctionsToExport` in `Source/EmailAddress.psd1`
3. Create `Tests/Unit/Public/YourVerb-EmailAddress.Tests.ps1` with full Pester
   coverage (see [Tests](#tests) below)
4. Add the cmdlet to the `CMDLET SUMMARY` section in
   `Docs/help/en-US/about_EmailAddress.help.txt`

### Adding a new private helper

1. Create `Source/Private/Your-HelperName.ps1`
2. Create `Tests/Unit/Private/Your-HelperName.Tests.ps1`

### Modifying the EmailAddress class

The class lives in `Source/Classes/EmailAddress.ps1`. Its corresponding tests
are in `Tests/Unit/Classes/EmailAddress.Tests.ps1`. Both files must be updated
together for any change to validation logic, methods, or properties.

---

## Tests

The project uses [Pester 5](https://pester.dev) and enforces a **90% code coverage
threshold**. A pull request that drops coverage below 90% will fail CI.

### Running tests

```powershell
# Unit tests only (fast — no build required)
Invoke-Build TestUnit

# Integration tests (requires a build first)
Invoke-Build TestIntegration

# Both
Invoke-Build Test
```

Unit tests dot-source the source files directly. Integration tests import the
compiled module from `Build/`. Run unit tests during development; run integration
tests before opening a pull request.

### Test file conventions

- One test file per source file, named `<SourceFileName>.Tests.ps1`
- Test files live in the same relative path under `Tests/Unit/` as their source
  file lives under `Source/`
  (e.g. `Source/Public/New-EmailAddress.ps1` →
  `Tests/Unit/Public/New-EmailAddress.Tests.ps1`)
- Tests are organized with `Describe` → `Context` → `It`, using the numbering
  scheme already established in the existing test files
  (e.g. `"1 Parameter Set - FromString"`, `"1.1 Valid Input"`, `"1.1.1 Should..."`)
- Each `It` block tests exactly one thing and has a descriptive name that reads
  as a statement of expected behavior
- Use `BeforeAll` for shared fixtures; avoid relying on test execution order
- Every public parameter, parameter set, pipeline input path, error condition, and
  output type should have at least one test

### What the CI checks

Every pull request runs on three platforms via GitHub Actions:

| Platform         | PowerShell  |
|------------------|-------------|
| Windows          | 5.1         |
| Windows          | 7 (latest)  |
| Ubuntu           | 7 (latest)  |

All three must pass before a pull request can be merged.

---

## Code Style

The project does not yet have a populated `.editorconfig`. Follow the conventions
in the existing source files:

- **Indentation:** 4 spaces (no tabs)
- **Line endings:** CRLF in `.ps1` and `.psd1` files
- **Encoding:** UTF-8
- **Brace style:** opening brace on the same line as the statement
- **Comment-based help:** every public function must have a full `.SYNOPSIS`,
  `.DESCRIPTION`, one `.PARAMETER` block per parameter, at least two `.EXAMPLE`
  blocks, and an `.INPUTS` / `.OUTPUTS` / `.NOTES` section — follow the existing
  cmdlets as a template
- **`[CmdletBinding()]`:** required on every public function
- **`[OutputType()]`:** required on every public function
- **Parameter validation:** use `[ValidateNotNullOrEmpty()]`, `[AllowNull()]`,
  `[AllowEmptyString()]` etc. rather than manual null checks where possible
- **Error handling:** public cmdlets use `$PSCmdlet.ThrowTerminatingError()` for
  terminating errors, not `throw`; `Write-Error` for non-terminating errors

### PSScriptAnalyzer

The build runs PSScriptAnalyzer on all source files at `Error` and `Warning`
severity. A pull request with any analyzer errors will fail CI. Run the analyzer
locally before pushing:

```powershell
Invoke-Build Analyze
```

The following rules are explicitly excluded (see `PSScriptAnalyzerSettings.ps1`):

- `PSAvoidGlobalVars`
- `PSAvoidUsingDeprecatedManifestFields`
- `PSPossibleIncorrectUsageOfAssignmentOperator`
- `PSUseShouldProcessForStateChangingFunctions`
- `PSUseOutputTypeCorrectly`

Do not suppress additional rules in source files without discussing it first.

---

## Submitting a Pull Request

1. **Create a branch** off `main` with a descriptive name:
   ```
   git checkout -b fix/validation-consecutive-dots
   git checkout -b feature/add-group-address-support
   ```

2. **Make your changes** — keep commits focused and atomic. A pull request should
   do one thing.

3. **Run the full default build** and confirm it is clean:
   ```powershell
   Invoke-Build
   ```

4. **Run integration tests** to verify nothing is broken end-to-end:
   ```powershell
   Invoke-Build TestIntegration
   ```

5. **Push and open a pull request** against the `main` branch. Use the appropriate
   pull request template (bug fix or feature). Fill it in completely — a PR with
   an empty description takes longer to review.

6. **Respond to review feedback.** Push additional commits to the same branch; do
   not close and reopen the PR.

### Pull request checklist

Before marking a pull request ready for review, confirm:

- [ ] `Invoke-Build` (analyze + build + unit tests) passes cleanly
- [ ] `Invoke-Build TestIntegration` passes
- [ ] All new code has corresponding Pester tests
- [ ] Code coverage remains at or above 90%
- [ ] Comment-based help is complete for any new or modified public functions
- [ ] `CHANGELOG.md` has an entry under the appropriate section in the current
  unreleased version block
- [ ] No build artifacts from `Build/` are included in the commit

---

## What to Expect

This module is maintained by a single developer. Pull requests are reviewed on a
best-effort basis — typically within a few business days for small changes, longer
for larger ones. You will receive feedback, a request for changes, or a merge.

If you have not heard back within two weeks, a polite comment on the PR to check
in is welcome.

Thank you for contributing.
