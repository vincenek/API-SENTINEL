# Simple Server Exposure Script
Write-Host "Starting API Sentinel Backend Exposure..." -ForegroundColor Cyan
Write-Host ""

# Start backend server in background
Write-Host "1. Starting backend server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\Users\gidc\OneDrive\Documents\APPS\apisentinei\backend; dart run bin/server.dart" -WindowStyle Normal

Start-Sleep -Seconds 3

# Test if server is running
Write-Host "2. Testing local server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
    Write-Host "✅ Server is running!" -ForegroundColor Green
} catch {
    Write-Host "❌ Server not responding. Please check the other window." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Your server is running at http://localhost:8080" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps to make it public:" -ForegroundColor Cyan
Write-Host "1. Extract C:\Users\gidc\Downloads\ngrok-v3-stable-windows-amd64.zip manually" -ForegroundColor White
Write-Host "2. Double-click ngrok.exe" -ForegroundColor White
Write-Host "3. In the ngrok window, type: http 8080" -ForegroundColor White
Write-Host "4. Copy the public URL it gives you" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
