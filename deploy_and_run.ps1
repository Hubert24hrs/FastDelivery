$ScriptDir = Split-Path $MyInvocation.MyCommand.Path
Set-Location "C:\Users\HP\.gemini\antigravity\scratch\fast_delivery"

Write-Host ">>> Step 1: Deploying Firestore Rules..." -ForegroundColor Cyan
firebase deploy --only firestore:rules

# Proceed to run app regardless of deploy success (in case agent has no auth)
Write-Host ">>> Step 2: Launching App on Phone (Release Mode)..." -ForegroundColor Cyan
flutter run --release
