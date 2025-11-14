# Start backend and expose it with localtunnel
Write-Host "Starting API Sentinel Backend..." -ForegroundColor Green

# Start localtunnel in background and capture URL
$tunnel = Start-Job -ScriptBlock { 
    npx localtunnel --port 8080 2>&1 | Tee-Object -Variable output
} 

# Wait for tunnel to establish
Start-Sleep -Seconds 5

# Get the tunnel URL
$tunnelOutput = Receive-Job -Job $tunnel -Keep
$url = ($tunnelOutput | Select-String -Pattern "your url is: (.+)" | Select-Object -First 1).Matches.Groups[1].Value

if ($url) {
    Write-Host "`n✅ Backend exposed at: $url" -ForegroundColor Cyan
    Write-Host "`nUpdate your HTML files with this URL:" -ForegroundColor Yellow
    Write-Host "BACKEND_URL = '$url'" -ForegroundColor White
    Write-Host "`nThen run: cd deploy; surge --domain api-sentinel-live.surge.sh" -ForegroundColor Yellow
    Write-Host "`nPress Ctrl+C to stop the tunnel..." -ForegroundColor Gray
    
    # Keep the tunnel running
    Wait-Job -Job $tunnel
} else {
    Write-Host "❌ Failed to get tunnel URL" -ForegroundColor Red
    Get-Job | Remove-Job -Force
}
