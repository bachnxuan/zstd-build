#!/usr/bin/env bash

# Recreate directory
reset_dir() {
    local path="$1"
    [[ -d $path ]] && rm -rf -- "$path"
    mkdir -p -- "$path"
}

# Shallow clone owner/repo@branch into a destination
git_clone() {
    local source="$1"
    local dest="$2"
    local repo branch

    IFS=':@' read -r repo branch <<< "$source"
    git clone -q --depth=1 --single-branch --no-tags \
        "https://github.com/${repo}" -b "${branch}" "${dest}"
}

# Fetch latest tag
latest_tag() {
    gh api "repos/$1/releases/latest" --jq '.tag_name'
}

info() {
    printf '[INFO] %s\n' "$1"
}
