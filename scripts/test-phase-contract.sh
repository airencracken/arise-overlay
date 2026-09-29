#!/usr/bin/env bash

overlay_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
scratch=$(mktemp -d) || exit 1
cleanup() { rm -rf -- "$scratch"; }
trap cleanup EXIT
printf '#!/usr/bin/env bash\nexit 42\n' > "$scratch/go" || exit 1
chmod 755 "$scratch/go" || exit 1
inherit() { :; }
die() { printf 'expected test failure: %s\n' "$*" >&2; exit 42; }
eqawarn() { printf '%s\n' "$*" >&2; }
dispatch=0
for portage_script in /usr/lib/portage/python*/ebuild.sh; do
	if [[ -f $portage_script ]]; then
		source <(sed -n '/^__qa_call() {/,/^}/p' "$portage_script") || exit 1
		source <(sed -n '/^__ebuild_phase() {/,/^}/p' "${portage_script%/*}/phase-functions.sh") || exit 1
		dispatch=1
		break
	fi
done
PATH="$scratch:$PATH"
T="$scratch"
GOCACHE="$scratch/cache"
GOMODCACHE="$scratch/mod"
status=0
for ebuild_file in "$overlay_dir"/sys-apps/arise/*.ebuild; do
	(
		source "$ebuild_file" || exit 2
		if (( dispatch )); then
			__ebuild_phase src_test
		else
			src_test
			# Match a dispatcher that ignores a phase's return value.
			exit 0
		fi
	)
	phase_status=$?
	if (( phase_status != 42 )); then
		printf '%s did not propagate the Go test failure (exit %s)\n' "$ebuild_file" "$phase_status" >&2
		status=1
	fi
done
exit "$status"
