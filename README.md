![preserve — stamp and anchor data to the Bitcoin blockchain](banner.png)

# OTSkit Skills

> Immutable. Verifiable. Forever. — Agent skills for digital preservation anchored on the Bitcoin blockchain via OpenTimestamps.

![BagIt RFC 8493](https://img.shields.io/badge/BagIt-RFC%208493-0066cc?style=flat-square)
![OAIS ISO 14721](https://img.shields.io/badge/OAIS-ISO%2014721-0066cc?style=flat-square)
![PREMIS 3.0](https://img.shields.io/badge/PREMIS-3.0-0066cc?style=flat-square)
![OpenTimestamps](https://img.shields.io/badge/anchored-Bitcoin-f7931a?style=flat-square&logo=bitcoin&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-supported-8A2BE2?style=flat-square)
![Codex](https://img.shields.io/badge/Codex-supported-10a37f?style=flat-square)

---

## What is this?

OTSkit Skills lets your AI agent **preserve any file or folder** as a standards-compliant archive and **anchor its hash to the Bitcoin blockchain** — creating a tamper-evident, cryptographically verifiable proof of existence that requires no trusted third party.

Say *"preserve this"* or *"stamp this folder"* and the agent handles the rest.

---

## Skills

| Skill | Agents | Description |
|---|---|---|
| [preserve](preserve/) | Claude Code · Codex | BagIt preservation packages anchored to Bitcoin via OpenTimestamps |

---

## What it produces

Every preservation run delivers four portable, self-contained files:

| File | Purpose |
|---|---|
| `.zip` | BagIt package — payload + fixity manifests + PREMIS metadata |
| `.sha256` | SHA-256 of the ZIP (what was submitted to Bitcoin) |
| `.ots` | OpenTimestamps proof file — portable, verifiable offline forever |
| `.stamp-id.txt` | OTSkit stamp UUID for MCP lookups and upgrades |

---

## How to install

**Via Smithery:**

```shell
npx -y skills add https://smithery.ai/skills/otskit/preserve
```

**Via Claude Code plugin marketplace:**

```shell
/plugin marketplace add OTSkit/SKILLS
/plugin install preserve@otskit-skills
```

Then trigger the skill with natural language:

> *"preserve this"* · *"stamp this folder"* · *"archive this document"* · *"create a preservation package"*

---

## Requirements

- `@otskit/mcp` MCP server configured in your agent
- PowerShell (Windows) or bash (Linux/macOS)

---

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
