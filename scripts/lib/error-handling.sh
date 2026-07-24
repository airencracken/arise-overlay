#!/usr/bin/env bash

# Shared explicit error handling for overlay maintenance tools. This library
# changes no global shell options and never exits its caller.

overlay_error() {
	printf 'error: %s\n' "$*" >&2
}

overlay_have_command() {
	command -v "$1" >/dev/null 2>&1
}

overlay_require_commands() {
	local command_name missing=0
	for command_name in "$@"; do
		if ! overlay_have_command "$command_name"; then
			overlay_error "required command not found: $command_name"
			missing=1
		fi
	done
	return "$missing"
}

overlay_run_required() {
	local description=$1
	shift
	"$@"
	local status=$?
	if (( status != 0 )); then
		overlay_error "$description failed with status $status"
	fi
	return "$status"
}
