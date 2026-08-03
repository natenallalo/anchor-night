# Deploy Flutter web preview to GitHub Pages (works when PC is off).
# Prerequisites: gh auth login
$ErrorActionPreference = "Stop"
Set-Location "$PSScriptRoot\.."

$repoName = "anchor-night"
$baseHref = "/$repoName/"

Write-Host "Building web with base-href $baseHref ..."
puro flutter build web --release --no-wasm-dry-run --base-href $baseHref

# Ensure git identity only if missing (do not rewrite existing config beyond need)
$user = gh api user --jq .login
if (-not $user) { throw "Not logged into GitHub. Run: gh auth login" }

Write-Host "Logged in as $user"

# Init commit if needed
if (-not (Test-Path .git)) { git init }

$status = git status --porcelain
$hasCommits = git rev-parse --verify HEAD 2>$null
if (-not $hasCommits) {
  git add -A
  git commit -m "Initial Anchor Night app for web preview hosting"
}

$remote = git remote get-url origin 2>$null
if (-not $remote) {
  gh repo create $repoName --public --source=. --remote=origin --push
} else {
  git push -u origin HEAD
}

# Publish build/web to gh-pages branch
$work = Join-Path $env:TEMP "anchor-night-gh-pages"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work | Out-Null
Copy-Item -Path "build\web\*" -Destination $work -Recurse -Force
Set-Location $work
git init
git checkout -b gh-pages
git add -A
git commit -m "Publish web preview"
git remote add origin "https://github.com/$user/$repoName.git"
git push -f origin gh-pages

gh api -X POST "repos/$user/$repoName/pages" -f "build_type=legacy" -f "source[branch]=gh-pages" -f "source[path]=/" 2>$null

$url = "https://$user.github.io/$repoName/"
Write-Host ""
Write-Host "Public URL (works when PC is off):"
Write-Host $url
Write-Host "Onboarding: ${url}?preview=onboarding"
Write-Host "Night:      ${url}?preview=night"
Write-Host "Grounding:  ${url}?preview=grounding"
Write-Host "Morning:    ${url}?preview=morning"
