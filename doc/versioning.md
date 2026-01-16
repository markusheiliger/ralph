# Ralph CLI - Versioning

Ralph uses [Semantic Versioning](https://semver.org/) (SemVer) with git tags to manage releases.

## Version Format

```
MAJOR.MINOR.PATCH
```

- **MAJOR**: Incompatible API/CLI changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

## Creating a Stable Release

### Quick Copy-Paste

```bash
# Replace X.Y.Z with your version number
git checkout main && git pull origin main
git tag -a vX.Y.Z -m "Release vX.Y.Z: Brief description"
git push origin vX.Y.Z
```

### Step-by-Step

#### 1. Ensure you're on the main branch

```bash
git checkout main
git pull origin main
```

#### 2. Create an annotated tag

```bash
git tag -a v1.0.0 -m "Release v1.0.0: Brief description"
```

#### 3. Push the tag to GitHub

```bash
git push origin v1.0.0
```

This triggers the release workflow which will:
- Package the `/src` folder as a tarball (`ralph-1.0.0.tar.gz`)
- Create a GitHub release tagged `v1.0.0`
- Mark it as the **latest** stable release

## Preview Releases

Preview releases are **automatically created** when changes are pushed to the `main` branch that affect files in `/src`. No manual action required!

### Version Format

```
0.0.0-preview.YYYYMMDDHHMMSS
```

### Manual Preview Release (Optional)

If you want to manually trigger a preview release:

```bash
# Push changes to main branch
git checkout main
git add .
git commit -m "Your changes"
git push origin main
```

Or trigger the workflow manually from the GitHub Actions tab using "workflow_dispatch".

Preview releases are marked as **pre-releases** on GitHub and can be installed with:

```bash
curl -fsSL https://raw.githubusercontent.com/markusheiliger/ralph/refs/heads/main/install.sh | bash -s -- --preview
```

## Version Examples

| Change Type | Example | Version Bump |
|:------------|:--------|:-------------|
| Breaking CLI change | Renamed `--story` to `--new` | `1.0.0` → `2.0.0` |
| New feature | Added `--verbose` option | `1.0.0` → `1.1.0` |
| Bug fix | Fixed path resolution | `1.0.0` → `1.0.1` |

## Listing Existing Tags

```bash
# List all tags
git tag

# List tags with messages
git tag -n

# List tags matching a pattern
git tag -l "v1.*"
```

## Deleting a Tag (if needed)

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

> **Note:** Avoid deleting tags for releases that have already been published and used by others.
