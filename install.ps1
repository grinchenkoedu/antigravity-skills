$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/grinchenkoedu/antigravity-skills.git"
$CloneDir = Join-Path $env:TEMP "antigravity-skills-tmp"
$TargetDir = Join-Path $HOME ".gemini\skills"

# Directory names used before the gku- prefix was introduced. Removed on install so a
# renamed skill does not linger beside its replacement and load twice.
$LegacyNames = @("review", "plan", "implement", "pr-review", "pr-resolve", "verify", "reference")

Write-Host "Fetching latest skills from $RepoUrl..."

# Clean up any previous temp directory
if (Test-Path $CloneDir) {
    Remove-Item -Recurse -Force $CloneDir
}

# Clone the repo silently
git clone --quiet --depth 1 $RepoUrl $CloneDir

Write-Host "Installing skills to $TargetDir..."

if (-Not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Force $TargetDir | Out-Null
}

# Remove earlier, unprefixed copies of these skills — but only ones that are recognisably
# ours. A directory called "review" could easily belong to a different toolkit, and deleting
# someone else's work would be a far worse outcome than leaving a stale copy behind.
foreach ($name in $LegacyNames) {
    $legacy = Join-Path $TargetDir $name
    if (-Not (Test-Path $legacy)) { continue }
    $looksLikeOurs = Get-ChildItem -Recurse -File $legacy -ErrorAction SilentlyContinue |
        Select-String -Pattern "repo-profile" -List -ErrorAction SilentlyContinue
    if ($looksLikeOurs) {
        Write-Host "  removing previous unprefixed copy: $name"
        Remove-Item -Recurse -Force $legacy
    } else {
        Write-Host "  NOTE: $legacy exists but does not look like ours - leaving it alone."
        Write-Host "        If it is a leftover from an older install, remove it by hand."
    }
}

# Copy skills and the shared reference, overwriting existing ones
Copy-Item -Recurse -Force (Join-Path $CloneDir "skills\*") $TargetDir
Copy-Item -Recurse -Force (Join-Path $CloneDir "gku-reference") $TargetDir

# Clean up
Remove-Item -Recurse -Force $CloneDir

Write-Host "Installation/Update complete! Type '/' in Google Antigravity to see the skills."
Write-Host "They are prefixed: /gku-plan, /gku-implement, /gku-review, /gku-pr-review,"
Write-Host "/gku-pr-resolve, /gku-verify."
