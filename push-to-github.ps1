# Git Push Helper Script
# Run this script to push all branches to GitHub

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Repository Upload Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if gh CLI is available
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if ($ghInstalled) {
    Write-Host "✅ GitHub CLI detected!" -ForegroundColor Green
    Write-Host "Authenticating with GitHub..." -ForegroundColor Yellow
    gh auth login
    Write-Host ""
}

Write-Host "📤 Pushing to GitHub repository..." -ForegroundColor Yellow
Write-Host "Repository: https://github.com/jimmy622001/AWS-Enterprise-Edition-EKS-Application-with-DR-Region" -ForegroundColor Cyan
Write-Host ""

# Push main branch
Write-Host "Pushing 'main' branch..." -ForegroundColor Magenta
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Main branch pushed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Push all other branches
    Write-Host "Pushing all environment branches..." -ForegroundColor Magenta
    git push origin dev
    git push origin uat
    git push origin staging
    git push origin prod
    git push origin dr-london
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  ✅ ALL BRANCHES PUSHED SUCCESSFULLY!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Branches available on GitHub:" -ForegroundColor Cyan
        Write-Host "  • main (default)" -ForegroundColor White
        Write-Host "  • dev" -ForegroundColor White
        Write-Host "  • uat" -ForegroundColor White
        Write-Host "  • staging" -ForegroundColor White
        Write-Host "  • prod" -ForegroundColor White
        Write-Host "  • dr-london" -ForegroundColor White
        Write-Host ""
        Write-Host "🌐 View on GitHub: https://github.com/jimmy622001/AWS-Enterprise-Edition-EKS-Application-with-DR-Region" -ForegroundColor Cyan
    } else {
        Write-Host "❌ Failed to push environment branches" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "❌ Failed to push to GitHub" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible solutions:" -ForegroundColor Yellow
    Write-Host "1. Install GitHub CLI: https://cli.github.com/" -ForegroundColor White
    Write-Host "2. Or create a Personal Access Token:" -ForegroundColor White
    Write-Host "   → Go to: https://github.com/settings/tokens" -ForegroundColor White
    Write-Host "   → Generate new token (classic)" -ForegroundColor White
    Write-Host "   → Select 'repo' scope" -ForegroundColor White
    Write-Host "   → Use token as password when prompted" -ForegroundColor White
}

Write-Host ""
Read-Host "Press Enter to exit"
