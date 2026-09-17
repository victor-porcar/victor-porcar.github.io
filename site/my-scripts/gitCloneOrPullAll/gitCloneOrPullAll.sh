#!/usr/bin/env bash
#
# Clone or update every repository of a GitHub user.
#
#   gitCloneOrPullAll.sh <USER_NAME> <LOCAL_DIRECTORY>
#
# The token is never passed on the command line: it is read from $GITHUB_TOKEN
# or from ~/.config/github-token. An argument would end up in the shell history
# and be visible in `ps` to every user on the machine while the script runs.
#
# Repositories are cloned over SSH, so no credential is ever written into the
# .git/config of the clones. Set CLONE_PROTOCOL=https to use HTTPS instead and
# let git's own credential helper deal with authentication.

set -euo pipefail

TOKEN_FILE="${TOKEN_FILE:-$HOME/.config/github-token}"
CLONE_PROTOCOL="${CLONE_PROTOCOL:-ssh}"
API="https://api.github.com"

usage() {
    echo "Usage: $(basename "$0") <USER_NAME> <LOCAL_DIRECTORY>"
    echo "Example: $(basename "$0") victor-porcar ~/workspaces/mine"
    echo
    echo "Token (optional, needed only for private repositories):"
    echo "  export GITHUB_TOKEN=...      or      put it in $TOKEN_FILE (chmod 600)"
    exit 1
}

[ $# -eq 2 ] || usage
name=$1
dir=$2

command -v jq >/dev/null || { echo "jq is required: sudo apt install jq"; exit 1; }

# ---------- token ----------
token="${GITHUB_TOKEN:-}"
if [ -z "$token" ] && [ -r "$TOKEN_FILE" ]; then
    perms=$(stat -c '%a' "$TOKEN_FILE")
    [ "$perms" = "600" ] || echo "WARNING: $TOKEN_FILE is $perms, should be 600"
    token=$(tr -d '[:space:]' < "$TOKEN_FILE")
fi

if [ -n "$token" ]; then
    echo "Listing repositories of the authenticated user (private ones included)"
    endpoint="$API/user/repos"
else
    echo "No token found: listing the PUBLIC repositories of '$name' only"
    endpoint="$API/users/$name/repos"
fi

# ---------- list, one page at a time ----------
url_field="ssh_url"
[ "$CLONE_PROTOCOL" = "https" ] && url_field="clone_url"

repos=()
page=1
while :; do
    if [ -n "$token" ]; then
        body=$(curl -fsSL -H "Authorization: Bearer $token" \
                          -H "Accept: application/vnd.github+json" \
                          "$endpoint?per_page=100&page=$page")
    else
        body=$(curl -fsSL -H "Accept: application/vnd.github+json" \
                          "$endpoint?per_page=100&page=$page")
    fi

    count=$(jq 'length' <<<"$body")
    [ "$count" -eq 0 ] && break

    while IFS= read -r line; do repos+=("$line"); done < <(jq -r ".[].$url_field" <<<"$body")

    [ "$count" -lt 100 ] && break
    page=$((page + 1))
done

echo "${#repos[@]} repositories found"
[ "${#repos[@]}" -gt 0 ] || exit 0

mkdir -p "$dir"
cd "$dir"

# ---------- clone or pull, without stopping at the first failure ----------
failed=()
for repo in "${repos[@]}"; do
    repo_name=$(basename "$repo" .git)

    if [ -d "$repo_name/.git" ]; then
        remote=$(git -C "$repo_name" remote get-url origin 2>/dev/null || echo '')
        case "$remote" in
            *://*@*)        # a credential sits before the host: ssh remotes never match
                echo "  !! $repo_name: its remote carries a credential, rewriting it"
                git -C "$repo_name" remote set-url origin "$repo"
                ;;
        esac
        echo "  pull  $repo_name"
        git -C "$repo_name" pull --ff-only --quiet || failed+=("$repo_name (pull)")
    else
        echo "  clone $repo_name"
        git clone --quiet "$repo" || failed+=("$repo_name (clone)")
    fi
done

if [ "${#failed[@]}" -gt 0 ]; then
    echo
    echo "${#failed[@]} failed:"
    printf '  %s\n' "${failed[@]}"
    exit 1
fi

echo "All repositories processed successfully."
