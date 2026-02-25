# paperctl

Config-driven CLI for managing multi-repo conference paper workflows with **GitHub + Overleaf** bidirectional sync.

Built for research labs juggling multiple paper submissions across conferences (ECCV, NeurIPS, CVPR, ...) with a mix of original and forked student repos.

## Features

- **Bidirectional sync** — GitHub ↔ Local ↔ Overleaf in one command
- **Fork-aware** — auto-merge from upstream student repos
- **Format compliance checker** — pluggable per-conference templates (ECCV, CVPR, NeurIPS)
- **Config-driven** — one `conference.json` per conference, zero hardcoded paths
- **Fully portable** — works on any machine, any directory layout

## Data Flow

```
  upstream (student)          origin (GitHub org)
        │                           │
        │  pull-upstream            │  push / pull
        ▼                           ▼
     ┌─────────────────────────────────┐
     │           LOCAL REPO            │
     │  (~/Project/Papers/eccv2026/)   │
     └─────────────────────────────────┘
                    │
                    │  push / pull (main:master)
                    ▼
            overleaf (Overleaf Git)
```

## Installation

```bash
# 1. Clone — pick any path you like
git clone https://github.com/CYMaxwellLee/paperctl.git ~/Project/paperctl
#   other common choices:
#   git clone ... ~/paperctl
#   git clone ... /opt/paperctl

# 2. Symlink to PATH (use the path you chose above)
ln -sf ~/Project/paperctl/paperctl /usr/local/bin/paperctl

# 3. Install jq (recommended, python3 works as fallback)
brew install jq          # macOS
# apt install jq         # Ubuntu/Debian
```

> **Note:** paperctl resolves its own install location via symlinks at runtime — you can clone it anywhere and the tool will find its `paperctl.d/` directory automatically.

## Quick Start

```bash
# 1. Create a conference workspace
mkdir ~/Project/Papers/eccv2026
cp "$(dirname "$(which paperctl)")/examples/conference.json.example" \
   ~/Project/Papers/eccv2026/conference.json
# Edit conference.json — fill in your papers, Overleaf URLs, etc.

# 2. Bootstrap (clone repos, set up remotes)
cd ~/Project/Papers/eccv2026
paperctl init

# 3. Daily workflow
paperctl start                        # pre-session sync
# ... edit papers on Overleaf or locally ...
paperctl push "fix: abstract typo"    # commit & push to GitHub + Overleaf
paperctl check                        # format compliance check
paperctl status                       # dashboard
```

## Commands

| Command | Description |
|---------|-------------|
| `paperctl start` | Pull all remotes (run before every work session) |
| `paperctl sync` | Full bidirectional sync (pull + push all remotes) |
| `paperctl push [msg]` | Commit & push repos that have local changes |
| `paperctl pull-overleaf` | Pull latest from Overleaf only |
| `paperctl pull-upstream` | Pull from upstream (fork repos only) |
| `paperctl check` | Run format compliance checks |
| `paperctl init` | Bootstrap repos from `conference.json` |
| `paperctl status` | Show conference dashboard & paper status |
| `paperctl help` | Show usage help |

### Global Flags

| Flag | Description |
|------|-------------|
| `--dir <path>` | Path to conference directory (default: `$PWD`) |
| `--paper <name>` | Operate on a single paper only |

### Examples

```bash
# Push a single paper
paperctl push --paper elsa "fix: Table 1 caption"

# Check format for one paper
paperctl check --paper ivl

# Operate from a different directory
paperctl status --dir ~/Project/Papers/neurips2025
```

## `conference.json` Reference

Each conference workspace needs a `conference.json` at its root. See [`examples/conference.json.example`](examples/conference.json.example) for a full annotated template.

### Top-level Structure

```json
{
  "conference": { ... },
  "defaults": { ... },
  "papers": [ ... ]
}
```

### `conference` Section

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Conference name (e.g. `"ECCV"`) |
| `year` | ✅ | Year (e.g. `2026`) |
| `slug` | ✅ | Directory/ID slug (e.g. `"eccv2026"`) |
| `template` | ✅ | Format checker template name — maps to `templates/{name}.checks.sh` |
| `org` | ✅ | GitHub org or user (e.g. `"ElsaLab-2026"`) |
| `template_repo` | ❌ | Official LaTeX template repo URL (used by `init` to copy style files) |
| `deadline` | ❌ | Submission deadline ISO 8601 (shown in `status`) |

### `defaults` Section

| Field | Default | Description |
|-------|---------|-------------|
| `github_branch` | `"main"` | Local branch name |
| `overleaf_branch` | `"master"` | Overleaf branch name |
| `overleaf_remote` | `"overleaf"` | Git remote name for Overleaf |
| `upstream_remote` | `"upstream"` | Git remote name for upstream (forks) |
| `upstream_branch` | `""` (auto) | Upstream branch; empty = try `main` then `master` |

### `papers` Array

| Field | Required | Description |
|-------|----------|-------------|
| `name` | ✅ | Short name used with `--paper` flag |
| `repo` | ✅ | GitHub repo name (under `org`) |
| `overleaf` | ✅ | Overleaf Git URL (`https://git.overleaf.com/PROJECT_ID`) |
| `upstream` | ❌ | Upstream GitHub path (`user/repo`) — presence marks this as a fork |
| `paper_id` | ❌ | Submission ID from OpenReview/CMT |
| `title` | ❌ | Paper title |
| `domain` | ❌ | Research domain |
| `status` | ❌ | Progress status (`early`, `outline`, `near-complete`, `complete`) |

## Switching to a New Conference

paperctl is designed so that switching conferences requires **zero code changes** — just a new `conference.json`:

```bash
# 1. Create workspace
mkdir ~/Project/Papers/neurips2025

# 2. Create config
cp "$(dirname "$(which paperctl)")/examples/conference.json.example" \
   ~/Project/Papers/neurips2025/conference.json
# Edit: change conference name/year/slug/template/org, add your papers

# 3. Bootstrap
cd ~/Project/Papers/neurips2025
paperctl init

# 4. Work!
paperctl start
```

Multiple conferences coexist side-by-side — just `cd` to the right directory (or use `--dir`).

### Supported Format Templates

| Template | Conference | Checks |
|----------|-----------|--------|
| `eccv` | ECCV (llncs + eccv.sty) | 13 checks |
| `cvpr` | CVPR / ICCV (cvpr.sty) | 10 checks |
| `neurips` | NeurIPS (neurips.sty) | 8 checks |

Set the `template` field in `conference.json` to match.

## New Computer Migration

### Method A: Clean Re-init (Recommended)

```bash
# 1. Install paperctl (clone to any path you prefer)
git clone https://github.com/CYMaxwellLee/paperctl.git ~/Project/paperctl
ln -sf ~/Project/paperctl/paperctl /usr/local/bin/paperctl
brew install jq

# 2. Set up Git credential storage
git config --global credential.helper store

# 3. Set up GitHub authentication
#    Create a PAT at https://github.com/settings/tokens
#    It will be cached on first git push

# 4. Set up Overleaf authentication
#    Go to: Overleaf → Account Settings → Git Integration
#    Generate a "Git Authentication Token" (starts with olp_)
#    When prompted by git: username = "git", password = your olp_ token

# 5. Copy conference.json from old machine
mkdir ~/Project/Papers/eccv2026
scp old-mac:~/Project/Papers/eccv2026/conference.json \
    ~/Project/Papers/eccv2026/

# 6. Bootstrap everything
cd ~/Project/Papers/eccv2026
paperctl init      # clones all repos, sets up all remotes
paperctl start     # syncs all content from GitHub + Overleaf
```

### Method B: Direct Copy (faster, no re-clone)

```bash
# 1. Install paperctl (same as above)

# 2. Copy entire conference directory
rsync -avz old-mac:~/Project/Papers/eccv2026/ \
    ~/Project/Papers/eccv2026/

# 3. Set up credentials (same as steps 2-4 above)

# 4. Verify
cd ~/Project/Papers/eccv2026
paperctl status
paperctl start
```

### Important Notes

- **Overleaf tokens** (`~/.git-credentials`) are per-machine — regenerate on each new computer
- **GitHub PATs** in `.mcp.json` or remote URLs are sensitive — never commit them
- SSH keys need to be set up separately if you use SSH authentication

## Writing a New Format Template

To add support for a new conference, create `paperctl.d/templates/{name}.checks.sh`:

```bash
#!/bin/bash
# Template: {name}

run_checks() {
  local repo_dir="$1" main_tex="$2" all_tex="$3"
  local tex_dir
  tex_dir=$(dirname "$main_tex")

  # Use these helpers from lib_check.sh:
  #   check_pass "message"   — ✅ passed
  #   check_warn "message"   — ⚠️ warning
  #   check_fail "message"   — ❌ failed
  #   check_info "message"   — ℹ️ info

  # Example check:
  if echo "$all_tex" | grep -q '\\documentclass.*{article}'; then
    check_pass "Document class: article"
  else
    check_fail "Wrong document class"
  fi

  # Add more checks...
}
```

Set `"template": "{name}"` in your `conference.json` and `paperctl check` will use it.

## Requirements

- **git** (required)
- **jq** (recommended) or **python3** (fallback for JSON parsing)
- **bash** 4+ (macOS default or Homebrew bash)
- macOS or Linux

## License

MIT
