#!/usr/bin/env bash

# Validate the public bootstrap boundary without global shell error modes.

overlay_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
document=$overlay_dir/BOOTSTRAP.md
version=$(awk '$1 == "VERSION" { print $3; exit }' "$overlay_dir/Makefile")
release_ebuild=$overlay_dir/sys-apps/arise/arise-${version}.ebuild
status=0

if [[ -z $version || ! -f $release_ebuild ]]; then
	printf 'bootstrap contract cannot resolve current release ebuild: %s\n' "$release_ebuild" >&2
	exit 1
fi

for required in \
	'emerge --oneshot dev-vcs/git app-eselect/eselect-repository' \
	'emaint sync -r arise-overlay' \
	'sys-apps/arise ~amd64' \
	'emerge --ask sys-apps/arise' \
	'arise sync' \
	'--with-bdeps=y' \
	'Keep Portage installed'; do
	if ! grep -Fq -- "$required" "$document"; then
		printf 'bootstrap contract missing: %s\n' "$required" >&2
		status=1
	fi
done

for dependency in \
	'app-arch/bzip2' \
	'app-arch/tar' \
	'app-arch/xz-utils' \
	'app-shells/bash' \
	'sys-apps/portage' \
	'sys-apps/sandbox' \
	'sys-apps/util-linux'; do
	if ! grep -Fq -- "$dependency" "$release_ebuild"; then
		printf 'release runtime dependency missing: %s\n' "$dependency" >&2
		status=1
	fi
done

for forbidden in \
	'emerge --depclean sys-apps/portage' \
	'ACCEPT_KEYWORDS="~amd64" emerge' \
	'--jobs-tmpdir-require-free-gb=0'; do
	if grep -Fq -- "$forbidden" "$document"; then
		printf 'bootstrap contract contains unsafe guidance: %s\n' "$forbidden" >&2
		status=1
	fi
done

exit "$status"
