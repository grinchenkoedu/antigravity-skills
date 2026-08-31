$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/grinchenkoedu/antigravity-skills.git"
$CloneDir = Join-Path $env:TEMP "antigravity-skills-tmp"
$TargetDir = Join-Path $HOME ".gemini\skills"
$CliSkillsDir = Join-Path $HOME ".gemini\antigravity-cli\skills"
$ConfigSkillsDir = Join-Path $HOME ".gemini\config\skills"

# Directory names used before the gku- prefix was introduced. Removed on install so a
# renamed skill does not linger beside its replacement and load twice.
$LegacyNames = @("review", "plan", "implement", "pr-review", "pr-resolve", "verify", "reference", "init", "pr", "fix")

# Determine source: use local repo if run from within the clone, else fetch from git
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "skills")) -and (Test-Path (Join-Path $ScriptDir "gku-reference"))) {
    $SrcDir = $ScriptDir
    Write-Host "Installing skills from local source ($SrcDir)..."
} else {
    Write-Host "Fetching latest skills from $RepoUrl..."
    if (Test-Path $CloneDir) {
        Remove-Item -Recurse -Force $CloneDir
    }
    git clone --quiet --depth 1 $RepoUrl $CloneDir
    $SrcDir = $CloneDir
}

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
Copy-Item -Recurse -Force (Join-Path $SrcDir "skills\*") $TargetDir
$TargetRefDir = Join-Path $TargetDir "gku-reference"
if (Test-Path $TargetRefDir) {
    Remove-Item -Recurse -Force $TargetRefDir
}
Copy-Item -Recurse -Force (Join-Path $SrcDir "gku-reference") $TargetDir

# Link to Antigravity CLI and config workspace skill directories if needed
foreach ($aliasDir in @($CliSkillsDir, $ConfigSkillsDir)) {
    $parent = Split-Path -Parent $aliasDir
    if (-Not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force $parent | Out-Null
    }

    $isLinked = $false
    # If aliasDir exists as a directory (not symlink/junction), remove it to try symlink/junction
    if (Test-Path $aliasDir) {
        $item = Get-Item $aliasDir -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)) {
            $isLinked = $true
        } else {
            Remove-Item -Recurse -Force $aliasDir -ErrorAction SilentlyContinue
        }
    }

    if (-Not $isLinked) {
        try {
            New-Item -ItemType SymbolicLink -Path $aliasDir -Target $TargetDir -ErrorAction Stop | Out-Null
            $isLinked = $true
        } catch {
            try {
                New-Item -ItemType Junction -Path $aliasDir -Target $TargetDir -ErrorAction Stop | Out-Null
                $isLinked = $true
            } catch {
                # Fall back to copying all skills and references directly into the alias directory
                if (-Not (Test-Path $aliasDir)) {
                    New-Item -ItemType Directory -Force $aliasDir | Out-Null
                }
                Copy-Item -Recurse -Force (Join-Path $TargetDir "*") $aliasDir
            }
        }
    }
}

# Clean up temporary clone if one was made
if ($SrcDir -eq $CloneDir) {
    Remove-Item -Recurse -Force $CloneDir
}

Write-Host "Installation/Update complete! Type '/' in Google Antigravity to see the skills."
Write-Host "Available skills: /gku-init, /gku-plan, /gku-implement, /gku-fix, /gku-review,"
Write-Host "/gku-pr, /gku-pr-review, /gku-pr-resolve, /gku-verify."
