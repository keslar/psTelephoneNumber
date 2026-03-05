# Security Policy

## Supported Versions

Only the latest published version of the EmailAddress module receives security fixes.
Older versions are not patched. If a vulnerability is found, the fix will be released
as a new version and the advisory will note the first safe version to use.

| Version | Supported |
|---------|-----------|
| Latest  | ✅ Yes    |
| Older   | ❌ No     |

## Scope

The EmailAddress module is a pure parsing and validation library. It:

- Accepts string input and produces typed objects
- Performs no network operations
- Makes no system calls
- Stores no data
- Handles no credentials, tokens, or secrets

The realistic vulnerability surface is narrow: input parsing logic that could be
exploited to cause unexpected behavior in a consuming application, such as a
validation bypass (accepting an address the caller believes is invalid), a
validation false positive (rejecting a valid address), or a denial-of-service
condition triggered by a crafted input string (e.g. catastrophic regex backtracking).

Issues with third-party dependencies (`Pester`, `PSScriptAnalyzer`, `ModuleBuilder`,
`InvokeBuild`) should be reported to those projects' maintainers directly. If you
believe this module is using a dependency in an insecure way, that is in scope.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Use one of the following private channels:

- **GitHub private vulnerability reporting** — the preferred method. From the
  repository's Security tab, click **"Report a vulnerability"** to open a private
  draft advisory. GitHub will notify the maintainer and keep the report confidential
  until a fix is available.

- **Email** — if you are unable to use GitHub's private reporting feature, send a
  report to [crk4@pitt.edu](mailto:crk4@pitt.edu) with the subject line:
  `[SECURITY] psEmailAddress — <brief description>`.

## What to Include in Your Report

The more detail you provide, the faster the issue can be assessed and resolved.
Please include:

- A clear description of the vulnerability and its potential impact
- The affected version(s)
- Step-by-step instructions to reproduce the issue
- A minimal code example or test case that demonstrates the problem
- Any relevant context — operating system, PowerShell edition (5.1 / 7.x), locale

## What to Expect

- **Acknowledgement** within 5 business days of receipt
- **Initial assessment** (confirmed, not confirmed, or needs more information)
  within 10 business days
- **Fix and coordinated disclosure** as soon as a patch is ready — typically within
  30 days for confirmed issues, depending on complexity

You will be kept informed throughout the process. Once a fix is released, a GitHub
Security Advisory will be published and you will be credited unless you prefer
otherwise.

## Coordinated Disclosure

Please give the maintainer a reasonable opportunity to investigate and release a fix
before disclosing the issue publicly. If you have not received an acknowledgement
within 5 business days or have not received a substantive update within 30 days,
you are welcome to disclose publicly.

## Out of Scope

The following are not considered security vulnerabilities for this project:

- Validation rule disagreements (e.g. "this address should be valid/invalid per RFC X")
  — please open a regular issue instead
- Vulnerabilities in PowerShell itself or the .NET runtime
- Issues that require a malicious actor to already have arbitrary code execution on
  the target machine
