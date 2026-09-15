#!/bin/sh
set -eu

root=/usr/share/nginx/html
manifest=/tmp/git-mtimes

if [ -f "$manifest" ]; then
    while IFS="$(printf '\t')" read -r timestamp path; do
        [ "$path" = . ] && continue
        [ ! -e "$root/$path" ] || touch -d "@$timestamp" "$root/$path"
    done < "$manifest"
    rm "$manifest"
fi

exec "$@"
