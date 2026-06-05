![otskit-preserve for Claude](banner.png)

# otskit-preserve

A Claude skill that creates BagIt-compatible preservation packages and anchors them to the Bitcoin blockchain via OpenTimestamps.

## What it does

- Packages any file or folder into a standards-compliant archive (BagIt / RFC 8493, OAIS / ISO 14721, PREMIS 3.0)
- Computes SHA-256 for every file in the package
- Stamps the archive hash on Bitcoin via the OTSkit MCP server
- Produces four portable deliverables: `.zip`, `.sha256`, `.ots`, `.stamp-id.txt`

## Requirements

- Claude Code with the `@otskit/mcp` MCP server configured
- PowerShell (Windows) or bash (Linux/macOS)

## Usage

Trigger with: *"preserve this"*, *"stamp this folder"*, *"archive this document"*, or *"create a preservation package"*.

Claude will ask for the path, an optional description, and an optional output directory, then run the full workflow automatically.

## Standards

| Standard | Role |
|---|---|
| BagIt (RFC 8493) | Package structure and fixity manifest |
| OAIS (ISO 14721) | Preservation metadata model |
| PREMIS 3.0 | Event and agent provenance |
| OpenTimestamps | Bitcoin blockchain anchoring |

See [preservation-standards.md](preservation-standards.md) for the rationale behind every design decision.
