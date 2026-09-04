# sync-repos.ps1 — sync all git repos in the workspace to their non-prod branch
# Usage:
#   .\sync-repos.ps1              # sync all repos
#   .\sync-repos.ps1 -DryRun      # report only, no changes
#   .\sync-repos.ps1 -Repo NAME   # sync a single repo by directory name

param(
    [switch]$DryRun,
    [string]$Repo = ""
)

$ErrorActionPreference = "Stop"

$WorkspaceRoot = (Get-Location).Path
$Timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$Results = @()

# ---------------------------------------------------------------
# Determine the non-prod branch for a given repo directory.
# Reads remote branches and excludes main/master.
# Returns empty string if none found (caller handles this).
# ---------------------------------------------------------------
function Get-NonProdBranch {
    param([string]$RepoDir)

    $Preferred = @("develop", "staging", "pre-prod", "preprod", "uat", "test")

    # fetch remote branches quietly
    git -C $RepoDir fetch --quiet 2>$null

    $RemoteBranches = git -C $RepoDir branch -r 2>$null |
        ForEach-Object { $_.Trim() -replace "^origin/", "" } |
        Where-Object { $_ -notmatch "^HEAD$|^main$|^master$" }

    foreach ($Branch in $Preferred) {
        if ($RemoteBranches -contains $Branch) {
            return $Branch
        }
    }

    return ""
}

# ---------------------------------------------------------------
# Sync a single repo
# ---------------------------------------------------------------
function Sync-Repo {
    param([string]$RepoDir)

    $RepoName = Split-Path $RepoDir -Leaf
    $TargetBranch = Get-NonProdBranch -RepoDir $RepoDir

    if ([string]::IsNullOrEmpty($TargetBranch)) {
        $script:Results += "[UNKNOWN] $RepoName | Could not determine non-prod branch -- needs manual discovery"
        return
    }

    if ($DryRun) {
        $script:Results += "[DRY RUN] $RepoName | would sync to '$TargetBranch'"
        return
    }

    # stash any uncommitted changes
    $StashMsg = "sync-repos auto-stash $Timestamp"
    $StashOutput = git -C $RepoDir stash push -m $StashMsg 2>&1
    $Stashed = $StashOutput -match "Saved working directory"

    # checkout and pull
    $CheckoutOutput = git -C $RepoDir checkout $TargetBranch --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        $script:Results += "[ERROR]   $RepoName | could not checkout '$TargetBranch'"
        return
    }

    $PullOutput = git -C $RepoDir pull --ff-only --quiet 2>&1
    if ($LASTEXITCODE -ne 0) {
        $script:Results += "[ERROR]   $RepoName | pull --ff-only failed on '$TargetBranch' (diverged or conflict)"
        return
    }

    if ($Stashed) {
        $script:Results += "[STASHED] $RepoName | synced to '$TargetBranch' -- run 'git stash pop' to restore changes"
    } else {
        $script:Results += "[OK]      $RepoName | '$TargetBranch' is up to date"
    }
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------
Get-ChildItem -Path $WorkspaceRoot -Directory | ForEach-Object {
    $Dir = $_.FullName
    if (-not (Test-Path (Join-Path $Dir ".git"))) { return }
    $RepoName = $_.Name
    if ($Repo -ne "" -and $RepoName -ne $Repo) { return }
    Sync-Repo -RepoDir $Dir
}

# Print results
Write-Host ""
Write-Host "--- sync-repos result ---"
foreach ($Line in $Results) {
    Write-Host "  $Line"
}
Write-Host ""
