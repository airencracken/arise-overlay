#!/usr/bin/env bash

overlay_dir=${ARISE_OVERLAY_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}
source_repo=${ARISE_SOURCE_REPO:-https://github.com/airencracken/arise.git}
version=${1:-}

if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	printf 'error: usage: %s VERSION\n' "${0##*/}" >&2
	exit 2
fi

ebuild=$overlay_dir/sys-apps/arise/arise-$version.ebuild
if [[ ! -f $ebuild ]]; then
	printf 'error: release ebuild does not exist: %s\n' "$ebuild" >&2
	exit 2
fi

pin=$(awk -F'"' '/^ARISE_COMMIT="[0-9a-f]{40}"$/ { print $2; exit }' "$ebuild")
if [[ ! $pin =~ ^[0-9a-f]{40}$ ]]; then
	printf 'error: %s does not contain one valid ARISE_COMMIT\n' "$ebuild" >&2
	exit 2
fi

refs=$(git ls-remote "$source_repo" "refs/tags/v$version" "refs/tags/v$version^{}")
git_status=$?
if (( git_status != 0 )); then
	printf 'error: could not resolve source tag v%s\n' "$version" >&2
	exit "$git_status"
fi

tag_commit=$(awk -v peeled="refs/tags/v$version^{}" -v direct="refs/tags/v$version" '
	$2 == peeled { peeled_commit=$1 }
	$2 == direct { direct_commit=$1 }
	END {
		if (peeled_commit != "") print peeled_commit
		else print direct_commit
	}
' <<<"$refs")
if [[ ! $tag_commit =~ ^[0-9a-f]{40}$ ]]; then
	printf 'error: source tag v%s was not found\n' "$version" >&2
	exit 2
fi

if [[ $pin != "$tag_commit" ]]; then
	printf 'error: arise-%s pins %s, but v%s resolves to %s\n' \
		"$version" "$pin" "$version" "$tag_commit" >&2
	exit 1
fi

printf 'release pin verified: arise-%s -> %s\n' "$version" "$pin"
