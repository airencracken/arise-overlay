#!/usr/bin/env bash

# Prepare a pinned versioned Arise ebuild and, by default, regenerate all
# derived repository metadata. Errors are handled explicitly so independent
# cleanup and diagnostics are not hidden by global shell failure modes.

fail() {
	printf 'prepare-release: %s\n' "$*" >&2
	exit 1
}

version=${1:-}
commit=${2:-}
mode=${3:-}

[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] ||
	fail "VERSION must use MAJOR.MINOR.PATCH"
[[ $commit =~ ^[0-9a-f]{40}$ ]] ||
	fail "COMMIT must be a full lowercase 40-character Git object ID"
if [[ -n $mode && $mode != --prepare-only ]]; then
	fail "the optional third argument must be --prepare-only"
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) ||
	fail "cannot resolve script directory"
overlay_dir=${ARISE_OVERLAY_DIR:-$(cd -- "$script_dir/.." && pwd)} ||
	fail "cannot resolve overlay directory"
package_dir=$overlay_dir/sys-apps/arise
[[ -d $package_dir ]] || fail "package directory is missing: $package_dir"

target=$package_dir/arise-$version.ebuild
[[ ! -e $target ]] || fail "target already exists: $target"

template=
while IFS= read -r candidate; do
	template=$candidate
done < <(find "$package_dir" -maxdepth 1 -type f -name 'arise-[0-9]*.ebuild' -print | sort -V)
[[ -n $template ]] || fail "no stable versioned ebuild is available as a template"

target_tmp=$(mktemp "$package_dir/.arise-$version.ebuild.XXXXXX") ||
	fail "cannot create temporary ebuild"
makefile_tmp=
cleanup() {
	[[ -z $target_tmp ]] || rm -f -- "$target_tmp"
	[[ -z $makefile_tmp ]] || rm -f -- "$makefile_tmp"
}
trap cleanup EXIT

if ! awk -v commit="$commit" '
	/^ARISE_COMMIT=/ { print "ARISE_COMMIT=\"" commit "\""; next }
	{ print }
' "$template" >"$target_tmp"; then
	fail "cannot render versioned ebuild"
fi
if ! grep -q "^ARISE_COMMIT=\"$commit\"$" "$target_tmp"; then
	fail "template does not contain an ARISE_COMMIT assignment"
fi
if ! chmod 0644 "$target_tmp" || ! mv -- "$target_tmp" "$target"; then
	fail "cannot publish versioned ebuild"
fi
target_tmp=

makefile=$overlay_dir/Makefile
[[ -f $makefile ]] || fail "Makefile is missing"
makefile_tmp=$(mktemp "$overlay_dir/.Makefile.XXXXXX") ||
	fail "cannot create temporary Makefile"
if ! awk -v version="$version" '
	/^VERSION[[:space:]]*\?=/ { print "VERSION ?= " version; found=1; next }
	{ print }
	END { if (!found) exit 3 }
' "$makefile" >"$makefile_tmp"; then
	fail "cannot update the Makefile release default"
fi
if ! chmod --reference="$makefile" "$makefile_tmp" ||
	! mv -- "$makefile_tmp" "$makefile"; then
	fail "cannot publish the updated Makefile"
fi
makefile_tmp=

printf 'Prepared %s at commit %s\n' "${target#$overlay_dir/}" "$commit"
if [[ $mode == --prepare-only ]]; then
	exit 0
fi

if ! make -C "$overlay_dir" manifest VERSION="$version"; then
	fail "Manifest generation failed"
fi

repositories_configuration=$(printf \
	'[gentoo]\nlocation = /var/db/repos/gentoo\nauto-sync = no\n\n[arise-overlay]\nlocation = %s\nmasters = gentoo\nauto-sync = no\n' \
	"$overlay_dir") ||
	fail "cannot render repositories configuration"
if ! egencache --repositories-configuration="$repositories_configuration" \
	--repo=arise-overlay --cache-dir="$overlay_dir/metadata/md5-cache" --update; then
	fail "metadata cache generation failed"
fi
if ! make -C "$overlay_dir" check; then
	fail "overlay QA failed"
fi

printf 'Release metadata for arise %s is ready.\n' "$version"
