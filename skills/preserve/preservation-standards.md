# Preservation Standards Reference — otskit-preserve

Context and rationale behind the design decisions in this skill.
Research sources: OAIS/ISO 14721, BagIt/RFC 8493, RFC 3161, OpenTimestamps protocol,
PREMIS 3.0 (Library of Congress), eIDAS regulation (EU).

---

## Why hash the final ZIP, not the original file

OpenTimestamps stamps an opaque SHA-256 digest — it does not care about content.
The design decision is to build the complete preservation package first (payload +
manifests + metadata), close the ZIP, and then hash it.

This binds all evidence elements into a single object: if the ZIP hash verifies,
it proves that payload, checksums, provenance metadata, and the tool version
all existed together at stamp time. Hashing only the original file leaves the
metadata unprotected.

The `.ots` proof file must be stored **next to** the ZIP, never inside it — the ZIP
must be closed and its hash fixed before the OTS proof can be created.

---

## BagIt (RFC 8493) — internal ZIP structure

BagIt is the packaging standard used by the Library of Congress, Stanford, Cornell,
and the NSF DataONE network. Using it gives our ZIPs immediate recognizability in
archival and institutional contexts.

Minimum required files:

| File | Purpose |
|------|---------|
| `bagit.txt` | Declares BagIt version and encoding |
| `manifest-sha256.txt` | SHA-256 of every file under `data/` |
| `tagmanifest-sha256.txt` | SHA-256 of the tag files themselves |
| `bag-info.txt` | Human-readable metadata (optional but recommended) |
| `data/` | The preserved payload (user's files, unchanged) |

`bagit.txt` must contain exactly:
```
BagIt-Version: 1.0
Tag-File-Character-Encoding: UTF-8
```

`manifest-sha256.txt` format (one line per file):
```
<sha256hex>  data/path/to/file.ext
```

---

## OAIS (ISO 14721) — conceptual mapping

OAIS defines a Submission Information Package (SIP) as content + metadata packaged
for ingest into a preservation repository. Our ZIP maps to a SIP:

| OAIS concept | Our implementation |
|---|---|
| Content Information | `data/` (payload + format info) |
| Fixity | `manifest-sha256.txt` + ZIP-level SHA-256 |
| Provenance | `bag-info.txt` + `preservation.json` (tool, version, creator) |
| Context | `oais-note.txt` (purpose, description) |
| Reference | Stable SHA-256 hash, OTS stamp ID |

---

## PREMIS minimum fields

PREMIS (Preservation Metadata Implementation Strategies) defines five entities.
We implement a lightweight subset ("premis-lite") in `preservation.json`:

**Object** (the ZIP itself):
- identifier (UUID or hash)
- objectCategory: `file` (single file input) or `representation` (folder input)
- originalName

> `size` and `fixity` of the ZIP **cannot go inside `preservation.json`** because the ZIP
> must be sealed before its hash is known — and once sealed, files inside cannot be updated.
> The ZIP SHA-256 is written to the external `<name>.sha256` sidecar file instead. This is
> intentional, not an omission.

**Event** (one record per action):
- eventType: `package creation` | `fixity calculation` | `timestamp request` | `timestamp confirmation` | `verification`
- eventDateTime (UTC ISO 8601)
- eventDetail (free text)

**Agent** (the tool that acted):
- agentName: `@otskit/mcp`
- agentVersion: (semver)
- agentType: `software`

---

## RFC 3161 vs OpenTimestamps — legal standing

| | RFC 3161 | OpenTimestamps |
|--|--|--|
| Trust model | Trusted third-party TSA | Bitcoin blockchain (no trusted party) |
| Legal recognition | Recognized under eIDAS (EU) | Not yet formally recognized under eIDAS |
| Cost | Paid service | Free |
| Precision | Milliseconds | ~Bitcoin block time (~10 min) |
| Vendor dependency | Yes (TSA must remain operational) | No |

OTSkit uses OpenTimestamps. This is a deliberate trade-off: decentralized,
free, and cryptographically robust — but not a qualified timestamp under eIDAS.

### Defensible language — use these exact terms

**Use:**
- "Bitcoin/OpenTimestamps proof of existence"
- "cryptographic proof that this hash existed before block N"
- "OpenTimestamps attestation"

**Never use:**
- "notarized"
- "legally certified"
- "equivalent to a notarial act"
- "qualified electronic timestamp"

---

## Full ZIP layout

```
preserved-<name>-<date>.zip
└── preserved-<name>-<date>/
    ├── bagit.txt
    ├── bag-info.txt
    ├── manifest-sha256.txt
    ├── tagmanifest-sha256.txt
    ├── metadata/
    │   ├── preservation.json      ← provenance, package events, tool/version
    │   └── oais-note.txt          ← human-readable SIP description
    └── data/
        └── <user files, paths preserved>

Alongside the ZIP (not inside):
  preserved-<name>-<date>.sha256       ← ZIP-level SHA-256 (computed after sealing)
  preserved-<name>-<date>.ots          ← OpenTimestamps proof
  preserved-<name>-<date>.stamp-id.txt ← OTSkit stamp UUID
```
