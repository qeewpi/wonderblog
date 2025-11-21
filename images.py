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