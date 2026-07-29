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
release_dist=$(mktemp -d /tmp/arise-overlay-release-dist-test.XXXXXX) || exit 1
release_tmp=$(mktemp -d /tmp/arise-overlay-release-portage-test.XXXXXX) || exit 1
cleanup() {
	rm -rf -- "$fixture" "$release_dist" "$release_tmp"
}
trap cleanup EXIT

mkdir -p "$fixture/sys-apps/arise" "$fixture/scripts/templates" || exit 1
printf 'VERSION ?= 0.0.3\n' >"$fixture/Makefile" || exit 1
printf 'EAPI=8\nARISE_COMMIT="%040d"\nSRC_URI="https://example.invalid/${ARISE_COMMIT}"\n' 0 \
	>"$fixture/sys-apps/arise/arise-0.0.3.ebuild" || exit 1
printf 'EAPI=8\ninherit git-r3\nEGIT_BRANCH="master"\n' \
	>"$fixture/sys-apps/arise/arise-9999.ebuild" || exit 1
printf 'EAPI=8\nARISE_COMMIT="@ARISE_COMMIT@"\nSRC_URI="https://example.invalid/${P}-vendor.tar.xz"\nGOPROXY=off ego build -mod=vendor\n' \
	>"$fixture/scripts/templates/arise-vendor.ebuild.in" || exit 1

commit=1111111111111111111111111111111111111111
check env ARISE_OVERLAY_DIR="$fixture" "$script_dir/prepare-release.sh" 0.0.4 "$commit" --prepare-only
check grep -qx "ARISE_COMMIT=\"$commit\"" "$fixture/sys-apps/arise/arise-0.0.4.ebuild"
check grep -Fq '${P}-vendor.tar.xz' "$fixture/sys-apps/arise/arise-0.0.4.ebuild"
check grep -Fq -- '-mod=vendor' "$fixture/sys-apps/arise/arise-0.0.4.ebuild"
check grep -qx 'VERSION ?= 0.0.4' "$fixture/Makefile"
if grep -q 'EGIT_BRANCH' "$fixture/sys-apps/arise/arise-0.0.4.ebuild"; then
	printf 'prepare-release test failed: live ebuild was used as the release template\n' >&2
	failures=$((failures + 1))
fi

if env ARISE_OVERLAY_DIR="$fixture" "$script_dir/prepare-release.sh" bad "$commit" --prepare-only >/dev/null 2>&1; then
	printf 'prepare-release test failed: invalid version was accepted\n' >&2
	failures=$((failures + 1))
fi
if env ARISE_OVERLAY_DIR="$fixture" "$script_dir/prepare-release.sh" 0.0.4 "$commit" --prepare-only >/dev/null 2>&1; then
	printf 'prepare-release test failed: existing target was overwritten\n' >&2
	failures=$((failures + 1))
fi

command_log="$fixture/release-commands.log"
fake_bin="$fixture/fake-bin"
mkdir -p "$fake_bin" || exit 1
printf '%s\n' \
	'#!/usr/bin/env bash' \
	'printf "ebuild DISTDIR=%s PORTAGE_TMPDIR=%s PORTAGE_USERNAME=%s PORTAGE_GRPNAME=%s ARGS=%s\n" "$DISTDIR" "$PORTAGE_TMPDIR" "$PORTAGE_USERNAME" "$PORTAGE_GRPNAME" "$*" >>"$RELEASE_COMMAND_LOG"' \
	>"$fake_bin/ebuild" || exit 1
printf '%s\n' \
	'#!/usr/bin/env bash' \
	'printf "egencache ARGS=%s\n" "$*" >>"$RELEASE_COMMAND_LOG"' \
	>"$fake_bin/egencache" || exit 1
printf '%s\n' \
	'#!/usr/bin/env bash' \
	'printf "make ARGS=%s\n" "$*" >>"$RELEASE_COMMAND_LOG"' \
	>"$fake_bin/make" || exit 1
chmod 0755 "$fake_bin/ebuild" "$fake_bin/egencache" "$fake_bin/make" || exit 1

check env \
	ARISE_OVERLAY_DIR="$fixture" \
	ARISE_RELEASE_DISTDIR="$release_dist" \
	ARISE_RELEASE_PORTAGE_TMPDIR="$release_tmp" \
	RELEASE_COMMAND_LOG="$command_log" \
	PATH="$fake_bin:$PATH" \
	"$script_dir/prepare-release.sh" 0.0.5 "$commit"
check grep -Fq "ebuild DISTDIR=$release_dist PORTAGE_TMPDIR= PORTAGE_USERNAME= PORTAGE_GRPNAME= ARGS=--force $fixture/sys-apps/arise/arise-0.0.5.ebuild manifest" "$command_log"
check grep -Fq "egencache ARGS=--repositories-configuration=" "$command_log"
check grep -Fq "make ARGS=-C $fixture check" "$command_log"
check grep -Fq "ebuild DISTDIR=$release_dist PORTAGE_TMPDIR=$release_tmp PORTAGE_USERNAME=" "$command_log"
check grep -Fq "ARGS=$fixture/sys-apps/arise/arise-0.0.5.ebuild clean unpack compile test" "$command_log"
check grep -Fq "env -i" \
	"$script_dir/../sys-apps/arise/arise-9999.ebuild"
check grep -Fq "GOPROXY=off" \
	"$script_dir/../sys-apps/arise/arise-9999.ebuild"
check grep -Fq "arise-overlay-assets/releases/download" \
	"$script_dir/templates/arise-vendor.ebuild.in"
check grep -Fq "arise-vendor-manifest" \
	"$script_dir/templates/arise-vendor.ebuild.in"

exit "$failures"
