$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/grinchenkoedu/antigravity-skills.git"
$CloneDir = Join-Path $env:TEMP "antigravity-skills-tmp"
$TargetDir = Join-Path $HOME ".gemini\antigravity-cli\skills"

Write-Host "Fetching latest skills from $RepoUrl..."

# Clean up any previous temp directory
if (Test-Path $CloneDir) {
    Remove-Item -Recurse -Force $CloneDir
}

# Clone the repo silently
git clone --quiet --depth 1 $RepoUrl $CloneDir

Write-Host "Installing skills to $TargetDir..."

# Create target directories
if (-Not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Force $TargetDir | Out-Null
}

# Copy skills and reference, overwriting existing ones
Copy-Item -Recurse -Force (Join-Path $CloneDir "skills\*") $TargetDir
Copy-Item -Recurse -Force (Join-Path $CloneDir "reference") $TargetDir

# Clean up
Remove-Item -Recurse -Force $CloneDir

Write-Host "Installation/Update complete! Type '/' in Google Antigravity to see the skills."
