# Automated script to expose backend and update Surge deployment
Write-Host "`n🚀 API Sentinel - Automated Deployment Script`n" -ForegroundColor Cyan

# Check if backend is running
Write-Host "Checking if backend is running..." -ForegroundColor Yellow
try {
    $health = Invoke-WebRequest -Uri "http://localhost:8080/health" -TimeoutSec 2
    Write-Host "✅ Backend is running on localhost:8080" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend is NOT running!" -ForegroundColor Red
    Write-Host "Please start the backend first with: cd backend; dart run bin/server.dart" -ForegroundColor Yellow
    exit 1
}

# Start cloudflared tunnel and capture URL
Write-Host "`nStarting Cloudflare tunnel..." -ForegroundColor Yellow
$tunnelProcess = Start-Process -FilePath "cloudflared" -ArgumentList "tunnel --url http://localhost:8080" -NoNewWindow -PassThru -RedirectStandardOutput "c:\temp\tunnel-output.txt" -RedirectStandardError "c:\temp\tunnel-error.txt"

# Wait for tunnel to initialize
Write-Host "Waiting for tunnel to establish..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

# Read the tunnel URL from output
$tunnelUrl = $null
$maxAttempts = 10
$attempt = 0

while ($attempt -lt $maxAttempts -and !$tunnelUrl) {
    Start-Sleep -Seconds 1
    if (Test-Path "c:\temp\tunnel-output.txt") {
        $output = Get-Content "c:\temp\tunnel-output.txt" -Raw
        if ($output -match "https://[a-zA-Z0-9-]+\.trycloudflare\.com") {
            $tunnelUrl = $matches[0]
            break
        }
    }
    if (Test-Path "c:\temp\tunnel-error.txt") {
        $errorOutput = Get-Content "c:\temp\tunnel-error.txt" -Raw
        if ($errorOutput -match "https://[a-zA-Z0-9-]+\.trycloudflare\.com") {
            $tunnelUrl = $matches[0]
            break
        }
    }
    $attempt++
}

if (!$tunnelUrl) {
    Write-Host "❌ Could not capture tunnel URL automatically" -ForegroundColor Red
    Write-Host "`nPlease check the cloudflared window and manually note the URL" -ForegroundColor Yellow
    Write-Host "It should look like: https://XXXXX.trycloudflare.com" -ForegroundColor White
    Write-Host "`nThen update the files with:" -ForegroundColor Yellow
    Write-Host "(Get-Content deploy\landing-page.html) -replace 'https://proud-groups-wash\.loca\.lt', 'YOUR_TUNNEL_URL' | Set-Content deploy\landing-page.html" -ForegroundColor White
    exit 1
}

Write-Host "`n✅ Tunnel established at: $tunnelUrl" -ForegroundColor Green

# Update deploy files
Write-Host "`nUpdating HTML files with tunnel URL..." -ForegroundColor Yellow
$deployPath = "c:\Users\gidc\OneDrive\Documents\APPS\apisentinei\deploy"

@('landing-page.html', 'customer-dashboard.html', 'admin-dashboard.html') | ForEach-Object {
    $filePath = Join-Path $deployPath $_
    $content = Get-Content $filePath -Raw
    $content = $content -replace 'https://proud-groups-wash\.loca\.lt', $tunnelUrl
    $content = $content -replace 'http://localhost:8080', $tunnelUrl
    Set-Content $filePath $content
    Write-Host "  ✓ Updated $_" -ForegroundColor Green
}

# Deploy to Surge
Write-Host "`nDeploying to Surge..." -ForegroundColor Yellow
Set-Location $deployPath
$surgeOutput = surge --domain api-sentinel-live.surge.sh 2>&1
Write-Host $surgeOutput

Write-Host "`n✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "`n📍 Your sites are live at:" -ForegroundColor Cyan
Write-Host "   Landing Page: https://api-sentinel-live.surge.sh/landing-page.html" -ForegroundColor White
Write-Host "   Customer Dashboard: https://api-sentinel-live.surge.sh/customer-dashboard.html" -ForegroundColor White
Write-Host "   Admin Dashboard: https://api-sentinel-live.surge.sh/admin-dashboard.html" -ForegroundColor White
Write-Host "`n⚠️  Keep this window and the cloudflared window open for the backend to remain accessible!" -ForegroundColor Yellow
Write-Host "`nPress any key to stop the tunnel and exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Cleanup
Stop-Process -Id $tunnelProcess.Id -Force
Remove-Item "c:\temp\tunnel-output.txt" -ErrorAction SilentlyContinue
Remove-Item "c:\temp\tunnel-error.txt" -ErrorAction SilentlyContinue
