#!/usr/bin/env bash

# Accumulate independent QA failures without global shell error modes.

overlay_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
if ! source "$overlay_dir/scripts/lib/error-handling.sh"; then
	printf 'error: cannot load overlay error-handling library\n' >&2
	exit 2
fi

status=0
if ! "$overlay_dir/scripts/prepare-release_test.sh"; then
	status=1
fi
if ! "$overlay_dir/scripts/check-release-pin_test.sh"; then
	status=1
fi
for required in \
	metadata/layout.conf \
	profiles/repo_name \
	sys-apps/arise/metadata.xml \
	sys-apps/arise/arise-0.0.1.ebuild \
	sys-apps/arise/arise-9999.ebuild \
	scripts/templates/arise-vendor.ebuild.in; do
	if [[ ! -f $overlay_dir/$required ]]; then
		overlay_error "required overlay file is missing: $required"
		status=1
	fi
done

while IFS= read -r ebuild_file; do
	if ! bash -n "$ebuild_file"; then
		status=1
	fi
	relative=${ebuild_file#"$overlay_dir/"}
	category=${relative%%/*}
	cache_relative=$category/${relative##*/}
	cache_relative=${cache_relative%.ebuild}
	cache_file=$overlay_dir/metadata/md5-cache/$cache_relative
	if [[ ! -f $cache_file ]]; then
		overlay_error "metadata cache is missing for $relative: metadata/md5-cache/$cache_relative"
		status=1
	fi
done < <(find "$overlay_dir" -type f -name '*.ebuild' -print | sort)

while IFS= read -r script_file; do
	if ! bash -n "$script_file"; then
		status=1
	fi
done < <(find "$overlay_dir/scripts" -type f -name '*.sh' -print | sort)

if overlay_have_command xmllint; then
	if ! xmllint --noout "$overlay_dir/sys-apps/arise/metadata.xml"; then
		status=1
	fi
else
	printf 'check-overlay: xmllint unavailable; skipped XML syntax check\n' >&2
fi

if overlay_have_command pkgcheck; then
	if ! pkgcheck scan "$overlay_dir"; then
		status=1
	fi
else
	printf 'check-overlay: pkgcheck unavailable; skipped repository QA\n' >&2
fi

if grep -R -n -E '/home/[^/]+|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|github_pat_|ghp_' \
	"$overlay_dir" --exclude-dir=.git --exclude=.git --exclude=check-overlay.sh; then
	overlay_error "overlay contains a host path or credential-like text"
	status=1
fi

exit "$status"
