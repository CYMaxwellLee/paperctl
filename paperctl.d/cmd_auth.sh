#!/bin/bash
# paperctl.d/cmd_auth.sh -- Seed git credentials so push/pull never prompt for a password.
#
# Root cause this fixes: HTTPS git remotes prompt for a password on every push unless a
# credential helper is configured AND seeded. gh may be logged in, yet git was never told to
# use it, so each push falls back to an interactive prompt (and background/parallel pushes
# stall on an invisible prompt). This command:
#   1. runs `gh auth setup-git`        -> git uses gh's token for github.com (all platforms)
#   2. sets a platform credential helper (osxkeychain on macOS)
#   3. seeds github.com into the helper with the existing gh token (zero prompts)
#   4. probes each paper's origin + overleaf remotes read-only and reports PASS/FAIL
#
# It does NOT overwrite a working Overleaf credential: Overleaf git uses its own token, not
# the GitHub one, so we only PROBE overleaf and advise if it is not already cached.
#
# Idempotent and safe to run repeatedly. Called once per session by `paperctl start`.
#
# Usage: paperctl auth [--quiet]

QUIET=false
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --quiet) QUIET=true; shift ;;
    *) break ;;
  esac
done
_say() { $QUIET || echo "$@"; }

# --- Platform credential helper ---
HELPER=""
STORE=""
case "$(uname -s)" in
  Darwin) HELPER="osxkeychain"; STORE="git credential-osxkeychain store" ;;
  *)
    if [[ -x /usr/lib/git-core/git-credential-libsecret ]]; then
      HELPER="libsecret"; STORE="/usr/lib/git-core/git-credential-libsecret store"
    else
      HELPER="cache --timeout=86400"; STORE=""
    fi ;;
esac

_say ""
_say "🔑 Git credential setup"

# --- 1. gh auth setup-git (cross-platform github.com helper) ---
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  gh auth setup-git >/dev/null 2>&1 || true
  _say "  ✅ gh auth setup-git (github.com uses gh token)"
  GH_TOK=$(gh auth token 2>/dev/null || echo "")
  GH_ACCT=$(gh api user --jq .login 2>/dev/null || echo "git")
else
  GH_TOK=""; GH_ACCT="git"
  _say "  ⚠️  gh not logged in -- run 'gh auth login' then 'paperctl auth' (github will still prompt until then)"
fi

# --- 2. Set + seed the platform helper (macOS keychain stores the token permanently) ---
if [[ -n "$HELPER" ]]; then
  CUR=$(git config --global credential.helper 2>/dev/null || echo "")
  if [[ "$CUR" != "$HELPER" ]]; then
    git config --global credential.helper "$HELPER"
    _say "  ✅ credential.helper = $HELPER"
  else
    _say "  ✅ credential.helper already = $HELPER"
  fi
  if [[ -n "$GH_TOK" && -n "$STORE" ]]; then
    printf 'protocol=https\nhost=github.com\nusername=%s\npassword=%s\n\n' "$GH_ACCT" "$GH_TOK" | $STORE 2>/dev/null || true
    printf 'protocol=https\nhost=gist.github.com\nusername=%s\npassword=%s\n\n' "$GH_ACCT" "$GH_TOK" | $STORE 2>/dev/null || true
    _say "  ✅ seeded github.com into $HELPER (account: $GH_ACCT)"
  fi
fi

# --- 3. Probe remotes read-only (only if a conference.json is reachable) ---
HAVE_CONF=false
if [[ -n "${PAPERCTL_DIR:-}" && -f "$PAPERCTL_DIR/conference.json" ]]; then
  HAVE_CONF=true
else
  _d="$PWD"
  while [[ "$_d" != "/" ]]; do
    if [[ -f "$_d/conference.json" ]]; then HAVE_CONF=true; break; fi
    _d=$(dirname "$_d")
  done
fi

if $HAVE_CONF && ! $QUIET; then
  load_config
  _auth_probe() {
    local repo="$1" name="$2" overleaf="$3" upstream="$4" repo_dir="$5"
    if git -C "$repo_dir" remote | grep -q '^origin$'; then
      if GIT_TERMINAL_PROMPT=0 git -C "$repo_dir" ls-remote origin -h >/dev/null 2>&1; then
        _say "  ✅ $name: origin (GitHub) no-prompt OK"
      else
        _say "  ❌ $name: origin (GitHub) still needs auth"
      fi
    fi
    if git -C "$repo_dir" remote | grep -q "^${CONF_OVERLEAF_REMOTE}\$"; then
      if GIT_TERMINAL_PROMPT=0 git -C "$repo_dir" ls-remote "$CONF_OVERLEAF_REMOTE" -h >/dev/null 2>&1; then
        _say "  ✅ $name: overleaf no-prompt OK"
      else
        _say "  ⚠️  $name: overleaf token not cached -- push once manually to store it (uses Overleaf's own token, not GitHub's)"
      fi
    fi
  }
  $QUIET || echo ""
  for_each_paper _auth_probe
fi

_say ""
$QUIET || echo "Done. Future push/pull will not prompt for a GitHub password."
