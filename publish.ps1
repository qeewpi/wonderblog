# This script automates the publishing process by running sub-scripts.

Write-Host "--- Starting Publishing Process ---" -ForegroundColor Green

# Step 1: Run the Python script to process and audit images.
Write-Host "`n[Step 1/2] Running image audit and link fixing script..." -ForegroundColor Cyan
python ./images.py

# Check if the python script ran successfully
if ($LASTEXITCODE -ne 0) {
    Write-Host "Python script 'images.py' failed. Aborting." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "Image script completed." -ForegroundColor Green

# Step 2: Run the PowerShell script to commit and sync new posts.
Write-Host "`n[Step 2/2] Running post synchronization script..." -ForegroundColor Cyan
# The -File parameter ensures it runs in a new scope and handles paths correctly.
powershell.exe -File ./sync-posts.ps1

if ($LASTEXITCODE -ne 0) {
    Write-Host "PowerShell script 'sync-posts.ps1' failed." -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host "`n--- Publishing Process Finished ---" -ForegroundColor Green
# The sync-posts script already has a pause at the end, so no need for another one here.
