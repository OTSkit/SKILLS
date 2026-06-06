param(
  [Parameter(Mandatory=$true)][string]$SourcePath,
  [string]$Description = "",
  [string]$OutputDir = "",
  [string]$Date = ""
)

$ErrorActionPreference = "Stop"

function Convert-To-SafeName([string]$Name) {
  $safe = $Name -replace '[^A-Za-z0-9._-]+', '-'
  $safe = $safe.Trim('-')
  if ([string]::IsNullOrWhiteSpace($safe)) { return "package" }
  return $safe
}

function Get-RelativePathCompat([string]$BasePath, [string]$TargetPath) {
  $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).ProviderPath.TrimEnd('\') + '\')
  $targetUri = [Uri]((Resolve-Path -LiteralPath $TargetPath).ProviderPath)
  return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()).Replace('/', '\')
}

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$source = Get-Item -LiteralPath $SourcePath
if ([string]::IsNullOrWhiteSpace($Date)) {
  $Date = Get-Date -Format "yyyy-MM-dd"
}

$safeName = Convert-To-SafeName $source.Name
$parent = if ($source.PSIsContainer) { $source.Parent.FullName } else { $source.Directory.FullName }
$baseName = "preserved-$safeName-$Date"

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = Join-Path $parent $baseName
}

$stagingDir = Join-Path $parent "_staging-$safeName-$Date"
$dataDir = Join-Path $stagingDir "data"
$metadataDir = Join-Path $stagingDir "metadata"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null
New-Item -ItemType Directory -Force -Path $metadataDir | Out-Null

if ($source.PSIsContainer) {
  Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $dataDir $source.Name) -Recurse -Force
  $objectCategory = "representation"
} else {
  Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $dataDir $source.Name) -Force
  $objectCategory = "file"
}

Write-Utf8NoBom (Join-Path $stagingDir "bagit.txt") "BagIt-Version: 1.0`nTag-File-Character-Encoding: UTF-8`n"

$payloadFiles = Get-ChildItem -LiteralPath $dataDir -Recurse -File | Sort-Object FullName
$manifestLines = New-Object System.Collections.Generic.List[string]
$totalBytes = 0L

foreach ($file in $payloadFiles) {
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()
  $relative = (Get-RelativePathCompat $stagingDir $file.FullName).Replace('\','/')
  $manifestLines.Add("$hash  $relative")
  $totalBytes += $file.Length
}

Write-Utf8NoBom (Join-Path $stagingDir "manifest-sha256.txt") (($manifestLines -join "`n") + "`n")

$bagInfoLines = @(
  "Bagging-Date: $Date",
  "Bag-Software-Agent: OTSkit MCP",
  "Payload-Oxum: $totalBytes.$($payloadFiles.Count)"
)

if (-not [string]::IsNullOrWhiteSpace($Description)) {
  $bagInfoLines = @(
    "Bagging-Date: $Date",
    "Bag-Software-Agent: OTSkit MCP",
    "External-Description: $Description",
    "Payload-Oxum: $totalBytes.$($payloadFiles.Count)"
  )
}

Write-Utf8NoBom (Join-Path $stagingDir "bag-info.txt") (($bagInfoLines -join "`n") + "`n")

$nowUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$preservation = [ordered]@{
  object = [ordered]@{
    identifier = [guid]::NewGuid().ToString()
    objectCategory = $objectCategory
    originalPath = $source.FullName
  }
  events = @(
    [ordered]@{
      eventType = "package creation"
      eventDateTime = $nowUtc
      eventDetail = "BagIt package assembled"
    },
    [ordered]@{
      eventType = "fixity calculation"
      eventDateTime = $nowUtc
      eventDetail = "SHA-256 computed for all payload files"
    }
  )
  agent = [ordered]@{
    agentName = "OTSkit MCP"
    agentType = "software"
  }
}

Write-Utf8NoBom (Join-Path $metadataDir "preservation.json") (($preservation | ConvertTo-Json -Depth 10) + "`n")

$note = "Preservation package created for '$($source.FullName)' on $Date. The original payload was copied into a BagIt-compatible package, fixity information was calculated with SHA-256, and the sealed ZIP hash is timestamped externally with OpenTimestamps."
Write-Utf8NoBom (Join-Path $metadataDir "oais-note.txt") ($note + "`n")

$tagFiles = @(
  Join-Path $stagingDir "bagit.txt"
  Join-Path $stagingDir "bag-info.txt"
  Join-Path $stagingDir "manifest-sha256.txt"
)
$tagFiles += Get-ChildItem -LiteralPath $metadataDir -Recurse -File | Sort-Object FullName | ForEach-Object { $_.FullName }
$tagLines = New-Object System.Collections.Generic.List[string]

foreach ($filePath in $tagFiles) {
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $filePath).Hash.ToLowerInvariant()
  $relative = (Get-RelativePathCompat $stagingDir $filePath).Replace('\','/')
  $tagLines.Add("$hash  $relative")
}

Write-Utf8NoBom (Join-Path $stagingDir "tagmanifest-sha256.txt") (($tagLines -join "`n") + "`n")

$zipPath = Join-Path $OutputDir "$baseName.zip"
if (Test-Path -LiteralPath $zipPath) {
  $zipPath = Join-Path $OutputDir "$baseName-$((Get-Date).ToString('HHmmss')).zip"
}

$stagingItems = Get-ChildItem -LiteralPath $stagingDir | ForEach-Object { $_.FullName }
Compress-Archive -LiteralPath $stagingItems -DestinationPath $zipPath -Force

$sidecarBase = [System.IO.Path]::GetFileNameWithoutExtension($zipPath)

[pscustomobject]@{
  source_path = $source.FullName
  output_dir = (Resolve-Path -LiteralPath $OutputDir).ProviderPath
  staging_dir = (Resolve-Path -LiteralPath $stagingDir).ProviderPath
  base_name = $sidecarBase
  zip_path = (Resolve-Path -LiteralPath $zipPath).ProviderPath
  payload_file_count = $payloadFiles.Count
  payload_bytes = $totalBytes
  object_category = $objectCategory
} | ConvertTo-Json
