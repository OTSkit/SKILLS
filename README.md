![preserve — a set of skills that stamp and anchor data to the Bitcoin blockchain](banner.png)

# OTSkit Skills

> Agent skills for digital preservation anchored on the Bitcoin blockchain via OpenTimestamps.

![BagIt RFC 8493](https://img.shields.io/badge/BagIt-RFC%208493-0066cc?style=flat-square)
![OAIS ISO 14721](https://img.shields.io/badge/OAIS-ISO%2014721-0066cc?style=flat-square)
![PREMIS 3.0](https://img.shields.io/badge/PREMIS-3.0-0066cc?style=flat-square)
![OpenTimestamps](https://img.shields.io/badge/anchored-Bitcoin-f7931a?style=flat-square&logo=bitcoin&logoColor=white)

---

## Skills

| Skill | Agent | Description |
|---|---|---|
| [preserve / claude](skills/preserve/claude/) | Claude Code | Creates BagIt-compliant preservation packages and anchors them to Bitcoin |
| [preserve / codex](skills/preserve/codex/) | Codex | Same workflow adapted for Codex, with PowerShell helper scripts |

## Requirements

- `@otskit/mcp` MCP server configured in your agent
- PowerShell (Windows) or bash (Linux/macOS)

## What these skills produce

Every preservation run delivers four portable, self-contained files:

| File | Purpose |
|---|---|
| `.zip` | BagIt package — payload + fixity manifests + PREMIS metadata |
| `.sha256` | SHA-256 of the ZIP (what was submitted to Bitcoin) |
| `.ots` | OpenTimestamps proof file (portable, verifiable offline) |
| `.stamp-id.txt` | OTSkit stamp UUID for MCP lookups |

## Standards

| Standard | Role |
|---|---|
| BagIt (RFC 8493) | Package structure and fixity manifest |
| OAIS (ISO 14721) | Preservation metadata model |
| PREMIS 3.0 | Event and agent provenance |
| OpenTimestamps | Bitcoin blockchain anchoring |

---

## Roadmap

- **OpenClaw skills** — coming soon
