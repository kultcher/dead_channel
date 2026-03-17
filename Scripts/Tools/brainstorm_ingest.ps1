param(
    [string]$InboxPath = "DesignNotes/BrainstormInbox",
    [string]$WorkingPath = "DesignNotes/BrainstormWorking",
    [string]$SourceIndexPath = "DesignNotes/SourceIndex.md",
    [switch]$RefreshExisting
)

$repoRoot = Resolve-Path "."
$inboxFullPath = Join-Path $repoRoot $InboxPath
$workingFullPath = Join-Path $repoRoot $WorkingPath
$sourceIndexFullPath = Join-Path $repoRoot $SourceIndexPath

if (-not (Test-Path $inboxFullPath)) {
    throw "Inbox path not found: $InboxPath"
}

if (-not (Test-Path $workingFullPath)) {
    New-Item -ItemType Directory -Path $workingFullPath | Out-Null
}

if (-not (Test-Path $sourceIndexFullPath)) {
    throw "Source index not found: $SourceIndexPath"
}

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseUri = [System.Uri]((Resolve-Path $BasePath).Path + [System.IO.Path]::DirectorySeparatorChar)
    $targetUri = [System.Uri](Resolve-Path $TargetPath).Path
    $relativeUri = $baseUri.MakeRelativeUri($targetUri)
    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', '\')
}

function New-WorkingNoteContent {
    param(
        [string]$SourceRelativePath,
        [hashtable]$Metadata
    )

    $metadataLines = New-Object System.Collections.Generic.List[string]

    foreach ($key in $Metadata.Keys) {
        if ($key -eq "TranscriptSnapshot") {
            continue
        }

        $value = $Metadata[$key]
        if ($null -eq $value -or $value -eq "") {
            continue
        }

        $metadataLines.Add(("- {0}: {1}" -f $key, $value)) | Out-Null
    }

    if ($metadataLines.Count -eq 0) {
        $metadataLines.Add("- Status: extracting") | Out-Null
    }

    @"
# Working Note: $SourceRelativePath

## Source Metadata

$($metadataLines -join "`n")

## High-Fidelity Summary

Pending extraction.

## Transcript Snapshot

$($Metadata["TranscriptSnapshot"])

## Concrete Decisions

- None recorded yet.

## Speculative Ideas

- None recorded yet.

## Unresolved Questions

- None recorded yet.

## Terminology And Definitions

- None recorded yet.

## Mechanics And Systems Details

- None recorded yet.

## Narrative Or Tone Details

- None recorded yet.

## Implementation Constraints

- None recorded yet.

## Contradictions To Log

- None recorded yet.

## Merge Recommendations

- None recorded yet.
"@
}

function Get-TextPreview {
    param(
        [string]$Text,
        [int]$MaxLength = 700
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return "No preview extracted."
    }

    $normalized = ($Text -replace '\s+', ' ').Trim()
    if ($normalized.Length -le $MaxLength) {
        return $normalized
    }

    return $normalized.Substring(0, $MaxLength) + "..."
}

function Get-TranscriptTextFromItem {
    param(
        [pscustomobject]$ItemRecord
    )

    if ($null -eq $ItemRecord -or $null -eq $ItemRecord.data -or $null -eq $ItemRecord.data.content) {
        return $null
    }

    $contentParts = New-Object System.Collections.Generic.List[string]

    foreach ($content in $ItemRecord.data.content) {
        if ($null -eq $content) {
            continue
        }

        if ($content.PSObject.Properties.Name -contains "text" -and -not [string]::IsNullOrWhiteSpace($content.text)) {
            $contentParts.Add($content.text.Trim()) | Out-Null
            continue
        }

        if ($content.type -eq "input_file") {
            $label = "Attached file"
            if ($content.PSObject.Properties.Name -contains "filename" -and $content.filename) {
                $label = "Attached file: {0}" -f $content.filename
            }
            $contentParts.Add($label) | Out-Null
        }
    }

    if ($contentParts.Count -eq 0) {
        return $null
    }

    return ($contentParts -join " ")
}

function Get-JsonChatMetadata {
    param(
        [string]$SourceFilePath,
        [string]$SourceRelativePath
    )

    $rawContent = Get-Content $SourceFilePath -Raw
    $json = $rawContent | ConvertFrom-Json

    $metadata = [ordered]@{
        Source = ('`{0}`' -f $SourceRelativePath)
        Status = "extracting"
        SourceType = "json"
        SourceTitle = $null
        ConversationFormat = $null
        Participants = $null
        MessageCount = $null
        UserMessages = $null
        AssistantMessages = $null
        StartedAt = $null
        UpdatedAt = $null
        Preview = $null
        TranscriptSnapshot = "Pending extraction."
    }

    if ($json.PSObject.Properties.Name -contains "title") {
        $metadata.SourceTitle = $json.title
    }

    if ($json.PSObject.Properties.Name -contains "version") {
        $metadata.ConversationFormat = $json.version
    }

    if ($json.PSObject.Properties.Name -contains "characters" -and $null -ne $json.characters) {
        $participants = $json.characters.PSObject.Properties | ForEach-Object {
            $character = $_.Value
            if ($null -ne $character.modelInfo -and $character.modelInfo.short_name) {
                $character.modelInfo.short_name
            } elseif ($character.model) {
                $character.model
            }
        } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique

        if ($participants) {
            $metadata.Participants = ($participants -join ", ")
        }
    }

    $messages = New-Object System.Collections.Generic.List[object]

    if ($json.PSObject.Properties.Name -contains "messages" -and $null -ne $json.messages) {
        foreach ($property in ($json.messages.PSObject.Properties | Sort-Object { $_.Value.createdAt })) {
            $message = $property.Value
            $itemText = $null

            if ($message.PSObject.Properties.Name -contains "items" -and $null -ne $message.items) {
                foreach ($messageItem in $message.items) {
                    if ($null -eq $messageItem -or -not $messageItem.id) {
                        continue
                    }

                    $itemRecord = $json.items.PSObject.Properties[$messageItem.id].Value
                    $candidateText = Get-TranscriptTextFromItem -ItemRecord $itemRecord
                    if (-not [string]::IsNullOrWhiteSpace($candidateText)) {
                        $itemText = $candidateText
                        break
                    }
                }
            }

            $messages.Add([pscustomobject]@{
                Type = $message.type
                CreatedAt = $message.createdAt
                Text = $itemText
            }) | Out-Null
        }
    }

    $metadata.MessageCount = $messages.Count
    $metadata.UserMessages = ($messages | Where-Object { $_.Type -eq "user" }).Count
    $metadata.AssistantMessages = ($messages | Where-Object { $_.Type -eq "assistant" }).Count

    $datedMessages = $messages | Where-Object { -not [string]::IsNullOrWhiteSpace($_.CreatedAt) }
    if ($datedMessages.Count -gt 0) {
        $metadata.StartedAt = ($datedMessages | Select-Object -First 1).CreatedAt
        $metadata.UpdatedAt = ($datedMessages | Select-Object -Last 1).CreatedAt
    }

    $previewSource = ($messages | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Text) } | Select-Object -First 1).Text
    $metadata.Preview = Get-TextPreview -Text $previewSource

    $snapshotLines = New-Object System.Collections.Generic.List[string]
    $snapshotSource = $messages | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Text) } | Select-Object -First 6

    if ($snapshotSource.Count -eq 0) {
        $snapshotLines.Add("No transcript preview extracted.") | Out-Null
    } else {
        foreach ($entry in $snapshotSource) {
            $role = if ($entry.Type -eq "assistant") { "Assistant" } else { "User" }
            $snapshotLines.Add(("- {0}: {1}" -f $role, (Get-TextPreview -Text $entry.Text -MaxLength 240))) | Out-Null
        }
    }

    $metadata.TranscriptSnapshot = $snapshotLines -join "`n"
    return $metadata
}

function Get-GenericFileMetadata {
    param(
        [System.IO.FileInfo]$SourceFile,
        [string]$SourceRelativePath
    )

    $rawPreview = if ($SourceFile.Length -gt 0) {
        Get-Content $SourceFile.FullName -Raw
    } else {
        ""
    }

    return [ordered]@{
        Source = ('`{0}`' -f $SourceRelativePath)
        Status = "extracting"
        SourceType = $SourceFile.Extension.TrimStart('.')
        SourceTitle = $SourceFile.BaseName
        FileSizeBytes = $SourceFile.Length
        Preview = Get-TextPreview -Text $rawPreview
        TranscriptSnapshot = "- File preview: $(Get-TextPreview -Text $rawPreview -MaxLength 240)"
    }
}

function Get-SourceMetadata {
    param(
        [System.IO.FileInfo]$SourceFile,
        [string]$SourceRelativePath
    )

    if ($SourceFile.Extension -eq ".json") {
        try {
            return Get-JsonChatMetadata -SourceFilePath $SourceFile.FullName -SourceRelativePath $SourceRelativePath
        } catch {
            $metadata = Get-GenericFileMetadata -SourceFile $SourceFile -SourceRelativePath $SourceRelativePath
            $metadata.SourceType = "json"
            $metadata.TranscriptSnapshot = "- JSON parse failed during ingest. Treat as generic source until manually reviewed."
            return $metadata
        }
    }

    return Get-GenericFileMetadata -SourceFile $SourceFile -SourceRelativePath $SourceRelativePath
}

function Sanitize-TableCell {
    param(
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return (($Value -replace '\|', '/') -replace '\r?\n', ' ').Trim()
}

$sourceIndexLines = Get-Content $sourceIndexFullPath
$existingEntries = @{}

foreach ($line in $sourceIndexLines) {
    if ($line -match '^\|\s+(.+?)\s+\|\s+(.+?)\s+\|\s+(.+?)\s+\|\s+(.+?)\s+\|\s+(.+?)\s+\|$') {
        $source = $matches[1].Trim()
        if ($source -ne 'Source' -and $source -ne '---') {
            $existingEntries[$source] = [pscustomobject]@{
                Type = $matches[2].Trim()
                Status = $matches[3].Trim()
                WorkingNote = $matches[4].Trim()
                Notes = $matches[5].Trim()
            }
        }
    }
}

$indexRows = New-Object System.Collections.Generic.List[string]
$newCount = 0
$refreshedCount = 0
$sourceFiles = Get-ChildItem -Path $inboxFullPath -File -Recurse | Where-Object {
    $_.Extension -in @('.md', '.txt', '.json') -and $_.Name -ne 'README.md'
}

foreach ($sourceFile in $sourceFiles) {
    $sourceRelativePath = Get-RelativePath -BasePath $repoRoot -TargetPath $sourceFile.FullName
    $entry = $existingEntries[$sourceRelativePath]

    if ($null -ne $entry) {
        $workingRelativePath = $entry.WorkingNote
        $workingFilePath = Join-Path $repoRoot $workingRelativePath
        $status = $entry.Status
    } else {
        $workingFileName = "{0}.md" -f $sourceFile.BaseName
        $workingFilePath = Join-Path $workingFullPath $workingFileName
        $workingRelativePath = Join-Path $WorkingPath $workingFileName

        $suffix = 1
        while (Test-Path $workingFilePath) {
            $workingFileName = "{0}-{1}.md" -f $sourceFile.BaseName, $suffix
            $workingFilePath = Join-Path $workingFullPath $workingFileName
            $workingRelativePath = Join-Path $WorkingPath $workingFileName
            $suffix += 1
        }

        $status = "queued"
        $newCount += 1
    }

    $metadata = Get-SourceMetadata -SourceFile $sourceFile -SourceRelativePath $sourceRelativePath
    if ($RefreshExisting -or -not (Test-Path $workingFilePath) -or $null -eq $entry) {
        $noteContent = New-WorkingNoteContent -SourceRelativePath $sourceRelativePath -Metadata $metadata
        Set-Content -Path $workingFilePath -Value $noteContent

        if ($null -ne $entry) {
            $refreshedCount += 1
        }
    }

    $sourceTitle = Sanitize-TableCell -Value $metadata["SourceTitle"]
    $messageCount = Sanitize-TableCell -Value ([string]$metadata["MessageCount"])
    $rowNotes = if ($sourceTitle) {
        if ($messageCount) {
            "Imported by brainstorm_ingest.ps1; title: $sourceTitle; messages: $messageCount"
        } else {
            "Imported by brainstorm_ingest.ps1; title: $sourceTitle"
        }
    } else {
        "Imported by brainstorm_ingest.ps1"
    }

    $row = "| $sourceRelativePath | $($sourceFile.Extension.TrimStart('.')) | $status | $workingRelativePath | $rowNotes |"
    $indexRows.Add($row) | Out-Null
}

$sourceIndexContent = @'
# Brainstorm Source Index

This file tracks raw brainstorm sources and their synthesis state.

## Status Definitions

- `queued`: ready for extraction
- `extracting`: working note exists and is being distilled
- `needs_review`: blocked on contradiction or clarification
- `merged`: reflected in `DesignBible.md`
- `archived`: preserved for provenance only

## Sources

| Source | Type | Status | Working Note | Notes |
| --- | --- | --- | --- | --- |
'@ + "`n" + ($indexRows -join "`n")

Set-Content -Path $sourceIndexFullPath -Value $sourceIndexContent

if ($newCount -eq 0 -and $refreshedCount -eq 0) {
    Write-Output "No new brainstorm sources found."
    exit 0
}

if ($refreshedCount -gt 0) {
    Write-Output ("Registered {0} new source(s). Refreshed {1} existing note(s)." -f $newCount, $refreshedCount)
} else {
    Write-Output ("Registered {0} new source(s)." -f $newCount)
}
