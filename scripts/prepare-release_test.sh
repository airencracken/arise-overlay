#!/usr/bin/env bash

failures=0
check() {
	if ! "$@"; then
		printf 'prepare-release test failed: %q' "$1" >&2
		shift
		printf ' %q' "$@" >&2
		printf '\n' >&2
		failures=$((failures + 1))
	fi
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
fixture=$(mktemp -d /tmp/arise-overlay-release-test.XXXXXX) || exit 1
cleanup() {
	rm -rf -- "$fixture"
}
trap cleanup EXIT

mkdir -p "$fixture/sys-apps/arise" || exit 1
printf 'VERSION ?= 0.0.3\n' >"$fixture/Makefile" || exit 1
printf 'EAPI=8\nARISE_COMMIT="%040d"\nSRC_URI="https://example.invalid/${ARISE_COMMIT}"\n' 0 \
	>"$fixture/sys-apps/arise/arise-0.0.3.ebuild" || exit 1

commit=1111111111111111111111111111111111111111
check env ARISE_OVERLAY_DIR="$fixture" "$script_dir/prepare-release.sh" 0.0.4 "$commit" --prepare-only
check grep -qx "ARISE_COMMIT=\"$commit\"" "$fixture/sys-apps/arise/arise-0.0.4.ebuild"
check grep -qx 'VERSION ?= 0.0.4' "$fixture/Makefile"

if env ARISE_OVERLAY_DIR="$fixture" "$script_dir/prepare-release.sh" bad "$commit" --prepare-only >/dev/null 2>&1; then
	printf 'prepare-release test failed: invalid version was accepted\n' >&2
	failures=$((failures + 1))
fi
if env ARISE_OVERLAY_DIR="$fixture" "$script_dir/prepare-release.sh" 0.0.4 "$commit" --prepare-only >/dev/null 2>&1; then
	printf 'prepare-release test failed: existing target was overwritten\n' >&2
	failures=$((failures + 1))
fi

exit "$failures"
