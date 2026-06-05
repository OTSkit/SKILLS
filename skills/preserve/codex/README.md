![otskit-preserve for Codex](banner.png)

# otskit-preserve-codex

A Codex skill that creates BagIt-compatible preservation packages and anchors them to the Bitcoin blockchain via OpenTimestamps.

## What it does

- Packages any file or folder into a standards-compliant archive (BagIt / RFC 8493, OAIS / ISO 14721, PREMIS 3.0)
- Uses OTSkit MCP `hash_file` for local SHA-256 fixity when that tool is available
- Stamps the archive hash on Bitcoin via the OTSkit MCP server
- Uses the SHA-256 returned by OTSkit `stamp_file` as the authoritative ZIP hash
- Produces four portable deliverables: `.zip`, `.sha256`, `.ots`, `.stamp-id.txt`
- Includes Windows PowerShell helper scripts so Codex can run the packaging workflow consistently

## Requirements

- Codex CLI with the `@otskit/mcp` MCP server configured
- PowerShell (Windows) or bash (Linux/macOS)

## Usage

Trigger with: *"preserve this"*, *"stamp this folder"*, *"archive this document"*, or *"create a preservation package"*.

Codex will ask for the path, an optional description, and an optional output directory, then run the full workflow automatically.

On Windows, Codex should use:

```text
scripts/prepare-preservation-package.ps1
scripts/complete-preservation-sidecars.ps1
```

When the active MCP exposes `hash_file`, Codex should use it for BagIt payload and tag manifests. The first script remains a Windows fallback for sessions where `hash_file` is not yet visible.

Codex then calls the OTSkit MCP `stamp_file` tool for the final ZIP and uses the second script to write `.sha256` from the OTSkit-returned hash, copy the `.ots` proof, and write the `.stamp-id.txt` sidecar.

The skill also documents read-only status checks for pending/confirmed stamps, upgrade attempts, and local SQLite diagnostics.

## Standards

| Standard | Role |
|---|---|
| BagIt (RFC 8493) | Package structure and fixity manifest |
| OAIS (ISO 14721) | Preservation metadata model |
| PREMIS 3.0 | Event and agent provenance |
| OpenTimestamps | Bitcoin blockchain anchoring |

See [preservation-standards.md](references/preservation-standards.md) for the rationale behind every design decision.
