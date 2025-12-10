# PowerShell Script to Commit and Push Blog Posts Individually

# --- Main script logic wrapped in a try/catch/finally structure ---
try {
    # STEP 1: FIND THE GIT REPO ROOT AND NAVIGATE THERE
    # ----------------------------------------------------------------
    $gitRoot = git rev-parse --show-toplevel | ForEach-Object { $_.Trim() }
    if ($null -eq $gitRoot -or -not (Test-Path $gitRoot)) {
        throw "Could not find the root of the Git repository. Please run this script from within the repo."
    }
    Set-Location -Path $gitRoot
    Write-Host "Operating from Git repository root: $gitRoot" -ForegroundColor Yellow

    # --- Configuration ---
    $postsDirectory = "src/content/posts"
    $remote = "origin"
    $branch = "main"

    # --- Function to check Git's exit code ---
    function Check-Git-Success {
        if ($LASTEXITCODE -ne 0) {
            throw "A git command failed. Please review the output above for details from Git."
        }
    }

    # STEP 2: CHECK FOR UNSTAGED CHANGES
    # ----------------------------------------------------------------
    Write-Host "Checking for changes in $postsDirectory..." -ForegroundColor Cyan

    $statusOutput = git status $postsDirectory --porcelain --untracked-files=all
    Check-Git-Success

    # Group changes by their parent directory to handle posts as a single unit
    $postsToProcess = $statusOutput | ForEach-Object {
        $line = $_.Trim()
        # Get the path part, which starts at character 4 (e.g., after '?? ')
        $pathWithQuotes = $line.Substring(3)
        
        # THE CRITICAL FIX: Remove the surrounding double quotes that Git adds for paths with spaces
        $cleanPath = $pathWithQuotes.Trim('"')

        # Determine the post's root folder
        if ($cleanPath.EndsWith('/')) {
            $cleanPath.TrimEnd('/') # It's already a directory
        } else {
            Split-Path -Path $cleanPath -Parent # It's a file, get its parent directory
        }
    } | Get-Unique

    if ($postsToProcess.Count -eq 0) {
        Write-Host "No new file changes found in $postsDirectory." -ForegroundColor Yellow
    } else {
        # STEP 3: PROCESS EACH CHANGED POST
        # ----------------------------------------------------------------
        foreach ($postFolder in $postsToProcess) {
            # Find the primary .md file in the directory to get the title
            $mdFile = Get-ChildItem -Path $postFolder -Filter "*.md" | Select-Object -First 1
            if ($null -eq $mdFile) {
                Write-Warning "Directory found with no .md file, skipping: $postFolder"
                continue
            }
            $filePath = $mdFile.FullName # Use FullName here for reading the content

            $title = "Untitled Post"
            try {
                $content = Get-Content -Path $filePath -TotalCount 10 -ErrorAction Stop
                foreach ($line in $content) {
                    if ($line -match '^title:\s*"?([^"]+)"?') {
                        $title = $matches[1].Trim()
                        break
                    }
                }
            }
            catch {
                Write-Warning "Could not read title from file: $filePath. Using default."
            }

            # Git Operations for this specific post
            Write-Host "Processing: $title (from $postFolder)" -ForegroundColor Green
            
            try {
                # Use the clean, relative path for 'git add'
                git add "$postFolder/"
                Check-Git-Success

                # Determine the change type for the commit message
                $postStatus = git status $postFolder --porcelain
                $commitAction = "edit" # Default to edit
                if ($postStatus -match '^\?\?') {
                    $commitAction = "add new"
                }

                $commitMsg = "feat(blog): $commitAction post '$title'"
                git commit -m $commitMsg
                Check-Git-Success
            }
            catch {
                Write-Warning "Failed to add or commit post: '$title'. Please check for git conflicts or errors."
                Write-Warning $_.Exception.Message
            }
        }
    }

    # STEP 4: CHECK FOR PENDING COMMITS AND PUSH
    # ----------------------------------------------------------------
    Write-Host "`nChecking for local commits that need to be pushed..." -ForegroundColor Cyan
    $commitsToPush = git rev-list --count "$($remote)/$($branch)..HEAD"
    Check-Git-Success

    # Trim potential whitespace from command output
    $commitsToPush = $commitsToPush.Trim()

    if ($commitsToPush -gt 0) {
        Write-Host "Found $commitsToPush local commit(s) to push." -ForegroundColor Green

        Write-Host "`n[Step 4.1] Syncing with remote repository..." -ForegroundColor Cyan
        git pull --rebase --autostash $remote $branch
        Check-Git-Success
        Write-Host "Sync successful." -ForegroundColor Green

        Write-Host "`n[Step 4.2] Reviewing commits to be pushed..." -ForegroundColor Cyan
        git log "$($remote)/$($branch)..HEAD" --oneline
        Check-Git-Success

        Write-Host "`n[Step 4.3] Pushing changes to $remote $branch..." -ForegroundColor Cyan
        git push -u $remote $branch
        Check-Git-Success

        Write-Host "`nSuccessfully pushed all commits!" -ForegroundColor Green
    } else {
        Write-Host "`nNo new commits to push. Everything is up-to-date." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "`n-------------------------------------------------" -ForegroundColor Red
    Write-Host "A CRITICAL ERROR OCCURRED:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "-------------------------------------------------" -ForegroundColor Red
}
finally {
    Write-Host ""
    Read-Host "Script finished. Press Enter to exit..."
}