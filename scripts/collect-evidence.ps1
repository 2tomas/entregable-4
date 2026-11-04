param(
    [string]$ApplicationName = "coderhouse-dev-realtime-metrics",
    [string]$LogGroupName = "/aws/managed-flink/coderhouse-dev-realtime-metrics",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"
$evidenceDirectory = Join-Path $PSScriptRoot "..\evidence"
$resolvedEvidenceDirectory = [System.IO.Path]::GetFullPath($evidenceDirectory)
New-Item -ItemType Directory -Force -Path $resolvedEvidenceDirectory | Out-Null

aws kinesisanalyticsv2 describe-application `
    --application-name $ApplicationName `
    --region $Region `
    --output json |
    Out-File -FilePath (Join-Path $resolvedEvidenceDirectory "application.json") -Encoding utf8

$logStartTime = [DateTimeOffset]::UtcNow.AddHours(-2).ToUnixTimeMilliseconds()
$logEvents = aws logs get-log-events `
    --log-group-name $LogGroupName `
    --log-stream-name "application" `
    --start-time $logStartTime `
    --limit 10000 `
    --region $Region `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    throw "No se pudieron leer los eventos del log stream de Flink."
}

$windowMetrics = @($logEvents.events |
    Where-Object { $_.message -like "*WINDOW_METRIC*" } |
    Select-Object -Last 20)
$checkpointEvents = @($logEvents.events |
    Where-Object { $_.message -like "*Completed checkpoint*" } |
    Select-Object -Last 20)

[ordered]@{ events = $windowMetrics } |
    ConvertTo-Json -Depth 10 |
    Out-File -FilePath (Join-Path $resolvedEvidenceDirectory "window-metrics.json") -Encoding utf8

[ordered]@{ events = $checkpointEvents } |
    ConvertTo-Json -Depth 10 |
    Out-File -FilePath (Join-Path $resolvedEvidenceDirectory "checkpoints.json") -Encoding utf8

Write-Output "Evidencia guardada en $resolvedEvidenceDirectory"
