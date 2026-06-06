![preserve — a set of skills that stamp and anchor data to the Bitcoin blockchain](../../banner.png)

# preserve

A skill that creates BagIt-compatible preservation packages and anchors them to the Bitcoin blockchain via OpenTimestamps. Works with Claude Code and Codex.

## What it does

- Packages any file or folder into a standards-compliant archive (BagIt / RFC 8493, OAIS / ISO 14721, PREMIS 3.0)
- Computes SHA-256 for every file in the package via OTSkit MCP `hash_file`
- Stamps the archive hash on Bitcoin via OTSkit MCP `stamp_file`
- Produces four portable deliverables: `.zip`, `.sha256`, `.ots`, `.stamp-id.txt`
- Includes PowerShell helper scripts for Windows workflows

## Requirements

- `@otskit/mcp` MCP server configured in your agent
- PowerShell (Windows) or bash (Linux/macOS)

## Usage

Trigger with: *"preserve this"*, *"stamp this folder"*, *"archive this document"*, or *"create a preservation package"*.

## Standards

| Standard | Role |
|---|---|
| BagIt (RFC 8493) | Package structure and fixity manifest |
| OAIS (ISO 14721) | Preservation metadata model |
| PREMIS 3.0 | Event and agent provenance |
| OpenTimestamps | Bitcoin blockchain anchoring |

See [preservation-standards.md](preservation-standards.md) for the rationale behind every design decision.
