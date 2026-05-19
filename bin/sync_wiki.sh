#!/usr/bin/env bash
# Sync wiki/ staging to the GitHub Wiki repository (flat page names).
# Mapping: wiki/publish.map (keep in sync with wiki/README.md publish table).
#
# Usage:
#   bin/sync_wiki.sh              # preflight, copy, commit+push if changed
#   bin/sync_wiki.sh --dry-run    # preflight + copy; no commit/push
#   bin/sync_wiki.sh --check      # preflight + verify map vs README table only
#
# Environment:
#   WIKI_REPO_URL     default: https://github.com/osuarez1/architectures.wiki.git
#   WIKI_DIR          default: <repo>/.wiki-publish
#   WIKI_COMMIT_MSG   override full commit message (subject + optional body)
#
# Agents: do not run without explicit user request. See wiki/README.md § Publish.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${REPO_ROOT}/wiki"
MAP_FILE="${SRC_DIR}/publish.map"
README_FILE="${SRC_DIR}/README.md"
WIKI_REPO_URL="${WIKI_REPO_URL:-https://github.com/osuarez1/architectures.wiki.git}"
WIKI_DIR="${WIKI_DIR:-${REPO_ROOT}/.wiki-publish}"

DRY_RUN=0
CHECK_ONLY=0

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
}

for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --check) CHECK_ONLY=1 ;;
    *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

die() { echo "error: $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

preflight_links() {
  echo "=> Checking wiki links (no relative ../ paths)..."
  local hits
  hits="$(grep -R --include='*.md' -n '](\.\./' "${SRC_DIR}" 2>/dev/null \
    | grep -v '/README.md:' || true)"
  if [[ -n "$hits" ]]; then
    echo "$hits" >&2
    die "relative wiki links found; use [[Page-Name]] or full GitHub URLs (see wiki/README.md)"
  fi
  echo "   OK"
}

verify_readme_table() {
  [[ -f "$README_FILE" ]] || die "missing ${README_FILE}"
  [[ -f "$MAP_FILE" ]] || die "missing ${MAP_FILE}"

  echo "=> Verifying wiki/README.md publish table matches wiki/publish.map..."
  local table_lines map_lines
  table_lines="$(
    awk -F'|' '
      /^\| `wiki\// {
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        gsub(/^[ \t]+|[ \t]+$/, "", $3);
        gsub(/^`wiki\//, "", $2);
        gsub(/`$/, "", $2);
        print $2 "|" $3
      }
    ' "$README_FILE" | LC_ALL=C sort
  )"
  map_lines="$(
    grep -v '^[[:space:]]*#' "$MAP_FILE" | grep -v '^[[:space:]]*$' | LC_ALL=C sort
  )"
  if [[ "$table_lines" != "$map_lines" ]]; then
    echo "--- wiki/README.md table ---" >&2
    echo "$table_lines" >&2
    echo "--- wiki/publish.map ---" >&2
    echo "$map_lines" >&2
    die "publish table and publish.map differ; update both to match"
  fi
  echo "   OK"
}

default_commit_message() {
  local count="${1:-0}"
  shift || true
  local pages=("$@")

  if [[ "$count" -eq 0 ]]; then
    printf '%s\n' "docs(wiki): sync from architectures staging"
    return
  fi
  if [[ "$count" -eq 1 ]]; then
    printf '%s\n' "docs(wiki): sync ${pages[0]}"
    return
  fi
  local subject="docs(wiki): sync ${count} wiki pages"
  if ((${#subject} > 72)); then
    subject="docs(wiki): sync from architectures staging"
  fi
  printf '%s\n\n' "$subject"
  local page
  for page in "${pages[@]}"; do
    printf -- '- %s\n' "$page"
  done
}

wiki_commit() {
  local msg="$1"
  local subject="${msg%%$'\n'*}"
  [[ "$subject" =~ ^docs\(wiki\): ]] \
    || die "wiki commit subject must be docs(wiki): … (Conventional Commits); got: ${subject}"
  [[ "$msg" != *Co-authored-by:* && "$msg" != *Trello-Card:* ]] \
    || die "forbidden commit trailer (no Co-authored-by, no Trello-Card)"
  git -C "$WIKI_DIR" commit -m "$msg"
}

ensure_wiki_clone() {
  if [[ ! -d "$WIKI_DIR/.git" ]]; then
    echo "=> Cloning wiki repository into ${WIKI_DIR}..."
    git clone "$WIKI_REPO_URL" "$WIKI_DIR"
  else
    echo "=> Updating wiki repository..."
    git -C "$WIKI_DIR" pull --ff-only
  fi
}

copy_mappings() {
  echo "=> Copying staged files..."
  while IFS='|' read -r rel dest_base || [[ -n "${rel:-}" ]]; do
    [[ -z "${rel:-}" ]] && continue
    [[ "$rel" =~ ^[[:space:]]*# ]] && continue
    rel="${rel#"${rel%%[![:space:]]*}"}"
    rel="${rel%"${rel##*[![:space:]]}"}"
    dest_base="${dest_base#"${dest_base%%[![:space:]]*}"}"
    dest_base="${dest_base%"${dest_base##*[![:space:]]}"}"
    [[ -z "$rel" || -z "$dest_base" ]] && continue

    local src="${SRC_DIR}/${rel}"
    local dest="${WIKI_DIR}/${dest_base}.md"
    if [[ ! -f "$src" ]]; then
      echo "  warning: missing ${src}, skipping" >&2
      continue
    fi
    cp "$src" "$dest"
    echo "  ${rel} -> ${dest_base}.md"
  done < "$MAP_FILE"
}

collect_changed_pages() {
  CHANGED_PAGES=()
  while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    CHANGED_PAGES+=("${path%.md}")
  done < <(git -C "$WIKI_DIR" status --porcelain | awk '{print $2}')
}

main() {
  require_cmd git
  require_cmd awk
  require_cmd grep

  [[ -f "$MAP_FILE" ]] || die "missing ${MAP_FILE}"

  preflight_links
  verify_readme_table

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    echo "=> Check passed (no copy/push)."
    exit 0
  fi

  ensure_wiki_clone
  copy_mappings

  git -C "$WIKI_DIR" add -A

  if git -C "$WIKI_DIR" diff-index --quiet HEAD --; then
    echo "=> No changes. GitHub Wiki is up to date."
    exit 0
  fi

  collect_changed_pages

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "=> Dry run: changes in ${WIKI_DIR}; not committing."
    git -C "$WIKI_DIR" status --short
    exit 0
  fi

  local msg
  if [[ -n "${WIKI_COMMIT_MSG:-}" ]]; then
    msg="$WIKI_COMMIT_MSG"
  else
    msg="$(default_commit_message "${#CHANGED_PAGES[@]}" "${CHANGED_PAGES[@]}")"
  fi

  echo "=> Committing to GitHub Wiki..."
  wiki_commit "$msg"
  git -C "$WIKI_DIR" push
  echo "=> Wiki updated."
}

main "$@"
