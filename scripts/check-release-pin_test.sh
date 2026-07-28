#!/usr/bin/env bash

failures=0
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1
fixture=$(mktemp -d /tmp/arise-overlay-pin-test.XXXXXX) || exit 1
cleanup() {
	rm -rf -- "$fixture"
}
trap cleanup EXIT

mkdir -p "$fixture/overlay/sys-apps/arise" "$fixture/bin" || exit 1
matching=1111111111111111111111111111111111111111
different=2222222222222222222222222222222222222222
printf 'ARISE_COMMIT="%s"\n' "$matching" \
	>"$fixture/overlay/sys-apps/arise/arise-0.0.6.ebuild" || exit 1
printf '%s\n' \
	'#!/usr/bin/env bash' \
	'printf "%s\trefs/tags/v0.0.6\n" "$FAKE_TAG_OBJECT"' \
	'if [[ ${FAKE_PEELED_COMMIT:-} ]]; then' \
	'	printf "%s\trefs/tags/v0.0.6^{}\n" "$FAKE_PEELED_COMMIT"' \
	'fi' \
	>"$fixture/bin/git" || exit 1
chmod 0755 "$fixture/bin/git" || exit 1

if ! env \
	ARISE_OVERLAY_DIR="$fixture/overlay" \
	FAKE_TAG_OBJECT="$different" \
	FAKE_PEELED_COMMIT="$matching" \
	PATH="$fixture/bin:$PATH" \
	"$script_dir/check-release-pin.sh" 0.0.6 >/dev/null; then
	printf 'check-release-pin test failed: matching peeled tag was rejected\n' >&2
	failures=$((failures + 1))
fi

if env \
	ARISE_OVERLAY_DIR="$fixture/overlay" \
	FAKE_TAG_OBJECT="$different" \
	PATH="$fixture/bin:$PATH" \
	"$script_dir/check-release-pin.sh" 0.0.6 >/dev/null 2>&1; then
	printf 'check-release-pin test failed: mismatched tag was accepted\n' >&2
	failures=$((failures + 1))
fi

if env \
	ARISE_OVERLAY_DIR="$fixture/overlay" \
	FAKE_TAG_OBJECT="$matching" \
	PATH="$fixture/bin:$PATH" \
	"$script_dir/check-release-pin.sh" invalid >/dev/null 2>&1; then
	printf 'check-release-pin test failed: invalid version was accepted\n' >&2
	failures=$((failures + 1))
fi

exit "$failures"
