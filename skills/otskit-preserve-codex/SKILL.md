---
name: otskit-preserve-codex
description: Preserve, archive, package, hash, or timestamp a file or folder with OTSkit in Codex. Use when the user asks to preserve evidence, archive a document, stamp a folder, create a BagIt/OAIS/PREMIS preservation package, generate an OpenTimestamps proof, or anchor a file/folder package to Bitcoin.
---

# otskit-preserve-codex

Create a BagIt-compatible preservation ZIP for a file or folder, then timestamp the sealed ZIP with OTSkit/OpenTimestamps.

Use careful language: this creates a Bitcoin/OpenTimestamps proof of existence. Do not call it notarization, legal certification, or a qualified eIDAS timestamp.

Read `references/preservation-standards.md` only when the user asks about BagIt, OAIS, PREMIS, evidentiary wording, legal standing, or the design rationale.

## Preferred Automation

On Windows, prefer OTSkit MCP/library hashing when available, then use the bundled scripts for local packaging. Resolve script paths relative to this skill directory:

```text
scripts/prepare-preservation-package.ps1
scripts/complete-preservation-sidecars.ps1
```

If the MCP exposes `hash_file`, use it as the authoritative local SHA-256 helper for payload manifests and tag manifests. `hash_file` is read-only and does not stamp or send anything to calendars.

Run `prepare-preservation-package.ps1` first only when `hash_file` is not available to the active Codex session, or when a scripted fallback is needed. It creates the BagIt staging directory and ZIP, then returns JSON with `zip_path`, `output_dir`, and `base_name`. It does not create the final ZIP `.sha256`; that hash must come from OTSkit `stamp_file`.

```powershell
powershell.exe -ExecutionPolicy Bypass -File <skill-dir>\scripts\prepare-preservation-package.ps1 `
  -SourcePath "<source path>" `
  -Description "<description>" `
  -OutputDir "<optional output directory>"
```

Then call the OTSkit MCP `stamp_file` tool on the returned `zip_path`. After the MCP returns `id`, `hash`, and `proof_path`, run `complete-preservation-sidecars.ps1` to write `<base_name>.sha256` from the OTSkit-returned hash, write `<base_name>.stamp-id.txt`, copy `<base_name>.ots` beside the ZIP, and verify expected sidecars.

```powershell
powershell.exe -ExecutionPolicy Bypass -File <skill-dir>\scripts\complete-preservation-sidecars.ps1 `
  -OutputDir "<output_dir from prepare JSON>" `
  -BaseName "<base_name from prepare JSON>" `
  -StampId "<id from stamp_file>" `
  -StampHash "<hash from stamp_file>" `
  -ProofPath "<proof_path from stamp_file>"
```

If the user asks to save results "in the same directory", use the source parent as `OutputDir` only when they mean loose files beside the source. Otherwise prefer the default package folder `<source-parent>/preserved-<safe-name>-<YYYY-MM-DD>/`.

If a command writes outside the workspace, request permission normally. Do not work around sandbox approval.

If `hash_file` exists in the local OTSkit MCP source but is not visible as a Codex tool, tell the user that the MCP server/Codex session must be updated or restarted before the skill can call it directly.

## Inputs

Get or infer:

- Source file or folder path.
- Optional description.
- Optional output directory.

Default output directory:

```text
<source-parent>/preserved-<safe-name>-<YYYY-MM-DD>/
```

Use a separate staging directory:

```text
<source-parent>/_staging-<safe-name>-<YYYY-MM-DD>/
```

## Final Outputs

Put exactly these final companion files in the output directory:

```text
preserved-<safe-name>-<YYYY-MM-DD>.zip
preserved-<safe-name>-<YYYY-MM-DD>.sha256
preserved-<safe-name>-<YYYY-MM-DD>.ots
preserved-<safe-name>-<YYYY-MM-DD>.stamp-id.txt
```

Keep `.sha256`, `.ots`, and `.stamp-id.txt` outside the ZIP.

## Workflow

Follow this manual workflow when bundled scripts are unavailable, fail for a platform-specific reason, or the user needs a non-Windows implementation.

1. Create the staging BagIt directory.

```text
bagit.txt
bag-info.txt
manifest-sha256.txt
tagmanifest-sha256.txt
data/
metadata/preservation.json
metadata/oais-note.txt
```

2. Copy the source payload into `data/`.

Preserve original bytes and relative paths. Do not modify payload files.

3. Write `bagit.txt`.

```text
BagIt-Version: 1.0
Tag-File-Character-Encoding: UTF-8
```

4. Write `manifest-sha256.txt`.

Prefer OTSkit `hash_file` for each payload file. If the tool is not available in the active session, fall back to the bundled script or platform hashing only after telling the user why.

One line per payload file:

```text
<sha256>  data/path/to/file.ext
```

5. Write `bag-info.txt`.

Include:

```text
Bagging-Date: <YYYY-MM-DD>
Bag-Software-Agent: OTSkit MCP
External-Description: <description if provided>
Payload-Oxum: <total_bytes>.<file_count>
```

6. Write `metadata/preservation.json`.

Use this PREMIS-lite structure:

```json
{
  "object": {
    "identifier": "<uuid>",
    "objectCategory": "file or representation",
    "originalPath": "<source path>"
  },
  "events": [
    {
      "eventType": "package creation",
      "eventDateTime": "<UTC ISO 8601>",
      "eventDetail": "BagIt package assembled"
    },
    {
      "eventType": "fixity calculation",
      "eventDateTime": "<UTC ISO 8601>",
      "eventDetail": "SHA-256 computed for all payload files"
    }
  ],
  "agent": {
    "agentName": "OTSkit MCP",
    "agentType": "software"
  }
}
```

Use `objectCategory: "file"` for a single input file and `"representation"` for a folder.

Do not put the ZIP hash or stamp ID in `preservation.json`; the ZIP must be closed before its hash exists.

7. Write `metadata/oais-note.txt`.

Use one plain-language paragraph describing what was preserved, when the package was created, and that the sealed ZIP hash is timestamped externally.

8. Write `tagmanifest-sha256.txt`.

Hash:

- `bagit.txt`
- `bag-info.txt`
- `manifest-sha256.txt`
- every file under `metadata/`

Prefer OTSkit `hash_file` here too. These hashes are local fixity metadata only; do not stamp each payload or tag file.

9. Compress the staging directory into the final ZIP inside the output directory.

Do not reopen or modify the ZIP after hashing or stamping it.

10. Timestamp the sealed ZIP.

Prefer the current OTSkit MCP tool:

```json
{
  "tool": "stamp_file",
  "input": {
    "path": "<absolute path to final zip>"
  }
}
```

Expected response fields:

- `hash`: SHA-256 of the ZIP.
- `id`: stamp UUID.
- `proof_path`: local `.ots` proof path.

If `stamp_file` is unavailable but `create_timestamp` is available, compute the ZIP SHA-256 first and call:

```json
{
  "tool": "create_timestamp",
  "input": {
    "hash": "<64-char lowercase sha256>"
  }
}
```

Then use the returned `id` and proof path if provided. If no proof path is returned, report the stamp ID and leave the `.ots` sidecar pending/unavailable rather than inventing a file.

11. Write sidecars into the output directory.

```text
<hash from stamp_file> -> preserved-<safe-name>-<YYYY-MM-DD>.sha256
<id>   -> preserved-<safe-name>-<YYYY-MM-DD>.stamp-id.txt
copy proof_path -> preserved-<safe-name>-<YYYY-MM-DD>.ots
```

12. Verify the final output structure before reporting.

```text
preserved-<safe-name>-<YYYY-MM-DD>/
  preserved-<safe-name>-<YYYY-MM-DD>.zip
  preserved-<safe-name>-<YYYY-MM-DD>.sha256
  preserved-<safe-name>-<YYYY-MM-DD>.ots
  preserved-<safe-name>-<YYYY-MM-DD>.stamp-id.txt
```

If any sidecar is outside the output directory, move it into the output directory before responding.

## Status And Maintenance

When the user asks how many stamps are pending or confirmed, use OTSkit MCP `list_pending` with `status: "pending"` and `status: "confirmed"`, then report the totals plainly.

When the user asks to upgrade stamps, use `upgrade_timestamp` for pending stamp IDs. For several pending stamps, run upgrades in parallel when possible, then re-check pending and confirmed counts.

When looking at the local OTSkit database, treat this as read-only diagnostics. The usual database path is:

```text
C:\Users\<user>\.ots-mcp\db.sqlite
```

Useful tables are usually:

- `stamps`: stamp records, status, Bitcoin block/time, proof path, retry info.
- `operations_log`: stamp and upgrade history.
- `sqlite_sequence`: SQLite internal bookkeeping.

Do not edit the database directly unless the user explicitly asks for a repair and understands the risk.

## Rules

- Stamp the ZIP, not the original source file.
- Keep `.ots`, `.sha256`, and `.stamp-id.txt` outside the ZIP.
- Do not alter files copied into `data/`.
- Do not place the ZIP hash or stamp ID inside `preservation.json`.
- Do not delete staging with a destructive recursive command unless the user explicitly approves it.
- Report Bitcoin confirmation as pending unless `verify_timestamp` confirms it.
- If the source path does not exist, check nearby paths only to resolve likely typos, and tell the user which path was actually used.
- For BagIt payload and tag manifests, prefer OTSkit `hash_file` when exposed by MCP. Do not call `stamp_file` for individual payload files just to get hashes.
- Use the `stamp_file` return value as the authoritative SHA-256 for the sealed ZIP. Do not publish a separately computed ZIP hash as the preservation hash.
- Keep final answers human-readable; avoid dumping raw JSON unless the user asks for it.

## Final Response

Tell the user:

```text
Preservation package created:
ZIP:      <path>
SHA-256:  <hash>
OTS:      <path>
Stamp ID: <uuid>
Status:   pending Bitcoin confirmation
```

Also say that confirmation can be checked later with `upgrade_timestamp` or `verify_timestamp` using the stamp ID.
