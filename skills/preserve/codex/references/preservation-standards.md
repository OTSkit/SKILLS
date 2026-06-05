# Preservation Standards Reference

Use this reference only when the user asks why the package is built this way, asks about archival standards, or needs careful evidentiary language.

## Why stamp the final ZIP

OpenTimestamps stamps a SHA-256 digest. Build the complete preservation package first, close the ZIP, then stamp the ZIP hash.

This binds the payload, checksums, provenance metadata, and tool metadata into one sealed object. Stamping only the original file would leave the preservation metadata outside the proof.

The `.ots` proof belongs beside the ZIP, not inside it, because the ZIP must already be closed before the proof can be created.

## BagIt

The ZIP should contain a BagIt-style tree:

```text
bagit.txt
bag-info.txt
manifest-sha256.txt
tagmanifest-sha256.txt
data/
metadata/
```

`data/` contains the original payload files, unchanged.

`manifest-sha256.txt` contains one SHA-256 line per payload file:

```text
<sha256hex>  data/path/to/file.ext
```

`tagmanifest-sha256.txt` hashes BagIt tag files and metadata files.

## OAIS

Treat the ZIP as a Submission Information Package:

```text
Content Information: data/
Fixity: manifest-sha256.txt and external ZIP SHA-256
Provenance: bag-info.txt and metadata/preservation.json
Context: metadata/oais-note.txt
Reference: ZIP SHA-256 and OTSkit stamp ID
```

## PREMIS-lite

Use `metadata/preservation.json` for a small subset of PREMIS concepts:

- Object: identifier, objectCategory, originalPath.
- Events: package creation and fixity calculation.
- Agent: OTSkit MCP as software.

Do not put ZIP size, ZIP hash, or stamp ID in `preservation.json`. Those values are known only after the ZIP is sealed, so they must be external sidecars.

## Legal Wording

Use:

- "Bitcoin/OpenTimestamps proof of existence"
- "cryptographic proof that this hash existed before a Bitcoin block"
- "OpenTimestamps attestation"

Do not use:

- "notarized"
- "legally certified"
- "equivalent to a notarial act"
- "qualified electronic timestamp"
