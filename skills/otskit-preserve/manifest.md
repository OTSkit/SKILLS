# otskit-preserve — Manifiesto

## Qué es esto

Una skill para Claude Code que permite preservar documentos y carpetas de forma
permanente usando el ecosistema OTSkit. El resultado es un paquete de archivo
estándar (ZIP compatible con BagIt) cuya existencia queda anclada en la cadena
de bloques de Bitcoin mediante OpenTimestamps.

## Por qué existe

OTSkit MCP se diseñó deliberadamente ligero: solo estampa hashes. La lógica de
"empaquetar, estructurar y preservar" se dejó fuera de la librería para no añadir
dependencias innecesarias. Esta skill cubre ese hueco: orquesta todo el proceso
de preservación usando las herramientas del MCP como pieza final.

## Qué produce

Dado un fichero o carpeta, la skill genera cuatro ficheros en el directorio de salida:

| Fichero | Contenido |
|---|---|
| `preserved-<nombre>-<fecha>.zip` | Paquete de archivo (BagIt, con payload y metadatos) |
| `preserved-<nombre>-<fecha>.sha256` | SHA-256 del ZIP (lo que se selló en Bitcoin) |
| `preserved-<nombre>-<fecha>.ots` | Prueba OpenTimestamps portátil |
| `preserved-<nombre>-<fecha>.stamp-id.txt` | UUID del registro en OTSkit (para consultas MCP) |

## Qué garantiza (y qué no)

**Garantiza:** que el contenido del ZIP existía antes de un bloque Bitcoin concreto.
Si el ZIP verifica, todo lo que contiene (ficheros originales, checksums, metadatos
de proveniencia) existía en ese momento.

**No garantiza:** autoría, propiedad, ni tiene validez legal como timestamp
cualificado bajo eIDAS. Es una *prueba de existencia criptográfica*, no un acto notarial.

## Estándares en los que se basa

- **BagIt (RFC 8493)** — estructura interna del ZIP, usada por Library of Congress y Stanford
- **OAIS (ISO 14721)** — modelo conceptual de paquete de preservación (SIP)
- **PREMIS 3.0** — metadatos de preservación (subset mínimo en `preservation.json`)
- **OpenTimestamps** — anclaje en Bitcoin sin tercero de confianza

## Requisitos

- `@otskit/mcp` instalado y configurado en Claude Code
- PowerShell (Windows) o bash (Linux/macOS)

## Contexto de diseño

Ver `preservation-standards.md` para la justificación detallada de cada decisión:
por qué se hashea el ZIP completo y no el fichero original, la estructura BagIt,
el mapeo OAIS, los campos PREMIS mínimos, y el lenguaje legalmente defensible.
