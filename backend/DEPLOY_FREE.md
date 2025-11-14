# Free Deployment to Render - API Sentinel
Write-Host "🚀 API Sentinel - FREE Deployment to Render" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Option 1: Deploy via GitHub (EASIEST)" -ForegroundColor Yellow
Write-Host "1. Go to https://github.com/new" -ForegroundColor White
Write-Host "2. Create a new repository named 'apisentinel-backend'" -ForegroundColor White
Write-Host "3. Don't initialize with README" -ForegroundColor White
Write-Host ""
Write-Host "Then run these commands:" -ForegroundColor Yellow
Write-Host "  git init" -ForegroundColor Green
Write-Host "  git add ." -ForegroundColor Green
Write-Host "  git commit -m 'Initial commit'" -ForegroundColor Green
Write-Host "  git branch -M main" -ForegroundColor Green
Write-Host "  git remote add origin https://github.com/YOUR_USERNAME/apisentinel-backend.git" -ForegroundColor Green
Write-Host "  git push -u origin main" -ForegroundColor Green
Write-Host ""
Write-Host "4. Go to https://render.com" -ForegroundColor White
Write-Host "5. Click 'New +' → 'Web Service'" -ForegroundColor White
Write-Host "6. Connect your GitHub repo" -ForegroundColor White
Write-Host "7. Render will auto-detect Dockerfile" -ForegroundColor White
Write-Host "8. Select 'Free' plan" -ForegroundColor White
Write-Host "9. Click 'Create Web Service'" -ForegroundColor White
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Option 2: Deploy without GitHub (MANUAL)" -ForegroundColor Yellow
Write-Host "1. Zip your backend folder" -ForegroundColor White
Write-Host "2. Go to https://render.com" -ForegroundColor White
Write-Host "3. Use 'Deploy from a Git repository' with GitLab/Bitbucket" -ForegroundColor White
Write-Host "   OR use Render's Docker registry upload" -ForegroundColor White
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "After deployment, you'll get a FREE URL like:" -ForegroundColor Green
Write-Host "https://apisentinel-backend.onrender.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test it with: curl https://your-url.onrender.com/health" -ForegroundColor Yellow
Write-Host ""
Write-Host "⚠️  NOTE: Free tier spins down after 15 min of inactivity" -ForegroundColor Yellow
Write-Host "   First request after downtime may take 30-60 seconds" -ForegroundColor Yellow
Write-Host "   This is normal for free hosting!" -ForegroundColor Yellow
Write-Host ""
