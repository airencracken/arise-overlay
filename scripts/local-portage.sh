#!/usr/bin/env bash

command=${1:-build}
overlay_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if ! source "$overlay_dir/scripts/lib/error-handling.sh"; then
	printf 'local-portage: cannot load overlay error-handling library\n' >&2
	exit 2
fi
source_dir=${ARISE_SOURCE_DIR:-"${overlay_dir}/../arise"}
state_dir=${ARISE_LOCAL_STATE:-/tmp/arise-local}
version=${ARISE_LOCAL_VERSION:-0.0.0_pre9999}
pf="arise-${version}"
repo_dir="${state_dir}/repo"
dist_dir="${state_dir}/distfiles"
portage_tmp="${state_dir}/portage"
ebuild_path="${repo_dir}/sys-apps/arise/${pf}.ebuild"

die() {
	overlay_error "local-portage: $*"
	exit 1
}

need() {
	overlay_have_command "$1" || die "required command not found: $1"
}

run_required() {
	local description=$1
	shift
	overlay_run_required "$description" "$@" || die "$description"
}

validate_state_dir() {
	local state_base
	state_base=$(basename -- "${state_dir}")
	[[ ${state_dir} == /* && ${state_dir} != / && ${state_dir} != /tmp &&
		${state_dir} != /var/tmp && ${state_base} == arise-* ]] ||
		die "state directory must be an absolute, specifically named arise-* directory"
	[[ ${state_dir} != "${overlay_dir}" && ${state_dir} != "${source_dir}" ]] ||
		die "state directory overlaps a source repository"
}

prepare() {
	need go
	need make
	need tar
	need sha256sum

	[[ -f "${source_dir}/go.mod" ]] || die "Arise source not found at ${source_dir}"
	[[ -f "${overlay_dir}/sys-apps/arise/arise-9999.ebuild" ]] || die "live ebuild not found"
	validate_state_dir

	run_required "create local state directories" mkdir -p "${state_dir}" "${dist_dir}"
	run_required "remove previous disposable repository" rm -rf -- "${repo_dir}"
	run_required "create disposable repository" mkdir -p "${repo_dir}"
	run_required "copy overlay into disposable repository" cp -a "${overlay_dir}/." "${repo_dir}/"
	run_required "create local development ebuild" \
		cp "${repo_dir}/sys-apps/arise/arise-9999.ebuild" "${ebuild_path}"

	local source_archive="${dist_dir}/${pf}.tar.gz"
	run_required "remove previous local source archive" rm -f -- "${source_archive}"
	run_required "create local source archive" tar -C "${source_dir}" \
		--exclude=.git \
		--exclude=./arise \
		--exclude=dist \
		--transform="s,^,${pf}/," \
		-czf "${source_archive}" .

	local dependency_archive="${dist_dir}/${pf}-deps.tar.xz"
	local dependency_key dependency_digest key_input="${state_dir}/dependency-key.input"
	sha256sum "${source_dir}/go.mod" "${source_dir}/go.sum" > "${key_input}"
	[[ $? -eq 0 ]] || die "write dependency cache identity"
	dependency_digest=$(sha256sum "${key_input}")
	[[ $? -eq 0 ]] || die "hash dependency cache identity"
	dependency_digest=${dependency_digest%% *}
	dependency_key="v2-${dependency_digest}"
	local cached_archive="${state_dir}/arise-${dependency_key}-deps.tar.xz"
	if [[ ! -s "${cached_archive}" ]]; then
		echo "Building dependency archive (cached until go.mod or go.sum changes)..."
		run_required "build dependency archive" \
			env GOCACHE="${state_dir}/go-build-cache" \
			make -C "${source_dir}" deps VERSION="${version}"
		run_required "cache dependency archive" \
			cp "${source_dir}/dist/${pf}-deps.tar.xz" "${cached_archive}"
	fi
	run_required "publish disposable dependency archive" \
		cp "${cached_archive}" "${dependency_archive}"

	echo "Prepared ${pf} in ${state_dir}"
}

run_ebuild() {
	need ebuild
	local invocation
	printf -v invocation 'env DISTDIR=%q PORTAGE_TMPDIR=%q ebuild %q' \
		"${dist_dir}" "${portage_tmp}" "${ebuild_path}"
	local phase
	for phase in "$@"; do
		printf -v invocation '%s %q' "${invocation}" "${phase}"
	done

	if (( EUID == 0 )); then
		/bin/bash -c "${invocation}"
		[[ $? -eq 0 ]] || die "ebuild phases failed"
	else
		need su
		echo "Portage phases require root; invoking su."
		su -c "${invocation}"
		[[ $? -eq 0 ]] || die "ebuild phases failed"
	fi
}

case "${command}" in
	prepare)
		prepare
		;;
	build)
		prepare
		run_ebuild manifest clean unpack compile install package
		echo "Local Portage build passed. Binary package is under ${portage_tmp}."
		;;
	install)
		prepare
		run_ebuild manifest clean merge
		echo "Installed ${pf}. Run: arise info"
		;;
	clean)
		validate_state_dir
		if (( EUID == 0 )); then
			run_required "remove local state" rm -rf -- "${state_dir}"
		else
			need su
			printf -v cleanup 'rm -rf -- %q' "${state_dir}"
			su -c "${cleanup}"
			[[ $? -eq 0 ]] || die "remove local state"
		fi
		echo "Removed ${state_dir}"
		;;
	*)
		die "usage: $0 {prepare|build|install|clean}"
		;;
esac
