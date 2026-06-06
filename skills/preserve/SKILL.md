---
name: preserve
description: Use when a user wants to preserve, archive, or timestamp a file or folder — triggered by requests like "preserve this", "stamp this folder", "archive this document", "create a preservation package", or anchor a file to Bitcoin. Produces a BagIt (RFC 8493) / OAIS (ISO 14721) / PREMIS 3.0 compliant package anchored on Bitcoin via OpenTimestamps.
---

# preserve

Create a BagIt-compatible preservation ZIP for a file or folder, then timestamp the sealed ZIP with OTSkit/OpenTimestamps.

Use careful language: this creates a Bitcoin/OpenTimestamps proof of existence. Do not call it notarization, legal certification, or a qualified eIDAS timestamp.

Read `preservation-standards.md` only when the user asks about BagIt, OAIS, PREMIS, evidentiary wording, legal standing, or the design rationale.

## User Communication

Keep the user informed throughout. Before starting, confirm what you are about to do:

> "I'll preserve `<source>` — creating a BagIt archive and anchoring its hash to Bitcoin. This takes a few steps."

Announce each major phase as you enter it:

- **Building the package** — assembling files, computing hashes, writing metadata
- **Sealing the ZIP** — compressing the staging directory
- **Stamping on Bitcoin** — submitting the hash to OpenTimestamps calendars
- **Writing sidecars** — saving the proof, hash, and stamp ID beside the ZIP
- **Done** — confirm the four files are in place

If anything fails or takes longer than expected, tell the user what is happening and why.

## Preferred Automation

On Windows, prefer OTSkit MCP hashing when available, then use the bundled scripts. Resolve script paths relative to this skill directory:

```text
scripts/prepare-preservation-package.ps1
scripts/complete-preservation-sidecars.ps1
```

If the MCP exposes `hash_file`, use it as the authoritative local SHA-256 helper for payload and tag manifests. `hash_file` is read-only — it does not stamp or send anything to calendars.

Run `prepare-preservation-package.ps1` only when `hash_file` is unavailable or a scripted fallback is needed. It creates the BagIt staging directory and ZIP, and returns JSON with `zip_path`, `output_dir`, and `base_name`. It does not create the final ZIP `.sha256` — that hash must come from OTSkit `stamp_file`.

```powershell
powershell.exe -ExecutionPolicy Bypass -File <skill-dir>\scripts\prepare-preservation-package.ps1 `
  -SourcePath "<source path>" `
  -Description "<description>" `
  -OutputDir "<optional output directory>"
```

After `stamp_file` returns `id`, `hash`, and `proof_path`, run `complete-preservation-sidecars.ps1`:

```powershell
powershell.exe -ExecutionPolicy Bypass -File <skill-dir>\scripts\complete-preservation-sidecars.ps1 `
  -OutputDir "<output_dir from prepare JSON>" `
  -BaseName "<base_name from prepare JSON>" `
  -StampId "<id from stamp_file>" `
  -StampHash "<hash from stamp_file>" `
  -ProofPath "<proof_path from stamp_file>"
```

If `hash_file` exists in the local OTSkit MCP source but is not visible as a tool, tell the user that the MCP server/session must be updated or restarted.

## Inputs

Get or infer:

- Source file or folder path.
- Optional description.
- Optional output directory.

Default output directory: `<source-parent>/preserved-<safe-name>-<YYYY-MM-DD>/`

Staging directory: `<source-parent>/_staging-<safe-name>-<YYYY-MM-DD>/`

## Final Outputs

All four files go inside the output directory — never loose in the source directory:

```text
preserved-<safe-name>-<YYYY-MM-DD>.zip
preserved-<safe-name>-<YYYY-MM-DD>.sha256
preserved-<safe-name>-<YYYY-MM-DD>.ots
preserved-<safe-name>-<YYYY-MM-DD>.stamp-id.txt
```

## Workflow

Use this manual workflow when bundled scripts are unavailable, fail, or the user needs a non-Windows implementation.

### Step 1 — Create directories

**PowerShell:**
```powershell
New-Item -ItemType Directory "_staging-<name>-<date>"
New-Item -ItemType Directory "preserved-<name>-<date>"
```

**bash:**
```bash
mkdir "_staging-<name>-<date>" "preserved-<name>-<date>"
```

Work inside `_staging-<name>-<date>/` for steps 2–8.

### Step 2 — Copy payload

Copy the source into `data/` preserving relative paths. Do not modify payload files.

### Step 3 — Write `bagit.txt`

```text
BagIt-Version: 1.0
Tag-File-Character-Encoding: UTF-8
```

### Step 4 — Write `manifest-sha256.txt`

Use `hash_file` once per payload file:

```
Tool: hash_file
Input: { "path": "<absolute path to file>" }
```

One line per file:
```text
<sha256>  data/path/to/file.ext
```

If `hash_file` is not available, fall back to platform hashing after telling the user why.

### Step 5 — Write `bag-info.txt`

```text
Bagging-Date: <YYYY-MM-DD>
Bag-Software-Agent: OTSkit MCP
External-Description: <description if provided>
Payload-Oxum: <total_bytes>.<file_count>
```

### Step 6 — Write `metadata/preservation.json`

Set `objectCategory` to `"file"` for a single file or `"representation"` for a folder.

```json
{
  "object": {
    "identifier": "<uuid>",
    "objectCategory": "file | representation",
    "originalPath": "<source path>"
  },
  "events": [
    { "eventType": "package creation", "eventDateTime": "<UTC ISO 8601>", "eventDetail": "BagIt package assembled" },
    { "eventType": "fixity calculation", "eventDateTime": "<UTC ISO 8601>", "eventDetail": "SHA-256 computed for all payload files" }
  ],
  "agent": { "agentName": "OTSkit MCP", "agentType": "software" }
}
```

Do not put the ZIP hash or stamp ID here — the ZIP must be closed before its hash exists.

### Step 7 — Write `metadata/oais-note.txt`

One plain-language paragraph: what was preserved, when, and that the sealed ZIP hash is timestamped on Bitcoin.

### Step 8 — Write `tagmanifest-sha256.txt`

Use `hash_file` for each tag file: `bagit.txt`, `bag-info.txt`, `manifest-sha256.txt`, and every file under `metadata/`. Local fixity only — do not stamp tag files.

### Step 9 — Create the ZIP

**PowerShell:**
```powershell
Compress-Archive -Path "_staging-<name>-<date>" -DestinationPath "preserved-<name>-<date>\preserved-<name>-<date>.zip"
```

**bash:**
```bash
zip -r "preserved-<name>-<date>/preserved-<name>-<date>.zip" "_staging-<name>-<date>/"
```

> Do NOT put `Remove-Item` in the same script as `Compress-Archive`. The sandbox inspects the full script before running it — a recursive delete anywhere in the script blocks the entire script. Delete the staging dir in a separate step after the ZIP is confirmed.

### Step 10 — Stamp the ZIP

```
Tool: stamp_file
Input: { "path": "<absolute path to preserved-<name>-<date>/preserved-<name>-<date>.zip>" }
```

Returns: `hash` (SHA-256), `id` (stamp UUID), `proof_path` (local `.ots` path).

If `stamp_file` is unavailable but `create_timestamp` is available, compute the ZIP SHA-256 first and call:

```
Tool: create_timestamp
Input: { "hash": "<64-char lowercase sha256>" }
```

If no proof path is returned, report the stamp ID and leave the `.ots` sidecar pending rather than inventing a file.

### Step 11 — Write sidecars

**PowerShell:**
```powershell
"<hash>" | Out-File -Encoding utf8 "preserved-<name>-<date>\preserved-<name>-<date>.sha256"
"<UUID>" | Out-File -Encoding utf8 "preserved-<name>-<date>\preserved-<name>-<date>.stamp-id.txt"
Copy-Item "<proof_path>" "preserved-<name>-<date>\preserved-<name>-<date>.ots"
```

**bash:**
```bash
echo "<hash>" > "preserved-<name>-<date>/preserved-<name>-<date>.sha256"
echo "<UUID>" > "preserved-<name>-<date>/preserved-<name>-<date>.stamp-id.txt"
cp "<proof_path>" "preserved-<name>-<date>/preserved-<name>-<date>.ots"
```

### Step 12 — Verify before reporting

**STOP.** Confirm all 4 files are inside the output folder:

```text
preserved-<name>-<date>/                       ← deliver this
  preserved-<name>-<date>.zip
  preserved-<name>-<date>.sha256
  preserved-<name>-<date>.ots
  preserved-<name>-<date>.stamp-id.txt

_staging-<name>-<date>/                        ← discard
```

If any file is loose outside the output folder, move it in before reporting.

## Status and Maintenance

When the user asks about pending/confirmed stamps, use `list_pending` with `status: "pending"` and `status: "confirmed"`, then report totals plainly.

To upgrade stamps, use `upgrade_timestamp` for pending stamp IDs. For several pending stamps, run upgrades in parallel, then re-check counts.

For local database diagnostics (read-only):

```text
C:\Users\<user>\.ots-mcp\db.sqlite
```

Useful tables: `stamps` (records, status, Bitcoin block/time, proof path), `operations_log` (history).

Do not edit the database directly unless the user explicitly requests a repair and understands the risk.

## Rules

- Stamp the ZIP, not the original source file.
- Keep `.ots`, `.sha256`, and `.stamp-id.txt` outside the ZIP.
- Do not alter files copied into `data/`.
- Do not place the ZIP hash or stamp ID inside `preservation.json`.
- Do not delete staging with a destructive recursive command unless the user explicitly approves it.
- Report Bitcoin confirmation as pending unless `verify_timestamp` confirms it.
- If the source path does not exist, check nearby paths only to resolve likely typos, and tell the user which path was actually used.
- Use `hash_file` for payload and tag manifests. Do not call `stamp_file` on individual payload files just to get hashes.
- Use the `stamp_file` return value as the authoritative SHA-256 for the sealed ZIP.
- Keep final answers human-readable; avoid dumping raw JSON unless the user asks.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Output files loose in the source directory | All 4 files go inside `preserved-<name>-<date>/` — verify in Step 12 before reporting |
| Staging dir and output folder have the same name | Staging = `_staging-<name>-<date>/`; output = `preserved-<name>-<date>/` |
| Hashing the original file, not the ZIP | Call `stamp_file` on the ZIP — it binds payload + metadata together |
| Calling `stamp_file` on payload files to get their hashes | Use `hash_file` for payload/tag hashing; `stamp_file` is only for the final ZIP |
| Putting `.ots` inside the ZIP | Copy it from `proof_path` beside the ZIP after stamping; ZIP must be closed first |
| Saying "notarized" or "legally certified" | Say "proof of existence" — see preservation-standards.md |
| Modifying files under `data/` | Copy originals verbatim; never alter payload |
| Forgetting `tagmanifest-sha256.txt` | Required for full BagIt compliance |
| `Remove-Item` in the same script as `Compress-Archive` | Sandbox blocks the entire script; delete staging in a separate step |

## Final Response

```text
Preservation package created:
  ZIP:        preserved-<name>-<date>.zip
  SHA-256:    <hex>
  Stamp ID:   <UUID>
  OTS proof:  preserved-<name>-<date>.ots
  Status:     pending Bitcoin confirmation (~1–2 hours)
```

Then explain what each file is for, in plain language:

- **`.zip`** — the preservation package itself: contains all your original files plus the fixity manifests and provenance metadata. This is the object that was stamped.
- **`.sha256`** — the fingerprint of the ZIP (SHA-256 hash). This is the exact value submitted to Bitcoin. Anyone can verify the ZIP hasn't been altered by recomputing this hash.
- **`.ots`** — the OpenTimestamps proof file. Portable and self-contained: it can be verified offline against the Bitcoin blockchain at any point in the future, without relying on OTSkit or any third party.
- **`.stamp-id.txt`** — the OTSkit internal reference. Use it to check confirmation status, upgrade the proof once Bitcoin confirms, or look up the record later.

Close with:

> "Keep all four files together. The `.ots` proof only makes sense alongside the `.zip` it refers to."

Also say that confirmation can be checked later with `upgrade_timestamp` or `verify_timestamp` using the stamp ID.
