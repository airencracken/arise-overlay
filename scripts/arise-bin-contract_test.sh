#!/usr/bin/env bash

# Validate the staged binary package contract without fetching unpublished assets.

overlay_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
ebuild=$overlay_dir/sys-apps/arise-bin/arise-bin-0.0.23.ebuild
metadata=$overlay_dir/sys-apps/arise-bin/metadata.xml
contract=$overlay_dir/BINARY_RELEASE_CONTRACT.md
makefile=$overlay_dir/Makefile
status=0

for required_file in "$ebuild" "$metadata" "$contract"; do
	if [[ ! -f $required_file ]]; then
		printf 'arise-bin contract file is missing: %s\n' "$required_file" >&2
		status=1
	fi
done

for required in \
	'PACKAGE ?= arise' \
	'sys-apps/$(PACKAGE)/$(PACKAGE)-$(VERSION).ebuild'; do
	if ! grep -Fq -- "$required" "$makefile"; then
		printf 'overlay Manifest target cannot select arise-bin: %s\n' "$required" >&2
		status=1
	fi
done

if (( status != 0 )); then
	exit "$status"
fi

for required in \
	'arise-bin-${version}-linux-amd64.tar.xz' \
	'arise-artifact-manifest.json' \
	'mutually exclusive' \
	'Do not publish or Manifest' \
	'source-to-binary' \
	'binary-to-source replacement'; do
	if ! grep -Fq -- "$required" "$contract"; then
		printf 'binary release contract is missing: %s\n' "$required" >&2
		status=1
	fi
done

for required in \
	'!sys-apps/arise' \
	'RESTRICT="strip"' \
	'QA_PREBUILT="usr/bin/arise"' \
	'[[ ${reported_version} == "arise ${PV}" ]]' \
	'${linkage} == *"x86-64"*' \
	'${linkage} == *"statically linked"*' \
	'newbashcomp arise-completion.bash arise' \
	'dodoc README.md LICENSE arise-artifact-manifest.json'; do
	if ! grep -Fq -- "$required" "$ebuild"; then
		printf 'arise-bin ebuild contract is missing: %s\n' "$required" >&2
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
	if ! grep -Fq -- "$dependency" "$ebuild"; then
		printf 'arise-bin runtime dependency is missing: %s\n' "$dependency" >&2
		status=1
	fi
done

for forbidden in \
	'dev-lang/go' \
	'go-module' \
	'src_compile()' \
	'ACCEPT_KEYWORDS'; do
	if grep -Fq -- "$forbidden" "$ebuild"; then
		printf 'arise-bin ebuild contains forbidden source-build behavior: %s\n' "$forbidden" >&2
		status=1
	fi
done

exit "$status"
