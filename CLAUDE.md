# paperctl -- Conference Paper Management CLI

## Architecture

`paperctl` is a bash CLI tool for managing multiple academic paper submissions to a single conference. It handles git sync with GitHub + Overleaf, status tracking, quality checks, and dashboard generation.

### Directory Structure

```
paperctl/
  paperctl              # Main entry point (bash script)
  paperctl.d/
    lib.sh              # Core library (config, iterators, state management)
    cmd_start.sh        # Pre-session sync (saves state, then pulls)
    cmd_sync.sh         # Full bidirectional sync (pull + push, parallel support)
    cmd_push.sh         # Commit & push changed repos
    cmd_pull_overleaf.sh
    cmd_pull_upstream.sh
    cmd_check.sh        # Format compliance
    cmd_validate.sh     # Static LaTeX validation
    cmd_strip.sh        # Strip professor macros for camera-ready
    cmd_lint.sh         # Writing-style lint (BAN rules)
    cmd_preflight.sh    # Submission preflight checks
    cmd_heatmap.sh      # Per-section change heatmap
    cmd_init.sh         # Bootstrap repos from conference.json
    cmd_status.sh       # Show conference status table
    cmd_autostatus.sh   # Auto-detect paper status from section content
    cmd_pages.sh        # Extract page counts from compiled PDFs
    cmd_digest.sh       # Recent Overleaf/upstream changes
    cmd_report.sh       # Student activity report (pre/post sync diff)
    cmd_dashboard.sh    # Auto-generate README + STATUS.md dashboards
    help.txt            # CLI help text
```

### Core Concepts

1. **conference.json**: Central config file in the conference directory. Contains:
   - `conference`: name, year, slug, template, org, deadline
   - `defaults`: branch names, remote names
   - `papers[]`: array of paper objects with name, repo, overleaf URL, status, etc.

2. **for_each_paper**: Iterator in `lib.sh` that loops over all papers, calling a callback with `(repo, name, overleaf, upstream, repo_dir)`. Supports `PAPERCTL_PAPER` env var to filter to a single paper.

3. **State management**: `save_pre_sync_state()` saves HEAD SHAs to `.paperctl_state.json` before sync. `load_sync_state()` / `get_saved_sha()` read it back for diff comparison.

4. **Multi-remote sync**: Each paper repo has `origin` (GitHub) and `overleaf` (Overleaf git) remotes. Fork repos also have `upstream`. Sync pulls from all, pushes to all.

### Key Patterns

**Adding a new command:**
1. Create `paperctl.d/cmd_<name>.sh`
2. Start with flag parsing, then `load_config`
3. Use `for_each_paper` with a callback function
4. Add case to main `paperctl` script
5. Update `help.txt`

**Callback function signature:**
```bash
_my_callback() {
  local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
  # ... your logic
}
for_each_paper _my_callback
```

**JSON field access:**
```bash
paper_field $index "name"      # returns paper name
paper_field $index "status"    # returns status string
_jq "$CONF_FILE" '.conference.deadline'
```

**Updating conference.json:**
```bash
python3 -c "
import json
with open('$CONF_FILE') as f: data = json.load(f)
for p in data['papers']:
    if p['name'] == '$name':
        p['field'] = 'new_value'
with open('$CONF_FILE', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
"
```

### Sync Command Flags

- `--parallel`: Run all paper syncs concurrently (background subshells, temp log files)
- `--auto-resolve`: On merge conflict, take theirs (`git checkout --theirs`)
- `--paper <name>` / `--repo <name>`: Operate on single paper only

### Status Detection Heuristic (autostatus)

Scans `.tex` files in `sections/`, `Sections/`, or `ECCV_submission/sections/`:
- `early`: All section files are stubs (<=5 non-comment lines)
- `outline`: At least 1 section with content (>30 lines)
- `draft`: 2+ content sections, >100 total lines
- `near-complete`: 3+ content sections, >300 total lines
- `complete`: intro + method + experiments all have substantial content

### Dashboard Generation

`cmd_dashboard.sh` generates:
- **README.md** (`--output`): Markdown table with batch, paper name, OR ID, pages, status emoji, compile status, Claude project status, next steps
- **STATUS.md** (`--status`): Same progress table plus Quick Stats (Claude project count, knowledge upload count)

### Dependencies

- `git` (required)
- `jq` or `python3` (one required, for JSON parsing)
- `pdflatex` + `bibtex` (optional, for `--compile` flag)
- `mdls` or `pdfinfo` (optional, for page count extraction on macOS/Linux)

### Testing

```bash
# Test individual commands
paperctl status --dir /path/to/conference
paperctl autostatus --dir /path/to/conference
paperctl pages --dir /path/to/conference
paperctl sync --repo elsa --dir /path/to/conference
paperctl dashboard --status /tmp/test.md --dir /path/to/conference
```

### Common Issues

- **macOS case-insensitive filesystem**: `Sections/` and `sections/` are the same directory. Git tracks case but filesystem does not.
- **Large image warnings**: Sync warns about files >2MB in `figures/` or `Figures/`. Suggest converting to PDF.
- **Overleaf push**: Overleaf uses `master` branch. Push with `git push overleaf main:master`.
- **`local` keyword**: Only use inside functions, not at script top level.
