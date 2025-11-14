# Railway Deployment Script for API Sentinel
# Run this script to deploy your backend to Railway

Write-Host "🚀 API Sentinel - Railway Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check if Railway CLI is installed
Write-Host "Checking Railway CLI..." -ForegroundColor Yellow
$railwayInstalled = Get-Command railway -ErrorAction SilentlyContinue

if (-not $railwayInstalled) {
    Write-Host "❌ Railway CLI not found. Installing..." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Railway CLI by running:" -ForegroundColor Yellow
    Write-Host "npm install -g @railway/cli" -ForegroundColor Green
    Write-Host ""
    Write-Host "After installation, run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Railway CLI found" -ForegroundColor Green
Write-Host ""

# Login to Railway
Write-Host "Step 1: Login to Railway" -ForegroundColor Cyan
Write-Host "This will open your browser for authentication..." -ForegroundColor Yellow
railway login

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Login failed. Please try again." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Logged in successfully" -ForegroundColor Green
Write-Host ""

# Initialize Railway project
Write-Host "Step 2: Initialize Railway Project" -ForegroundColor Cyan
Write-Host "Creating new Railway project..." -ForegroundColor Yellow

# Check if already initialized
if (Test-Path ".railway") {
    Write-Host "⚠️  Railway project already exists" -ForegroundColor Yellow
    $continue = Read-Host "Continue with existing project? (y/n)"
    if ($continue -ne "y") {
        exit 0
    }
} else {
    railway init
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Project initialization failed" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Project initialized" -ForegroundColor Green
Write-Host ""

# Set environment variables
Write-Host "Step 3: Configure Environment Variables" -ForegroundColor Cyan
Write-Host "Setting JWT_SECRET..." -ForegroundColor Yellow

# Generate a secure JWT secret if needed
$jwtSecret = Read-Host "Enter JWT_SECRET (or press Enter to generate random)"
if ([string]::IsNullOrWhiteSpace($jwtSecret)) {
    $jwtSecret = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
    Write-Host "Generated JWT_SECRET: $jwtSecret" -ForegroundColor Green
}

railway variables set JWT_SECRET=$jwtSecret

Write-Host "✅ Environment configured" -ForegroundColor Green
Write-Host ""

# Deploy the application
Write-Host "Step 4: Deploy Application" -ForegroundColor Cyan
Write-Host "Uploading code and building Docker container..." -ForegroundColor Yellow
Write-Host "This may take 2-3 minutes..." -ForegroundColor Yellow
Write-Host ""

railway up

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Deployment successful!" -ForegroundColor Green
Write-Host ""

# Get the deployment URL
Write-Host "Step 5: Get Your Deployment URL" -ForegroundColor Cyan
Write-Host "Getting deployment URL..." -ForegroundColor Yellow

# Try to get domain
railway domain

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy the URL shown above (or from Railway dashboard)" -ForegroundColor White
Write-Host "2. Test health endpoint: curl YOUR_URL/health" -ForegroundColor White
Write-Host "3. Update landing-page.html with your production URL" -ForegroundColor White
Write-Host "4. Start accepting customer signups!" -ForegroundColor White
Write-Host ""
Write-Host "View logs: railway logs" -ForegroundColor Cyan
Write-Host "View dashboard: railway open" -ForegroundColor Cyan
Write-Host ""
