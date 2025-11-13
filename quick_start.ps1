# Quick Start Script for API Sentinel Development (Windows)

Write-Host "🚀 API Sentinel - Quick Start" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check Flutter installation
Write-Host "📋 Checking Flutter installation..." -ForegroundColor Yellow
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue

if (-not $flutterCmd) {
    Write-Host "❌ Flutter is not installed. Please install Flutter first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Flutter is installed" -ForegroundColor Green
flutter --version
Write-Host ""

# Get dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to install dependencies" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Dependencies installed" -ForegroundColor Green
Write-Host ""

# Run analyzer
Write-Host "🔍 Running code analysis..." -ForegroundColor Yellow
flutter analyze

if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Code analysis found issues (non-critical)" -ForegroundColor Yellow
} else {
    Write-Host "✅ Code analysis passed" -ForegroundColor Green
}
Write-Host ""

# Display next steps
Write-Host "🎯 Ready to run!" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run the demo app:" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "To run on specific platform:" -ForegroundColor White
Write-Host "  flutter run -d chrome    # Web" -ForegroundColor Gray
Write-Host "  flutter run -d windows   # Windows" -ForegroundColor Gray
Write-Host ""
Write-Host "To build for production:" -ForegroundColor White
Write-Host "  flutter build web" -ForegroundColor Gray
Write-Host "  flutter build windows" -ForegroundColor Gray
Write-Host ""
Write-Host "✨ Setup complete! Happy coding!" -ForegroundColor Green
