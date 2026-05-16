# test_azure_api.ps1
# Quick validation script for Azure OpenAI endpoint + credentials
# Run from PowerShell: .\test_azure_api.ps1
#
# NOTE: Fill in $ApiKey below OR set environment variable LINA_API_KEY before running.

$ApiKey      = $env:LINA_API_KEY   # preferred: set env var, don't hardcode here
$Endpoint    = "https://gavin-mh49j2cg-eastus2.cognitiveservices.azure.com"
$Deployment  = "gpt-5-mini"
$ApiVersion  = "2025-01-01-preview"

if (-not $ApiKey) {
    Write-Error "Set the LINA_API_KEY environment variable first: `$env:LINA_API_KEY = '<your-key>'"
    exit 1
}

$Url = "$Endpoint/openai/deployments/$Deployment/chat/completions?api-version=$ApiVersion"

$Body = @{
    messages = @(
        @{ role = "system"; content = "You are a test assistant. Call exactly one tool." }
        @{ role = "user";   content = "Say hello using the notify_player tool." }
    )
    tools = @(
        @{
            type = "function"
            function = @{
                name        = "notify_player"
                description = "Display a message to the player."
                parameters  = @{
                    type       = "object"
                    required   = @("message")
                    properties = @{
                        message = @{ type = "string" }
                    }
                }
            }
        }
    )
    tool_choice           = "required"
    parallel_tool_calls   = $false
    max_completion_tokens = 100
} | ConvertTo-Json -Depth 10

Write-Host "`n=== Azure OpenAI API Test ===" -ForegroundColor Cyan
Write-Host "URL:        $Url"
Write-Host "Deployment: $Deployment"
Write-Host "API Ver:    $ApiVersion"
Write-Host "Headers:    Content-Type: application/json"
Write-Host "            api-key: ***${($ApiKey.Substring([Math]::Max(0,$ApiKey.Length-4)))}"
Write-Host ""
Write-Host "Sending request..." -ForegroundColor Yellow

try {
    $Response = Invoke-RestMethod `
        -Method Post `
        -Uri $Url `
        -Headers @{
            "Content-Type" = "application/json"
            "api-key"      = $ApiKey
        } `
        -Body $Body `
        -TimeoutSec 15

    Write-Host "`n=== SUCCESS ===" -ForegroundColor Green
    Write-Host "Model:      $($Response.model)"
    Write-Host "Finish:     $($Response.choices[0].finish_reason)"

    $ToolCall = $Response.choices[0].message.tool_calls
    if ($ToolCall) {
        Write-Host "Tool called: $($ToolCall[0].function.name)"
        Write-Host "Arguments:   $($ToolCall[0].function.arguments)"
    } else {
        Write-Host "WARNING: No tool_calls in response - check tool_choice setting" -ForegroundColor Yellow
        Write-Host "Content: $($Response.choices[0].message.content)"
    }

    Write-Host "`nUsage: prompt=$($Response.usage.prompt_tokens) completion=$($Response.usage.completion_tokens) total=$($Response.usage.total_tokens)"

} catch {
    Write-Host "`n=== FAILED ===" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__) $($_.Exception.Response.StatusDescription)"

    try {
        $ErrStream = $_.Exception.Response.GetResponseStream()
        $Reader    = [System.IO.StreamReader]::new($ErrStream)
        $ErrBody   = $Reader.ReadToEnd()
        Write-Host "Body:   $ErrBody" -ForegroundColor Red
    } catch {
        Write-Host "Error:  $($_.Exception.Message)" -ForegroundColor Red
    }
}
