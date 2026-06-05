---
name: otskit-preserve
description: Use when a user wants to preserve, archive, or timestamp a file or folder using OTSkit — triggered by requests like "preserve this", "stamp this folder", "archive this document", or "create a preservation package". Produces a BagIt (RFC 8493) / OAIS (ISO 14721) / PREMIS 3.0 compliant package anchored on Bitcoin via OpenTimestamps.
---

# otskit-preserve

Creates a BagIt-compatible preservation package (ZIP) from a file or folder,
then stamps its SHA-256 hash on the Bitcoin blockchain via OTSkit MCP.

**REFERENCE:** See preservation-standards.md for rationale behind every design
decision (BagIt, OAIS mapping, PREMIS fields, legal language).

## Requirements

Dependencies must be installed in this order:

1. `@otskit/core` — base OpenTimestamps library
2. `@otskit/client` — requires core
3. `@otskit/mcp` — requires core + client; must be configured in Claude Code as an MCP tool

- PowerShell (Windows) or bash (Linux/macOS)
- A file or folder path from the user

## Workflow

### Step 1 — Gather input

Ask the user for:
1. Path to the file or folder to preserve
2. (Optional) A short description of what this is and why it is being preserved
3. (Optional) Output directory (default: `preserved-<name>-<YYYY-MM-DD>/` folder created next to the source)

All four output files go inside that folder — never loose in the source directory.

### Step 2 — Build the BagIt package directory

> **Two folders, two purposes — never confuse them:**
> - `_staging-<name>-<YYYY-MM-DD>/` — temporary BagIt tree, gets zipped and discarded
> - `preserved-<name>-<YYYY-MM-DD>/` — final output folder; all 4 deliverables go here

Create both folders now:

**PowerShell:**
```powershell
New-Item -ItemType Directory "_staging-<name>-<date>"
New-Item -ItemType Directory "preserved-<name>-<date>"
```

**bash:**
```bash
mkdir "_staging-<name>-<date>" "preserved-<name>-<date>"
```

Work inside `_staging-<name>-<date>/` for the rest of this step.

**Copy payload** into `data/` preserving relative paths.

**Compute per-file SHA-256** for every file under `data/` using the MCP tool:

```
Tool: hash_file
Input: { "path": "<absolute path to file>" }
```

Call it once per file. Use the returned hex string in `manifest-sha256.txt`.

**Create `bagit.txt`:**
```
BagIt-Version: 1.0
Tag-File-Character-Encoding: UTF-8
```

**Create `manifest-sha256.txt`** — one line per payload file:
```
<sha256>  data/path/to/file.ext
```

**Create `bag-info.txt`:**
```
Bagging-Date: <YYYY-MM-DD>
Bag-Software-Agent: @otskit/mcp <version>
Source-Organization: <user or org name if provided>
External-Description: <user description if provided>
Payload-Oxum: <total_bytes>.<file_count>
```

**Create `metadata/preservation.json`** (PREMIS-lite):

Set `objectCategory` based on input type:
- Single file → `"file"`
- Folder (multiple files) → `"representation"`

```json
{
  "object": {
    "identifier": "<UUID>",
    "objectCategory": "file" | "representation",
    "originalPath": "<source path>"
  },
  "events": [
    { "eventType": "package creation", "eventDateTime": "<UTC ISO 8601>", "eventDetail": "BagIt package assembled" },
    { "eventType": "fixity calculation", "eventDateTime": "<UTC ISO 8601>", "eventDetail": "SHA-256 computed for all payload files" }
  ],
  "agent": { "agentName": "@otskit/mcp", "agentVersion": "<version>", "agentType": "software" }
}
```

> The ZIP-level SHA-256 goes in `<name>.sha256` alongside the ZIP (computed after
> sealing), not inside this JSON — the ZIP must be closed before its hash is known.

**Create `metadata/oais-note.txt`** — one paragraph, plain English, describing what
this package is, who created it, and why.

**Compute `tagmanifest-sha256.txt`** — SHA-256 of `bagit.txt`, `bag-info.txt`,
`manifest-sha256.txt`, and every file under `metadata/` using `hash_file` for each.

### Step 3 — Create the ZIP

Compress the staging directory. The ZIP goes **directly into the output folder**:

**PowerShell:**
```powershell
Compress-Archive -Path "_staging-<name>-<date>" -DestinationPath "preserved-<name>-<date>\preserved-<name>-<date>.zip"
```

**bash:**
```bash
zip -r "preserved-<name>-<date>/preserved-<name>-<date>.zip" "_staging-<name>-<date>/"
```

> **Do NOT delete the staging dir inside the same script.** Claude Code's sandbox
> inspects the full script before running it; a `Remove-Item -Recurse -Force` call
> anywhere in the script will cause the entire script to be blocked before a single
> line executes. Leave the temp dir for the OS to clean up, or delete it in a
> separate, explicit step after the ZIP is confirmed.

### Step 4 — Stamp via OTSkit MCP (computes hash + stamps in one call)

The ZIP is now closed. Call `stamp_file` with the ZIP path — it computes the
SHA-256 internally and submits it to Bitcoin calendars in one operation:

```
Tool: stamp_file
Input: { "path": "<absolute path to preserved-<name>-<date>/preserved-<name>-<date>.zip>" }
```

The response includes:
- `hash` — SHA-256 of the ZIP (64-char lowercase hex)
- `id` — UUID of the stamp record (permanent reference)
- `proof_path` — local path to the `.ots` file (e.g. `~/.ots-mcp/proofs/<UUID>.ots`)

**Write all sidecars into the output folder:**

**PowerShell:**
```powershell
"<hash>"  | Out-File -Encoding utf8 "preserved-<name>-<date>\preserved-<name>-<date>.sha256"
"<UUID>"  | Out-File -Encoding utf8 "preserved-<name>-<date>\preserved-<name>-<date>.stamp-id.txt"
Copy-Item "<proof_path>" "preserved-<name>-<date>\preserved-<name>-<date>.ots"
```

**bash:**
```bash
echo "<hash>" > "preserved-<name>-<date>/preserved-<name>-<date>.sha256"
echo "<UUID>" > "preserved-<name>-<date>/preserved-<name>-<date>.stamp-id.txt"
cp "<proof_path>" "preserved-<name>-<date>/preserved-<name>-<date>.ots"
```

### Step 5 — Verify output structure before reporting

**STOP.** Before reporting to the user, confirm all 4 files are inside the output folder:

```
preserved-<name>-<date>/                       ← output folder (deliver this)
  preserved-<name>-<date>.zip                  ← BagIt preservation package
  preserved-<name>-<date>.sha256               ← SHA-256 of the ZIP (what was stamped)
  preserved-<name>-<date>.ots                  ← OpenTimestamps proof (portable)
  preserved-<name>-<date>.stamp-id.txt         ← OTSkit stamp UUID (for MCP lookups)

_staging-<name>-<date>/                        ← discard (already zipped)
```

If any file is loose outside the output folder, move it in before continuing.

### Step 6 — Report to user

Present this summary:

```
Preservation package created:
  ZIP:        preserved-<name>-<date>.zip
  SHA-256:    <hex>
  Stamp ID:   <UUID>
  OTS proof:  preserved-<name>-<date>.ots
  Status:     pending Bitcoin confirmation (~1–2 hours)

To check confirmation later:
  Tool: upgrade_timestamp  →  { "id": "<UUID>" }
  Tool: verify_timestamp   →  { "id": "<UUID>" }
```

Use defensible language: this is a **Bitcoin/OpenTimestamps proof of existence**,
not a notarial act or qualified eIDAS timestamp.

## Common mistakes

| Mistake | Fix |
|---|---|
| Output files left loose in source directory | All 4 files go inside `preserved-<name>-<date>/` — check Step 5 before reporting |
| Staging dir and output folder have the same name | Staging = `_staging-<name>-<date>/` (temporary); output = `preserved-<name>-<date>/` (final) |
| Hashing the original file, not the ZIP | Always call `stamp_file` on the ZIP — it binds payload + metadata together |
| Putting `.ots` inside the ZIP | Copy it from `proof_path` alongside the ZIP after stamping; the ZIP must be closed first |
| Saying "notarized" or "legally certified" | Say "proof of existence" — see preservation-standards.md |
| Modifying files under `data/` | Copy originals verbatim; never alter payload |
| Forgetting `tagmanifest-sha256.txt` | It covers the tag files; required for full BagIt compliance |
| Putting `Remove-Item` in the same script as `Compress-Archive` | Sandbox blocks the entire script before execution; delete the staging dir in a separate step or leave it for OS cleanup |
