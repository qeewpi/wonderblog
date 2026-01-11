---
title: Creating my blog with Obsidian, the Zettelkasten System, and Hugo
date: 2025-11-15T17:57:30+08:00
lastmod: 2026-01-11T20:15:00+08:00
draft: false
tags:
---
*Took me a while, but here I am, documenting my entire process – from my note-taking system to the creation of my blog. Hopefully this comes helpful to anyone who may come across this.*

## Obsidian
A few months ago I began utilizing Obsidian for my note-taking. It initially served my needs sufficiently. However, it came to a point where I felt a need for a more "concrete" system – one that essentially allowed me to have a "wiki" for my knowledge as well as improve my ability to synthesize new ideas.

I came across the concept of the Zettelkasten system through [Odyseas' video](https://www.youtube.com/watch?v=hSTy_BInQs8), where he provides an in-depth guide on how he set up his note-taking system in Obsidian. Since then, I've been using this system, with just the slightest alterations to fit my workflow.

### The Setup for the Blog 
I created a new folder in my vault labeled "008 - Posts". The name is pretty self-explanatory – this is where I will be storing all my blogposts. 

![Pasted image 20251115195649](/attachments/Pasted%20image%2020251115195649.png)

In the near future, I plan on improving the integration of Hugo with Obsidian through [oscarmlage's](https://oscarmlage.com/posts/hugo-and-obsidian/) method.

For now, let's keep things simple.
## Hugo
The idea of creating a blog to publish my write-ups has been looming in my mind since forever. A multitude of events have gotten in the way, but, alas, I'm *finally* getting to it.

While working on a side project, I watched Den Delimarsky's video on the GitHub Spec Kit. In the video, he used his own [blog](https://den.dev/) as a demonstration. I was in awe at how seamless his process for content creation was – through it, I discovered Hugo. 

For a long time, I've been planning to have a simple and straight-forward solution for my blog. As I was already utilizing Obsidian, being able to publish through the Markdown format was especially crucial to my ideal workflow. Hugo fit the criteria perfectly, at this point, it was a *no-brainer* decision.
### Prerequisites
- Go
- Git

### Setting up the directory

I created a new folder for my Hugo website, within that I made sure to create a "src" folder to store the actual contents.

```powershell
mkdir "C:\Users\Ashley-PC\Documents\wonderblog"
cd "C:\Users\Ashley-PC\Documents\wonderblog"
mkdir src
```

### Installation

I was facing issues setting up Docker on my Windows machine, thus, I decided to proceed with installing (using `Chocolatey`) and running Hugo directly on my machine.

```powershell
choco install hugo-extended
```

### Create a new site

With in the `src` directory, I initialized a new Hugo site.

```powershell
hugo new site .
```

### Creating the Git repository

```powershell
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/qeewpi/wonderblog.git
git push -u origin main
```

### Installing Congo theme

I followed the installation steps from the [Congo repository](https://github.com/jpanther/congo) as well as configured the theme to my liking.

### Syncing Obsidian with Hugo

To seamlessly edit my Hugo content directly from Obsidian, I've set up a workflow that uses a symbolic link (`mklink`). This allows me to see and edit my Hugo posts as a regular folder within my Obsidian vault, ensuring that any changes are instantly reflected in my Hugo project.

```powershell
mklink /D "008 - Posts" "C:\Users\Ashley-PC\Documents\wonderblog\src\content\posts"
```

### Creating new blogposts from within Obsidian

To instantly be able to create new blogposts, I utilized the `Templater` community plugin. The following template automates creating a properly structured Hugo Page Bundle (/posts/my-new-post/index.md).

Here is the full Templater script for creating a new post:

```javascript
<%*
// This function creates a URL-friendly "slug" from the post title.
function toSlug(title) {
    return title
        .toLowerCase()
        .normalize("NFD")
        .replace(/[\u0300-\u036f]/g, "")
        .replace(/[^a-z0-9\s-]/g, "")
        .trim()
        .replace(/\s+/g, "-");
}

let qcFileName = tp.file.title;
if (qcFileName.startsWith("Untitled")) {
	qcFileName = await tp.system.prompt("Post Title");
}
// Create the slug from the user-provided title
let titleSlug = toSlug(qcFileName);
// Rename the temporary file to 'index.md' to conform to Hugo's Page Bundle structure
await tp.file.rename("index");

// Move the 'index.md' file into a new folder named after the slug
// within the '008 - Posts' symlinked directory.
await tp.file.move("008 - Posts/" + titleSlug + "/index");
-%>
---
title: "<% qcFileName %>"
date: <% tp.file.creation_date("YYYY-MM-DDTHH:mm:ssZ") %>
draft: false
tags: []
---
```

#### Utilizing scripts for reducing friction

Here's my current workflow for publishing:

1. Write posts in Obsidian using the Templater template
2. Run `publish.ps1` - this orchestrates the entire publishing pipeline
3. The site automatically deploys via GitHub Pages

##### How the Scripts Work Together

```
┌─────────────────────┐
│  Write in Obsidian  │
│  (008 - Posts)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   publish.ps1       │ ◄── You run this one command
└──────────┬──────────┘
           │
           ├──────────────────────┐
           ▼                      ▼
┌──────────────────┐    ┌──────────────────┐
│   images.py      │    │  sync-posts.ps1  │
│                  │    │                  │
│ • Copy images    │    │ • Git commit     │
│ • Fix links      │    │ • Git push       │
└──────────────────┘    └──────────────────┘
           │                      │
           └──────────┬───────────┘
                      ▼
           ┌──────────────────┐
           │  Live on GitHub  │
           └──────────────────┘
```

`publish.ps1` orchestrates the entire pipeline in two steps:
- **Step 1:** Runs `images.py` to copy images and fix links
- **Step 2:** Runs `sync-posts.ps1` to commit and push changes

Let me break down what each script does:

---

##### `images.py` - Image Asset Management

**Purpose:** Ensures all images referenced in my blog posts are present in the Hugo project and properly linked.

**What it does:**
- Scans all markdown files for image references
- Copies missing images from Obsidian's `000 - Attachments` to Hugo's `src/content/attachments`
- Standardizes links to `![alt-text](/attachments/filename.ext)` format
- Handles URL-encoded filenames and auto-generates alt-text

**Key code snippet:**
```python
# Check if image exists in Hugo destination
destination_file = os.path.join(hugo_attachments_destination, image_filename_decoded)

if not os.path.exists(destination_file):
    # File is missing - copy from Obsidian
    source_file = os.path.join(obsidian_attachments_source, image_filename_decoded)
    if os.path.exists(source_file):
        print(f"AUDIT FAIL: '{image_filename_decoded}' is missing. Copying from source...")
        shutil.copy2(source_file, destination_file)

# Standardize the link format
correct_link = f"![{alt_text}]({hugo_final_url_path}{image_filename_encoded})"
```

<details>
<summary>📄 View full script</summary>

```python
import os
import re
import shutil
from urllib.parse import unquote

# --- Configuration ---
posts_dir = r"C:\Users\Ashley-PC\Documents\wonderblog\src\content\posts"
obsidian_attachments_source = r"C:\Users\Ashley-PC\Documents\Ashley in Wonderland\000 - Attachments"
hugo_attachments_destination = r"C:\Users\Ashley-PC\Documents\wonderblog\src\content\attachments"
hugo_final_url_path = "/attachments/" # The final URL path for links

# Regex to find all standard Markdown image links
pattern = re.compile(r"!\[(.*?)\]\((.*?)\)")

# --- Main Logic ---
os.makedirs(hugo_attachments_destination, exist_ok=True)
print(f"Hugo attachments destination: {hugo_attachments_destination}")
print(f"Scanning for posts in: {posts_dir}\n")

processed_files_count = 0

for root, _, filenames in os.walk(posts_dir):
    for filename in filenames:
        if filename.endswith(".md"):
            filepath = os.path.join(root, filename)
            
            try:
                with open(filepath, "r", encoding="utf-8") as file:
                    content = file.read()
                original_content = content
                
                for match in pattern.finditer(original_content):
                    original_full_link = match.group(0)
                    alt_text = match.group(1)
                    image_path = match.group(2)

                    # --- Universal Logic: Extract filename, Audit, Fix ---

                    # 1. EXTRACT the clean filename, no matter the original path format
                    image_filename_encoded = os.path.basename(image_path)
                    image_filename_decoded = unquote(image_filename_encoded)
                    
                    # 2. AUDIT: Check if the physical file exists in the Hugo destination
                    destination_file = os.path.join(hugo_attachments_destination, image_filename_decoded)
                    
                    if not os.path.exists(destination_file):
                        # File is MISSING. Let's find and copy it.
                        source_file = os.path.join(obsidian_attachments_source, image_filename_decoded)
                        
                        if os.path.exists(source_file):
                            print(f"AUDIT FAIL: '{image_filename_decoded}' is missing. Copying from source...")
                            shutil.copy2(source_file, destination_file)
                        else:
                            print(f"ERROR: Cannot find source file for '{image_filename_decoded}' in {obsidian_attachments_source}.")
                            continue # Skip to the next image
                    
                    # 3. FIX: Ensure the link format is correct, regardless of its original state
                    if not alt_text:
                        alt_text, _ = os.path.splitext(image_filename_decoded)
                        
                    correct_link = f"![{alt_text}]({hugo_final_url_path}{image_filename_encoded})"
                    
                    if original_full_link != correct_link:
                        print(f"  -> Fixing link format for '{image_filename_decoded}'")
                        content = content.replace(original_full_link, correct_link)

                # Write changes back to the file if anything was modified
                if content != original_content:
                    with open(filepath, "w", encoding="utf-8") as file:
                        file.write(content)
                    processed_files_count += 1
            except Exception as e:
                print(f"ERROR: Could not process file {filepath}: {e}")

if processed_files_count > 0:
    print(f"\nAudit complete. Copied missing files and/or updated links in {processed_files_count} file(s).")
else:
    print("\nAudit complete. All files and links are already correct.")
```

</details>

---

##### `sync-posts.ps1` - Git Automation

**Purpose:** Automatically commits and pushes each blog post individually with meaningful commit messages.

**What it does:**
- Detects new or modified posts in `src/content/posts`
- Groups all files within each post folder (markdown + images) as a single unit
- Extracts post title from frontmatter for commit messages
- Creates semantic commits like `feat(blog): add new post 'Your Title'`
- Syncs with remote using rebase strategy

**Key code snippet:**
```powershell
# Extract title from frontmatter
foreach ($line in $content) {
    if ($line -match '^title:\s*"?([^"]+)"?') {
        $title = $matches[1].Trim()
        break
    }
}

# Determine if it's a new post or edit
$postStatus = git status $postFolder --porcelain
$commitAction = "edit"
if ($postStatus -match '^\?\?') {
    $commitAction = "add new"
}

# Create descriptive commit
$commitMsg = "feat(blog): $commitAction post '$title'"
git commit -m $commitMsg
```

**Example commit messages:**
- `feat(blog): add new post 'Creating my blog with Obsidian'`
- `feat(blog): edit post 'My First Post'`

<details>
<summary>📄 View full script</summary>

```powershell
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
                # Determine the change type BEFORE staging (untracked files show as ??)
                $postStatus = git status $postFolder --porcelain
                $commitAction = "edit" # Default to edit
                if ($postStatus -match '^\?\?') {
                    $commitAction = "add new"
                }

                # Use the clean, relative path for 'git add'
                git add "$postFolder/"
                Check-Git-Success

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
```

</details>

---

##### `publish.ps1` - Master Script

**Purpose:** One-click publishing workflow that runs the entire pipeline.

**What it does:**
- Runs `images.py` to process images
- Runs `sync-posts.ps1` to handle Git operations
- Provides error handling and stops if any step fails

```powershell
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
```

---

##### Summary of Workflow

This automation eliminates friction in my publishing process:

✅ **No manual linking of images** - Images automatically sync from Obsidian  
✅ **Automated Git operations** - Each post gets its own semantic commit  
✅ **One command to publish** - Just run `publish.ps1`  
✅ **Fail-safe** - Scripts stop immediately if errors occur  
✅ **Semantic history** - Git log shows exactly which posts were added or edited