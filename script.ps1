# PowerShell Script for Windows

# Set variables for Obsidian to Hugo copy
$sourcePath = "C:\Users\Ashley-PC\Documents\Ashley in Wonderland\008 - Posts"
$destinationPath = "C:\Users\Ashley-PC\Documents\wonderblog\src\content\posts"

# Set Github repo 
$myrepo = "https://github.com/qeewpi/wonderblog/"

# Set error handling
Set-StrictMode -Version Latest

# Change to the script's directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

try {
    # Check for required commands
    $requiredCommands = @('git', 'hugo')

    # Check for Python command (python, python3, or py)
    $pythonCmd = Get-Command 'python' -ErrorAction SilentlyContinue
    if ($pythonCmd) {
        $pythonCommand = $pythonCmd.Source
    } else {
        $pythonCmd = Get-Command 'python3' -ErrorAction SilentlyContinue
        if ($pythonCmd) {
            $pythonCommand = $pythonCmd.Source
        } else {
            $pythonCmd = Get-Command 'py' -ErrorAction SilentlyContinue
            if ($pythonCmd) {
                $pythonCommand = $pythonCmd.Source
            } else {
                throw "Python is not installed or not in PATH."
            }
        }
    }

    foreach ($cmd in $requiredCommands) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            throw "$cmd is not installed or not in PATH."
        }
    }

    # Step 1: Check if Git is initialized, and initialize if necessary
    if (-not (Test-Path ".git")) {
        Write-Host "Initializing Git repository..."
        git init
        if ($LASTEXITCODE -ne 0) { throw "Git init failed" }
        git remote add origin $myrepo
        if ($LASTEXITCODE -ne 0) { throw "Failed to add git remote" }
    } else {
        Write-Host "Git repository already initialized."
        $remotes = git remote
        if ($LASTEXITCODE -ne 0) { throw "Failed to get git remotes" }
        if (-not ($remotes -contains 'origin')) {
            Write-Host "Adding remote origin..."
            git remote add origin $myrepo
            if ($LASTEXITCODE -ne 0) { throw "Failed to add git remote" }
        }
    }

    # Step 2: Sync posts from Obsidian to Hugo content folder using Robocopy
    Write-Host "Syncing posts from Obsidian..."

    if (-not (Test-Path $sourcePath)) {
        throw "Source path does not exist: $sourcePath"
    }

    if (-not (Test-Path $destinationPath)) {
        throw "Destination path does not exist: $destinationPath"
    }

    # Use Robocopy to mirror the directories
    $robocopyOptions = @('/MIR', '/Z', '/W:5', '/R:3')
    $robocopyResult = robocopy $sourcePath $destinationPath @robocopyOptions

    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed with exit code $LASTEXITCODE"
    }

    # Step 3: Process Markdown files with Python script to handle image links
    Write-Host "Processing image links in Markdown files..."
    if (-not (Test-Path "images.py")) {
        throw "Python script images.py not found."
    }

    # Execute the Python script
    & $pythonCommand images.py
    if ($LASTEXITCODE -ne 0) { throw "Python script failed" }

    # Step 4: Start the Hugo server
    Write-Host "Starting the Hugo server..."
    Set-Location "src"
    hugo server
    if ($LASTEXITCODE -ne 0) { throw "Hugo server failed" }

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
}

Read-Host "Script completed successfully. Press Enter to exit"


