# Security policy

## Scope
Security reports should cover md_Hero, its document parsers, archive handling, local file operations, packaging and release workflow.

## Reporting
Please do not disclose vulnerabilities in public issues. Use GitHub's private vulnerability reporting / Security Advisories feature if it is enabled for this repository. Otherwise, contact the repository owner privately through GitHub and request a confidential channel.

## Sensitive material
Do not attach confidential source documents, credentials, signing certificates, provisioning profiles or personal data to public reports.

## Security expectations
- Document conversion remains local.
- HTML scripts must never execute during extraction.
- Archive parsing must defend against path traversal, oversized entries and decompression bombs.
- Input files must remain unchanged.
- Temporary extraction files must be cleaned on success, failure and cancellation.
- Logs must not contain extracted document text.
